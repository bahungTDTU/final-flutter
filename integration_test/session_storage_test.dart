import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:uuid/uuid.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native legacy session migration, offline reopen, server logout and manual re-login preserve encrypted drafts',
    (tester) async {
      const url = String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://127.0.0.1:8017',
      );
      final api = Api(url), unreachable = Api('http://127.0.0.1:65530');
      const uuid = Uuid();
      final email = 'native-session-${uuid.v4()}@example.test';
      const password = 'Native-session-2026!';
      final auth = await api.call(
        'POST',
        '/auth/register',
        body: {
          'email': email,
          'name': 'Native private session',
          'password': password,
          'confirmation': password,
        },
      );
      final authToken = auth['token'] as String;
      final filename = path.join(
        (await getApplicationSupportDirectory()).path,
        'qa-session-${uuid.v4()}.db',
      );
      var db = await databaseFactoryIo.openDatabase(filename);
      var raw = SembastLocalStore(db);
      var local = EncryptedAccountStore(raw, const DeviceRecoveryKeys());
      final key = 'account:${auth['user']['id']}';
      final note = uuid.v4();
      await local.write(key, {
        'notes': [],
        'pending': [],
        'drafts': {
          note: {
            'title': ' ',
            'content': 'Private draft retained after session logout',
          },
        },
      });
      // Deliberate legacy fixture, never printed or retained outside this QA DB.
      await raw.write('session', {'user': auth['user'], 'token': authToken});
      var c = AppController(unreachable, local)..setForeground(false);
      await c.initialize();
      expect(c.token == authToken, true);
      expect((await raw.read('session'))!['vault_version'], 1);
      expect((await raw.read('session'))!.containsKey('token'), false);
      expect((await raw.read('session'))!.containsKey('user'), false);
      expect(jsonEncode(await raw.read('session')).contains(authToken), false);
      expect((await File(filename).readAsString()).contains(authToken), false);
      await c.synchronize();
      expect(c.online, false);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      var converted = false;
      Future<void> picture(String name) async {
        if (!converted) {
          await binding.convertFlutterSurfaceToImage();
          converted = true;
        }
        await tester.pump();
        await binding.takeScreenshot(name);
      }

      await picture('native-session-migrated-offline');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await db.close();
      db = await databaseFactoryIo.openDatabase(filename);
      raw = SembastLocalStore(db);
      local = EncryptedAccountStore(raw, const DeviceRecoveryKeys());
      c = AppController(api, local)..setForeground(false);
      await c.initialize();
      expect(c.token == authToken, true);
      expect(
        c.drafts[note]['content'],
        'Private draft retained after session logout',
      );
      await c.synchronize();
      expect(c.online, true);
      await c.logout();
      expect(await raw.read('session'), isNull);
      expect(
        (await local.read(key))!['drafts'][note]['content'],
        'Private draft retained after session logout',
      );
      var revoked = false;
      try {
        await api.call('GET', '/me', token: authToken);
      } on ApiException catch (e) {
        revoked = e.status == 401;
      }
      expect(revoked, true);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await picture('native-session-logged-out');
      Future<void> type(Key key, String value) async {
        tester.binding.focusedEditable = null;
        await tester.ensureVisible(find.byKey(key));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(key), value);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }

      await type(const Key('auth-email'), email);
      await type(const Key('auth-password'), password);
      await tester.ensureVisible(find.byKey(const Key('auth-submit')));
      await tester.tap(find.byKey(const Key('auth-submit')));
      for (var i = 0; i < 120 && (c.user == null || c.busy || c.syncing); i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(c.user?['id'] == auth['user']['id'], true);
      expect(c.token != authToken, true);
      expect(
        c.drafts[note]['content'],
        'Private draft retained after session logout',
      );
      expect((await raw.read('session'))!['vault_version'], 1);
      expect(jsonEncode(await raw.read('session')).contains(c.token!), false);
      await picture('native-session-login-restored-draft');
      await c.logout();
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      api.client.close();
      unreachable.client.close();
      await db.close();
      await databaseFactoryIo.deleteDatabase(filename);
    },
  );
}
