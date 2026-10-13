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
  // Let focus leave the preceding password field before opening Quill's
  // TextInputClient. Otherwise native drive can inject into the old client.
  field.focusNode.requestFocus();
  await tester.pumpAndSettle();
  final focusedField = tester.widget<NoteRichTextField>(finder);
  focusedField.document.requestKeyboard(focusedField.focusNode);
  await tester.pump();
  expect(focusedField.focusNode.hasFocus, true);
  expect(focusedField.readOnly, false);
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
