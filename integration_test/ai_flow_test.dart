import '../test_driver/editor_input.dart';

import 'package:note_together/ui/rich_note_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/data/open_database.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native AI transport fixture: summary, regeneration, multi-note citations and source open',
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
      final email =
          'native-ai-${DateTime.now().microsecondsSinceEpoch}@example.test';
      expect(
        await c.authenticate(
          register: true,
          email: email,
          name: 'AI Native Fixture',
          password: 'Native-AI-2026!',
          confirmation: 'Native-AI-2026!',
        ),
        true,
      );
      final status = await api.call('GET', '/ai/status', token: c.token);
      // This scenario explicitly requires a double; it never claims Gemini success.
      expect(status['provider'], 'test-double');
      final id = c.uuid.v4(), second = c.uuid.v4();
      await c.save(
        second,
        'Orion ngân sách',
        'Ngân sách dự án Orion là 300.000 đồng.',
      );
      await c.save(
        id,
        'Orion lịch nộp',
        'Dự án Orion nộp ngày 20 tháng 11 năm 2026.',
      );
      await c.synchronize();
      Future<void> until(bool Function() ready) async {
        for (var i = 0; i < 120 && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(ready(), true);
        await tester.pumpAndSettle();
      }

      await until(() => !c.syncing && c.pending.isEmpty);
      final original = await api.call('GET', '/notes/$id', token: c.token);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Orion lịch nộp'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tóm tắt bằng AI'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ai-summary-generate')));
      await until(
        () => find.byKey(const Key('ai-result')).evaluate().isNotEmpty,
      );
      expect(
        tester.widget<SelectableText>(find.byKey(const Key('ai-result'))).data,
        contains('fixture kiểm thử'),
      );
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('ai-native-summary-fixture');
      await tester.ensureVisible(find.byKey(const Key('ai-summary-generate')));
      await tester.tap(find.byKey(const Key('ai-summary-generate')));
      await until(
        () => find.byKey(const Key('ai-result')).evaluate().isNotEmpty,
      );
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      expect(await api.call('GET', '/notes/$id', token: c.token), original);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hỏi ghi chú'));
      await tester.pumpAndSettle();
      await enterNoteField(
        tester,
        find.byKey(const Key('ai-question')),
        'Dự án Orion nộp khi nào và ngân sách bao nhiêu?',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('ai-ask')));
      await tester.tap(find.byKey(const Key('ai-ask')));
      await until(
        () => find.byKey(ValueKey('ai-source-$id')).evaluate().isNotEmpty,
      );
      expect(find.byKey(ValueKey('ai-source-$second')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('ai-result')));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('ai-native-question-fixture');
      await tester.ensureVisible(find.byKey(ValueKey('ai-source-$id')));
      await tester.tap(find.byKey(ValueKey('ai-source-$id')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-title')))
            .controller!
            .text,
        'Orion lịch nộp',
      );
      expect(
        tester
            .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
            .document
            .text,
        original['content'],
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
    },
  );
}
