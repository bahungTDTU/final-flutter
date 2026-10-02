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
import 'package:note_together/ui/home.dart';

Future<void> idle(AppController c) async {
  for (var i = 0; i < 200 && c.syncing; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(c.syncing, false);
}

Future<void> until(
  WidgetTester tester,
  bool Function() condition, {
  int tries = 100,
}) async {
  for (var i = 0; i < tries && !condition(); i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(condition(), true);
  await tester.pumpAndSettle();
}

Future<void> text(WidgetTester tester, String value) async {
  tester.binding.focusedEditable = null;
  await tester.enterText(find.byType(TextFormField).last, value);
  expect(
    tester
        .widget<TextFormField>(find.byType(TextFormField).last)
        .controller!
        .text,
    value,
  );
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native OS avatar picker and durable label IDs sync across account sessions',
    (tester) async {
      var database = await openLocalDatabase();
      final api = Api(
        const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://127.0.0.1:8000',
        ),
      );
      AppController make(Api api) => AppController(
        api,
        EncryptedAccountStore(
          SembastLocalStore(database),
          const DeviceRecoveryKeys(),
        ),
      );
      var c = make(api);
      await c.initialize();
      await idle(c);
      await c.logout();
      final email =
          'native-avatar-${DateTime.now().microsecondsSinceEpoch}@example.test';
      const password = 'native-avatar-password-123';
      expect(
        await c.authenticate(
          register: true,
          email: email,
          name: 'Avatar label fixture',
          password: password,
          confirmation: password,
        ),
        true,
      );
      await idle(c);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hồ sơ và tùy chỉnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi ảnh đại diện'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('avatar-pick')));
      debugPrint(
        'QA_NATIVE_PICKER_READY: select notetogether-avatar.png in Android document picker.',
      );
      await until(
        tester,
        () => find.textContaining('Đã chọn:').evaluate().isNotEmpty,
        tries: 240,
      );
      expect(find.textContaining('notetogether-avatar.png'), findsOneWidget);
      await tester.tap(find.byKey(const Key('avatar-upload')));
      await until(
        tester,
        () => find.text('Server đã lưu ảnh đại diện.').evaluate().isNotEmpty,
      );
      expect(c.user!['has_avatar'], true);
      expect(c.avatarBytes, isNotNull);
      final canonical = c.avatarBytes!;
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(HomeScreen))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Quản lý nhãn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm nhãn'));
      await tester.pumpAndSettle();
      await text(tester, 'Nhãn native');
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await until(
        tester,
        () => c.labels.length == 1 && c.pendingLabels.isEmpty && !c.syncing,
      );
      final id = c.labels.single;
      Navigator.of(tester.element(find.byType(HomeScreen))).pop();
      await tester.pumpAndSettle();
      final noteId = c.uuid.v4();
      await c.save(
        noteId,
        'Native labeled note',
        'Original text',
        noteLabels: [id],
      );
      await idle(c);
      final peer = await api.call(
        'POST',
        '/auth/login',
        body: {'email': email, 'password': password},
      );
      final peerToken = peer['token'] as String;
      expect(peer['user']['has_avatar'], true);
      expect(
        (await api.binary(
          'GET',
          '/me/avatar?revision=1',
          token: peerToken,
        )).bodyBytes,
        canonical,
      );

      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await database.close();
      database = await openLocalDatabase();
      c = make(Api('http://127.0.0.1:65530'));
      await c.initialize();
      await idle(c);
      expect(c.avatarBytes, canonical);
      await c.renameLabel(id, 'Offline rename');
      await idle(c);
      await c.save(
        noteId,
        'Native labeled note',
        'Native offline text',
        baseRevision: 1,
      );
      await idle(c);
      await c.draft(
        noteId,
        'Native labeled note',
        'Typing continues after queued save',
      );
      expect(c.pendingLabels.single['label_id'], id);
      final pendingId = c.pendingLabels.single['op_id'];
      c.dispose();
      await database.close();
      database = await openLocalDatabase();
      c = make(Api('http://127.0.0.1:65530'));
      await c.initialize();
      await idle(c);
      expect(c.pendingLabels.single['op_id'], pendingId);
      expect(c.labelName(id), 'Offline rename');
      expect(c.avatarBytes, canonical);
      expect(c.drafts[noteId]['content'], 'Typing continues after queued save');
      c.dispose();
      await database.close();
      database = await openLocalDatabase();
      c = make(api);
      await c.initialize();
      await idle(c);
      expect(c.pendingLabels, isEmpty);
      expect(c.pending, isEmpty);
      expect(c.labels, [id]);
      final note = await api.call('GET', '/notes/$noteId', token: peerToken);
      expect(note['content'], 'Native offline text');
      expect(note['labels'], [id]);
      expect(note['label_names'][id], 'Offline rename');
      expect(note['revision'], 2);
      await api.call(
        'POST',
        '/labels/sync',
        token: peerToken,
        body: {
          'op_id': c.uuid.v4(),
          'label_id': id,
          'base_revision': 2,
          'kind': 'upsert',
          'name': 'Peer rename',
        },
      );
      await c.synchronize();
      expect(c.labelName(id), 'Peer rename');
      expect(c.notes.single.revision, 2);

      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Quản lý nhãn'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Xóa nhãn Peer rename'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa nhãn'));
      await until(
        tester,
        () => c.labels.isEmpty && c.pendingLabels.isEmpty && !c.syncing,
      );
      final after = await api.call('GET', '/notes/$noteId', token: peerToken);
      expect(after['content'], 'Native offline text');
      expect(after['labels'], isEmpty);
      expect(after['revision'], 2);
      Navigator.of(tester.element(find.byType(HomeScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hồ sơ và tùy chỉnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi ảnh đại diện'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('avatar-remove')));
      await until(
        tester,
        () => c.user!['has_avatar'] == false && c.avatarBytes == null,
      );
      expect(
        (await api.call('GET', '/me', token: peerToken))['has_avatar'],
        false,
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await database.close();
    },
  );
}
