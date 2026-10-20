import 'dart:convert';
import '../../lib/domain/note.dart';

void main() {
  final cases = <Map<String, dynamic>>[];
  void check(String name, String title, String content, bool expected) {
    final valid = validNote(title, content);
    if (valid != expected) throw StateError('Unexpected validation: $name');
    cases.add({'name': name, 'title': title, 'content': content, 'valid': valid});
  }

  check('emoji_grapheme_overflow', '👨‍👩‍👧‍👦' * 50, 'body', false);
  check('200_astral_codepoints', '😀' * 200, 'body', true);
  check('200_combining_codepoints', 'e\u0301' * 100, 'body', true);
  check('202_combining_codepoints', 'e\u0301' * 101, 'body', false);
  check('raw_title_with_trailing_space', '${'a' * 200} ', 'body', false);
  check('content_limit', 'Title', 'a' * 100000, true);
  check('content_overflow', 'Title', 'a' * 100001, false);
  check('recovery_ascii', recoveryNoteTitle('a' * 200), 'body', true);
  final recovered = recoveryNoteTitle('e\u0301' * 100);
  if (recovered != '${'e\u0301' * 92} (bản phục hồi)') {
    throw StateError('Recovery split a grapheme or exceeded its budget');
  }
  check('recovery_combining', recovered, 'body', true);
  check('recovery_emoji', recoveryNoteTitle('👨‍👩‍👧‍👦' * 28), 'body', true);
  print(jsonEncode(cases));
}
