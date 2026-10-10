import '../test_driver/editor_input.dart';

import 'package:note_together/ui/rich_note_field.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart' hide Finder;
import 'package:uuid/uuid.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native encrypted draft projection survives offline file reopen then folds/syncs same ID',
    (tester) async {
      const url = String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://127.0.0.1:8017',
      );
      const uuid = Uuid();
      final api = Api(url), unreachable = Api('http://127.0.0.1:65530');
      final filename = path.join(
        (await getApplicationSupportDirectory()).path,
        'qa-perf-${uuid.v4()}.db',
      );
      var db = await databaseFactoryIo.openDatabase(filename);
      var raw = SembastLocalStore(db);
      var local = EncryptedAccountStore(raw, const DeviceRecoveryKeys());
      var c = AppController(api, local)..setForeground(false);
      await c.initialize();
      expect(
        await c.authenticate(
          register: true,
          email: 'native-perf-${uuid.v4()}@example.test',
          password: 'Native-perf-2026!',
          confirmation: 'Native-perf-2026!',
          name: 'Native performance',
        ),
        true,
      );
      Future<void> until(bool Function() ready) async {
        for (var i = 0; i < 120 && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(ready(), true);
        await tester.pumpAndSettle();
      }

      await until(() => !c.syncing);
      final id = uuid.v4();
      await api.call(
        'POST',
        '/sync',
        token: c.token,
        body: {
          'op_id': uuid.v4(),
          'note_id': id,
          'base_revision': 0,
          'kind': 'upsert',
          'title': 'Native performance note',
          'content': 'Original server content',
        },
      );
      await c.synchronize();
      c.dispose();
      await db.close();
      db = await databaseFactoryIo.openDatabase(filename);
      raw = SembastLocalStore(db);
      local = EncryptedAccountStore(raw, const DeviceRecoveryKeys());
      c = AppController(unreachable, local)..setForeground(false);
      await c.initialize();
      await c.synchronize();
      expect(c.online, false);
      final account = c.accountKey, before = await raw.read(account);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      final card = find.byKey(ValueKey('card-$id'));
      await tester.scrollUntilVisible(
        card,
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();
      Future<void> type(Finder field, String value) async {
        tester.binding.focusedEditable = null;
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await enterNoteField(tester, field, value);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }

      // Invalid title deliberately keeps the latest input in drafts, not /sync.
      await type(find.byKey(const Key('note-title')), ' ');
      await type(
        find.byKey(const Key('note-content')),
        'Native overlay survives reopen',
      );
      await until(
        () => c.drafts[id]?['content'] == 'Native overlay survives reopen',
      );
      await c.draft(
        id,
        ' ',
        'Native overlay survives reopen',
      ); // Await the real durable boundary.
      expect(await raw.read(account), before);
      expect(await raw.read('drafts:$account'), isNotNull);
      expect(
        jsonEncode(await raw.read('drafts:$account')),
        isNot(contains('Native overlay survives reopen')),
      );
      bool converted = false;
      Future<void> picture(String name) async {
        if (!converted) {
          await binding.convertFlutterSurfaceToImage();
          converted = true;
        }
        await tester.pump();
        await binding.takeScreenshot(name);
      }

      await picture('native-perf-offline-draft');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
      db = await databaseFactoryIo.openDatabase(filename);
      raw = SembastLocalStore(db);
      local = EncryptedAccountStore(raw, const DeviceRecoveryKeys());
      c = AppController(unreachable, local)..setForeground(false);
      await c.initialize();
      expect(c.drafts[id]['content'], 'Native overlay survives reopen');
      expect(c.notes.single.revision, 1);
      c.dispose();
      await db.close();
      db = await databaseFactoryIo.openDatabase(filename);
      raw = SembastLocalStore(db);
      local = EncryptedAccountStore(raw, const DeviceRecoveryKeys());
      c = AppController(api, local)..setForeground(false);
      await c.initialize();
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        card,
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
            .document
            .text,
        'Native overlay survives reopen',
      );
      await type(find.byKey(const Key('note-title')), 'Native optimized draft');
      await until(
        () =>
            c.notes.single.title == 'Native optimized draft' &&
            c.pending.isEmpty &&
            !c.syncing,
      );
      final remote = await api.call('GET', '/notes/$id', token: c.token);
      expect(remote['revision'], 2);
      expect(remote['content'], 'Native overlay survives reopen');
      expect(
        (await api.call('GET', '/notes', token: c.token) as List),
        hasLength(1),
      );
      expect(await raw.read('drafts:$account'), isNull);
      await picture('native-perf-synced');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      api.client.close();
      unreachable.client.close();
      await db.close();
      await databaseFactoryIo.deleteDatabase(filename);
    },
  );
}
