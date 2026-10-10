import '../test_driver/editor_input.dart';

import 'package:note_together/ui/rich_note_field.dart';
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
import 'package:note_together/ui/editor.dart';

Future<void> idle(AppController c) async {
  for (var i = 0; i < 200 && c.syncing; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(c.syncing, false);
}

Future<void> until(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 100 && !ready(); i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(ready(), true);
  await tester.pumpAndSettle();
}

Future<void> type(WidgetTester tester, Finder field, String value) async {
  tester.binding.focusedEditable = null;
  await tester.ensureVisible(field);
  await enterNoteField(tester, field, value);
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native sharing manager and server role changes preserve encrypted drafts on reopen',
    (tester) async {
      var db = await openLocalDatabase();
      final api = Api(
        const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://127.0.0.1:8000',
        ),
      );
      AppController make(Api transport) => AppController(
        transport,
        EncryptedAccountStore(
          SembastLocalStore(db),
          const DeviceRecoveryKeys(),
        ),
      );
      var c = make(api);
      await c.initialize();
      await idle(c);
      await c.logout();
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final ownerEmail = 'native-share-owner-$suffix@example.test';
      final recipientEmail = 'native-share-recipient-$suffix@example.test';
      final otherEmail = 'native-share-other-$suffix@example.test';
      const password = 'native-sharing-password-123';
      expect(
        await c.authenticate(
          register: true,
          email: ownerEmail,
          name: 'Native owner',
          password: password,
          confirmation: password,
        ),
        true,
      );
      await idle(c);
      final ownerToken = c.token!;
      Future<dynamic> register(String email, String name) => api.call(
        'POST',
        '/auth/register',
        body: {
          'email': email,
          'name': name,
          'password': password,
          'confirmation': password,
        },
      );
      final recipient = await register(recipientEmail, 'Native recipient');
      await register(otherEmail, 'Native second viewer');
      final stranger = await register(
        'native-share-stranger-$suffix@example.test',
        'Native stranger',
      );
      final recipientId = recipient['user']['id'] as String;
      final noteId = c.uuid.v4();
      await c.save(noteId, 'Native sharing fixture', 'Original server content');
      await idle(c);
      expect(c.notes.single.revision, 1);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Native sharing fixture'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Native sharing fixture'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Chia sẻ ghi chú'));
      await until(
        tester,
        () => find.byKey(const Key('share-emails')).evaluate().isNotEmpty,
      );
      await type(
        tester,
        find.byKey(const Key('share-emails')),
        '$recipientEmail\n$otherEmail',
      );
      await tester.ensureVisible(find.byKey(const Key('share-add')));
      await tester.tap(find.byKey(const Key('share-add')));
      await until(
        tester,
        () => find.text('Native recipient').evaluate().isNotEmpty,
      );
      final catalog = await api.call(
        'GET',
        '/notes/$noteId/shares',
        token: ownerToken,
      );
      expect(catalog['recipients'], hasLength(2));
      expect(
        (catalog['recipients'] as List).every((r) => r['role'] == 'viewer'),
        true,
      );
      final shareTime = (catalog['recipients'] as List).firstWhere(
        (r) => r['user_id'] == recipientId,
      )['shared_at'];
      final roleControl = find.byKey(ValueKey('share-role-$recipientId'));
      await tester.ensureVisible(roleControl);
      await tester.tap(roleControl);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Có thể chỉnh sửa').last);
      await until(tester, () => !c.syncing && c.notes.single.sharedCount == 2);
      final updated = await api.call(
        'GET',
        '/notes/$noteId/shares',
        token: ownerToken,
      );
      expect(
        (updated['recipients'] as List).firstWhere(
          (r) => r['user_id'] == recipientId,
        )['role'],
        'editor',
      );
      expect(
        (updated['recipients'] as List).firstWhere(
          (r) => r['user_id'] == recipientId,
        )['shared_at'],
        shareTime,
      );
      expect(
        (await api.call(
          'GET',
          '/notes/$noteId',
          token: ownerToken,
        ))['revision'],
        1,
      );
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(c.notes.single.sharedCount, 2);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      c = make(api);
      expect(
        await c.authenticate(
          register: false,
          email: recipientEmail,
          password: password,
        ),
        true,
      );
      await idle(c);
      c.ready = true;
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Được chia sẻ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Từ Native owner'), findsOneWidget);
      expect(c.notes.single.sharedAt, shareTime);
      await expectLater(
        api.call('GET', '/notes/$noteId/shares', token: c.token),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
      await expectLater(
        api.call('GET', '/notes/$noteId', token: stranger['token']),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
      await tester.tap(find.text('Native sharing fixture'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
            .readOnly,
        false,
      );
      await type(
        tester,
        find.byKey(const Key('note-content')),
        'Saved by native editor',
      );
      await until(
        tester,
        () =>
            !c.syncing &&
            c.pending.isEmpty &&
            c.notes.single.content == 'Saved by native editor',
      );
      await idle(c);
      expect(
        (await api.call('GET', '/notes/$noteId', token: ownerToken))['content'],
        'Saved by native editor',
      );
      Future<void> change(String action, [String? role]) async {
        final current = await api.call(
          'GET',
          '/notes/$noteId/shares',
          token: ownerToken,
        );
        await api.call(
          'POST',
          '/notes/$noteId/shares/sync',
          token: ownerToken,
          body: {
            'op_id': c.uuid.v4(),
            'base_revision': current['revision'],
            'action': action,
            'user_id': recipientId,
            'role': ?role,
          },
        );
      }

      await type(tester, find.byKey(const Key('note-title')), '');
      await type(
        tester,
        find.byKey(const Key('note-content')),
        'Draft before role downgrade',
      );
      await change('role', 'viewer');
      await c.synchronize();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
            .readOnly,
        true,
      );
      expect(
        tester
            .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
            .document
            .text,
        'Saved by native editor',
      );
      expect(
        c.recoveries.values.single['content'],
        'Draft before role downgrade',
      );
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      await change('role', 'editor');
      await c.synchronize();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Native sharing fixture'));
      await tester.pumpAndSettle();
      await type(tester, find.byKey(const Key('note-title')), '');
      await type(
        tester,
        find.byKey(const Key('note-content')),
        'Draft before native revoke',
      );
      await change('revoke');
      await c.synchronize();
      await tester.pumpAndSettle();
      expect(
        find.text('Bạn không còn quyền truy cập ghi chú này.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      expect(c.pending, isEmpty);
      expect(c.recoveries.values.last['content'], 'Draft before native revoke');
      expect(
        (await api.call(
          'GET',
          '/notes/$noteId',
          token: ownerToken,
        ))['revision'],
        2,
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
      db = await openLocalDatabase();
      c = make(Api('http://127.0.0.1:65530'));
      await c.initialize();
      await idle(c);
      expect(c.online, false);
      expect(c.notes, isEmpty);
      expect(c.accessUnavailable, contains(noteId));
      expect(c.recoveries, hasLength(2));
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phục hồi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bản chỉnh sửa đã giữ').last);
      await tester.pumpAndSettle();
      expect(find.byType(EditorScreen), findsOneWidget);
      expect(
        tester
            .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
            .document
            .text,
        'Draft before native revoke',
      );
      final copy = tester.widget<EditorScreen>(find.byType(EditorScreen)).id;
      expect(copy, isNot(noteId));
      expect(c.drafts[copy]['content'], 'Draft before native revoke');
      expect(c.pending, isEmpty);
      expect(tester.takeException(), isNull);
      debugPrint(
        'QA_NATIVE_SHARING_PASS: atomic batch, editor/viewer/revoke, owner/time, encrypted DB reopen offline, new-ID recovery. No mocks.',
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
    },
  );
}
