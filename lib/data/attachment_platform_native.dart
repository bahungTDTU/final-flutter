import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

Future<bool> saveAttachment(String name, String mime, Uint8List bytes) async =>
    await const MethodChannel('notetogether/documents').invokeMethod<bool>(
      'save',
      {'name': name, 'mime': mime, 'bytes': bytes},
    ) ??
    false;

class AttachmentVideoSource {
  AttachmentVideoSource(String url, String token, Uint8List bytes)
    : controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: {'Authorization': 'Bearer $token'},
      );
  final VideoPlayerController controller;
  Future<void> dispose() => controller.dispose();
}
