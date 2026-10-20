import 'dart:convert';
import 'package:characters/characters.dart';
import '../../lib/domain/note.dart';

void main() {
  final title = List.filled(50, '👨‍👩‍👧‍👦').join();
  print(jsonEncode({
    'target': 'actual Dart domain validator, not widget runtime',
    'title_graphemes': title.characters.length,
    'title_codepoints': title.runes.length,
    'ui_maxLength': 200,
    'validNote': validNote(title, 'body'),
    'oversize_plain_content_validNote': validNote('title', 'x' * 100001),
  }));
}
