import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/domain/workspace.dart';

void main() {
  test('valid Unicode notes survive export and import without truncation', () {
    final title = List.filled(200, '😀').join();
    final content = List.filled(100000, '😀').join();
    final source = Note(
      id: 'unicode',
      title: title,
      content: content,
      revision: 1,
      updatedAt: '2026-10-22T00:00:00Z',
    );
    expect(validNote(title, content), isTrue);
    final restored = decodeNoteBundle(encodeNoteBundle([source])).single;
    expect(restored.title, title);
    expect(restored.content, content);
    expect(validPortable('$title😀', content), isFalse);
    expect(validPortable(title, '$content😀'), isFalse);
  });

  test('Unicode personal templates remain available after snapshot reload', () {
    final title = List.filled(150, '😀').join();
    final restored = WorkspaceData.fromJson({
      'templates': [
        {
          'id': 'template',
          'title': title,
          'description': '',
          'content': 'Body',
        },
      ],
    });
    expect(restored.templates.single.title, title);
  });
}
