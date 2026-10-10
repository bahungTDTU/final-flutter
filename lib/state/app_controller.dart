import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/api.dart';
import '../data/local_store.dart';
import '../data/realtime_feed.dart';
import '../domain/note.dart';
import '../domain/workspace.dart';
import '../domain/note_plan.dart';
import '../domain/focus_session.dart';
import '../domain/writing_tools.dart';

class AppController extends ChangeNotifier {
  AppController(this.api, this.local, {this.realtime});
  final Api api;
  final LocalStore local;
  final RealtimeFeed? realtime;
  final remoteChanges = ChangeNotifier();
  RealtimeStatus realtimeStatus = RealtimeStatus.idle;
  Timer? _realtimeRefresh;
  bool _foreground = true, _realtimeDirty = false;
  bool get realtimeLive => realtimeStatus == RealtimeStatus.live;
  bool get foreground => _foreground;
  int realtimeSignals = 0;

  void setForeground(bool value) {
    if (_foreground == value || _disposed) return;
    _foreground = value;
    if (!value) {
      realtime?.stop();
      realtimeStatus = RealtimeStatus.idle;
      _realtimeRefresh?.cancel();
    } else {
      _startRealtime();
      // A client without SSE must catch up on resume rather than wait 15s.
      if (realtime == null) unawaited(synchronize());
    }
    notifyListeners();
  }

  void _startRealtime() {
    if (realtime == null ||
        !_foreground ||
        _disposed ||
        user == null ||
        token == null) {
      return;
    }
    final generation = _generation, sessionToken = token;
    bool active() =>
        !_disposed &&
        _foreground &&
        _generation == generation &&
        token == sessionToken;
    realtime!.start(
      sessionToken!,
      onRefresh: () {
        if (!active()) return;
        realtimeSignals++;
        _realtimeDirty = true;
        remoteChanges.notifyListeners();
        _scheduleRealtimeRefresh();
      },
      onExpired: () {
        if (active()) unawaited(logout());
      },
      onState: (state) {
        if (!active()) return;
        realtimeStatus = state;
        notifyListeners();
      },
    );
  }

  void _scheduleRealtimeRefresh() {
    if (!_foreground ||
        _disposed ||
        !_realtimeDirty ||
        user == null ||
        _realtimeRefresh?.isActive == true) {
      return;
    }
    _realtimeRefresh = Timer(const Duration(milliseconds: 100), () {
      if (_syncing) {
        return; // synchronize's finally drains a signal received in-flight.
      }
      _realtimeDirty = false;
      unawaited(synchronize());
    });
  }

  final uuid = const Uuid();
  Map<String, dynamic>? user;
  String? token, error;
  String? emailDelivery;

  void recordEmailDelivery(String status) {
    emailDelivery = status;
    if (!_disposed) notifyListeners();
  }

  bool ready = false, busy = false, online = true, _syncing = false;
  bool _disposed = false;
  bool _localWriteFailed = false;
  bool _accountLoaded = true;
  bool _hasAccountSnapshot = false;
  bool sessionRemovalFailed = false;
  int _generation = 0;
  List<Note> notes = [];
  WorkspaceData workspace = WorkspaceData();
  final _importCommits = <String, Completer<bool>>{};
  List<Map<String, dynamic>> pending = [];
  List<Map<String, dynamic>> pendingPreferences = [];
  Map<String, dynamic> drafts = {}, conflicts = {}, recoveries = {};
  Map<String, Map<String, dynamic>> protectedVaults = {};
  final accessUnavailable = <String>{};
  List<String> labels = [];
  Map<String, Map<String, dynamic>> labelCatalogue = {}, remoteLabels = {};
  List<Map<String, dynamic>> pendingLabels = [];
  Map<String, dynamic> labelConflicts = {};
  Uint8List? avatarBytes;
  int cachedAvatarRevision = 0;
  String? avatarError;
  String labelName(String id, [Note? note]) =>
      labelCatalogue[id]?['name'] as String? ?? note?.labelNames[id] ?? id;
  List<String> noteLabelIds(Note note) => note.labels
      .where((id) => labelCatalogue[id]?['deleted'] != true)
      .toList();
  bool labelNameExists(String name, [String? except]) => labels.any(
    (id) =>
        id != except &&
        labelName(id).toLowerCase() == name.trim().toLowerCase(),
  );
  bool get labelsPending => pendingLabels.isNotEmpty;
  Map<String, dynamic> preferences = {
    'grid': true,
    'dark': false,
    'font_size': 16.0,
  };
  Timer? _retry;
  Future<void> _writes = Future.value();
  final Map<String, Future<void>> _grantCalls = {};

  // Also orders grants across readers when a route is closed and reopened.
  Future<dynamic> noteGrantCall(
    String id,
    String action,
    String? sessionToken, [
    Map<String, dynamic>? body,
  ]) {
    final key = '$sessionToken:$id';
    final result = (_grantCalls[key] ?? Future<void>.value()).then(
      (_) => api.call(
        'POST',
        '/notes/$id/$action',
        token: sessionToken,
        body: body,
      ),
    );
    final settled = result.then<void>((_) {}, onError: (Object _) {});
    _grantCalls[key] = settled;
    unawaited(
      settled.then((_) {
        if (identical(_grantCalls[key], settled)) _grantCalls.remove(key);
      }),
    );
    return result;
  }

  String get accountKey => 'account:${user!['id']}';
  bool get grid => preferences['grid'] as bool? ?? true;
  bool get dark => preferences['dark'] as bool? ?? false;
  double get fontSize => (preferences['font_size'] as num? ?? 16).toDouble();
  bool hasPending(String id) => pending.any((op) => op['note_id'] == id);
  bool get syncing => _syncing;
  bool get localWriteFailed => _localWriteFailed;

  Future<void> changeNoteProtection(
    String id, {
    required String currentPassword,
    required String? password,
    String? confirmation,
  }) async {
    final note = notes.where((n) => n.id == id).firstOrNull;
    if (user == null || note?.role != 'owner') {
      throw StateError('Owner required');
    }
    if (_syncing || hasPending(id) || drafts.containsKey(id)) {
      throw StateError(
        'Sync and finish local draft before changing protection',
      );
    }
    final generation = _generation;
    final response = await api.call(
      'POST',
      '/notes/$id/protection',
      token: token,
      body: {
        'current_password': currentPassword,
        'password': password,
        'confirmation': confirmation,
      },
    );
    if (_disposed || generation != _generation) return;
    if (password != null) {
      _archiveLocked(
        Note(
          id: id,
          title: 'Ghi chú đã khóa',
          content: '',
          revision: response['revision'] as int,
          updatedAt: '',
          role: 'owner',
          locked: true,
          pinnedAt: note?.pinnedAt,
          shared: note?.isShared ?? false,
        ),
      );
      notifyListeners();
      try {
        await _persist();
      } catch (_) {
        error = 'Server đã cập nhật khóa. Chưa ghi được dữ liệu trên thiết bị; giữ app mở và thử đồng bộ.';
        notifyListeners();
        return;
      }
    }
    await synchronize();
  }

  Future<void> initialize() async {
    if (_disposed) return;
    try {
      final session = await local.read('session');
      if (_disposed) return;
      if (session != null) {
        user = Map<String, dynamic>.from(session['user'] as Map);
        token = session['token'] as String;
        await _loadAccount();
      }
    } catch (e) {
      if (_disposed) return;
      user = null;
      token = null;
      error = 'Không thể mở dữ liệu local: $e';
    }
    if (_disposed) return;
    ready = true;
    notifyListeners();
    _retry = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_disposed && _foreground && user != null) unawaited(synchronize());
    });
    if (_foreground && user != null) unawaited(synchronize());
    _startRealtime();
  }

  Future<void> _loadAccount() async {
    accessUnavailable.clear();
    _accountLoaded = false;
    _hasAccountSnapshot = false;
    notes = [];
    workspace = WorkspaceData();
    pending = [];
    pendingPreferences = [];
    drafts = {};
    conflicts = {};
    recoveries = {};
    protectedVaults = {};
    labels = [];
    labelCatalogue = {};
    remoteLabels = {};
    pendingLabels = [];
    labelConflicts = {};
    avatarBytes = null;
    cachedAvatarRevision = 0;
    avatarError = null;
    preferences = {'grid': true, 'dark': false, 'font_size': 16.0};
    await _writes.catchError((_) {});
    final durable = await local.read(accountKey);
    _hasAccountSnapshot = durable != null;
    final cached = durable ?? {};
    workspace = WorkspaceData.fromJson(cached['workspace'] as Map?);
    notes = (cached['notes'] as List? ?? [])
        .map((n) => Note.fromListingJson(Map<String, dynamic>.from(n as Map)))
        .toList();
    pending = (cached['pending'] as List? ?? [])
        .map((op) => Map<String, dynamic>.from(op as Map))
        .toList();
    drafts = Map<String, dynamic>.from(cached['drafts'] as Map? ?? {});
    recoveries = Map<String, dynamic>.from(cached['recoveries'] as Map? ?? {});
    protectedVaults = (cached['protected_vaults'] as Map? ?? {}).map(
      (key, value) =>
          MapEntry(key as String, Map<String, dynamic>.from(value as Map)),
    );
    accessUnavailable.addAll(
      recoveries.values
          .whereType<Map>()
          .where((r) => ['permission', 'revoked'].contains(r['reason']))
          .map((r) => r['source_id'] as String),
    );
    pendingPreferences = (cached['pending_preferences'] as List? ?? [])
        .map((op) => Map<String, dynamic>.from(op as Map))
        .toList();
    conflicts = Map<String, dynamic>.from(cached['conflicts'] as Map? ?? {});
    labels = (cached['labels'] as List? ?? []).cast<String>();
    labelCatalogue = (cached['label_catalogue'] as Map? ?? {}).map(
      (key, value) =>
          MapEntry(key as String, Map<String, dynamic>.from(value as Map)),
    );
    remoteLabels = (cached['remote_labels'] as Map? ?? {}).map(
      (key, value) =>
          MapEntry(key as String, Map<String, dynamic>.from(value as Map)),
    );
    pendingLabels = (cached['pending_labels'] as List? ?? [])
        .map((op) => Map<String, dynamic>.from(op as Map))
        .toList();
    labelConflicts = Map<String, dynamic>.from(
      cached['label_conflicts'] as Map? ?? {},
    );
    if (cached['label_catalogue'] == null) _migrateLocalLabels();
    _rebuildLabels();
    final avatar = cached['avatar'] as Map?;
    cachedAvatarRevision = avatar?['revision'] as int? ?? 0;
    avatarBytes = avatar?['data'] == null
        ? null
        : base64Decode(avatar!['data'] as String);
    preferences = Map<String, dynamic>.from(
      cached['preferences'] as Map? ??
          user?['preferences'] as Map? ??
          {'grid': true, 'dark': false, 'font_size': 16.0},
    );
    _accountLoaded = true;
  }

  Future<void> _persist() {
    if (user == null) return Future.value();
    if (!_accountLoaded) {
      throw StateError('Kho tài khoản chưa mở được; không ghi đè dữ liệu.');
    }
    final key = accountKey;
    final protectedSnapshot = Map<String, dynamic>.from(protectedVaults);
    final workspaceSnapshot = workspace.toJson();
    final snapshot = {
      'notes': notes.map((n) => n.toListingJson()).toList(),
      'pending': pending.map((op) => Map<String, dynamic>.from(op)).toList(),
      'drafts': Map<String, dynamic>.from(drafts),
      'recoveries': Map<String, dynamic>.from(recoveries),
      'pending_preferences': pendingPreferences
          .map((op) => Map<String, dynamic>.from(op))
          .toList(),
      'conflicts': Map<String, dynamic>.from(conflicts),
      'labels': List<String>.from(labels),
      'label_catalogue': labelCatalogue.map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
      ),
      'remote_labels': remoteLabels.map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
      ),
      'pending_labels': pendingLabels
          .map((op) => Map<String, dynamic>.from(op))
          .toList(),
      'label_conflicts': Map<String, dynamic>.from(labelConflicts),
      'avatar': {
        'revision': cachedAvatarRevision,
        'data': avatarBytes == null ? null : base64Encode(avatarBytes!),
      },
      'preferences': Map<String, dynamic>.from(preferences),
    };
    return _queueWrite(() async {
      // Protected encryption may finish after this ordinary snapshot was captured.
      // Merge its independently serialized field from the durable record at commit.
      final durable = await local.read(key);
      snapshot['protected_vaults'] =
          durable?['protected_vaults'] ?? protectedSnapshot;
      // Independently serialized personal workspace must survive older captures.
      snapshot['workspace'] = durable?['workspace'] ?? workspaceSnapshot;
      await local.write(key, snapshot);
      if (user != null && accountKey == key) _hasAccountSnapshot = true;
    });
  }

  Future<void> _persistDrafts() {
    final storage = local;
    if (storage is! DraftLocalStore ||
        !storage.supportsDraftWrites ||
        !_hasAccountSnapshot) {
      return _persist(); // First publish and legacy test stores keep snapshot semantics.
    }
    if (user == null) return Future.value();
    if (!_accountLoaded) {
      throw StateError('Kho tài khoản chưa mở được; không ghi đè dữ liệu.');
    }
    final key = accountKey;
    final projection = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(drafts)) as Map,
    );
    return _queueWrite(() => storage.writeDrafts(key, projection));
  }

  Future<void> storeProtectedEnvelope(
    String id,
    String account,
    Future<Map<String, dynamic>> Function() encrypt,
  ) {
    final key = 'account:$account';
    final fallback = user?['id'] == account
        ? {
            'notes': notes.map((n) => n.toListingJson()).toList(),
            'pending': pending,
            'drafts': drafts,
            'recoveries': recoveries,
            'preferences': preferences,
            'protected_vaults': protectedVaults,
            'workspace': workspace.toJson(),
          }
        : <String, dynamic>{};
    final write = _queueWrite(() async {
      final envelope = await encrypt();
      final snapshot = await local.read(key) ?? fallback;
      final records = Map<String, dynamic>.from(
        snapshot['protected_vaults'] as Map? ?? {},
      );
      final old = records[id] as Map?;
      records[id] = {
        ...envelope,
        if (old?['copy_id'] != null) 'copy_id': old!['copy_id'],
      };
      snapshot['protected_vaults'] = records;
      await local.write(key, snapshot);
      if (user?['id'] == account) {
        protectedVaults = records.map(
          (key, value) =>
              MapEntry(key, Map<String, dynamic>.from(value as Map)),
        );
      }
    });
    return write.then((_) {
      if (user?['id'] == account && !_disposed) notifyListeners();
    });
  }

  Future<void> invalidateProtectedVault(String id, String account) =>
      _queueWrite(() async {
        final key = 'account:$account';
        final snapshot = await local.read(key);
        if (snapshot == null) return;
        final records = Map<String, dynamic>.from(
          snapshot['protected_vaults'] as Map? ?? {},
        );
        final previous = records[id] as Map?;
        if (previous?['dirty'] == true) {
          records[id] = {...previous!, 'recovery_only': true};
        } else {
          records.remove(id);
        }
        snapshot['protected_vaults'] = records;
        await local.write(key, snapshot);
        if (user?['id'] == account) {
          protectedVaults = records.map(
            (key, value) =>
                MapEntry(key, Map<String, dynamic>.from(value as Map)),
          );
        }
      });

  Future<Map<String, dynamic>?> readProtectedEnvelope(
    String id,
    String account,
  ) async {
    await _writes.catchError((_) {});
    final snapshot = await local.read('account:$account');
    final value = (snapshot?['protected_vaults'] as Map?)?[id];
    return value == null ? null : Map<String, dynamic>.from(value as Map);
  }

  Future<String> copyProtectedDraft(
    String id,
    String account,
    String title,
    String content,
  ) async {
    if (user?['id'] != account) throw StateError('Account changed');
    final record = protectedVaults[id];
    if (record == null || record['dirty'] != true) {
      throw StateError('No protected draft');
    }
    final copyId = record['copy_id'] as String? ?? uuid.v4();
    await storeProtectedEnvelope(
      id,
      account,
      () async => {...record, 'copy_id': copyId},
    );
    if (user?['id'] != account) throw StateError('Account changed');
    if (!drafts.containsKey(copyId) && !notes.any((n) => n.id == copyId)) {
      await draft(copyId, title, content);
    }
    await _queueWrite(() async {
      final key = 'account:$account';
      final snapshot = await local.read(key);
      if (snapshot == null) return;
      final records = Map<String, dynamic>.from(
        snapshot['protected_vaults'] as Map? ?? {},
      );
      final current = records[id] as Map?;
      final copied =
          (snapshot['drafts'] as Map?)?.containsKey(copyId) == true ||
          (snapshot['notes'] as List? ?? []).any(
            (n) => (n as Map)['id'] == copyId,
          );
      // A later keystroke must not be marked as copied by an older copy request.
      if (!copied || current?['ciphertext'] != record['ciphertext']) return;
      records[id] = {...current!, 'recovered_copy_id': copyId};
      snapshot['protected_vaults'] = records;
      await local.write(key, snapshot);
      if (user?['id'] == account) {
        protectedVaults = records.map(
          (key, value) =>
              MapEntry(key, Map<String, dynamic>.from(value as Map)),
        );
      }
    });
    notifyListeners();
    return copyId;
  }

  Future<void> _queueWrite(Future<void> Function() action) {
    final write = _writes.catchError((_) {}).then((_) async {
      try {
        await action();
        _localWriteFailed = false;
      } catch (_) {
        _localWriteFailed = true;
        rethrow;
      }
    });
    _writes = write;
    return write;
  }

  Future<bool> authenticate({
    required bool register,
    required String email,
    required String password,
    String name = '',
    String confirmation = '',
  }) async {
    var accepted = false;
    String? issuedToken;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await api.call(
        'POST',
        register ? '/auth/register' : '/auth/login',
        body: {
          'email': email,
          'password': password,
          if (register) 'name': name,
          if (register) 'confirmation': confirmation,
        },
      );
      accepted = true;
      issuedToken = result['token'] as String;
      _generation++;
      realtime?.stop();
      _realtimeRefresh?.cancel();
      _realtimeDirty = false;
      user = Map<String, dynamic>.from(result['user'] as Map);
      token = issuedToken;
      emailDelivery = register ? result['email_delivery'] as String? : null;
      await _loadAccount();
      final session = {'user': user, 'token': token};
      await _queueWrite(() => local.write('session', session));
      sessionRemovalFailed = false;
      online = true;
      _startRealtime();
      unawaited(synchronize());
      return true;
    } catch (e) {
      if (accepted || !_accountLoaded) {
        user = null;
        token = null;
        _accountLoaded = false;
      }
      if (accepted && issuedToken != null) {
        try {
          await api.call('POST', '/auth/logout', token: issuedToken);
        } catch (_) {
          // The newly issued session still expires server-side if unreachable.
        }
      }
      error = 'Không thể đăng nhập/đăng ký: $e';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    sessionRemovalFailed = false;
    accessUnavailable.clear();
    final oldToken = token;
    _generation++;
    realtime?.stop();
    _realtimeRefresh?.cancel();
    _realtimeDirty = false;
    realtimeStatus = RealtimeStatus.idle;
    user = null;
    token = null;
    _hasAccountSnapshot = false;
    notes = [];
    workspace = WorkspaceData();
    pending = [];
    pendingPreferences = [];
    drafts = {};
    conflicts = {};
    recoveries = {};
    protectedVaults = {};
    labels = [];
    labelCatalogue = {};
    remoteLabels = {};
    pendingLabels = [];
    labelConflicts = {};
    avatarBytes = null;
    cachedAvatarRevision = 0;
    avatarError = null;
    preferences = {'grid': true, 'dark': false, 'font_size': 16.0};
    error = null;
    emailDelivery = null;
    notifyListeners();
    try {
      await _queueWrite(() => local.remove('session'));
    } catch (_) {
      sessionRemovalFailed = true;
      error = 'Chưa xóa được phiên đăng nhập trên thiết bị. Hãy thử đăng xuất lại trước khi đóng ứng dụng.';
      notifyListeners();
    }
    if (oldToken != null) {
      try {
        await api.call('POST', '/auth/logout', token: oldToken);
      } catch (_) {
        /* Expires in 24h. */
      }
    }
  }

  /// Serialize personal organization independently of ordinary note captures.
  /// Reading the durable record here preserves drafts/vault writes queued first.
  Future<void> _editWorkspace(
    WorkspaceData Function(WorkspaceData) edit,
  ) async {
    if (user == null || !_accountLoaded) {
      throw StateError('Tài khoản chưa sẵn sàng.');
    }
    final key = accountKey;
    final generation = _generation;
    bool active() =>
        !_disposed &&
        user != null &&
        accountKey == key &&
        generation == _generation;
    if (!_hasAccountSnapshot) await _persist();
    await _queueWrite(() async {
      if (!active()) throw StateError('Tài khoản đã thay đổi.');
      final root = await local.read(key);
      if (!active() || root == null) {
        throw StateError('Kho tài khoản chưa sẵn sàng.');
      }
      final next = edit(WorkspaceData.fromJson(root['workspace'] as Map?));
      root['workspace'] = next.toJson();
      await local.write(key, root);
      if (active()) {
        workspace = next;
        notifyListeners();
      }
    });
    if (!active()) throw StateError('Tài khoản đã thay đổi.');
  }

  List<Note> get workspaceNotes => notes
      .where((n) => !n.locked && !accessUnavailable.contains(n.id))
      .toList();

  Future<void> saveNotePlan(
    String id, {
    PlanStage stage = PlanStage.planned,
    PlanPriority priority = PlanPriority.normal,
    String? dueDay,
  }) => _editWorkspace((current) {
    if (!workspaceNotes.any((n) => n.id == id)) {
      throw StateError('Ghi chú không còn khả dụng.');
    }
    if (!validPlanDay(dueDay)) throw StateError('Ngày hạn không hợp lệ.');
    if (!current.plans.containsKey(id) && current.plans.length >= 500) {
      throw StateError('Tối đa 500 ghi chú trong kế hoạch.');
    }
    return current.copy(
      plans: {
        ...current.plans,
        id: NotePlan(id, stage: stage, priority: priority, dueDay: dueDay),
      },
    );
  });

  Future<void> moveNotePlan(String id, PlanStage stage) =>
      _editWorkspace((current) {
        if (!workspaceNotes.any((n) => n.id == id)) {
          throw StateError('Ghi chú không còn khả dụng.');
        }
        final plan = current.plans[id];
        if (plan == null) throw StateError('Ghi chú đã được bỏ khỏi kế hoạch.');
        return current.copy(plans: {...current.plans, id: plan.move(stage)});
      });

  Future<void> removeNotePlan(String id) => _editWorkspace(
    (current) => current.copy(plans: {...current.plans}..remove(id)),
  );

  Future<void> startFocus(
    int minutes, {
    bool breakTime = false,
    DateTime? now,
  }) => _editWorkspace((current) {
    if (![5, 15, 25, 50].contains(minutes) || (breakTime && minutes != 5)) {
      throw StateError('Thời lượng không hợp lệ.');
    }
    if (current.focus.session != null) {
      throw StateError('Hãy kết thúc phiên hiện tại trước khi bắt đầu.');
    }
    final clock = now ?? DateTime.now();
    final session = FocusSession(
      id: uuid.v4(),
      breakTime: breakTime,
      seconds: minutes * 60,
      remainingSeconds: minutes * 60,
      endsAtMs: clock.millisecondsSinceEpoch + minutes * 60000,
    );
    return current.copy(focus: current.focus.copy(session: session));
  });

  Future<void> changeFocus(
    String id,
    String action, {
    DateTime? now,
  }) => _editWorkspace((current) {
    final focus = current.focus;
    final session = focus.session;
    if (session == null || session.id != id) return current;
    final clock = now ?? DateTime.now();
    if (action == 'reset') {
      return current.copy(focus: focus.copy(clearSession: true));
    }
    if (session.running && session.remaining(clock) == 0) {
      // Use the deadline, not the later reopen time, for daily statistics.
      final records =
          !session.breakTime && !focus.completed.any((v) => v.id == id)
          ? [
              FocusCompletion(id, session.endsAtMs!, session.seconds),
              ...focus.completed,
            ].take(100).toList()
          : focus.completed;
      return current.copy(
        focus: focus.copy(clearSession: true, completed: records),
      );
    }
    if (action == 'pause' && session.running) {
      return current.copy(focus: focus.copy(session: session.pause(clock)));
    }
    if (action == 'resume' && !session.running) {
      return current.copy(focus: focus.copy(session: session.resume(clock)));
    }
    if (action != 'finish') throw StateError('Thao tác đồng hồ không hợp lệ.');
    return current;
  });

  Future<void> setFocusGoal(int goal) => _editWorkspace((current) {
    if (goal < 1 || goal > 12) throw StateError('Mục tiêu từ 1 đến 12 phiên.');
    return current.copy(focus: current.focus.copy(dailyGoal: goal));
  });

  Future<void> recordRecent(String id) => _editWorkspace((current) {
    if (!workspaceNotes.any((n) => n.id == id)) return current;
    return current.copy(
      recent: [id, ...current.recent.where((v) => v != id)].take(20).toList(),
    );
  });

  Future<void> toggleFavorite(String id) => _editWorkspace((current) {
    if (!workspaceNotes.any((n) => n.id == id)) {
      throw StateError('Ghi chú không còn khả dụng.');
    }
    final ids = {...current.favorites};
    if (!ids.remove(id)) {
      if (ids.length >= 500) {
        throw StateError('Bạn đã có 500 ghi chú yêu thích.');
      }
      ids.add(id);
    }
    return current.copy(favorites: ids);
  });

  Future<void> saveWorkspaceView(
    String name,
    String query,
    Set<String> selectedLabels, {
    bool shared = false,
    String? id,
  }) => _editWorkspace((current) {
    if (name.trim().isEmpty ||
        name.trim().length > 60 ||
        query.length > 200 ||
        selectedLabels.length > 30 ||
        !selectedLabels.every(labels.contains)) {
      throw StateError('Tên, từ khóa hoặc nhãn không hợp lệ.');
    }
    if (id == null && current.views.length >= 20) {
      throw StateError('Tối đa 20 bộ sưu tập.');
    }
    if (id != null && !current.views.any((v) => v.id == id)) {
      throw StateError('Bộ sưu tập đã bị xóa.');
    }
    final value = WorkspaceView(
      id ?? uuid.v4(),
      name.trim(),
      query.trim(),
      labels: selectedLabels,
      shared: shared,
    );
    return current.copy(
      views: [value, ...current.views.where((v) => v.id != value.id)],
    );
  });

  Future<void> deleteWorkspaceView(String id) => _editWorkspace(
    (current) =>
        current.copy(views: current.views.where((v) => v.id != id).toList()),
  );

  Future<void> savePersonalTemplate(
    String title,
    String description,
    String content, {
    String? id,
  }) => _editWorkspace((current) {
    if (!validPortable(title, content) || description.trim().length > 140) {
      throw StateError(
        'Mẫu cần tiêu đề, nội dung hợp lệ và mô tả tối đa 140 ký tự.',
      );
    }
    if (id == null && current.templates.length >= 30) {
      throw StateError('Tối đa 30 mẫu riêng.');
    }
    if (id != null && !current.templates.any((v) => v.id == id)) {
      throw StateError('Mẫu đã bị xóa.');
    }
    final value = NoteTemplate(
      id ?? uuid.v4(),
      title.trim(),
      description.trim(),
      content,
    );
    return current.copy(
      templates: [value, ...current.templates.where((v) => v.id != value.id)],
    );
  });

  Future<void> deletePersonalTemplate(String id) => _editWorkspace(
    (current) => current.copy(
      templates: current.templates.where((v) => v.id != id).toList(),
    ),
  );

  Future<void> toggleWorkspaceTask(WorkspaceTask row) async {
    final current = workspaceNotes
        .where((n) => n.id == row.note.id)
        .firstOrNull;
    if (current == null ||
        current.role == 'viewer' ||
        hasPending(current.id) ||
        drafts.containsKey(current.id) ||
        conflicts.containsKey(current.id) ||
        current.revision != row.note.revision ||
        current.title != row.note.title ||
        current.content != row.note.content) {
      throw StateError(
        'Ghi chú đã thay đổi hoặc đang chờ lưu. Hãy mở ghi chú để xử lý trước.',
      );
    }
    final content = toggleWritingTask(
      row.note.content,
      current.content,
      row.task,
    );
    if (content == null) {
      throw StateError('Công việc đã thay đổi. Hãy thử lại.');
    }
    await save(
      current.id,
      current.title,
      content,
      baseRevision: row.note.revision,
    );
  }

  /// Publish one local transaction before sending any immutable operation.
  Future<List<String>> importNotes(List<PortableNote> imported) async {
    if (user == null ||
        !_accountLoaded ||
        imported.isEmpty ||
        imported.length > 50 ||
        imported.any((n) => !validPortable(n.title, n.content)) ||
        utf8
                .encode(jsonEncode(imported.map((n) => n.toJson()).toList()))
                .length >
            5 * 1024 * 1024) {
      throw StateError('Không thể nhập các ghi chú này.');
    }
    final generation = _generation;
    final key = accountKey;
    final created = imported
        .map(
          (n) => Note(
            id: uuid.v4(),
            title: n.title.trim(),
            content: n.content,
            revision: 1,
            updatedAt: DateTime.now().toUtc().toIso8601String(),
          ),
        )
        .toList();
    final ops = created
        .map(
          (n) => <String, dynamic>{
            'op_id': uuid.v4(),
            'note_id': n.id,
            'kind': 'upsert',
            'base_revision': 0,
            'title': n.title,
            'content': n.content,
            'pinned_at': null,
            'labels': <String>[],
            'labels_format': 'ids',
          },
        )
        .toList();
    final ids = created.map((n) => n.id).toSet();
    final opIds = ops.map((op) => op['op_id']).toSet();
    final commit = Completer<bool>();
    for (final op in ops) {
      _importCommits[op['op_id'] as String] = commit;
    }
    notes = [...created, ...notes];
    pending = [...pending, ...ops];
    try {
      await _persist();
    } catch (_) {
      if (user != null && accountKey == key && generation == _generation) {
        notes = notes.where((n) => !ids.contains(n.id)).toList();
        pending = pending.where((op) => !opIds.contains(op['op_id'])).toList();
        notifyListeners();
        // A concurrent ordinary capture might have included the unpublished batch.
        // Publish its rollback after those queued captures, without sending it.
        try {
          await _persist();
        } catch (_) {
          /* Original storage failure is reported. */
        }
      }
      commit.complete(false);
      for (final op in ops) {
        _importCommits.remove(op['op_id']);
      }
      rethrow;
    }
    commit.complete(true);
    for (final op in ops) {
      _importCommits.remove(op['op_id']);
    }
    if (user == null || accountKey != key || generation != _generation) {
      throw StateError('Tài khoản đã thay đổi.');
    }
    notifyListeners();
    unawaited(synchronize());
    return created.map((n) => n.id).toList();
  }

  Future<void> draft(String id, String title, String content) async {
    if (user == null ||
        accessUnavailable.contains(id) ||
        notes.any((n) => n.id == id && (n.locked || n.role == 'viewer'))) {
      return;
    }
    final saved = notes.where((n) => n.id == id).firstOrNull;
    if (saved != null &&
        saved.title == title.trim() &&
        saved.content == content) {
      drafts.remove(id);
      await _persistDrafts();
      return;
    }
    drafts[id] = {'title': title, 'content': content};
    await _persistDrafts();
  }

  Future<void> save(
    String id,
    String title,
    String content, {
    String? pinnedAt,
    List<String>? noteLabels,
    bool updatePin = false,
    int? baseRevision,
  }) async {
    if (user == null || !validNote(title, content)) return;
    if (accessUnavailable.contains(id)) return;
    final existing = notes.where((n) => n.id == id).firstOrNull;
    if (existing?.locked == true || existing?.role == 'viewer') return;
    final pin = updatePin ? pinnedAt : existing?.pinnedAt;
    final selectedLabels = List<String>.from(
      noteLabels ?? existing?.labels ?? [],
    );
    if (existing != null &&
        existing.title == title.trim() &&
        existing.content == content &&
        existing.pinnedAt == pin &&
        listEquals(existing.labels, selectedLabels)) {
      drafts.remove(id);
      await _persist();
      return;
    }
    final revision = baseRevision ?? existing?.revision ?? 0;
    pending = [
      ...pending,
      {
        'op_id': uuid.v4(),
        'note_id': id,
        'kind': 'upsert',
        'base_revision': revision,
        'title': title.trim(),
        'content': content,
        'pinned_at': pin,
        'labels': selectedLabels,
        'labels_format': 'ids',
      },
    ];
    notes = [
      Note(
        id: id,
        title: title.trim(),
        content: content,
        revision: revision + 1,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
        pinnedAt: pin,
        labels: selectedLabels,
        labelNames: existing?.labelNames ?? {},
        role: existing?.role ?? 'owner',
        sharedCount: existing?.sharedCount ?? 0,
        shared: existing?.isShared ?? false,
        sharedByName: existing?.sharedByName,
        sharedByEmail: existing?.sharedByEmail,
        sharedAt: existing?.sharedAt,
      ),
      ...notes.where((n) => n.id != id),
    ];
    drafts.remove(id);
    await _persist();
    notifyListeners();
    unawaited(synchronize());
  }

  Future<void> delete(Note note) async {
    if (note.locked || note.role != 'owner') return;
    pending = [
      ...pending,
      {
        'op_id': uuid.v4(),
        'note_id': note.id,
        'base_revision': note.revision,
        'kind': 'delete',
      },
    ];
    notes = notes.where((n) => n.id != note.id).toList();
    drafts.remove(note.id);
    await _persist();
    notifyListeners();
    unawaited(synchronize());
  }

  Future<void> synchronize() async {
    if (_disposed || _syncing || user == null) return;
    _syncing = true;
    final generation = _generation, sessionToken = token!, userId = user!['id'];
    bool active() =>
        !_disposed && generation == _generation && user?['id'] == userId;
    try {
      // Never send an operation until its current local snapshot is durable.
      await _persist();
      if (!active()) return;
      final profile = await api.call('GET', '/me', token: sessionToken);
      if (!active()) return;
      _acceptProfile(Map<String, dynamic>.from(profile as Map));
      final session = {'user': user, 'token': sessionToken};
      await _queueWrite(() => local.write('session', session));
      if (!active()) return;
      for (final op in List<Map<String, dynamic>>.from(pendingPreferences)) {
        if (!active()) return;
        await api.call(
          'POST',
          '/me/preferences/sync',
          token: sessionToken,
          body: op,
        );
        if (!active()) return;
        pendingPreferences = pendingPreferences
            .where((p) => p['op_id'] != op['op_id'])
            .toList();
        await _persist();
        if (!active()) return;
      }
      final latestProfile = await api.call('GET', '/me', token: sessionToken);
      if (!active()) return;
      _acceptProfile(Map<String, dynamic>.from(latestProfile as Map));
      preferences = {
        'grid': true,
        'dark': false,
        'font_size': 16.0,
        ...Map<String, dynamic>.from(user!['preferences'] as Map? ?? {}),
      };
      for (final op in pendingPreferences) {
        preferences.addAll(Map<String, dynamic>.from(op)..remove('op_id'));
      }
      if (user!['schema_version'] == 2) {
        await _syncLabels(sessionToken, active);
        if (!active()) return;
      }
      for (final op in List<Map<String, dynamic>>.from(pending)) {
        final importing = _importCommits[op['op_id']];
        if (importing != null && !await importing.future) continue;
        if (!active()) return;
        final id = op['note_id'] as String;
        if (conflicts.containsKey(id) ||
            !pending.any((p) => p['op_id'] == op['op_id'])) {
          continue;
        }
        // A new label may still be conflicted, or have arrived after the label
        // phase. Keep its note immutable/queued while continuing remote refresh
        // so a remote lock can still archive the latest draft safely.
        if (user!['schema_version'] == 2 &&
            op['labels_format'] == 'ids' &&
            (op['labels'] as List? ?? []).any(
              (label) =>
                  !remoteLabels.containsKey(label) &&
                  (labelConflicts.containsKey(label) ||
                      pendingLabels.any((p) => p['label_id'] == label)),
            )) {
          continue;
        }
        try {
          await api.call('POST', '/sync', token: sessionToken, body: op);
          if (!active()) return;
          pending = pending.where((p) => p['op_id'] != op['op_id']).toList();
          await _persist();
        } on ApiException catch (e) {
          if (!active()) return;
          if (e.status == 423) {
            final previous = notes.where((n) => n.id == id).firstOrNull;
            _archiveLocked(
              Note(
                id: id,
                title: 'Ghi chú đã khóa',
                content: '',
                revision: previous?.revision ?? op['base_revision'] as int,
                updatedAt: '',
                role: previous?.role ?? 'viewer',
                locked: true,
                pinnedAt: previous?.pinnedAt,
                shared: previous?.isShared ?? false,
              ),
            );
            notifyListeners();
            await _persist();
          } else if ([403, 404, 409].contains(e.status)) {
            final source = notes.where((n) => n.id == id).firstOrNull;
            if ([403, 404].contains(e.status) &&
                source != null &&
                source.role != 'owner') {
              _archiveAccessLoss(id, reason: 'permission');
              notifyListeners();
            } else {
              conflicts[id] = {'status': e.status, 'detail': e.detail};
            }
            await _persist();
          } else {
            rethrow;
          }
        }
      }
      final remote =
          await api.call('GET', '/notes', token: sessionToken) as List;
      if (!active()) return;
      final incoming = remote
          .map((n) => Note.fromListingJson(Map<String, dynamic>.from(n as Map)))
          .toList();
      final incomingById = {for (final note in incoming) note.id: note};
      final localStateIds = {
        ...drafts.keys,
        ...conflicts.keys,
        ...pending.map((op) => op['note_id']),
      };
      for (final n in incoming.where((n) => n.locked)) {
        if (localStateIds.contains(n.id)) _archiveLocked(n);
      }
      for (final old in List<Note>.from(notes)) {
        if (old.role != 'owner' && !incomingById.containsKey(old.id)) {
          if (localStateIds.contains(old.id)) {
            _archiveAccessLoss(old.id, reason: 'revoked');
          } else {
            accessUnavailable.add(old.id);
          }
        }
      }
      for (final n in incoming.where((n) => !n.locked && n.role == 'viewer')) {
        if (localStateIds.contains(n.id)) {
          _archiveAccessLoss(n.id, reason: 'viewer', remote: n);
        }
      }
      accessUnavailable.removeAll(incoming.map((n) => n.id));
      // Recovery may retire operations above; index only the surviving queue.
      final pendingIds = pending.map((op) => op['note_id']).toSet();
      final pendingNotes =
          notes
              .where(
                (n) =>
                    pendingIds.contains(n.id) &&
                    incomingById[n.id]?.locked != true,
              )
              .map((n) {
                final metadata = incomingById[n.id];
                return metadata == null ? n : n.withAccessFrom(metadata);
              })
              .toList()
            ..sort(compareNotes);
      notes = [
        // Optimistic local edits precede the accepted server array until ACK.
        // Their immutable operations/base revisions are unchanged.
        ...pendingNotes,
        ...incoming.where((n) => n.locked || !pendingIds.contains(n.id)),
      ];
      online = true;
      error = null;
      await refreshAvatar();
      if (!active()) return;
      await _persist();
    } on ApiException catch (e) {
      if (!active()) return;
      if (e.status == 401) {
        await logout();
        error = 'Phiên hết hạn. Đăng nhập lại để tiếp tục.';
      } else {
        error = 'Đồng bộ thất bại: $e';
      }
    } catch (_) {
      if (active()) {
        if (_localWriteFailed) {
          error = 'Chưa ghi được dữ liệu trên thiết bị. Giữ ứng dụng mở và thử đồng bộ lại.';
        } else {
          online = false;
          error = 'Chưa kết nối được backend. Dữ liệu đang lưu trên thiết bị.';
        }
      }
    } finally {
      _syncing = false;
      if (!_disposed) notifyListeners();
      _scheduleRealtimeRefresh();
    }
  }

  void _archiveLocked(Note locked) {
    final id = locked.id;
    final localNote = notes.where((n) => n.id == id && !n.locked).firstOrNull;
    final draft = drafts[id] as Map?;
    final lastEdit = pending
        .where((op) => op['note_id'] == id && op['kind'] == 'upsert')
        .lastOrNull;
    if (draft != null || lastEdit != null) {
      recoveries = {
        ...recoveries,
        uuid.v4(): {
          'source_id': id,
          'title':
              draft?['title'] ?? lastEdit?['title'] ?? localNote?.title ?? '',
          'content':
              draft?['content'] ??
              lastEdit?['content'] ??
              localNote?.content ??
              '',
          'saved_at': DateTime.now().toUtc().toIso8601String(),
        },
      };
    }
    drafts = Map<String, dynamic>.from(drafts)..remove(id);
    pending = pending.where((op) => op['note_id'] != id).toList();
    conflicts = Map<String, dynamic>.from(conflicts)..remove(id);
    notes = notes.any((n) => n.id == id)
        ? notes.map((n) => n.id == id ? locked : n).toList()
        : [...notes, locked];
  }

  /// Keep only the user's unsent edit in the existing encrypted recovery vault.
  void _archiveAccessLoss(String id, {required String reason, Note? remote}) {
    final draft = drafts[id] as Map?;
    final edit = pending
        .where((op) => op['note_id'] == id && op['kind'] == 'upsert')
        .lastOrNull;
    if (draft != null || edit != null) {
      recoveries = {
        ...recoveries,
        uuid.v4(): {
          'source_id': id,
          'title': draft?['title'] ?? edit?['title'] ?? '',
          'content': draft?['content'] ?? edit?['content'] ?? '',
          'reason': reason,
          'saved_at': DateTime.now().toUtc().toIso8601String(),
        },
      };
    }
    drafts = Map<String, dynamic>.from(drafts)..remove(id);
    pending = pending.where((op) => op['note_id'] != id).toList();
    conflicts = Map<String, dynamic>.from(conflicts)..remove(id);
    notes = remote == null
        ? notes.where((n) => n.id != id).toList()
        : notes.any((n) => n.id == id)
        ? notes.map((n) => n.id == id ? remote : n).toList()
        : [...notes, remote];
    if (remote == null) accessUnavailable.add(id);
  }

  Future<void> resolveConflict(String id, {required bool keepCopy}) async {
    if (user == null) return;
    final note = notes.where((n) => n.id == id).firstOrNull;
    final previousPending = pending;
    final previousNotes = notes;
    final previousDrafts = drafts;
    final previousConflicts = conflicts;
    final generation = _generation;
    final draft = drafts[id] as Map?;
    final title = draft?['title'] as String? ?? note?.title ?? '';
    final content = draft?['content'] as String? ?? note?.content ?? '';
    // One transaction stores the replacement and retires the old operation.
    // Invalid drafts remain recoverable as drafts under the replacement ID.
    pending = pending.where((op) => op['note_id'] != id).toList();
    conflicts = Map<String, dynamic>.from(conflicts)..remove(id);
    drafts = Map<String, dynamic>.from(drafts)..remove(id);
    notes = notes.where((n) => n.id != id).toList();
    if (keepCopy && note != null && !note.locked) {
      final copyId = uuid.v4();
      if (validNote(title, content)) {
        final copyTitle = '${title.trim()} (bản phục hồi)';
        pending = [
          ...pending,
          {
            'op_id': uuid.v4(),
            'note_id': copyId,
            'kind': 'upsert',
            'base_revision': 0,
            'title': copyTitle,
            'content': content,
            'pinned_at': null,
            'labels': <String>[],
          },
        ];
        notes = [
          Note(
            id: copyId,
            title: copyTitle,
            content: content,
            revision: 1,
            updatedAt: DateTime.now().toUtc().toIso8601String(),
          ),
          ...notes,
        ];
      } else {
        drafts[copyId] = {'title': title, 'content': content};
      }
    }
    try {
      await _persist();
    } catch (_) {
      if (generation == _generation) {
        pending = previousPending;
        notes = previousNotes;
        drafts = previousDrafts;
        conflicts = previousConflicts;
        notifyListeners();
      }
      rethrow;
    }
    if (generation != _generation || _disposed) return;
    await synchronize();
    notifyListeners();
  }

  /// Copies only the user's previously held local edit, never unlocks the source.
  /// Reuse one new draft ID on retries; retain the encrypted recovery until saved.
  Future<String> restoreRecovery(String id) async {
    if (user == null || recoveries[id] == null) {
      throw StateError('Recovery unavailable');
    }
    final generation = _generation;
    final item = Map<String, dynamic>.from(recoveries[id] as Map);
    final previousId = item['draft_id'] as String?;
    if (previousId != null &&
        (drafts.containsKey(previousId) ||
            notes.any((n) => n.id == previousId))) {
      await _persist();
      if (_disposed || generation != _generation) {
        throw StateError('Account changed');
      }
      return previousId;
    }
    final draftId = previousId ?? uuid.v4();
    recoveries = {
      ...recoveries,
      id: {...item, 'draft_id': draftId},
    };
    drafts = {
      ...drafts,
      draftId: {'title': item['title'] ?? '', 'content': item['content'] ?? ''},
    };
    await _persist();
    if (_disposed || generation != _generation) {
      throw StateError('Account changed');
    }
    notifyListeners();
    return draftId;
  }

  Future<void> setPreferences(Map<String, dynamic> changes) async {
    if (user == null) return;
    if (changes.isEmpty ||
        changes.keys.any(
          (key) => !['grid', 'dark', 'font_size'].contains(key),
        ) ||
        changes.entries.any(
          (entry) => entry.key == 'font_size'
              ? entry.value is! num ||
                    !(entry.value as num).isFinite ||
                    entry.value < 14 ||
                    entry.value > 24
              : entry.value is! bool,
        )) {
      throw ArgumentError('Invalid preferences');
    }
    changes = Map<String, dynamic>.from(changes)
      ..removeWhere((key, value) => preferences[key] == value);
    if (changes.isEmpty) return;
    preferences = {...preferences, ...changes};
    pendingPreferences = [
      ...pendingPreferences,
      {'op_id': uuid.v4(), ...changes},
    ];
    await _persist();
    notifyListeners();
    unawaited(synchronize());
  }

  void _migrateLocalLabels() {
    final names = {
      ...labels,
      ...notes
          .where((n) => n.role == 'owner' && !n.locked)
          .expand((n) => n.labels),
    };
    final mapping = <String, String>{};
    for (final name in names.where((name) => name.trim().isNotEmpty)) {
      final id =
          'legacy_${uuid.v5(Namespace.url.value, '${user!['id']}\u0000${name.trim()}').replaceAll('-', '')}';
      mapping[name] = id;
      labelCatalogue[id] = {
        'id': id,
        'name': name.trim(),
        'revision': 1,
        'deleted': false,
      };
      pendingLabels.add({
        'op_id': uuid.v4(),
        'label_id': id,
        'base_revision': 0,
        'kind': 'upsert',
        'name': name.trim(),
      });
    }
    notes = notes
        .map(
          (note) => note.role != 'owner' || note.locked
              ? note
              : Note.fromJson({
                  ...note.toJson(),
                  'labels': note.labels
                      .map((name) => mapping[name] ?? name)
                      .toList(),
                }),
        )
        .toList();
    // v1 note operations remain byte-for-byte unchanged for idempotent replay.
  }

  void _rebuildLabels() {
    labels =
        labelCatalogue.entries
            .where((e) => e.value['deleted'] != true)
            .map((e) => e.key)
            .toList()
          ..sort((a, b) => labelName(a).compareTo(labelName(b)));
  }

  Future<void> _syncLabels(String sessionToken, bool Function() active) async {
    for (final op in List<Map<String, dynamic>>.from(pendingLabels)) {
      final id = op['label_id'] as String;
      if (!active()) return;
      if (labelConflicts.containsKey(id) ||
          !pendingLabels.any((p) => p['op_id'] == op['op_id'])) {
        continue;
      }
      try {
        await api.call('POST', '/labels/sync', token: sessionToken, body: op);
        if (!active()) return;
        pendingLabels = pendingLabels
            .where((p) => p['op_id'] != op['op_id'])
            .toList();
        await _persist();
      } on ApiException catch (e) {
        if (!active()) return;
        if ([404, 409, 422].contains(e.status)) {
          labelConflicts[id] = {'status': e.status, 'detail': e.detail};
          await _persist();
        } else {
          rethrow;
        }
      }
    }
    final remote =
        await api.call('GET', '/labels', token: sessionToken) as List;
    if (!active()) return;
    remoteLabels = {
      for (final row in remote)
        row['id'] as String: Map<String, dynamic>.from(row as Map),
    };
    labelCatalogue = remoteLabels.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
    for (final op in pendingLabels) {
      final id = op['label_id'] as String;
      labelCatalogue[id] = {
        'id': id,
        'name': op['name'] ?? labelCatalogue[id]?['name'] ?? '',
        'revision': (op['base_revision'] as int) + 1,
        'deleted': op['kind'] == 'delete',
      };
    }
    _rebuildLabels();
  }

  String? validateLabelName(String value, [String? except]) {
    final name = value.trim();
    if (name.isEmpty ||
        name.runes.length > 60 ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(name)) {
      return 'Dùng 1–60 ký tự cho tên nhãn';
    }
    if (labelNameExists(name, except)) return 'Nhãn này đã tồn tại';
    return null;
  }

  Future<void> _labelChange(String id, String kind, String name) async {
    if (user == null) return;
    if (kind == 'upsert' && validateLabelName(name, id) != null) {
      throw ArgumentError(validateLabelName(name, id));
    }
    final generation = _generation;
    var revision = labelCatalogue[id]?['revision'] as int? ?? 0;
    if (labelConflicts.containsKey(id)) {
      // Explicit new user edit retires the conflicted immutable operation.
      revision = remoteLabels[id]?['revision'] as int? ?? 0;
      pendingLabels = pendingLabels
          .where((op) => op['label_id'] != id)
          .toList();
      labelConflicts.remove(id);
    }
    pendingLabels = [
      ...pendingLabels,
      {
        'op_id': uuid.v4(),
        'label_id': id,
        'base_revision': revision,
        'kind': kind,
        'name': name.trim(),
      },
    ];
    labelCatalogue[id] = {
      'id': id,
      'name': name.trim(),
      'revision': revision + 1,
      'deleted': kind == 'delete',
    };
    _rebuildLabels();
    await _persist();
    if (generation != _generation || _disposed) return;
    notifyListeners();
    unawaited(synchronize());
  }

  Future<void> addLabel(String name) => _labelChange(uuid.v4(), 'upsert', name);
  Future<void> renameLabel(String id, String name) =>
      _labelChange(id, 'upsert', name);
  Future<void> removeLabel(String id) =>
      _labelChange(id, 'delete', labelName(id));

  Future<void> useRemoteLabel(String id) async {
    if (_syncing) {
      throw StateError('Chờ đồng bộ xong rồi chọn lại');
    }
    final generation = _generation;
    final previousPending = pending,
        previousNotes = notes,
        previousPendingLabels = pendingLabels;
    final previousCatalogue = Map<String, Map<String, dynamic>>.from(
      labelCatalogue,
    );
    final previousConflicts = Map<String, dynamic>.from(labelConflicts);
    if (remoteLabels[id] == null) {
      final detail = (labelConflicts[id] as Map?)?['detail'];
      final duplicate = detail is Map ? detail['duplicate'] as Map? : null;
      final replacement = duplicate?['id'] as String?;
      final target = remoteLabels[replacement];
      final nextId = target?['deleted'] == false ? replacement : null;
      final affected = pending
          .where((op) => (op['labels'] as List? ?? []).contains(id))
          .map((op) => op['note_id'] as String)
          .toSet();
      for (final noteId in affected) {
        final group = pending.where((op) => op['note_id'] == noteId).toList();
        final latest = Map<String, dynamic>.from(group.last);
        latest['op_id'] = uuid.v4();
        latest['base_revision'] = group.first['base_revision'];
        latest['labels_format'] = 'ids';
        latest['labels'] = (latest['labels'] as List? ?? [])
            .cast<String>()
            .map((value) => value == id ? nextId : value)
            .whereType<String>()
            .toSet()
            .toList();
        pending = [...pending.where((op) => op['note_id'] != noteId), latest];
        notes = notes
            .map(
              (note) => note.id != noteId
                  ? note
                  : Note.fromJson({
                      ...note.toJson(),
                      'labels': latest['labels'],
                      'revision': (latest['base_revision'] as int) + 1,
                    }),
            )
            .toList();
      }
    }
    pendingLabels = pendingLabels.where((op) => op['label_id'] != id).toList();
    labelConflicts.remove(id);
    if (remoteLabels[id] == null) {
      labelCatalogue.remove(id);
    } else {
      labelCatalogue[id] = Map<String, dynamic>.from(remoteLabels[id]!);
    }
    _rebuildLabels();
    try {
      await _persist();
    } catch (_) {
      if (generation == _generation) {
        pending = previousPending;
        notes = previousNotes;
        pendingLabels = previousPendingLabels;
        labelCatalogue = previousCatalogue;
        labelConflicts = previousConflicts;
        _rebuildLabels();
      }
      rethrow;
    }
    if (generation != _generation || _disposed) {
      return;
    }
    notifyListeners();
    unawaited(synchronize());
  }

  void _acceptProfile(Map<String, dynamic> profile) {
    if ((profile['avatar_revision'] as int? ?? 0) <
        (user?['avatar_revision'] as int? ?? 0)) {
      profile['avatar_revision'] = user!['avatar_revision'];
      profile['has_avatar'] = user!['has_avatar'];
    }
    user = profile;
  }

  Future<void> refreshAvatar() async {
    if (user == null) return;
    final generation = _generation,
        revision = user!['avatar_revision'] as int? ?? 0;
    if (user!['has_avatar'] != true) {
      avatarBytes = null;
      cachedAvatarRevision = revision;
      avatarError = null;
      return;
    }
    if (revision == cachedAvatarRevision && avatarBytes != null) return;
    try {
      final response = await api.binary(
        'GET',
        '/me/avatar?revision=$revision',
        token: token!,
      );
      if (_disposed ||
          generation != _generation ||
          user?['avatar_revision'] != revision) {
        return;
      }
      avatarBytes = response.bodyBytes;
      cachedAvatarRevision = revision;
      avatarError = null;
    } catch (_) {
      if (generation == _generation && !_disposed) {
        avatarError = 'Chưa tải được ảnh mới; đang dùng ảnh trên thiết bị.';
      }
    }
  }

  Future<void> updateAvatar(Uint8List bytes, String contentType) async {
    if (bytes.isEmpty || bytes.length > 2 * 1024 * 1024) {
      throw ArgumentError('Chọn ảnh tối đa 2 MiB');
    }
    final generation = _generation, sessionToken = token!;
    final revision = user!['avatar_revision'] as int? ?? 0;
    final response = await api.binary(
      'POST',
      '/me/avatar?base_revision=$revision',
      token: sessionToken,
      bytes: bytes,
      contentType: contentType,
    );
    if (_disposed || generation != _generation) return;
    _acceptProfile(Map<String, dynamic>.from(jsonDecode(response.body) as Map));
    await refreshAvatar();
    if (_disposed || generation != _generation) return;
    await _persist();
    if (_disposed || generation != _generation) return;
    final session = {
      'user': Map<String, dynamic>.from(user!),
      'token': sessionToken,
    };
    await _queueWrite(() => local.write('session', session));
    if (!_disposed && generation == _generation) notifyListeners();
  }

  Future<void> removeAvatar() async {
    final generation = _generation, sessionToken = token!;
    final profile = await api.call(
      'DELETE',
      '/me/avatar?base_revision=${user!['avatar_revision'] ?? 0}',
      token: sessionToken,
    );
    if (_disposed || generation != _generation) return;
    _acceptProfile(Map<String, dynamic>.from(profile as Map));
    await refreshAvatar();
    if (_disposed || generation != _generation) return;
    await _persist();
    if (_disposed || generation != _generation) return;
    final session = {
      'user': Map<String, dynamic>.from(user!),
      'token': sessionToken,
    };
    await _queueWrite(() => local.write('session', session));
    if (!_disposed && generation == _generation) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _retry?.cancel();
    _realtimeRefresh?.cancel();
    realtime?.stop();
    remoteChanges.dispose();
    super.dispose();
  }
}
