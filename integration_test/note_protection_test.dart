import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/data/open_database.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/note_protection.dart';

Future<void> idle(AppController c) async {
  for (var i = 0; i < 100 && c.syncing; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(c.syncing, false);
}

Future<void> until(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 100 && !condition(); i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  if (!condition()) {
    debugPrint(
      'Protection fixture visible labels: ${tester.widgetList<Text>(find.byType(Text)).map((w) => w.data).whereType<String>().join(' | ')}',
    );
  }
  expect(condition(), true);
  await tester.pumpAndSettle();
}

Future<void> pressUnlock(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('unlock-note')));
  await tester.tap(find.byKey(const Key('unlock-note')));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native protection UI: enable, wrong password, temporary read, background, change and disable',
    (tester) async {
      final database = await openLocalDatabase();
      final raw = SembastLocalStore(database);
      final local = EncryptedAccountStore(raw, const DeviceRecoveryKeys());
      final api = Api(
        const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://127.0.0.1:8000',
        ),
      );
      final c = AppController(api, local);
      await c.initialize();
      await idle(c);
      await c.logout();
      expect(
        await c.authenticate(
          register: true,
          email:
              'protection-${DateTime.now().microsecondsSinceEpoch}@example.com',
          name: 'Protection test',
          password: 'integration-account-123',
          confirmation: 'integration-account-123',
        ),
        true,
      );
      await idle(c);
      final id = c.uuid.v4();
      await c.save(id, 'Native private title', 'Native private body');
      await idle(c);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      // Exercise the same dialog as the home menu without relying on card layout.
      final context = tester.element(find.byType(Scaffold).first);
      final enabled = showDialog<bool>(
        context: context,
        builder: (_) => NoteProtectionDialog(
          controller: c,
          id: id,
          action: ProtectionAction.enable,
        ),
      );
      await tester.pumpAndSettle();
      for (final key in ['note-new-password', 'note-confirm-password']) {
        tester.binding.focusedEditable = null;
        await tester.enterText(find.byKey(Key(key)), 'first-note-password-123');
      }
      await tester.tap(find.byKey(const Key('confirm-note-protection')));
      await tester.pumpAndSettle();
      expect(await enabled, true);
      await idle(c);
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await tester.pump(const Duration(seconds: 1));
      expect(c.notes.single.content, isEmpty);
      expect(
        jsonEncode(await raw.read(c.accountKey)),
        isNot(contains('Native private body')),
      );
      await expectLater(
        api.call('GET', '/notes/$id', token: c.token),
        throwsA(isA<ApiException>().having((e) => e.status, 'locked', 423)),
      );
      await api.call(
        'POST',
        '/notes/$id/unlock',
        token: c.token,
        body: {'password': 'first-note-password-123'},
      );
      await api.call('POST', '/notes/$id/lock', token: c.token);
      await tester.tap(find.text('Ghi chú đã khóa').first);
      await tester.pumpAndSettle();
      tester.binding.focusedEditable = null;
      await tester.enterText(
        find.byKey(const Key('unlock-note-password')),
        'wrong',
      );
      await pressUnlock(tester);
      await until(
        tester,
        () => find
            .text('Mật khẩu ghi chú chưa đúng hoặc quyền đã thay đổi.')
            .evaluate()
            .isNotEmpty,
      );
      expect(find.text('Native private body'), findsNothing);
      expect(
        find.text('Mật khẩu ghi chú chưa đúng hoặc quyền đã thay đổi.'),
        findsOneWidget,
      );
      tester.binding.focusedEditable = null;
      await tester.enterText(
        find.byKey(const Key('unlock-note-password')),
        'first-note-password-123',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('unlock-note-password')),
            )
            .controller!
            .text,
        'first-note-password-123',
      );
      await pressUnlock(tester);
      await until(
        tester,
        () => find.text('Native private body').evaluate().isNotEmpty,
      );
      expect(find.text('Native private body'), findsOneWidget);
      expect(c.notes.single.content, isEmpty);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Native private body'), findsNothing);
      tester.binding.focusedEditable = null;
      await tester.enterText(
        find.byKey(const Key('unlock-note-password')),
        'first-note-password-123',
      );
      await pressUnlock(tester);
      await until(
        tester,
        () => find.text('Native private body').evaluate().isNotEmpty,
      );
      await tester.ensureVisible(find.text('Đổi mật khẩu ghi chú'));
      await tester.tap(find.text('Đổi mật khẩu ghi chú'));
      await tester.pumpAndSettle();
      tester.binding.focusedEditable = null;
      await tester.enterText(
        find.byKey(const Key('note-current-password')),
        'first-note-password-123',
      );
      for (final key in ['note-new-password', 'note-confirm-password']) {
        tester.binding.focusedEditable = null;
        await tester.enterText(
          find.byKey(Key(key)),
          'second-note-password-123',
        );
      }
      await tester.tap(find.byKey(const Key('confirm-note-protection')));
      await until(
        tester,
        () => find.byType(NoteProtectionDialog).evaluate().isEmpty,
      );
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      expect(find.text('Native private body'), findsNothing);
      await expectLater(
        api.call(
          'POST',
          '/notes/$id/unlock',
          token: c.token,
          body: {'password': 'first-note-password-123'},
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.status,
            'old password rejected',
            403,
          ),
        ),
      );
      tester.binding.focusedEditable = null;
      await tester.enterText(
        find.byKey(const Key('unlock-note-password')),
        'second-note-password-123',
      );
      await pressUnlock(tester);
      await until(
        tester,
        () => find.text('Native private body').evaluate().isNotEmpty,
      );
      await tester.ensureVisible(find.text('Tắt khóa ghi chú'));
      await tester.tap(find.text('Tắt khóa ghi chú'));
      await tester.pumpAndSettle();
      tester.binding.focusedEditable = null;
      await tester.enterText(
        find.byKey(const Key('note-current-password')),
        'second-note-password-123',
      );
      await tester.tap(find.byKey(const Key('confirm-note-protection')));
      await until(
        tester,
        () =>
            !c.notes.single.locked &&
            find.byType(ProtectedNoteScreen).evaluate().isEmpty,
      );
      await idle(c);
      expect(c.notes.single.locked, false);
      expect(
        (await api.call('GET', '/notes/$id', token: c.token))['content'],
        'Native private body',
      );
      await tester.pumpWidget(const SizedBox());
      await c.logout();
      c.dispose();
      await database.close();
    },
  );
}
