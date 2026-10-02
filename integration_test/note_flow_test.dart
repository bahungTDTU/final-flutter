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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Real backend registration, auto-save and persistent reopen', (
    tester,
  ) async {
    final database = await openLocalDatabase();
    final store = EncryptedAccountStore(
      SembastLocalStore(database),
      const DeviceRecoveryKeys(),
    );
    final api = Api(
      const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://127.0.0.1:8000',
      ),
    );
    final c = AppController(api, store);
    await c.initialize();
    await c.logout();
    final email =
        'integration-${DateTime.now().microsecondsSinceEpoch}@example.com';
    expect(
      await c.authenticate(
        register: true,
        email: email,
        name: 'Integration',
        password: 'integration-password-123',
        confirmation: 'integration-password-123',
      ),
      true,
    );
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-note')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-title')),
      'Persistent note',
    );
    await tester.enterText(
      find.byKey(const Key('note-content')),
      'Real backend content',
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    // Poll bounded real requests until the asynchronously triggered sync finishes.
    for (var i = 0; i < 15 && c.pending.isNotEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await c.synchronize();
    }
    expect(c.pending, isEmpty);
    expect(c.notes.single.content, 'Real backend content');
    final remote = await api.call(
      'GET',
      '/notes/${c.notes.single.id}',
      token: c.token,
    );
    expect(remote['content'], 'Real backend content');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await database.close();
    final reopened = await openLocalDatabase();
    final newController = AppController(
      api,
      EncryptedAccountStore(
        SembastLocalStore(reopened),
        const DeviceRecoveryKeys(),
      ),
    );
    await newController.initialize();
    expect(newController.notes.single.content, 'Real backend content');
    newController.dispose();
    await reopened.close();

    // Real connection failure, not a mocked transport. Persist an edit AND a create in the native store.
    final offlineDatabase = await openLocalDatabase();
    final offline = AppController(
      Api('http://127.0.0.1:65530'),
      EncryptedAccountStore(
        SembastLocalStore(offlineDatabase),
        const DeviceRecoveryKeys(),
      ),
    );
    await offline.initialize();
    await offline.setPreferences({
      'dark': true,
      'grid': false,
      'font_size': 22.0,
    });
    expect(offline.pendingPreferences.length, 1);
    final existing = offline.notes.single;
    await offline.save(
      existing.id,
      existing.title,
      'Edited with backend unreachable',
    );
    await offline.save(
      'offline-${DateTime.now().microsecondsSinceEpoch}',
      'Offline creation',
      'Created offline',
    );
    expect(offline.pending.length, 2);
    for (var i = 0; i < 30 && offline.syncing; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    expect(offline.online, false);
    offline.dispose();
    await offlineDatabase.close();

    final reconnectDatabase = await openLocalDatabase();
    final reconnect = AppController(
      api,
      EncryptedAccountStore(
        SembastLocalStore(reconnectDatabase),
        const DeviceRecoveryKeys(),
      ),
    );
    await reconnect.initialize();
    expect(reconnect.dark, true);
    expect(reconnect.grid, false);
    expect(reconnect.fontSize, 22);
    expect(reconnect.pendingPreferences.length, 1);
    expect(reconnect.pending.length, 2);
    for (
      var i = 0;
      i < 40 && (reconnect.syncing || reconnect.pending.isNotEmpty);
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!reconnect.syncing) await reconnect.synchronize();
    }
    expect(reconnect.pending, isEmpty);
    expect(reconnect.pendingPreferences, isEmpty);
    final savedProfile = await api.call('GET', '/me', token: reconnect.token);
    expect(savedProfile['preferences'], {
      'dark': true,
      'grid': false,
      'font_size': 22.0,
    });
    // Another authenticated session updates one field; synchronization preserves the other fields.
    final second = await api.call(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': 'integration-password-123'},
    );
    await api.call(
      'POST',
      '/me/preferences/sync',
      token: second['token'] as String,
      body: {
        'op_id': 'second-${DateTime.now().microsecondsSinceEpoch}',
        'font_size': 18.0,
      },
    );
    await reconnect.synchronize();
    expect(reconnect.fontSize, 18);
    expect(reconnect.dark, true);
    expect(reconnect.grid, false);
    final serverNotes =
        await api.call('GET', '/notes', token: reconnect.token) as List;
    expect(serverNotes.length, 2);
    expect(
      serverNotes.map((n) => n['content']),
      containsAll(['Edited with backend unreachable', 'Created offline']),
    );
    await reconnect.logout();
    reconnect.dispose();
    await reconnectDatabase.close();
  });
}
