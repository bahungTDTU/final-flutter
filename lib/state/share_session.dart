import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/api.dart';
import 'app_controller.dart';

/// Online-only owner manager. Recipients and retries stay in this route's RAM.
class ShareSession extends ChangeNotifier {
  ShareSession(
    this.controller,
    this.noteId, {
    this.protectedGate,
    this.gateChanges,
  }) : account = controller.user?['id'],
       sessionToken = controller.token {
    controller.addListener(checkGate);
    controller.remoteChanges.addListener(onRemoteChange);
    gateChanges?.addListener(checkGate);
    poll = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(refresh()),
    );
  }
  final AppController controller;
  final String noteId;
  final Object? account;
  final String? sessionToken;
  final bool Function()? protectedGate;
  final Listenable? gateChanges;
  Timer? poll;
  bool disposed = false, busy = false, validated = false, foreground = true;
  int epoch = 0, revision = 0;
  List<Map<String, dynamic>> recipients = [];
  Map<String, dynamic>? pending;
  String? message;
  String get path => '/notes/$noteId/shares';
  bool get active {
    if (disposed ||
        !foreground ||
        account == null ||
        controller.user?['id'] != account ||
        controller.token != sessionToken) {
      return false;
    }
    if (protectedGate != null) return protectedGate!();
    final note = controller.notes.where((n) => n.id == noteId).firstOrNull;
    return note?.role == 'owner' && note?.locked == false;
  }

  bool get canManage => active && validated;
  void onRemoteChange() {
    if (active) unawaited(refresh());
  }

  void setForeground(bool value) {
    foreground = value;
    if (!value) {
      hide(
        'Đã che danh sách khi ứng dụng ra nền. Kiểm tra lại quyền khi trở về.',
      );
    } else if (!disposed) {
      notifyListeners();
    }
  }

  void checkGate() {
    if (!active) {
      hide('Phiên chia sẻ đã đóng. Mở lại ghi chú để kiểm tra quyền.');
    }
  }

  void hide(String reason) {
    epoch++;
    recipients = [];
    pending = null;
    validated = false;
    message = reason;
    if (!disposed) notifyListeners();
  }

  void accept(dynamic result) {
    revision = result['revision'] as int;
    recipients = (result['recipients'] as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
    validated = true;
  }

  Future<void> refresh() async {
    if (busy || !active) return;
    final attempt = epoch;
    busy = true;
    notifyListeners();
    try {
      final result = await controller.api.call(
        'GET',
        path,
        token: sessionToken,
      );
      if (!active || attempt != epoch) return;
      accept(result);
      if (pending == null) message = null;
    } catch (e) {
      if (!disposed && attempt == epoch) {
        hide(
          'Chưa kiểm tra được quyền chia sẻ. Cần kết nối và phiên mở khóa hợp lệ.',
        );
      }
    } finally {
      busy = false;
      if (!disposed) notifyListeners();
    }
  }

  Future<void> submit(Map<String, dynamic> mutation) async {
    if (busy || !canManage || pending != null) return;
    pending = Map<String, dynamic>.from(
      jsonDecode(
        jsonEncode({
          'op_id': controller.uuid.v4(),
          'base_revision': revision,
          ...mutation,
        }),
      ) as Map,
    );
    await retry();
  }

  Future<void> retry() async {
    if (busy || !canManage || pending == null) return;
    final attempt = epoch;
    final operation = pending!;
    busy = true;
    message = null;
    notifyListeners();
    try {
      final result = await controller.api.call(
        'POST',
        '$path/sync',
        token: sessionToken,
        body: operation,
      );
      if (!active || attempt != epoch) return;
      accept(result);
      pending = null;
      message = 'Server đã cập nhật chia sẻ.';
      await controller.synchronize();
    } on ApiException catch (e) {
      if (!active || attempt != epoch) return;
      if (e.status == 409) {
        final current = e.detail is Map ? e.detail['current'] : null;
        if (current != null) accept(current);
        pending = null;
        message = 'Danh sách quyền đã thay đổi hoặc người nhận đã có. Kiểm tra danh sách trước khi gửi lại.';
      } else if (e.status == 422 ||
          (e.status == 404 && e.detail == 'Recipient not registered')) {
        pending = null;
        message = e.status == 404
            ? 'Một email chưa đăng ký. Chưa thêm người nhận nào.'
            : 'Email trùng, không hợp lệ hoặc là tài khoản của bạn. Chưa cập nhật chia sẻ.';
      } else if (e.status >= 500) {
        message = 'Chưa nhận được xác nhận từ server. Thử lại cùng thao tác.';
      } else {
        hide(
          'Quyền hoặc phiên mở khóa đã thay đổi. Nội dung chia sẻ đã được che.',
        );
      }
    } catch (_) {
      if (active && attempt == epoch) {
        message = 'Chưa nhận được xác nhận. Thử lại cùng thao tác hoặc đóng cửa sổ rồi kiểm tra danh sách.';
      }
    } finally {
      busy = false;
      if (!disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    disposed = true;
    epoch++;
    recipients = [];
    pending = null;
    poll?.cancel();
    controller.removeListener(checkGate);
    controller.remoteChanges.removeListener(onRemoteChange);
    gateChanges?.removeListener(checkGate);
    super.dispose();
  }
}
