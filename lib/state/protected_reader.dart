import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api.dart';
import '../domain/note.dart';
import 'app_controller.dart';

/// Online, session-scoped reader. Content is never added to the account snapshot.
class ProtectedReader extends ChangeNotifier {
  ProtectedReader(this.controller, this.id)
    : account = controller.user?['id'],
      sessionToken = controller.token {
    controller.addListener(accountChanged);
  }
  final AppController controller;
  final String id;
  final dynamic account;
  final String? sessionToken;
  Note? note;
  String? error;
  bool busy = false, _disposed = false;
  int _epoch = 0;
  Timer? _expiry, _poll;
  bool get active =>
      !_disposed &&
      account != null &&
      controller.user?['id'] == account &&
      controller.token == sessionToken;

  void accountChanged() {
    final source = controller.notes.where((n) => n.id == id).firstOrNull;
    if (note != null &&
        (source == null ||
            source.role != note!.role ||
            source.revision > note!.revision)) {
      hide('Ghi chú hoặc quyền đã thay đổi. Mở khóa lại để đọc.');
    }
    if (!active || (!controller.online && (note != null || busy))) {
      hide('Phiên đọc đã đóng. Mở khóa lại khi có kết nối.');
    }
  }

  void hide([String? message]) {
    _epoch++;
    note = null;
    _expiry?.cancel();
    _poll?.cancel();
    error = message;
    busy = false;
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
        return 'Phiên mở khóa đã hết hạn hoặc quyền truy cập đã thay đổi.';
      }
    }
    return 'Chưa kết nối được backend. Nội dung đã được che; hãy thử lại khi có kết nối.';
  }

  Future<void> unlock(String password) async {
    if (busy || !active || note != null) return;
    final epoch = ++_epoch;
    final elapsed = Stopwatch()..start();
    busy = true;
    error = null;
    notifyListeners();
    try {
      final lease = await controller.noteGrantCall(id, 'unlock', sessionToken, {
        'password': password,
      });
      if (!active || epoch != _epoch) return;
      final remaining =
          Duration(seconds: (lease['expires_in'] as num).toInt()) -
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
      note = Note.fromJson(Map<String, dynamic>.from(result as Map));
      busy = false;
      _poll = Timer.periodic(
        const Duration(seconds: 15),
        (_) => unawaited(refresh()),
      );
      notifyListeners();
    } catch (e) {
      if (active && epoch == _epoch) hide(message(e));
    }
  }

  Future<void> refresh() async {
    if (busy || !active || note == null) return;
    final epoch = _epoch;
    busy = true;
    notifyListeners();
    try {
      final result = await controller.api.call(
        'GET',
        '/notes/$id',
        token: sessionToken,
      );
      if (!active || epoch != _epoch) return;
      note = Note.fromJson(Map<String, dynamic>.from(result as Map));
      busy = false;
      notifyListeners();
    } catch (e) {
      if (active && epoch == _epoch) hide(message(e));
    }
  }

  Future<void> relock([String? reason]) async {
    final canRevoke = active;
    hide(reason);
    if (!canRevoke) return;
    try {
      await controller.noteGrantCall(id, 'lock', sessionToken);
    } catch (_) {
      // Locally hidden even if offline; server grant still has its fixed TTL.
    }
  }

  @override
  void dispose() {
    unawaited(relock());
    controller.removeListener(accountChanged);
    _disposed = true;
    _expiry?.cancel();
    _poll?.cancel();
    note = null;
    super.dispose();
  }
}
