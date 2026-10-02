import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

class SelectedAvatar {
  const SelectedAvatar(this.name, this.bytes, this.contentType);
  final String name, contentType;
  final Uint8List bytes;
}

String avatarContentType(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes.take(8).join(',') == '137,80,78,71,13,10,26,10') {
    return 'image/png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 255 &&
      bytes[1] == 216 &&
      bytes[2] == 255) {
    return 'image/jpeg';
  }
  throw ArgumentError('Chọn ảnh PNG hoặc JPEG hợp lệ');
}

Future<SelectedAvatar?> pickAvatar() async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Ảnh PNG/JPEG',
        extensions: ['png', 'jpg', 'jpeg'],
        mimeTypes: ['image/png', 'image/jpeg'],
        uniformTypeIdentifiers: ['public.png', 'public.jpeg'],
      ),
    ],
  );
  if (file == null) return null;
  if (await file.length() > 2 * 1024 * 1024) {
    throw ArgumentError('Chọn ảnh tối đa 2 MiB');
  }
  if (!RegExp(r'\.(png|jpe?g)$', caseSensitive: false).hasMatch(file.name)) {
    throw ArgumentError('Chọn file .png, .jpg hoặc .jpeg');
  }
  final bytes = await file.readAsBytes();
  return SelectedAvatar(file.name, bytes, avatarContentType(bytes));
}
