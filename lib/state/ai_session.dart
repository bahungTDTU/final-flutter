import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api.dart';
import '../domain/note.dart';
import 'app_controller.dart';

/// AI output is route-scoped RAM, never written to notes, vault, outbox or history.
class AiSession extends ChangeNotifier {
  AiSession(
    this.controller, {
    this.noteId,
    this.protectedGate,
    this.gateChanges,
  }) : account = controller.user?['id'],
       sessionToken = controller.token {
    controller.addListener(checkGate);
    controller.remoteChanges.addListener(remoteChanged);
    gateChanges?.addListener(checkGate);
    _poll = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(validate()),
    );
  }
  final AppController controller;
  final String? noteId;
  final bool Function()? protectedGate;
  final Listenable? gateChanges;
  final Object? account;
  final String? sessionToken;
  Map<String, dynamic>? result;
  String? error;
  bool busy = false,
      _disposed = false,
      _validationBusy = false,
      _suspended = false;
  int _epoch = 0;
  Timer? _poll;
  Completer<void>? _cancellation;

  bool get active {
    if (_disposed ||
        _suspended ||
        !controller.foreground ||
        account == null ||
        controller.user?['id'] != account ||
        controller.token != sessionToken) {
      return false;
    }
    if (protectedGate != null && !protectedGate!()) return false;
    if (noteId != null) {
      final note = controller.notes.where((n) => n.id == noteId).firstOrNull;
      return note != null && (!note.locked || protectedGate != null);
    }
    return true;
  }

  List<Map<String, dynamic>> get sources => (result?['sources'] as List? ?? [])
      .map((s) => Map<String, dynamic>.from(s as Map))
      .toList();
  List<Map<String, dynamic>> get contexts =>
      (result?['context_sources'] as List? ?? result?['sources'] as List? ?? [])
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();

  void clear([String? message]) {
    _epoch++;
    if (_cancellation?.isCompleted == false) _cancellation!.complete();
    result = null;
    busy = false;
    error = message;
    if (!_disposed) notifyListeners();
  }

  void suspend() {
    _suspended = true;
    clear('Kết quả đã được che khi ứng dụng chuyển nền.');
  }

  void resume() {
    _suspended = false;
    checkGate();
  }

  bool sourceChanged(Map<String, dynamic> source) {
    final local = controller.notes
        .where((n) => n.id == source['id'])
        .firstOrNull;
    return local == null ||
        local.revision != source['revision'] ||
        (local.locked && (protectedGate == null || !protectedGate!()));
  }

  void checkGate() {
    if (!active || !controller.online || contexts.any(sourceChanged)) {
      if (busy || result != null) {
        clear(
          'Nguồn, quyền truy cập hoặc kết nối đã thay đổi. Hãy tạo lại kết quả.',
        );
      }
    }
  }

  void remoteChanged() {
    checkGate();
    if (active) unawaited(validate());
  }

  String message(Object error) {
    if (error is ApiException) {
      switch (error.detail) {
        case 'AI_NOT_CONFIGURED':
          return 'AI chưa được cấu hình trên máy chủ. Hãy thử lại sau.';
        case 'AI_CONFIGURATION':
          return 'Dịch vụ AI chưa sẵn sàng. Hãy thử lại sau.';
        case 'AI_QUOTA':
          return 'Đã đạt hạn mức AI. Hãy đợi rồi thử lại.';
        case 'AI_BUSY':
          return 'AI đang xử lý yêu cầu khác. Hãy thử lại sau ít phút.';
        case 'AI_TIMEOUT':
          return 'AI phản hồi quá lâu. Bạn có thể thử lại.';
        case 'AI_SOURCES_CHANGED':
          return 'Ghi chú hoặc quyền đã thay đổi. Hãy tạo lại kết quả.';
        case 'AI_NOTE_TOO_LONG':
          return 'Ghi chú vượt giới hạn tóm tắt 24.000 ký tự. Hãy dùng ghi chú ngắn hơn.';
        case 'AI_LIBRARY_TOO_LARGE':
          return 'Thư viện vượt giới hạn truy vấn AI hiện tại.';
        case 'AI_INVALID_OUTPUT':
          return 'AI chưa trả về kết quả có nguồn hợp lệ. Bạn có thể thử lại.';
      }
      if ([401, 403, 404, 423].contains(error.status)) {
        return 'Phiên đăng nhập hoặc quyền mở khóa đã thay đổi.';
      }
    }
    return 'Chưa nhận được phản hồi AI. Kiểm tra kết nối rồi thử lại.';
  }

  Future<void> generate({String? question}) async {
    if (!active || busy) return;
    clear();
    if (!controller.online) {
      error = 'Cần kết nối để dùng AI.';
      notifyListeners();
      return;
    }
    if (noteId != null &&
        (controller.hasPending(noteId!) ||
            controller.drafts.containsKey(noteId))) {
      error = 'Đồng bộ bản nháp trước khi tóm tắt phiên bản trên máy chủ.';
      notifyListeners();
      return;
    }
    final attempt = _epoch;
    _cancellation = Completer<void>();
    busy = true;
    notifyListeners();
    try {
      final data = await controller.api.call(
        'POST',
        noteId == null
            ? '/ai/questions'
            : '/notes/${Uri.encodeComponent(noteId!)}/ai/summary',
        token: sessionToken,
        body: noteId == null ? {'question': question!.trim()} : null,
        timeout: const Duration(seconds: 55),
        cancellation: _cancellation!.future,
      );
      if (attempt != _epoch || !active) return;
      result = Map<String, dynamic>.from(data as Map);
      busy = false;
      checkGate();
      if (result != null) await validate();
    } catch (e) {
      if (attempt == _epoch && active) {
        result = null;
        busy = false;
        error = message(e);
      }
    }
    if (!_disposed && attempt == _epoch) notifyListeners();
  }

  Future<void> validate() async {
    if (!active ||
        result == null ||
        contexts.isEmpty ||
        busy ||
        _validationBusy) {
      return;
    }
    final attempt = _epoch;
    _validationBusy = true;
    try {
      await controller.api.call(
        'POST',
        '/ai/validate',
        token: sessionToken,
        body: {
          'sources': contexts
              .map((s) => {'id': s['id'], 'revision': s['revision']})
              .toList(),
        },
      );
    } catch (e) {
      if (!_disposed && attempt == _epoch) clear(message(e));
    } finally {
      _validationBusy = false;
    }
  }

  Future<Note?> openSource(String id) async {
    if (!active || !sources.any((s) => s['id'] == id)) return null;
    final attempt = _epoch;
    try {
      final data = await controller.api.call(
        'GET',
        '/notes/${Uri.encodeComponent(id)}',
        token: sessionToken,
      );
      if (attempt != _epoch || !active) return null;
      final note = Note.fromJson(Map<String, dynamic>.from(data as Map));
      if (sources.firstWhere((s) => s['id'] == id)['revision'] !=
          note.revision) {
        clear('Nguồn đã có phiên bản mới. Hãy tạo lại kết quả.');
        return null;
      }
      return note;
    } catch (e) {
      if (attempt == _epoch && !_disposed) clear(message(e));
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    clear();
    _poll?.cancel();
    controller.removeListener(checkGate);
    controller.remoteChanges.removeListener(remoteChanged);
    gateChanges?.removeListener(checkGate);
    super.dispose();
  }
}
