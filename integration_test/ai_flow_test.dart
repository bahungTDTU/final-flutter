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
  const live = bool.fromEnvironment('AI_QA_LIVE');
  const capture = bool.fromEnvironment('AI_QA_CAPTURE');
  final provider = live ? 'gemini' : 'test-double';
  final deadline = RegExp(r'\b20(?:\s+tháng\s+|[./-])0?11\b');
  final budget = RegExp(r'\b300(?:[.,\s])?000\b');
  testWidgets(
    'Native AI ($provider): summary, regeneration, citations and source open',
    (tester) async {
      final api = Api(
        const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://127.0.0.1:8012',
        ),
      );
      final health = await api.call('GET', '/health');
      expect(health['ai'], 'configured');
      expect(health['email_delivery'], 'not_configured');
      final db = await openLocalDatabase();
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
          name: 'AI Native QA',
          password: 'Native-AI-2026!',
          confirmation: 'Native-AI-2026!',
        ),
        true,
      );
      final status = await api.call('GET', '/ai/status', token: c.token);
      expect(status['provider'], provider);
      await c.setLanguage('vi');
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
        final timer = Stopwatch()..start();
        while (!ready() && timer.elapsed < const Duration(seconds: 60)) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
        }
        expect(ready(), true);
        await tester.pumpAndSettle();
      }

      String resultText() => tester
          .widget<SelectableText>(find.byKey(const Key('ai-result')))
          .data!;

      await until(() => !c.syncing && c.pending.isEmpty);
      final original = await api.call('GET', '/notes/$id', token: c.token);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Orion lịch nộp'));
      await tester.pumpAndSettle();
      final compactTools = find.byKey(const Key('editor-tools-menu'));
      if (compactTools.evaluate().isNotEmpty) {
        await tester.tap(compactTools);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tóm tắt bằng AI'));
      } else {
        await tester.tap(find.byTooltip('Tóm tắt bằng AI'));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ai-summary-generate')));
      await until(
        () => find.byKey(const Key('ai-result')).evaluate().isNotEmpty,
      );
      expect(resultText(), matches(deadline));
      if (!live) expect(resultText(), contains('fixture kiểm thử'));
      if (capture) {
        await binding.convertFlutterSurfaceToImage();
        await tester.pump();
        await binding.takeScreenshot('ai-native-summary-$provider');
      }
      await tester.ensureVisible(find.byKey(const Key('ai-summary-generate')));
      await tester.tap(find.byKey(const Key('ai-summary-generate')));
      await tester.pump();
      expect(find.byKey(const Key('ai-result')), findsNothing);
      await until(
        () => find.byKey(const Key('ai-result')).evaluate().isNotEmpty,
      );
      expect(resultText(), matches(deadline));
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
      expect(resultText(), matches(deadline));
      expect(resultText(), matches(budget));
      if (capture) {
        await tester.ensureVisible(find.byKey(const Key('ai-result')));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('ai-native-question-$provider');
      }
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
