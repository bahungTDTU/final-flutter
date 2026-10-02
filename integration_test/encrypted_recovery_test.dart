import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/data/open_database.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';

Future<void> waitSync(AppController c) async {
  for (var i = 0; i < 100 && c.syncing; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(c.syncing, false);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Real second-session lock preserves encrypted draft across native reopen',
    (tester) async {
      var database = await openLocalDatabase();
      var raw = SembastLocalStore(database);
      var local = EncryptedAccountStore(raw, const DeviceRecoveryKeys());
      final api = Api(
        const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://127.0.0.1:8000',
        ),
      );
      var c = AppController(api, local);
      await c.initialize();
      await waitSync(c);
      await c.logout();
      final email =
          'vault-${DateTime.now().microsecondsSinceEpoch}@example.com';
      const password = 'integration-vault-password-123';
      expect(
        await c.authenticate(
          register: true,
          email: email,
          name: 'Vault test',
          password: password,
          confirmation: password,
        ),
        true,
      );
      await waitSync(c);
      final account = c.accountKey;
      final id = c.uuid.v4();
      await c.save(id, 'Server original', 'Server acknowledged text');
      await waitSync(c);
      expect(c.pending, isEmpty);
      await c.draft(id, '', 'My unfinished encrypted edit');
      final second = await api.call(
        'POST',
        '/auth/login',
        body: {'email': email, 'password': password},
      );
      await api.call(
        'POST',
        '/notes/$id/protection',
        token: second['token'],
        body: {
          'password': 'note-protection-123',
          'confirmation': 'note-protection-123',
        },
      );
      await c.synchronize();
      expect(c.notes.single.locked, true);
      expect(c.notes.single.role, 'owner');
      expect(
        c.recoveries.values.single['content'],
        'My unfinished encrypted edit',
      );
      expect(c.pending, isEmpty);
      expect(c.drafts, isEmpty);
      final envelope = (await raw.read(account))!;
      expect(envelope['vault_version'], 1);
      expect(
        jsonEncode(envelope),
        isNot(contains('My unfinished encrypted edit')),
      );
      await expectLater(
        api.call('GET', '/notes/$id', token: c.token),
        throwsA(isA<ApiException>().having((e) => e.status, 'locked', 423)),
      );
      c.dispose();
      await database.close();
      database = await openLocalDatabase();
      raw = SembastLocalStore(database);
      local = EncryptedAccountStore(raw, const DeviceRecoveryKeys());
      c = AppController(api, local);
      await c.initialize();
      await waitSync(c);
      expect(c.recoveries, hasLength(1));
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('open-recovery')));
      await tester.tap(find.byKey(const Key('open-recovery')));
      await tester.pumpAndSettle();
      expect(find.text('My unfinished encrypted edit'), findsNothing);
      await tester.tap(find.text('Bản chỉnh sửa đã giữ'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-content')))
            .controller!
            .text,
        'My unfinished encrypted edit',
      );
      await tester.enterText(
        find.byKey(const Key('note-title')),
        'Recovered copy',
      );
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      await waitSync(c);
      await c.synchronize();
      final recovery = c.recoveries.values.single as Map;
      final copyId = recovery['draft_id'] as String;
      expect(copyId, isNot(id));
      final copy = await api.call('GET', '/notes/$copyId', token: c.token);
      expect(copy['title'], 'Recovered copy');
      expect(copy['content'], 'My unfinished encrypted edit');
      await expectLater(
        api.call('GET', '/notes/$id', token: c.token),
        throwsA(isA<ApiException>().having((e) => e.status, 'locked', 423)),
      );
      final persisted = (await raw.read(account))!;
      expect(
        jsonEncode(persisted),
        isNot(contains('My unfinished encrypted edit')),
      );
      // A valid edit queued with a genuinely unreachable backend must also be
      // archived when /sync returns 423, not just an incomplete draft via GET.
      final queuedSource = c.uuid.v4();
      await c.save(queuedSource, 'Second source', 'Initial second content');
      await waitSync(c);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      final offline = AppController(Api('http://127.0.0.1:65530'), local);
      await offline.initialize();
      await waitSync(offline);
      await offline.save(
        queuedSource,
        'Queued title',
        'Queued encrypted change',
      );
      await waitSync(offline);
      expect(offline.pending, hasLength(1));
      await api.call(
        'POST',
        '/notes/$queuedSource/protection',
        token: second['token'],
        body: {
          'password': 'second-protection-123',
          'confirmation': 'second-protection-123',
        },
      );
      offline.dispose();
      await database.close();
      database = await openLocalDatabase();
      raw = SembastLocalStore(database);
      c = AppController(
        api,
        EncryptedAccountStore(raw, const DeviceRecoveryKeys()),
      );
      await c.initialize();
      await waitSync(c);
      expect(c.pending, isEmpty);
      expect(c.recoveries, hasLength(2));
      final queuedRecovery = c.recoveries.values.cast<Map>().singleWhere(
        (r) => r['source_id'] == queuedSource,
      );
      expect(queuedRecovery['content'], 'Queued encrypted change');
      expect(c.notes.singleWhere((n) => n.id == queuedSource).locked, true);
      await expectLater(
        api.call('GET', '/notes/$queuedSource', token: c.token),
        throwsA(isA<ApiException>().having((e) => e.status, 'locked', 423)),
      );
      expect(
        jsonEncode(await raw.read(account)),
        isNot(contains('Queued encrypted change')),
      );
      c.dispose();
      await database.close();
    },
  );
}
