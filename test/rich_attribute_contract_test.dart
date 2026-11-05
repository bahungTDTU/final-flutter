import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note_document.dart';
import 'package:note_together/domain/workspace.dart';

void main() {
  test(
    'Reject server-incompatible rich attributes and preserve legacy text',
    () {
      for (final attributes in <Map<String, dynamic>?>[
        null,
        {'size': '+12'},
        {'size': ' 12 '},
        {'line-height': '1e0'},
        {'line-height': '+1.5'},
        {'line-height': ' 1.5 '},
        {'color': '#1234567'},
        {'background': '#1234567'},
      ]) {
        final content =
            '$noteDocumentPrefix${jsonEncode([
              {'insert': 'Keep this text\n', 'attributes': attributes},
            ])}';
        expect(storedDocumentDelta(content), isNull, reason: '$attributes');
        expect(plainNoteContent(content), content);
        expect(
          () => decodeNoteBundle(
            utf8.encode(
              jsonEncode({
                'format': 'notetogether-notes',
                'version': 1,
                'notes': [
                  {'title': 'Imported note', 'content': content},
                ],
              }),
            ),
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('Canonical rich sizes, spacing and RGB/ARGB colors remain readable', () {
    for (final attributes in [
      {'size': '12', 'line-height': '1.5', 'color': '#123456'},
      {'size': 'huge', 'background': '#80123456'},
    ]) {
      final content =
          '$noteDocumentPrefix${jsonEncode([
            {'insert': 'Readable\n', 'attributes': attributes},
          ])}';
      expect(storedDocumentDelta(content), isNotNull);
      expect(plainNoteContent(content), 'Readable');
    }
  });
}
