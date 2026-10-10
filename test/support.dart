import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/rich_note_field.dart';

/// Send an actual TextInputClient event to Quill's focused editor. Flutter's
/// enterText helper only supports EditableText; Quill owns its native client.
Future<void> enterDocumentText(
  WidgetTester tester,
  Finder field,
  String text,
) async {
  final rich = tester.widget<NoteRichTextField>(field);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  rich.focusNode.requestFocus();
  await tester.pumpAndSettle();
  expect(rich.readOnly, false);
  rich.document.editorKey.currentState?.editableTextKey.currentState
      ?.requestKeyboard();
  await tester.pump();
  expect(tester.testTextInput.hasAnyClients, true);
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: '$text\n',
      selection: TextSelection.collapsed(offset: text.length),
    ),
  );
  await tester.pump();
}

/// Exercise the visible UI even when a lazy Home card has not been built yet.
Future<void> revealHome(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    160,
    scrollable: find
        .descendant(
          of: find.byType(CustomScrollView).first,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

class MemoryStore implements LocalStore {
  final values = <String, Map<String, dynamic>>{};
  @override
  Future<Map<String, dynamic>?> read(String key) async => values[key] == null
      ? null
      : Map<String, dynamic>.from(jsonDecode(jsonEncode(values[key])) as Map);
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    values[key] = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(value)) as Map,
    );
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

AppController offlineController({MemoryStore? store, String id = 'A'}) {
  final c = AppController(
    Api(
      'http://test',
      client: MockClient((_) async => throw http.ClientException('offline')),
    ),
    store ?? MemoryStore(),
  );
  c.user = {
    'id': id,
    'name': 'Test',
    'email': 'test@example.com',
    'verified': false,
  };
  c.token = 'test-token';
  c.ready = true;
  return c;
}
