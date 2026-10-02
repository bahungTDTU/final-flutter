import 'dart:js_interop';
import 'dart:typed_data';

import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

String objectUrl(Uint8List bytes, String mime) => web.URL.createObjectURL(
  web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime)),
);
Future<bool> saveAttachment(String name, String mime, Uint8List bytes) async {
  final url = objectUrl(bytes, 'application/octet-stream');
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  Future<void>.delayed(
    const Duration(seconds: 30),
    () => web.URL.revokeObjectURL(url),
  );
  return true; // Dispatched to browser; not a disk-completion receipt.
}

class AttachmentVideoSource {
  AttachmentVideoSource(String apiUrl, String token, Uint8List bytes)
    : url = objectUrl(bytes, 'video/mp4') {
    controller = VideoPlayerController.networkUrl(Uri.parse(url));
  }
  final String url;
  late final VideoPlayerController controller;
  Future<void> dispose() async {
    await controller.dispose();
    web.URL.revokeObjectURL(url);
  }
}
