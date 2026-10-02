import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:uuid/uuid.dart';

class SelectedAttachment {
  SelectedAttachment(this.name, this.bytes, {String? id})
    : id = id ?? const Uuid().v4();
  final String id, name;
  final Uint8List bytes;
  String get extension => name.split('.').last.toLowerCase();
  String get kind => switch (extension) {
    'png' || 'jpg' || 'jpeg' => 'image',
    'mp4' => 'video',
    _ => 'file',
  };
  String get contentType => switch (extension) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'mp4' => 'video/mp4',
    'pdf' => 'application/pdf',
    'txt' => 'text/plain',
    'csv' => 'text/csv',
    'zip' => 'application/zip',
    _ => throw ArgumentError('Chọn PNG/JPEG, MP4, PDF, TXT, CSV hoặc ZIP.'),
  };
  void validate() {
    contentType;
    if (name.isEmpty ||
        name.length > 160 ||
        name.contains(RegExp(r'[\\/\x00-\x1f\x7f]'))) {
      throw ArgumentError('Tên file không hợp lệ.');
    }
    if (bytes.isEmpty ||
        bytes.length > (kind == 'image' ? 10 : 20) * 1024 * 1024) {
      throw ArgumentError('Ảnh tối đa10 MiB; video/file tối đa20 MiB.');
    }
  }
}

Future<List<SelectedAttachment>> pickAttachments() async {
  final files = await openFiles(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Đính kèm',
        extensions: ['png', 'jpg', 'jpeg', 'mp4', 'pdf', 'txt', 'csv', 'zip'],
        mimeTypes: [
          'image/png',
          'image/jpeg',
          'video/mp4',
          'application/pdf',
          'text/plain',
          'text/csv',
          'application/zip',
        ],
        uniformTypeIdentifiers: [
          'public.png',
          'public.jpeg',
          'public.mpeg-4',
          'com.adobe.pdf',
          'public.plain-text',
          'public.comma-separated-values-text',
          'public.zip-archive',
        ],
      ),
    ],
  );
  if (files.length > 10) throw ArgumentError('Chọn tối đa10 file mỗi lần.');
  final selected = <SelectedAttachment>[];
  var total = 0;
  for (final file in files) {
    final length = await file.length();
    total += length;
    if (length > 20 * 1024 * 1024 || total > 100 * 1024 * 1024) {
      throw ArgumentError('Mỗi file tối đa20 MiB, tổng tối đa100 MiB.');
    }
    final attachment = SelectedAttachment(file.name, await file.readAsBytes());
    attachment.validate();
    selected.add(attachment);
  }
  return selected;
}
