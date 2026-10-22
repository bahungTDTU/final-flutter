import '../test_driver/editor_input.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/data/open_database.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/rich_note_field.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Owner peer delete preserves native encrypted draft, new UUID and reopen',
    (tester) async {
      final api = Api(
        const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://127.0.0.1:8000',
        ),
      );
      var db = await openLocalDatabase();
      AppController make() => AppController(
        api,
        EncryptedAccountStore(
          SembastLocalStore(db),
          const DeviceRecoveryKeys(),
        ),
      );
      var c = make();
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      Future<void> until(bool Function() ready) async {
        for (var i = 0; i < 120 && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(ready(), true);
        await tester.pumpAndSettle();
      }

      await c.initialize();
      await until(() => !c.syncing);
      await c.logout();
      final email =
          'owner-delete-${DateTime.now().microsecondsSinceEpoch}@example.test';
      const password = 'Owner-delete-local-2026!';
      expect(
        await c.authenticate(
          register: true,
          email: email,
          name: 'Recovery QA',
          password: password,
          confirmation: password,
        ),
        true,
      );
      await until(() => !c.syncing);
      final id = c.uuid.v4();
      await api.call(
        'POST',
        '/sync',
        token: c.token,
        body: {
          'op_id': c.uuid.v4(),
          'note_id': id,
          'kind': 'upsert',
          'base_revision': 0,
          'title': 'Owner source note',
          'content': 'Accepted server content',
        },
      );
      await c.synchronize();
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(ValueKey('card-$id')));
      await tester.tap(find.byKey(ValueKey('card-$id')));
      await tester.pumpAndSettle();
      await enterNoteField(tester, find.byKey(const Key('note-title')), '');
      const localText = 'Ban nhap native can duoc phuc hoi sau remote delete.';
      await enterNoteField(
        tester,
        find.byKey(const Key('note-content')),
        localText,
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 900));
      await until(() => c.drafts[id]?['content'] == localText);
      expect(c.pending, isEmpty);
      final accepted = await api.call('GET', '/notes/$id', token: c.token);
      expect(accepted['revision'], 1);
      expect(accepted['content'], 'Accepted server content');
      final peer = await api.call(
        'POST',
        '/auth/login',
        body: {'email': email, 'password': password},
      );
      await api.call(
        'POST',
        '/sync',
        token: peer['token'] as String,
        body: {
          'op_id': c.uuid.v4(),
          'note_id': id,
          'kind': 'delete',
          'base_revision': 1,
        },
      );
      await c.synchronize();
      await until(
        () => c.recoveries.length == 1 && c.accessUnavailable.contains(id),
      );
      expect(c.drafts.containsKey(id), false);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      final recovery = find.byKey(const Key('open-recovery'));
      await tester.ensureVisible(recovery);
      await tester.tap(recovery);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bản chỉnh sửa đã giữ'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
            .document
            .text,
        localText,
      );
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('native-owner-deleted-restored-draft');
      await enterNoteField(
        tester,
        find.byKey(const Key('note-title')),
        'Native recovered note',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 900));
      await until(
        () =>
            !c.syncing &&
            c.pending.isEmpty &&
            c.notes.any((n) => n.title == 'Native recovered note'),
      );
      final restored = c.notes.single;
      expect(restored.id, isNot(id));
      final remote = await api.call(
        'GET',
        '/notes/${restored.id}',
        token: peer['token'] as String,
      );
      expect(remote['content'], localText);
      await expectLater(
        api.call('GET', '/notes/$id', token: peer['token'] as String),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
      db = await openLocalDatabase();
      c = make();
      await c.initialize();
      await until(() => !c.syncing);
      expect(c.notes.single.id, restored.id);
      expect(c.notes.single.content, localText);
      expect(c.accessUnavailable, contains(id));
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('native-owner-deleted-reopened');
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['owner_delete_recovery'] = {
        'passed': true,
        'new_uuid': restored.id != id,
        'server_copy_matches': true,
        'original_404': true,
        'encrypted_store_reopened': true,
        'input': 'TextInputClient injection, not IME',
      };
      await tester.pumpWidget(const SizedBox());
    },
  );
}
