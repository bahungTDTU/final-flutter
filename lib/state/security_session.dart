import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api.dart';
import 'app_controller.dart';

@immutable
class AccountSession {
  const AccountSession(
    this.id,
    this.label,
    this.createdAt,
    this.expiresAt,
    this.current,
  );
  final String id, label;
  final DateTime? createdAt;
  final DateTime expiresAt;
  final bool current;

  factory AccountSession.fromJson(Map data) {
    final id = data['id'], label = data['label'], created = data['created_at'];
    final expires = data['expires_at'], current = data['is_current'];
    if (id is! String ||
        id.isEmpty ||
        id.length > 80 ||
        label is! String ||
        label.length > 80 ||
        current is! bool ||
        expires is! String ||
        (created != null && created is! String)) {
      throw const FormatException('Invalid session response');
    }
    return AccountSession(
      id,
      label,
      created == null ? null : DateTime.parse(created as String),
      DateTime.parse(expires),
      current,
    );
  }
}

/// Online-only, route-owned RAM. No passwords, session handles or metadata in cache/outbox.
class SecuritySession extends ChangeNotifier {
  SecuritySession(this.controller)
    : account = controller.user?['id'],
      sessionToken = controller.token,
      wasForeground = controller.foreground {
    controller.addListener(checkGate);
  }
  final AppController controller;
  final Object? account;
  final String? sessionToken;
  bool disposed = false, busy = false, validated = false, wasForeground;
  int epoch = 0, total = 0, limit = 20;
  List<AccountSession> sessions = const [];
  String? message;
  Completer<void>? cancellation;
  bool get active =>
      !disposed &&
      account != null &&
      sessionToken != null &&
      controller.user?['id'] == account &&
      controller.token == sessionToken &&
      controller.foreground;
  bool get canManage => active && validated && !busy;
  int get otherCount => total > 0 ? total - 1 : 0;

  void clearMessage() {
    message = null;
    if (!disposed) notifyListeners();
  }

  void hide(String reason) {
    epoch++;
    if (cancellation?.isCompleted == false) cancellation!.complete();
    sessions = const [];
    total = 0;
    validated = false;
    busy = false;
    message = reason;
    if (!disposed) notifyListeners();
  }

  void checkGate() {
    final resumed = !wasForeground && controller.foreground;
    wasForeground = controller.foreground;
    if (!active) {
      hide(
        'Đã che thông tin phiên. Cần tài khoản đang đăng nhập và ứng dụng đang mở.',
      );
    } else if (resumed) {
      unawaited(refresh());
    }
  }

  void accept(dynamic data) {
    if (data is! Map ||
        data['sessions'] is! List ||
        data['total'] is! int ||
        data['limit'] is! int ||
        data['limit'] != 20 ||
        data['total'] < 1) {
      throw const FormatException('Invalid session response');
    }
    final rows = data['sessions'] as List;
    if (rows.length > 20 || rows.isEmpty || rows.length > data['total']) {
      throw const FormatException('Invalid session response');
    }
    final next = rows.map((r) => AccountSession.fromJson(r as Map)).toList();
    if (next.map((r) => r.id).toSet().length != next.length ||
        next.where((r) => r.current).length != 1) {
      throw const FormatException('Invalid session response');
    }
    sessions = List.unmodifiable(next);
    total = data['total'] as int;
    limit = data['limit'] as int;
    validated = true;
  }

  Future<void> failure(
    Object error,
    int attempt, {
    bool preserve = false,
  }) async {
    if (!active || attempt != epoch) return;
    if (error is ApiException && error.status == 401) {
      hide('Phiên đăng nhập đã kết thúc. Đăng nhập lại để tiếp tục.');
      await controller.logout();
      return;
    }
    if (!preserve) {
      sessions = const [];
      total = 0;
      validated = false;
    }
    message = error is ApiException && error.status == 403
        ? 'Mật khẩu tài khoản chưa đúng. Hãy kiểm tra và thử lại.'
        : error is ApiException && error.status == 429
        ? 'Đã thử quá nhiều lần. Chờ khoảng một phút rồi thử lại.'
        : error is ApiException && error.status == 409
        ? 'Dùng Đăng xuất để kết thúc phiên hiện tại.'
        : 'Chưa kết nối được trung tâm bảo mật. Thông tin cần được tải lại.';
  }

  Future<void> refresh() async {
    if (!active || busy) return;
    final attempt = epoch;
    final cancel = Completer<void>();
    cancellation = cancel;
    busy = true;
    message = null;
    notifyListeners();
    try {
      final data = await controller.api.call(
        'GET',
        '/me/sessions',
        token: sessionToken,
        cancellation: cancel.future,
      );
      if (!active || attempt != epoch) return;
      accept(data);
    } catch (e) {
      await failure(e, attempt);
    } finally {
      if (identical(cancellation, cancel)) cancellation = null;
      if (!disposed && attempt == epoch) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<bool> revoke(String password, {String? id}) async {
    if (!canManage ||
        (id != null && !sessions.any((s) => s.id == id && !s.current))) {
      return false;
    }
    final attempt = epoch;
    final cancel = Completer<void>();
    cancellation = cancel;
    busy = true;
    message = null;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'scope': id == null ? 'others' : 'one',
        'password': password,
      };
      if (id != null) body['session_id'] = id;
      final result = await controller.api.call(
        'POST',
        '/me/sessions/revoke',
        token: sessionToken,
        cancellation: cancel.future,
        body: body,
      );
      if (!active || attempt != epoch) return false;
      if (result is! Map || result['ok'] != true || result['revoked'] is! int) {
        throw const FormatException('Invalid revocation response');
      }
      // A timeout can occur after server success; safe retries revalidate through the server.
      final data = await controller.api.call(
        'GET',
        '/me/sessions',
        token: sessionToken,
        cancellation: cancel.future,
      );
      if (!active || attempt != epoch) return false;
      accept(data);
      message =
          'Đã thu hồi ${result['revoked']} phiên đăng nhập. Phiên này được giữ nguyên.';
      return true;
    } catch (e) {
      await failure(
        e,
        attempt,
        preserve: e is ApiException && [403, 429, 409].contains(e.status),
      );
      return false;
    } finally {
      if (identical(cancellation, cancel)) cancellation = null;
      if (!disposed && attempt == epoch) {
        busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    disposed = true;
    epoch++;
    if (cancellation?.isCompleted == false) cancellation!.complete();
    sessions = const [];
    controller.removeListener(checkGate);
    super.dispose();
  }
}
