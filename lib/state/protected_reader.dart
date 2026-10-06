import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/api.dart';
import '../data/protected_note_vault.dart';
import '../domain/note.dart';
import 'app_controller.dart';

/// Session content; durable drafts are password-encrypted in the account vault.
class ProtectedReader extends ChangeNotifier {
  ProtectedReader(
    this.controller,
    this.id, {
    this.recoveryMode = false,
    ProtectedNoteVault? vault,
  }) : account = controller.user?['id'] as String?,
       sessionToken = controller.token,
       vault =
           vault ??
           ProtectedNoteVault(controller.user?['id'] as String? ?? '', id) {
    controller.addListener(accountChanged);
    controller.remoteChanges.addListener(remoteChanged);
  }
  final AppController controller;
  final String id;
  final String? account, sessionToken;
  final ProtectedNoteVault vault;
  final bool recoveryMode;
  Note? note;
  Map<String, dynamic>? draft, operation;
  ProtectedVaultLease? _lease;
  String? error;
  bool busy = false,
      saving = false,
      localWriteFailed = false,
      onlineLease = false;
  bool conflicted = false, _disposed = false, _refreshAgain = false;
  int baseRevision = 0, _epoch = 0;
  Timer? _expiry, _poll;
  Future<void> _lastWrite = Future.value();
  Map<String, dynamic>? _deleteOperation;
  bool picking = false, obscured = false;
  bool get active =>
      !_disposed &&
      account != null &&
      controller.user?['id'] == account &&
      controller.token == sessionToken;
  bool get dirty => draft != null || operation != null;
  String? get effectivePin =>
      draft != null ? draft!['pinned_at'] as String? : note?.pinnedAt;
  bool get canEdit =>
      active &&
      note != null &&
      !recoveryMode &&
      ['owner', 'editor'].contains(note!.role);
  bool get requiresReopen =>
      !dirty && note != null && note!.revision != baseRevision;
  bool get serverGate =>
      active &&
      onlineLease &&
      note != null &&
      controller.online &&
      !obscured &&
      controller.foreground;
  bool get canUseAi => serverGate && !dirty;

  Map<String, dynamic> _noteJson(Note n) => {
    ...n.toJson(),
    'protection_version': n.protectionVersion,
    'shared_count': n.sharedCount,
    'shared_by': {'name': n.sharedByName, 'email': n.sharedByEmail},
    'shared_at': n.sharedAt,
  };

  Future<void> persist() {
    if (_lease == null || note == null || account == null) {
      return Future.value();
    }
    final lease = _lease!;
    final payload = Map<String, dynamic>.from(
      jsonDecode(
        jsonEncode({
          'note': _noteJson(note!),
          'draft': draft,
          'operation': operation,
          'base_revision': baseRevision,
          'conflicted': conflicted,
        }),
      ) as Map,
    );
    _lastWrite = controller.storeProtectedEnvelope(
      id,
      account!,
      () => vault.seal(lease, payload),
    );
    return _lastWrite.then(
      (_) {
        localWriteFailed = false;
      },
      onError: (Object e) {
        localWriteFailed = true;
        if (!_disposed) {
          error = 'Chưa lưu được bản nháp mã hóa. Giữ ứng dụng mở và thử lại.';
          notifyListeners();
        }
        throw e;
      },
    );
  }

  void accountChanged() {
    if (!active || !controller.foreground) {
      if (active && picking && note != null) {
        obscureForPicker();
        return;
      }
      hide('Phiên đọc đã đóng. Mở khóa lại để tiếp tục.');
      return;
    }
    final source = controller.notes.where((n) => n.id == id).firstOrNull;
    if (note != null &&
        !recoveryMode &&
        (source == null || source.role != note!.role || !source.locked)) {
      unawaited(
        controller.invalidateProtectedVault(id, account!).catchError((_) {}),
      );
      hide('Ghi chú hoặc quyền đã thay đổi. Bản nháp mã hóa vẫn được giữ.');
      return;
    }
    if (note != null && !recoveryMode && controller.online != onlineLease) {
      hide(
        controller.online
            ? 'Đã có kết nối. Nhập mật khẩu để xác nhận quyền và đồng bộ bản nháp.'
            : 'Đang offline. Nhập mật khẩu để mở bản đã tải trên thiết bị.',
      );
      return;
    }
    if (source != null &&
        note != null &&
        source.revision > note!.revision &&
        serverGate) {
      unawaited(refresh());
    }
  }

  void remoteChanged() {
    if (serverGate) unawaited(refresh());
  }

  void obscureForPicker() {
    obscured = true;
    if (!_disposed) notifyListeners();
  }

  Future<void> setPicking(bool value) async {
    picking = value;
    if (value ||
        !obscured ||
        !active ||
        !controller.foreground ||
        note == null) {
      return;
    }
    final epoch = _epoch;
    try {
      final response = await controller.api.call(
        'GET',
        '/notes/$id',
        token: sessionToken,
      );
      if (!active || epoch != _epoch) return;
      final current = Note.fromJson(Map<String, dynamic>.from(response as Map));
      if (!current.locked ||
          current.role != note!.role ||
          current.protectionVersion != note!.protectionVersion) {
        await controller.invalidateProtectedVault(id, account!);
        hide('Quyền đã đổi trong khi chọn tệp.');
        return;
      }
      note = current;
      obscured = false;
      await persist();
      if (!_disposed) notifyListeners();
    } catch (e) {
      if (active && epoch == _epoch) hide(message(e));
    }
  }

  void hide([String? message]) {
    _epoch++;
    note = null;
    draft = null;
    operation = null;
    _lease = null;
    _expiry?.cancel();
    _poll?.cancel();
    onlineLease = false;
    obscured = false;
    busy = false;
    error = message;
    if (!_disposed) notifyListeners();
  }

  String message(Object e) {
    if (e is ApiException) {
      if (e.status == 429) {
        return 'Bạn đã thử nhiều lần. Đợi một phút rồi thử lại.';
      }
      if (e.status == 403) {
        return 'Mật khẩu ghi chú chưa đúng hoặc quyền đã thay đổi.';
      }
      if ([401, 404, 423].contains(e.status)) {
        return 'Phiên mở khóa đã hết hạn hoặc quyền truy cập đã thay đổi. Bản nháp mã hóa vẫn được giữ.';
      }
    }
    if (e is StateError) return e.message.toString();
    return 'Chưa kết nối được backend. Bản nháp mã hóa vẫn được giữ; hãy thử lại khi có kết nối.';
  }

  Future<void> _openLocal(
    String password,
    int epoch, {
    required bool recovery,
  }) async {
    final envelope = await controller.readProtectedEnvelope(id, account!);
    if (envelope == null) {
      throw StateError(
        'Chưa có bản mã cục bộ. Cần kết nối để mở khóa lần đầu.',
      );
    }
    if (envelope['recovery_only'] == true && !recovery) {
      throw StateError(
        'Quyền hoặc khóa đã đổi. Mở “Bản nháp bảo vệ” để phục hồi thay đổi riêng.',
      );
    }
    final lease = await vault.open(envelope, password);
    if (!active || epoch != _epoch) return;
    final data = lease.data;
    final cached = Note.fromJson(
      Map<String, dynamic>.from(data['note'] as Map),
    );
    final localDraft = data['draft'] as Map?;
    if (recovery && localDraft == null && data['operation'] == null) {
      throw StateError('Không có bản chỉnh sửa cần phục hồi.');
    }
    _lease = lease;
    note = cached;
    draft = localDraft == null ? null : Map<String, dynamic>.from(localDraft);
    operation = data['operation'] == null
        ? null
        : Map<String, dynamic>.from(data['operation'] as Map);
    baseRevision = data['base_revision'] as int? ?? cached.revision;
    conflicted = data['conflicted'] == true;
    onlineLease = false;
    busy = false;
    _expiry = Timer(
      const Duration(minutes: 5),
      () => hide('Phiên cục bộ đã đóng. Nhập mật khẩu để mở lại.'),
    );
    error = recovery
        ? 'Đây là bản chỉnh sửa riêng được giữ trên thiết bị; không cấp quyền truy cập note nguồn.'
        : 'Bản cục bộ offline. Kết nối lại cần xác nhận quyền trước khi gửi thay đổi.';
    notifyListeners();
  }

  Future<void> unlock(String password) async {
    if (busy || !active || note != null) return;
    final epoch = ++_epoch;
    final elapsed = Stopwatch()..start();
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (recoveryMode || !controller.online) {
        await _openLocal(password, epoch, recovery: recoveryMode);
        return;
      }
      final grant = await controller.noteGrantCall(id, 'unlock', sessionToken, {
        'password': password,
      });
      if (!active || epoch != _epoch) return;
      final remaining =
          Duration(seconds: (grant['expires_in'] as num).toInt()) -
          elapsed.elapsed;
      if (remaining <= Duration.zero) {
        hide('Phiên mở khóa đã hết hạn.');
        return;
      }
      _expiry = Timer(
        remaining,
        () => unawaited(relock('Phiên mở khóa đã hết hạn.')),
      );
      final result = await controller.api.call(
        'GET',
        '/notes/$id',
        token: sessionToken,
      );
      if (!active || epoch != _epoch) return;
      final current = Note.fromJson(Map<String, dynamic>.from(result as Map));
      final envelope = await controller.readProtectedEnvelope(id, account!);
      ProtectedVaultLease? lease;
      if (envelope != null) {
        final copyId = envelope['recovered_copy_id'] as String?;
        final safelyCopied =
            copyId != null &&
            (controller.drafts.containsKey(copyId) ||
                controller.notes.any(
                  (n) => n.id == copyId && n.role == 'owner',
                ));
        try {
          lease = await vault.open(envelope, password);
        } catch (_) {
          if (envelope['dirty'] == true && !safelyCopied) {
            throw StateError(
              'Còn bản nháp dùng mật khẩu cũ. Hãy phục hồi bản nháp bảo vệ trước khi mở phiên mới.',
            );
          }
        }
        if (lease != null &&
            envelope['dirty'] == true &&
            ((lease.data['note'] as Map)['protection_version'] !=
                    current.protectionVersion ||
                current.role == 'viewer')) {
          if (safelyCopied) {
            lease = null;
          } else {
            await controller.invalidateProtectedVault(id, account!);
            throw StateError(
              'Quyền hoặc khóa đã đổi. Bản nháp riêng được giữ trong “Bản nháp bảo vệ”.',
            );
          }
        }
      }
      if (current.protectionVersion > 0 && lease == null) {
        lease = await vault.create(password, {});
      }
      if (!active || epoch != _epoch) return;
      note = current;
      _lease = lease;
      onlineLease = true;
      draft = lease?.data['draft'] == null
          ? null
          : Map<String, dynamic>.from(lease!.data['draft'] as Map);
      operation = lease?.data['operation'] == null
          ? null
          : Map<String, dynamic>.from(lease!.data['operation'] as Map);
      baseRevision = dirty
          ? lease!.data['base_revision'] as int
          : current.revision;
      conflicted =
          dirty && current.revision != baseRevision && operation == null;
      await persist();
      if (!active || epoch != _epoch) return;
      busy = false;
      _poll = Timer.periodic(
        const Duration(seconds: 15),
        (_) => unawaited(refresh()),
      );
      notifyListeners();
      if (dirty && !conflicted) unawaited(flush());
    } catch (e) {
      if (!active || epoch != _epoch) return;
      if ((e is TimeoutException || e is http.ClientException) &&
          !recoveryMode) {
        controller.online = false;
        try {
          await _openLocal(password, epoch, recovery: false);
          return;
        } catch (_) {}
      }
      if (e is ApiException && [401, 404, 423].contains(e.status)) {
        unawaited(
          controller.invalidateProtectedVault(id, account!).catchError((_) {}),
        );
      }
      hide(message(e));
    }
  }

  void beginFreshEdit() {
    if (!canEdit || dirty) return;
    baseRevision = note!.revision;
    conflicted = false;
    error = null;
    notifyListeners();
  }

  Future<void> edit(
    String title,
    String content, {
    String? pinnedAt,
    bool updatePin = false,
    List<String>? labels,
  }) async {
    if (!canEdit || requiresReopen || _lease == null) return;
    draft = {
      'title': title,
      'content': content,
      'pinned_at': updatePin ? pinnedAt : effectivePin,
      'labels': labels ?? draft?['labels'] ?? note!.labels,
    };
    error = null;
    final write = persist();
    notifyListeners();
    await write;
  }

  Future<void> flush() async {
    if (saving ||
        !serverGate ||
        !canEdit ||
        draft == null ||
        localWriteFailed) {
      return;
    }
    if (!validNote(draft!['title'] as String, draft!['content'] as String)) {
      return;
    }
    final epoch = _epoch;
    saving = true;
    notifyListeners();
    try {
      operation ??= {
        'op_id': controller.uuid.v4(),
        'note_id': id,
        'base_revision': baseRevision,
        'kind': 'upsert',
        'title': draft!['title'],
        'content': draft!['content'],
        'pinned_at': draft!['pinned_at'],
        'labels': draft!['labels'],
        'labels_format': 'ids',
      };
      await persist();
      final sent = Map<String, dynamic>.from(operation!);
      final result = await controller.api.call(
        'POST',
        '/sync',
        token: sessionToken,
        body: sent,
      );
      if (!active || epoch != _epoch || !serverGate) return;
      baseRevision = result['revision'] as int;
      final stillSame =
          jsonEncode(draft) ==
          jsonEncode({
            for (final k in ['title', 'content', 'pinned_at', 'labels'])
              k: sent[k],
          });
      if (stillSame) draft = null;
      operation = null;
      conflicted = false;
      note = Note.fromJson({
        ..._noteJson(note!),
        ...sent,
        'revision': baseRevision,
        'locked': true,
      });
      await persist();
      if (!active || epoch != _epoch) return;
      unawaited(controller.synchronize());
    } on ApiException catch (e) {
      if (!active || epoch != _epoch) return;
      if (e.status == 409) {
        conflicted = true;
        error = 'Có phiên bản mới trên máy chủ. Bản nháp của bạn được giữ; chọn bản máy chủ hoặc tạo ghi chú riêng.';
        await persist();
      } else if ([401, 403, 404, 423].contains(e.status)) {
        await controller.invalidateProtectedVault(id, account!);
        hide(message(e));
      } else {
        error = message(e);
      }
    } catch (e) {
      if (active && epoch == _epoch) error = message(e);
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
      if (_refreshAgain && serverGate) {
        _refreshAgain = false;
        unawaited(refresh());
      }
      if (draft != null &&
          operation == null &&
          error == null &&
          !conflicted &&
          serverGate &&
          !localWriteFailed) {
        unawaited(flush());
      }
    }
  }

  Future<void> refresh() async {
    if (!serverGate || busy || saving) {
      if (serverGate) _refreshAgain = true;
      return;
    }
    final epoch = _epoch;
    busy = true;
    try {
      final result = await controller.api.call(
        'GET',
        '/notes/$id',
        token: sessionToken,
      );
      if (!active || epoch != _epoch) return;
      final current = Note.fromJson(Map<String, dynamic>.from(result as Map));
      if (!current.locked ||
          current.role != note!.role ||
          current.protectionVersion != note!.protectionVersion) {
        await controller.invalidateProtectedVault(id, account!);
        hide('Quyền hoặc mật khẩu đã đổi. Bản nháp mã hóa vẫn được giữ.');
        return;
      }
      if (current.revision > note!.revision && dirty) conflicted = true;
      note = current;
      await persist();
    } catch (e) {
      if (active && epoch == _epoch) {
        if (e is ApiException && [401, 403, 404, 423].contains(e.status)) {
          await controller.invalidateProtectedVault(id, account!);
        }
        hide(message(e));
      }
    } finally {
      if (epoch == _epoch) busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> useRemote() async {
    if (!serverGate || saving || note == null) return;
    await refresh();
    if (!serverGate || note == null) return;
    draft = null;
    operation = null;
    conflicted = false;
    baseRevision = note!.revision;
    await persist();
    notifyListeners();
  }

  Future<String?> copyDraft() async {
    final localDraft = draft ?? operation;
    if (!active || localDraft == null || account == null) return null;
    await persist();
    return controller.copyProtectedDraft(
      id,
      account!,
      localDraft['title'] as String,
      localDraft['content'] as String,
    );
  }

  Future<bool> deleteNote() async {
    if (!serverGate || note?.role != 'owner' || dirty || saving) return false;
    final epoch = _epoch;
    saving = true;
    notifyListeners();
    try {
      _deleteOperation ??= {
        'op_id': controller.uuid.v4(),
        'note_id': id,
        'base_revision': note!.revision,
        'kind': 'delete',
      };
      await controller.api.call(
        'POST',
        '/sync',
        token: sessionToken,
        body: _deleteOperation,
      );
      if (!active || epoch != _epoch) return false;
      await controller.invalidateProtectedVault(id, account!);
      hide('Đã xóa ghi chú.');
      unawaited(controller.synchronize());
      return true;
    } catch (e) {
      if (active && epoch == _epoch) {
        if (e is ApiException && e.status == 409) {
          // A rejected delete has no acknowledgement to replay. A new explicit
          // confirmation must use the refreshed revision and a new operation.
          _deleteOperation = null;
          saving = false;
          await refresh();
          if (serverGate) {
            error = 'Ghi chú đã đổi. Kiểm tra bản mới và xác nhận xóa lại.';
          }
        } else if (e is ApiException &&
            [401, 403, 404, 423].contains(e.status)) {
          await controller.invalidateProtectedVault(id, account!);
          hide(message(e));
        } else {
          error = message(e);
        }
      }
      return false;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> relock([String? reason]) async {
    final revoke =
        active && !recoveryMode && (onlineLease || (busy && controller.online));
    hide(reason);
    if (!revoke) return;
    try {
      await controller.noteGrantCall(id, 'lock', sessionToken);
    } catch (_) {}
  }

  Future<void> drainWrites() async {
    await _lastWrite;
  }

  @override
  void dispose() {
    unawaited(relock());
    controller.removeListener(accountChanged);
    controller.remoteChanges.removeListener(remoteChanged);
    _disposed = true;
    _expiry?.cancel();
    _poll?.cancel();
    note = null;
    super.dispose();
  }
}
