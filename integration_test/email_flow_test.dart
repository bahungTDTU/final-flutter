import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/data/open_database.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/home.dart';

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
  expect(condition(), true);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String key, String value) async {
  tester.binding.focusedEditable = null;
  await tester.enterText(find.byKey(Key(key)), value);
  expect(
    tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text,
    value,
  );
}

Future<void> submit(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('email-code-submit')));
  await tester.tap(find.byKey(const Key('email-code-submit')));
}

Future<String> code(String email, String kind) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    final response = await http.get(
      Uri.http('127.0.0.1:8026', '/code', {'email': email, 'kind': kind}),
      headers: {'X-Email-Fixture': 'local-test-only'},
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map)['code'] as String;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  throw StateError('SMTP fixture did not receive the queued message');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native SMTP/TLS received code verifies banner and public reset requires manual login',
    (tester) async {
      final database = await openLocalDatabase();
      final api = Api(
        const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://127.0.0.1:8011',
        ),
      );
      final c = AppController(
        api,
        EncryptedAccountStore(
          SembastLocalStore(database),
          const DeviceRecoveryKeys(),
        ),
      );
      await c.initialize();
      await idle(c);
      await c.logout();
      final email =
          'native-mail-${DateTime.now().microsecondsSinceEpoch}@example.test';
      const password = 'native-account-password-123';
      expect(
        await c.authenticate(
          register: true,
          email: email,
          name: 'Mail fixture',
          password: password,
          confirmation: password,
        ),
        true,
      );
      await idle(c);
      expect(c.emailDelivery, 'queued');
      final oldSession = c.token;
      await c.save(
        c.uuid.v4(),
        'Email fixture note',
        'Still available before verification',
      );
      await idle(c);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.byType(UnverifiedBanner), findsOneWidget);
      final verifyCode = await code(email, 'verify');
      await tester.tap(find.text('Xác minh'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('email-delivery-status')),
      );
      await tester.tap(find.byKey(const Key('email-delivery-status')));
      await until(tester, () => c.emailDelivery == 'smtp_accepted');
      await bindingScreenshot(tester, 'email-queue-native-status');
      await enter(tester, 'email-code', verifyCode);
      await submit(tester);
      await until(
        tester,
        () => find.text('Mã xác minh đã được chấp nhận.').evaluate().isNotEmpty,
      );
      expect(c.user!['verified'], true);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(UnverifiedBanner), findsNothing);
      await c.logout();
      await tester.pumpAndSettle();
      // Public forgot UI creates the actual SMTP message; do not read database tokens.
      await tester.tap(find.text('Quên mật khẩu'));
      await tester.pumpAndSettle();
      tester.binding.focusedEditable = null;
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email khôi phục'),
        email,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await until(tester, () => find.byType(TokenScreen).evaluate().isNotEmpty);
      expect(find.byKey(const Key('email-reset-password')), findsNothing);
      await enter(tester, 'email-code', await code(email, 'reset'));
      await submit(tester);
      await until(
        tester,
        () =>
            find.byKey(const Key('email-reset-password')).evaluate().isNotEmpty,
      );
      await enter(tester, 'email-reset-password', 'native-next-password-123');
      await enter(
        tester,
        'email-reset-confirmation',
        'native-next-password-123',
      );
      await submit(tester);
      await until(tester, () => find.byType(TokenScreen).evaluate().isEmpty);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(c.user, isNull);
      await expectLater(
        api.call('GET', '/me', token: oldSession),
        throwsA(
          isA<ApiException>().having((e) => e.status, 'old session', 401),
        ),
      );
      expect(
        await c.authenticate(
          register: false,
          email: email,
          password: 'native-next-password-123',
        ),
        true,
      );
      await idle(c);
      expect(c.user!['verified'], true);
      expect(c.notes.single.content, 'Still available before verification');
      await tester.pumpWidget(const SizedBox());
      await c.logout();
      c.dispose();
      await database.close();
    },
  );
}

Future<void> bindingScreenshot(WidgetTester tester, String name) async {
  final binding = IntegrationTestWidgetsFlutterBinding.instance;
  await binding.convertFlutterSurfaceToImage();
  await tester.pump();
  await binding.takeScreenshot(name);
}
