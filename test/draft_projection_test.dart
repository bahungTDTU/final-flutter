import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sembast/sembast_io.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/app_controller.dart';

import 'encrypted_recovery_test.dart' show TestKeys;

class FailingBatchStore extends SembastLocalStore {
  FailingBatchStore(super.database);
  bool fail = false;
  Completer<void>? gate;
  final entered = Completer<void>();
  @override
  Future<void> writeBatch(
    Map<String, Map<String, dynamic>> values,
    Set<String> removed,
  ) async {
    if (gate != null) {
      if (!entered.isCompleted) entered.complete();
      await gate!.future;
    }
    if (!fail) return super.writeBatch(values, removed);
    await database.transaction((txn) async {
      for (final entry in values.entries) {
        await store.record(entry.key).put(txn, entry.value);
      }
      for (final key in removed) {
        await store.record(key).delete(txn);
      }
      throw StateError('Injected transaction failure after changes');
    });
  }
}

Api offlineApi() => Api(
  'http://test',
  client: MockClient((_) async => throw http.ClientException('offline')),
);
Future<void> idle(AppController c) async {
  while (c.syncing) {
    await Future<void>.delayed(Duration.zero);
  }
}

Map<String, dynamic> seed() => {
  'notes': [
    const Note(
      id: 'n',
      title: 'Saved',
      content: 'Server body',
      revision: 7,
      updatedAt: '2026-10-07',
    ).toListingJson(),
  ],
  'drafts': {},
  'pending': [],
  'protected_vaults': {
    'p': {'ciphertext': 'existing-password-envelope', 'dirty': true},
  },
};

void main() {
  late Directory folder;
  late Database db;
  late FailingBatchStore raw;
  late TestKeys keys;
  late EncryptedAccountStore local;
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('nt-draft-projection-');
    db = await databaseFactoryIo.openDatabase('${folder.path}/store.db');
    raw = FailingBatchStore(db);
    keys = TestKeys();
    local = EncryptedAccountStore(raw, keys);
  });
  tearDown(() async {
    await db.close();
    await File('${folder.path}/store.db').delete();
    await folder.delete();
  });

  test('Typing changes only encrypted draft record; file reopen retains newest text and original base/vault', () async {
    await local.write('account:A', seed());
    await local.write('session', {
      'user': {'id': 'A'},
      'token': 'fixture-A',
    });
    final c = AppController(offlineApi(), local)..setForeground(false);
    await c.initialize();
    final before = await raw.read('account:A');
    await Future.wait(
      List.generate(20, (i) => c.draft('n', 'Saved', 'Newest-$i')),
    );
    expect(await raw.read('account:A'), before);
    final projection = await raw.read('drafts:account:A');
    expect(projection!['vault_version'], 1);
    expect(jsonEncode(projection), isNot(contains('Newest')));
    expect(
      await File('${folder.path}/store.db').readAsString(),
      isNot(contains('Newest-19')),
    );
    c.dispose();
    await db.close();
    db = await databaseFactoryIo.openDatabase('${folder.path}/store.db');
    final restored = await EncryptedAccountStore(
      SembastLocalStore(db),
      keys,
    ).read('account:A');
    expect(restored!['drafts']['n']['content'], 'Newest-19');
    expect(restored['notes'][0]['revision'], 7);
    expect(
      restored['protected_vaults']['p']['ciphertext'],
      'existing-password-envelope',
    );
  });

  test('A failed root fold rolls back both writes and deletes; retry folds latest draft once', () async {
    await local.write('account:A', seed());
    await local.writeDrafts('account:A', {
      'n': {'title': 'Saved', 'content': 'Durable latest'},
    });
    final base = await raw.read('account:A'),
        projection = await raw.read('drafts:account:A');
    final folded = (await local.read('account:A'))!;
    raw.fail = true;
    await expectLater(local.write('account:A', folded), throwsStateError);
    expect(await raw.read('account:A'), base);
    expect(await raw.read('drafts:account:A'), projection);
    expect(
      (await local.read('account:A'))!['drafts']['n']['content'],
      'Durable latest',
    );
    raw.fail = false;
    await local.write('account:A', folded);
    expect(await raw.read('drafts:account:A'), isNull);
    expect(
      (await local.read('account:A'))!['drafts']['n']['content'],
      'Durable latest',
    );
    // Empty projection must override drafts folded into the root, even on reopen.
    await local.writeDrafts('account:A', {});
    await db.close();
    db = await databaseFactoryIo.openDatabase('${folder.path}/store.db');
    raw = FailingBatchStore(db);
    local = EncryptedAccountStore(raw, keys);
    expect((await local.read('account:A'))!['drafts'], isEmpty);
  });

  test('Failure publishing a draft preserves the previous durable draft and exposes local write error', () async {
    await local.write('account:A', seed());
    await local.writeDrafts('account:A', {
      'n': {'title': 'Saved', 'content': 'Previous'},
    });
    await local.write('session', {
      'user': {'id': 'A'},
      'token': 'fixture-A',
    });
    final c = AppController(offlineApi(), local)..setForeground(false);
    await c.initialize();
    raw.fail = true;
    await expectLater(
      c.draft('n', 'Saved', 'Newest unsaved'),
      throwsStateError,
    );
    expect(c.localWriteFailed, true);
    expect(
      (await local.read('account:A'))!['drafts']['n']['content'],
      'Previous',
    );
    raw.fail = false;
    await c.draft('n', 'Saved', 'Newest unsaved');
    expect(c.localWriteFailed, false);
    expect(
      (await local.read('account:A'))!['drafts']['n']['content'],
      'Newest unsaved',
    );
    c.dispose();
  });

  test('Rotate and remove account include its draft projection; AAD/key binding rejects swapped data', () async {
    await local.write('account:A', seed());
    await local.write('account:B', seed());
    await local.writeDrafts('account:A', {
      'n': {'title': 'A', 'content': 'A private draft'},
    });
    final patch = await raw.read('drafts:account:A');
    // Same key ID still cannot decrypt a root envelope under the draft AAD.
    await raw.write('drafts:account:A', (await raw.read('account:A'))!);
    await expectLater(local.read('account:A'), throwsA(isA<VaultException>()));
    await raw.write('drafts:account:A', patch!);
    await raw.write('drafts:account:B', patch);
    await expectLater(local.read('account:B'), throwsA(isA<VaultException>()));
    await raw.remove('drafts:account:B');
    final old = await raw.read('account:A');
    await local.rotateAccount('account:A');
    expect((await raw.read('account:A'))!['key_id'], isNot(old!['key_id']));
    expect(await raw.read('drafts:account:A'), isNull);
    expect(
      (await local.read('account:A'))!['drafts']['n']['content'],
      'A private draft',
    );
    await local.writeDrafts('account:A', {
      'n': {'title': 'A', 'content': 'Next'},
    });
    await local.remove('account:A');
    expect(await raw.read('account:A'), isNull);
    expect(await raw.read('drafts:account:A'), isNull);
    expect(await local.read('account:B'), isNotNull);
  });

  test('Missing root/key never recreates credentials or discards orphaned encrypted draft', () async {
    await local.write('account:A', seed());
    await local.writeDrafts('account:A', {
      'n': {'title': 'Saved', 'content': 'Keep ciphertext'},
    });
    final patch = await raw.read('drafts:account:A');
    keys.values.clear();
    await expectLater(
      local.writeDrafts('account:A', {}),
      throwsA(isA<VaultException>()),
    );
    expect(await raw.read('drafts:account:A'), patch);
    await raw.remove('account:A');
    await expectLater(local.read('account:A'), throwsA(isA<VaultException>()));
    await expectLater(
      local.write('account:A', seed()),
      throwsA(isA<VaultException>()),
    );
    await expectLater(
      local.rotateAccount('account:A'),
      throwsA(isA<VaultException>()),
    );
    expect(await raw.read('drafts:account:A'), patch);
    expect(keys.values, isEmpty);
  });

  test('Captured draft cannot write account B when logout/switch races with its transaction', () async {
    await local.write('account:A', seed());
    await local.write('session', {
      'user': {'id': 'A'},
      'token': 'fixture-A',
    });
    final c = AppController(offlineApi(), local)..setForeground(false);
    await c.initialize();
    raw.gate = Completer<void>();
    final write = c.draft('n', 'Saved', 'Frozen A edit');
    await raw.entered.future;
    c.user = {'id': 'B'};
    c.token = 'fixture-B';
    c.drafts = {};
    raw.gate!.complete();
    await write;
    expect(
      (await local.read('account:A'))!['drafts']['n']['content'],
      'Frozen A edit',
    );
    expect(await local.read('account:B'), isNull);
    c.dispose();
  });

  test('Save/lost ACK keeps immutable operation; remote lock archives latest overlay draft and retires it', () async {
    await local.write('account:A', seed());
    await local.write('session', {
      'user': {'id': 'A'},
      'token': 'fixture-A',
    });
    var locked = false;
    final sent = <Map<String, dynamic>>[];
    final api = Api(
      'http://test',
      client: MockClient((request) async {
        if (request.url.path == '/sync') {
          sent.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
          if (locked) return http.Response('{"detail":"Unlock required"}', 423);
          throw http.ClientException('Lost acknowledgement');
        }
        if (request.url.path == '/notes') {
          return http.Response(
            '[{"id":"n","locked":true,"revision":9,"role":"owner","shared":false,"pinned_at":null}]',
            200,
          );
        }
        return http.Response('{"id":"A","preferences":{}}', 200);
      }),
    );
    final c = AppController(api, local)..setForeground(false);
    await c.initialize();
    await c.draft('n', 'Saved', 'Queued edit');
    await c.save('n', 'Saved', 'Queued edit', baseRevision: 7);
    await idle(c);
    final immutable = Map<String, dynamic>.from(c.pending.single);
    await c.draft('n', 'Saved', 'Newest unfinished edit');
    await c.synchronize();
    expect(c.pending.single, immutable);
    expect(sent[0], sent[1]);
    locked = true;
    await c.synchronize();
    expect(c.notes.single.locked, true);
    expect(c.pending, isEmpty);
    expect(c.drafts, isEmpty);
    expect(c.recoveries.values.single['content'], 'Newest unfinished edit');
    expect(await raw.read('drafts:account:A'), isNull);
    expect(
      (await local.read('account:A'))!['recoveries'].values.single['content'],
      'Newest unfinished edit',
    );
    c.dispose();
  });
}
