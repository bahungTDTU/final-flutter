import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/ui/rich_note_field.dart';

/// The native integration harness uses the same TextInputClient event injection
/// as tester.enterText. Quill owns its client rather than an EditableText.
/// This verifies app input handling, not a physical keyboard or real IME.
Future<void> enterNoteField(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  final field = tester.widget(finder);
  if (field is! NoteRichTextField) {
    await tester.enterText(finder, text);
    return;
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  field.document.requestKeyboard(field.focusNode);
  await tester.pump();
  expect(field.readOnly, false);
  if (tester.testTextInput.isRegistered) {
    expect(tester.testTextInput.hasAnyClients, true);
  }
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: '$text\n',
      selection: TextSelection.collapsed(offset: text.length),
    ),
  );
  await tester.pump();
}
