import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api.dart';
import '../data/attachment_files.dart';
import 'app_controller.dart';

/// Route-scoped RAM only. Attachment metadata/bytes never enter the account vault.
class AttachmentSession extends ChangeNotifier {
  AttachmentSession(
    this.controller,
    this.noteId, {
    this.protectedGate,
    this.gateChanges,
  }) : account = controller.user?['id'],
       sessionToken = controller.token {
    controller.addListener(checkGate);
    controller.remoteChanges.addListener(onRemoteChange);
    gateChanges?.addListener(checkGate);
    _poll = Timer.periodic(
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
  List<Map<String, dynamic>> files = [];
  String? error;
  bool busy = false, _disposed = false;
  int epoch = 0;
  Timer? _poll;
  bool get active {
    if (_disposed ||
        controller.user?['id'] != account ||
        controller.token != sessionToken ||
        sessionToken == null) {
      return false;
    }
    if (protectedGate != null) return protectedGate!();
    final note = controller.notes.where((n) => n.id == noteId).firstOrNull;
    return note != null && !note.locked;
  }

  String get path => '/notes/${Uri.encodeComponent(noteId)}/attachments';
  void onRemoteChange() {
    if (active) unawaited(refresh());
  }

  bool get canEdit =>
      active &&
      controller.notes.any(
        (n) => n.id == noteId && ['owner', 'editor'].contains(n.role),
      );
  void checkGate() {
    if (!active) {
      hide('Phiên đính kèm đã đóng. Mở lại ghi chú để kiểm tra quyền.');
    } else if (!_disposed) {
      notifyListeners();
    }
  }

  void hide(String message) {
    epoch++;
    files = [];
    error = message;
    if (!_disposed) notifyListeners();
  }

  void failure(Object e) {
    hide(
      e is ApiException && [401, 403, 404, 423].contains(e.status)
          ? 'Quyền truy cập hoặc phiên mở khóa đã thay đổi. Nội dung đã được che.'
          : 'Chưa kết nối hoặc xử lý được file. Kiểm tra kết nối rồi thử lại.',
    );
  }

  Future<void> refresh() async {
    if (busy || !active) return;
    final attempt = epoch;
    busy = true;
    notifyListeners();
    try {
      final rows = await controller.api.call('GET', path, token: sessionToken);
      if (active && attempt == epoch) {
        files = (rows as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        error = null;
      }
    } catch (e) {
      if (!_disposed && attempt == epoch) failure(e);
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> upload(SelectedAttachment file) async {
    file.validate();
    if (!canEdit) throw StateError('Attachment edit permission unavailable');
    final attempt = epoch;
    final query = Uri(queryParameters: {'name': file.name, 'kind': file.kind})
        .query;
    await controller.api.binary(
      'POST',
      '$path/${file.id}?$query',
      token: sessionToken!,
      bytes: file.bytes,
      contentType: file.contentType,
      timeout: const Duration(seconds: 60),
    );
    if (!active || attempt != epoch) {
      throw StateError('Attachment session changed');
    }
    await refresh();
  }

  Future<Uint8List> read(String id) async {
    if (!active) throw StateError('Attachment session closed');
    final attempt = epoch;
    try {
      final response = await controller.api.binary(
        'GET',
        '$path/${Uri.encodeComponent(id)}',
        token: sessionToken!,
        timeout: const Duration(seconds: 60),
      );
      if (!active || attempt != epoch) {
        throw StateError('Attachment session changed');
      }
      return response.bodyBytes;
    } catch (e) {
      if (!_disposed && attempt == epoch) failure(e);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    if (!canEdit) throw StateError('Attachment edit permission unavailable');
    await controller.api.call(
      'DELETE',
      '$path/${Uri.encodeComponent(id)}',
      token: sessionToken,
    );
    await refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    epoch++;
    files = [];
    _poll?.cancel();
    controller.removeListener(checkGate);
    controller.remoteChanges.removeListener(onRemoteChange);
    gateChanges?.removeListener(checkGate);
    super.dispose();
  }
}
