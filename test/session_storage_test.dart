import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_io.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';

import 'encrypted_recovery_test.dart' show TestKeys;
import 'support.dart' show MemoryStore;

const keyName = 'notetogether.vault.v1:session:device';
const session = {
  'user': {
    'id': 'A',
    'name': 'Private profile',
    'email': 'private@example.test',
  },
  'token': 'private-fixture-session',
};
const cached = {
  'notes': [],
  'drafts': {
    'n': {'title': 'Unfinished', 'content': 'Keep my edit'},
  },
  'pending': [],
};

class FaultSessionStore extends SembastLocalStore {
  FaultSessionStore(super.database);
  bool failWrite = false, failCompact = false;
  Completer<void>? gate;
  final entered = Completer<void>();
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key == 'session' && gate != null) {
      if (!entered.isCompleted) entered.complete();
      await gate!.future;
    }
    if (key == 'session' && failWrite) {
      await database.transaction((txn) async {
        await store.record(key).put(txn, value);
        throw StateError('Injected session transaction failure');
      });
    } else {
      await super.write(key, value);
    }
  }

  @override
  Future<void> compact() async {
    if (failCompact) throw StateError('Injected compaction failure');
    await super.compact();
  }
}

class UnconfirmedKeys extends TestKeys {
  @override
  Future<void> write(String key, String value) async {}
}

class FailedRemovalMemory extends MemoryStore {
  bool fail = true;
  @override
  Future<void> remove(String key) async {
    if (fail && key == 'session') throw StateError('Injected removal failure');
    await super.remove(key);
  }
}

Api offline() => Api(
  'http://test',
  client: MockClient((_) async => throw http.ClientException('offline')),
);

void main() {
  late Directory directory;
  late String filename;
  late Database db;
  late FaultSessionStore raw;
  late TestKeys keys;
  late EncryptedAccountStore local;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nt-session-');
    filename = '${directory.path}/session.db';
    db = await databaseFactoryIo.openDatabase(filename);
    raw = FaultSessionStore(db);
    keys = TestKeys();
    local = EncryptedAccountStore(raw, keys);
  });
  tearDown(() async {
    await db.close();
    await File(filename).delete();
    await directory.delete();
  });

  test('Legacy migration compacts token/profile history before offline file reopen and preserves drafts', () async {
    await local.write('account:A', cached);
    final root = await raw.read('account:A');
    await raw.write('session', {...session, 'token': 'older-plaintext-token'});
    await raw.write('session', session);
    expect(await local.read('session'), session);
    expect((await raw.read('session'))!['vault_version'], 1);
    expect(await raw.read('account:A'), root);
    final disk = await File(filename).readAsString();
    for (final text in [
      'older-plaintext-token',
      'private-fixture-session',
      'Private profile',
      'private@example.test',
    ]) {
      expect(disk, isNot(contains(text)));
    }
    await db.close();
    db = await databaseFactoryIo.openDatabase(filename);
    local = EncryptedAccountStore(FaultSessionStore(db), keys);
    final c = AppController(offline(), local)..setForeground(false);
    await c.initialize();
    expect(c.token, session['token']);
    expect(c.drafts['n']['content'], 'Keep my edit');
    c.dispose();
  });

  test('Fresh session nonces and independent key/AAD authenticate token and complete profile', () async {
    final records = MemoryStore();
    final vault = EncryptedAccountStore(records, keys);
    await vault.write('account:A', cached);
    final account = (await records.read('account:A'))!;
    await vault.write('session', session);
    final first = (await records.read('session'))!;
    await vault.write('session', session);
    final second = (await records.read('session'))!;
    expect(first['nonce'], isNot(second['nonce']));
    expect(jsonEncode(second), isNot(contains('private-fixture-session')));
    expect(
      keys.values[keyName],
      isNot(
        keys.values['notetogether.vault.v1:account:A:${account['key_id']}'],
      ),
    );
    expect(await vault.read('session'), session);
    await vault.rotateAccount('account:A');
    expect(await records.read('session'), second);
    expect(await vault.read('session'), session);
    // Even matching key bytes and IDs do not bypass the record's AAD namespace.
    keys.values['notetogether.vault.v1:account:B:device'] =
        keys.values[keyName]!;
    await records.write('account:B', second);
    await expectLater(vault.read('account:B'), throwsA(isA<VaultException>()));
  });

  test('Key publication/readback and failed transaction leave legacy credentials untouched', () async {
    await raw.write('session', session);
    keys.fail = true;
    await expectLater(local.read('session'), throwsStateError);
    expect(await raw.read('session'), session);
    await expectLater(
      EncryptedAccountStore(raw, UnconfirmedKeys()).read('session'),
      throwsA(isA<VaultException>()),
    );
    expect(await raw.read('session'), session);
    keys.fail = false;
    raw.failWrite = true;
    await expectLater(local.read('session'), throwsStateError);
    expect(await raw.read('session'), session);
    raw.failWrite = false;
    expect(await local.read('session'), session);
  });

  test('Interrupted migration retries compaction before releasing a token or calling any API', () async {
    await local.write('account:A', cached);
    await raw.write('session', session);
    raw.failCompact = true;
    var requests = 0;
    final api = Api(
      'http://test',
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    final c = AppController(api, local)..setForeground(false);
    await c.initialize();
    expect(c.user, isNull);
    expect(c.token, isNull);
    expect(requests, 0);
    expect((await raw.read('session'))!['needs_compaction'], true);
    await expectLater(local.read('session'), throwsStateError);
    c.dispose();
    raw.failCompact = false;
    expect(await local.read('session'), session);
    expect((await raw.read('session'))!.containsKey('needs_compaction'), false);
    expect(
      await File(filename).readAsString(),
      isNot(contains('private-fixture-session')),
    );
  });

  test('Missing or tampered session key/envelope fails closed and rejected login cannot enter Home or overwrite it', () async {
    await local.write('account:A', cached);
    await local.write('session', session);
    final envelope = (await raw.read('session'))!;
    keys.values.remove(keyName);
    var revoked = 0, noteRequests = 0;
    final api = Api(
      'http://test',
      client: MockClient((request) async {
        if (request.url.path == '/auth/login') {
          return http.Response(
            jsonEncode({...session, 'token': 'new-rejected-token'}),
            200,
          );
        }
        if (request.url.path == '/auth/logout') {
          revoked++;
          expect(request.headers['Authorization'], 'Bearer new-rejected-token');
          return http.Response('{}', 200);
        }
        noteRequests++;
        return http.Response('{}', 200);
      }),
    );
    final c = AppController(api, local)..setForeground(false);
    await c.initialize();
    expect(c.token, isNull);
    expect(
      await c.authenticate(
        register: false,
        email: 'fixture@example.test',
        password: 'fixture',
      ),
      false,
    );
    expect(c.user, isNull);
    expect(c.token, isNull);
    expect(revoked, 1);
    expect(noteRequests, 0);
    expect(await raw.read('session'), envelope);
    expect(keys.values.containsKey(keyName), false);
    c.dispose();
    final tamperKeys = TestKeys();
    final records = MemoryStore(),
        vault = EncryptedAccountStore(records, tamperKeys);
    await vault.write('session', session);
    final original = (await records.read('session'))!;
    final bytes = base64Decode(original['ciphertext'] as String)..[0] ^= 1;
    final damaged = {...original, 'ciphertext': base64Encode(bytes)};
    await records.write('session', damaged);
    await expectLater(vault.read('session'), throwsA(isA<VaultException>()));
    await expectLater(
      vault.write('session', session),
      throwsA(isA<VaultException>()),
    );
    expect(await records.read('session'), damaged);
  });

  test('Logout tombstone survives interrupted compaction, still revokes server, never resurrects session on reopen', () async {
    await local.write('account:A', cached);
    await local.write('session', session);
    var revoked = 0;
    final api = Api(
      'http://test',
      client: MockClient((_) async {
        revoked++;
        return http.Response('{}', 200);
      }),
    );
    final c = AppController(api, local)..setForeground(false);
    await c.initialize();
    raw.failCompact = true;
    await c.logout();
    expect(revoked, 1);
    expect(c.sessionRemovalFailed, true);
    expect((await raw.read('session'))!['session_removed'], true);
    c.dispose();
    await db.close();
    db = await databaseFactoryIo.openDatabase(filename);
    raw = FaultSessionStore(db);
    local = EncryptedAccountStore(raw, keys);
    expect(await local.read('session'), isNull);
    expect(await raw.read('session'), isNull);
    expect(
      (await local.read('account:A'))!['drafts']['n']['content'],
      'Keep my edit',
    );
    expect(
      await File(filename).readAsString(),
      isNot(contains('private-fixture-session')),
    );
  });

  test('Blocked encrypted session refresh then logout/login B cannot send A queue or revive A session', () async {
    await local.write('account:A', {
      ...cached,
      'pending_preferences': [
        {'op_id': 'A-pref', 'dark': true},
      ],
    });
    await local.write('session', session);
    var oldMutations = 0;
    final api = Api(
      'http://test',
      client: MockClient((r) async {
        final b = r.headers['Authorization'] == 'Bearer B-token';
        if (r.url.path == '/auth/login') {
          return http.Response('{"user":{"id":"B"},"token":"B-token"}', 200);
        }
        if (r.url.path == '/me') {
          return http.Response(jsonEncode({'id': b ? 'B' : 'A'}), 200);
        }
        if (r.url.path == '/me/preferences/sync') oldMutations++;
        if (r.url.path == '/notes' || r.url.path == '/labels') {
          return http.Response('[]', 200);
        }
        return http.Response('{}', 200);
      }),
    );
    final c = AppController(api, local)..setForeground(false);
    await c.initialize();
    raw.gate = Completer<void>();
    final refresh = c.synchronize();
    await raw.entered.future;
    final logout = c.logout();
    final login = c.authenticate(
      register: false,
      email: 'B@example.test',
      password: 'fixture',
    );
    raw.gate!.complete();
    await Future.wait([refresh, logout, login]);
    while (c.syncing) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(oldMutations, 0);
    expect((await local.read('session'))!['user']['id'], 'B');
    expect((await local.read('session'))!['token'], 'B-token');
    expect(
      (await local.read('account:A'))!['pending_preferences'],
      hasLength(1),
    );
    expect(c.drafts, isEmpty);
    c.dispose();
  });

  testWidgets(
    'Failed local logout shows safe notice and retry removes only session, preserving account draft',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final memory = FailedRemovalMemory();
      await memory.write('account:A', cached);
      await memory.write('session', session);
      final c = AppController(offline(), memory)..setForeground(false);
      await c.initialize();
      await c.logout();
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Chưa xóa được phiên đăng nhập'),
        findsOneWidget,
      );
      expect(find.textContaining('private-fixture-session'), findsNothing);
      memory.fail = false;
      final retry = find.text('Thử xóa phiên trên thiết bị');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(await memory.read('session'), isNull);
      expect(c.sessionRemovalFailed, false);
      expect(c.error, isNull);
      expect(
        (await memory.read('account:A'))!['drafts']['n']['content'],
        'Keep my edit',
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
