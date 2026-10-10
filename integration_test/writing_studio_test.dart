import '../test_driver/editor_input.dart';

import 'package:flutter/material.dart';
import 'package:note_together/ui/rich_note_field.dart';
import 'package:note_together/domain/note_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/data/open_database.dart';
import 'package:note_together/domain/writing_tools.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/writing_studio.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native template checklist focus and encrypted offline reopen with real API',
    (tester) async {
      final db = await openLocalDatabase();
      final api = Api(
        const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://127.0.0.1:8012',
        ),
      );
      final c = AppController(
        api,
        EncryptedAccountStore(
          SembastLocalStore(db),
          const DeviceRecoveryKeys(),
        ),
      );
      await c.initialize();
      await c.logout();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      expect(
        await c.authenticate(
          register: true,
          email: 'studio-native-$stamp@example.test',
          name: 'Studio QA',
          password: 'Studio-local-2026!',
          confirmation: 'Studio-local-2026!',
        ),
        true,
      );
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-templates')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('template-meeting')));
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('native-studio-gallery');
      await tester.tap(find.byKey(const Key('use-template')));
      await tester.pumpAndSettle();
      final id = c.drafts.keys.single;
      final body = tester.widget<NoteRichTextField>(
        find.byKey(const Key('note-content')),
      );
      await enterNoteField(
        tester,
        find.byKey(const Key('note-content')),
        '${body.document.text}\nNghiệm thu trên Android.',
      );
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      for (var i = 0; i < 20 && (c.pending.isNotEmpty || c.syncing); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await c.synchronize();
      }
      expect(c.pending, isEmpty);
      await tester.ensureVisible(find.byKey(const Key('writing-outline')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('writing-outline')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(CheckboxListTile, 'Phân công người phụ trách'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckboxListTile, 'Phân công người phụ trách'),
      );
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      for (var i = 0; i < 20 && (c.pending.isNotEmpty || c.syncing); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await c.synchronize();
      }
      expect(c.pending, isEmpty);
      final remote = await api.call('GET', '/notes/$id', token: c.token);
      expect(
        plainNoteContent(remote['content'] as String),
        contains('Nghiệm thu trên Android.'),
      );
      expect(
        WritingSnapshot(remote['content'] as String).tasks
            .singleWhere((task) => task.text == 'Phân công người phụ trách')
            .done,
        true,
      );
      expect(remote['id'], id);
      expect(remote['revision'], 2);
      await binding.takeScreenshot('native-studio-checklist');
      await tester.tap(find.byKey(const Key('focus-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('focus-start')));
      await tester.pump();
      final session = tester.widget<FocusBar>(find.byType(FocusBar)).session;
      expect(session.running, true);
      await tester.tap(find.byKey(const Key('focus-start')));
      await tester.pumpAndSettle();
      expect(session.running, false);
      await binding.takeScreenshot('native-studio-focus');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
      final reopened = await openLocalDatabase();
      final offline = AppController(
        Api('http://127.0.0.1:65530'),
        EncryptedAccountStore(
          SembastLocalStore(reopened),
          const DeviceRecoveryKeys(),
        ),
      );
      await offline.initialize();
      expect(offline.notes.single.id, id);
      expect(offline.notes.single.content, remote['content']);
      expect(offline.notes.single.revision, 2);
      offline.dispose();
      await reopened.close();
    },
  );
}
