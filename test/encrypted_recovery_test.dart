import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';
import 'package:sembast/sembast_io.dart';

import 'support.dart';

class TestKeys implements RecoveryKeyStore {
  final values = <String, String>{};
  bool fail = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('key storage unavailable');
    values[key] = value;
  }
}

class FailingCompaction extends SembastLocalStore {
  FailingCompaction(super.database);
  bool fail = true;
  @override
  Future<void> compact() async {
    if (fail) throw StateError('compaction interrupted');
    await super.compact();
  }
}

class FaultRecords extends MemoryStore {
  bool fail = false;
  int accountWrites = 0;
  int? failOnAccountWrite;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key.startsWith('account:')) {
      accountWrites++;
      if (fail || accountWrites == failOnAccountWrite) {
        throw StateError('disk full');
      }
    }
    await super.write(key, value);
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

Api lockedApi({Future<http.Response>? notes, void Function()? onNotes}) => Api(
  'http://test',
  client: MockClient((request) async {
    if (request.url.path == '/sync') {
      return http.Response('{"detail":"locked"}', 423);
    }
    if (request.url.path == '/notes') {
      onNotes?.call();
      return notes ??
          http.Response('[{"id":"n","revision":2,"locked":true}]', 200);
    }
    return http.Response('{"id":"A"}', 200);
  }),
);

void main() {
  test('423 archives latest queued edit even when the following list request fails', () async {
    final raw = MemoryStore(), keys = TestKeys();
    final store = EncryptedAccountStore(raw, keys);
    final seed = AppController(offlineApi(), store)
      ..user = {'id': 'A'}
      ..token = 'token';
    await seed.save('n', 'First', 'first edit');
    await seed.save('n', 'Latest', 'latest queued edit');
    await idle(seed);
    await store.write('session', {'user': seed.user, 'token': seed.token});
    seed.dispose();
    var sent = 0, maskedBeforeList = false;
    late AppController c;
    final api = Api(
      'http://test',
      client: MockClient((request) async {
        if (request.url.path == '/sync') {
          sent++;
          return http.Response('{"detail":"locked"}', 423);
        }
        if (request.url.path == '/notes') {
          maskedBeforeList =
              c.notes.single.locked && c.notes.single.content.isEmpty;
          throw http.ClientException('list unavailable');
        }
        return http.Response('{"id":"A"}', 200);
      }),
    );
    c = AppController(api, store);
    await c.initialize();
    await idle(c);
    expect(maskedBeforeList, true);
    expect(sent, 1);
    expect(c.notes.single.locked, true);
    expect(c.pending, isEmpty);
    expect(c.recoveries.values.single['content'], 'latest queued edit');
    expect((await store.read('account:A'))!['recoveries'], hasLength(1));
    await c.synchronize();
    expect(sent, 1);
    expect(c.recoveries, hasLength(1));
    c.dispose();
  });

  testWidgets(
    'Open editor clears controllers and stops autosave when lock arrives',
    (tester) async {
      final c = AppController(lockedApi(), MemoryStore())
        ..user = {'id': 'A'}
        ..token = 'token'
        ..ready = true;
      c.notes = [
        const Note(
          id: 'n',
          title: 'Before lock',
          content: 'Previously held text',
          revision: 1,
          updatedAt: '',
        ),
      ];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Before lock'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Before lock'));
      await tester.pumpAndSettle();
      final title = tester
          .widget<TextField>(find.byKey(const Key('note-title')))
          .controller!;
      final content = tester
          .widget<TextField>(find.byKey(const Key('note-content')))
          .controller!;
      await tester.enterText(
        find.byKey(const Key('note-content')),
        'Unfinished editor edit',
      );
      await c.synchronize();
      await tester.pumpAndSettle();
      expect(title.text, isEmpty);
      expect(content.text, isEmpty);
      expect(find.text('Ghi chú đã bị khóa.'), findsOneWidget);
      expect(c.recoveries.values.single['content'], 'Unfinished editor edit');
      expect(c.drafts, isEmpty);
      expect(c.pending, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(c.pending, isEmpty);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  test(
    'Interrupted native compaction retries before releasing migrated data',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'nt-vault-compact-',
      );
      final path = '${directory.path}/legacy.db';
      final db = await databaseFactoryIo.openDatabase(path);
      try {
        final raw = FailingCompaction(db);
        await raw.write('account:A', {
          'drafts': {'n': 'legacy interrupted recovery'},
        });
        final store = EncryptedAccountStore(raw, TestKeys());
        await expectLater(store.read('account:A'), throwsStateError);
        expect((await raw.read('account:A'))!['needs_compaction'], true);
        await expectLater(store.read('account:A'), throwsStateError);
        raw.fail = false;
        expect(
          (await store.read('account:A'))!['drafts']['n'],
          'legacy interrupted recovery',
        );
        expect(
          (await raw.read('account:A'))!.containsKey('needs_compaction'),
          false,
        );
        expect(
          await File(path).readAsString(),
          isNot(contains('legacy interrupted recovery')),
        );
      } finally {
        await db.close();
        await File(path).delete();
        await directory.delete();
      }
    },
  );
  testWidgets(
    'Recovery dialog hides content until explicit copy and opens a new draft',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController();
      c.notes = [
        const Note(
          id: 'locked',
          title: 'Ghi chú đã khóa',
          content: '',
          revision: 2,
          updatedAt: '',
          locked: true,
        ),
      ];
      c.recoveries = {
        'recovery': {
          'source_id': 'locked',
          'title': 'Private draft title',
          'content': 'Private unfinished content',
          'saved_at': '2026-10-01T00:00:00Z',
        },
      };
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.textContaining('Private'), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('open-recovery')));
      await tester.tap(find.byKey(const Key('open-recovery')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Private'), findsNothing);
      await tester.tap(find.text('Bản chỉnh sửa đã giữ'));
      await tester.pumpAndSettle();
      final id = c.drafts.keys.single;
      expect(id, isNot('locked'));
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-content')))
            .controller!
            .text,
        'Private unfinished content',
      );
      expect(c.pending, isEmpty);
      expect(c.notes.single.locked, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  test(
    'Lock without local changes never archives cached server content',
    () async {
      final raw = MemoryStore();
      final c =
          AppController(lockedApi(), EncryptedAccountStore(raw, TestKeys()))
            ..user = {'id': 'A'}
            ..token = 'token';
      c.notes = [
        const Note(
          id: 'n',
          title: 'Remote secret',
          content: 'Remote cached content',
          revision: 1,
          updatedAt: '',
        ),
      ];
      await c.synchronize();
      expect(c.recoveries, isEmpty);
      expect(c.notes.single.content, isEmpty);
      expect(c.notes.single.title, isNot('Remote secret'));
      c.dispose();
    },
  );

  test(
    'AES-GCM account envelope hides draft/outbox and uses fresh nonces',
    () async {
      final raw = MemoryStore(), keys = TestKeys();
      final store = EncryptedAccountStore(raw, keys);
      final payload = {
        'drafts': {
          'n': {'title': 'Secret title', 'content': 'Private edit'},
        },
        'pending': [
          {'content': 'Private operation'},
        ],
      };
      await store.write('account:A', payload);
      final first = (await raw.read('account:A'))!;
      expect(jsonEncode(first), isNot(contains('Private')));
      expect(jsonEncode(first), isNot(contains('Secret title')));
      expect(first.keys.toSet(), {
        'vault_version',
        'key_id',
        'nonce',
        'ciphertext',
        'mac',
      });
      expect(await store.read('account:A'), payload);
      await store.write('account:A', payload);
      expect((await raw.read('account:A'))!['nonce'], isNot(first['nonce']));
      expect(keys.values, hasLength(1));
    },
  );

  test(
    'Ciphertext tamper and account transplant fail authentication',
    () async {
      final raw = MemoryStore(), keys = TestKeys();
      final store = EncryptedAccountStore(raw, keys);
      await store.write('account:A', {
        'drafts': {'n': 'private'},
      });
      final envelope = (await raw.read('account:A'))!;
      final bytes = base64Decode(envelope['ciphertext'] as String)..[0] ^= 1;
      await raw.write('account:A', {
        ...envelope,
        'ciphertext': base64Encode(bytes),
      });
      await expectLater(
        store.read('account:A'),
        throwsA(isA<VaultException>()),
      );
      // Even if the same key bytes are deliberately copied, account AAD rejects B.
      keys.values['notetogether.vault.v1:account:B:${envelope['key_id']}'] =
          keys.values.values.first;
      await raw.write('account:B', envelope);
      await expectLater(
        store.read('account:B'),
        throwsA(isA<VaultException>()),
      );
    },
  );

  test(
    'Legacy migration is atomic; failed key/write leaves original untouched',
    () async {
      final raw = FaultRecords(), keys = TestKeys();
      const legacy = {
        'drafts': {
          'n': {'content': 'legacy private'},
        },
      };
      await raw.write('account:A', legacy);
      final store = EncryptedAccountStore(raw, keys);
      keys.fail = true;
      await expectLater(store.read('account:A'), throwsStateError);
      expect(await raw.read('account:A'), legacy);
      keys.fail = false;
      raw.fail = true;
      await expectLater(store.read('account:A'), throwsStateError);
      expect(await raw.read('account:A'), legacy);
      raw.fail = false;
      expect(await store.read('account:A'), legacy);
      expect((await raw.read('account:A'))!['vault_version'], 1);
    },
  );

  test(
    'Missing key never regenerates or overwrites a locked account',
    () async {
      final raw = MemoryStore(), keys = TestKeys();
      final store = EncryptedAccountStore(raw, keys);
      await store.write('account:A', {
        'drafts': {'n': 'private'},
      });
      await store.write('session', {
        'user': {'id': 'A'},
        'token': 'token',
      });
      final before = await raw.read('account:A');
      keys.values.clear();
      final c = AppController(lockedApi(), EncryptedAccountStore(raw, keys));
      await c.initialize();
      expect(c.user, isNull);
      expect(c.error, contains('Thiếu khóa'));
      await c.synchronize();
      expect(await raw.read('account:A'), before);
      expect(keys.values, isEmpty);
      c.dispose();
    },
  );

  test('Key rotation is atomic and preserves old key after failed ciphertext write', () async {
    final raw = FaultRecords(), keys = TestKeys();
    final store = EncryptedAccountStore(raw, keys);
    await store.write('account:A', {
      'recoveries': {'r': 'edit'},
    });
    final before = (await raw.read('account:A'))!;
    raw.fail = true;
    await expectLater(store.rotateAccount('account:A'), throwsStateError);
    expect(await raw.read('account:A'), before);
    expect((await store.read('account:A'))!['recoveries'], {'r': 'edit'});
    raw.fail = false;
    await store.rotateAccount('account:A');
    expect((await raw.read('account:A'))!['key_id'], isNot(before['key_id']));
    expect((await store.read('account:A'))!['recoveries'], {'r': 'edit'});
    expect(
      keys.values.containsKey(
        'notetogether.vault.v1:account:A:${before['key_id']}',
      ),
      true,
    );
  });

  test(
    'Remote lock captures newest in-flight draft and never requeues original',
    () async {
      final raw = MemoryStore(), keys = TestKeys();
      final store = EncryptedAccountStore(raw, keys);
      final response = Completer<http.Response>(), fetched = Completer<void>();
      final c =
          AppController(
              lockedApi(notes: response.future, onNotes: fetched.complete),
              store,
            )
            ..user = {'id': 'A'}
            ..token = 'token';
      c.notes = [
        const Note(
          id: 'n',
          title: 'Cached',
          content: 'old',
          revision: 1,
          updatedAt: '',
        ),
      ];
      final sync = c.synchronize();
      await fetched.future;
      await c.draft('n', '', 'newest unfinished text');
      response.complete(
        http.Response('[{"id":"n","revision":2,"locked":true}]', 200),
      );
      await sync;
      expect(c.notes.single.locked, true);
      expect(c.notes.single.content, isEmpty);
      expect(c.drafts, isEmpty);
      expect(c.pending, isEmpty);
      expect(c.recoveries.values.single['content'], 'newest unfinished text');
      await c.draft('n', 'race', 'must not recreate original');
      expect(c.drafts, isEmpty);
      expect(
        jsonEncode(await raw.read('account:A')),
        isNot(contains('newest unfinished')),
      );
      await c.synchronize();
      expect(c.recoveries, hasLength(1));
      final id = c.recoveries.keys.single;
      final newId = await c.restoreRecovery(id);
      expect(newId, isNot('n'));
      expect(c.drafts[newId]['content'], 'newest unfinished text');
      await c.draft(newId, 'Later change', 'do not overwrite');
      expect(await c.restoreRecovery(id), newId);
      expect(c.drafts[newId]['content'], 'do not overwrite');
      expect(c.pending, isEmpty);
      c.dispose();
    },
  );

  test(
    'Queued edit survives failed restore write then encrypted reopen',
    () async {
      final raw = FaultRecords(), keys = TestKeys();
      final store = EncryptedAccountStore(raw, keys);
      final seed = AppController(offlineApi(), store)
        ..user = {'id': 'A'}
        ..token = 'token';
      await seed.save('n', 'My edit', 'local unsent content');
      await idle(seed);
      await store.write('session', {'user': seed.user, 'token': seed.token});
      seed.dispose();
      final c = AppController(lockedApi(), store);
      await c.initialize();
      await idle(c);
      expect(c.recoveries.values.single['content'], 'local unsent content');
      final recoveryId = c.recoveries.keys.single;
      raw.fail = true;
      await expectLater(c.restoreRecovery(recoveryId), throwsStateError);
      raw.fail = false;
      await c.synchronize();
      c.dispose();
      final reopened = AppController(
        offlineApi(),
        EncryptedAccountStore(raw, keys),
      );
      await reopened.initialize();
      await idle(reopened);
      expect(
        reopened.recoveries.values.single['content'],
        'local unsent content',
      );
      expect(reopened.notes.single.locked, true);
      expect(reopened.pending, isEmpty);
      final id = await reopened.restoreRecovery(recoveryId);
      expect(reopened.drafts[id]['content'], 'local unsent content');
      await reopened.logout();
      expect(reopened.recoveries, isEmpty);
      expect((await store.read('account:A'))!['recoveries'], hasLength(1));
      expect(await store.read('account:B'), isNull);
      reopened.dispose();
    },
  );

  test('Failed lock transition retains last durable edit and retries without duplicate recovery', () async {
    final raw = FaultRecords(), keys = TestKeys();
    final store = EncryptedAccountStore(raw, keys);
    final seed = AppController(offlineApi(), store)
      ..user = {'id': 'A'}
      ..token = 'token';
    await seed.save('n', 'Local edit', 'never lose this');
    await idle(seed);
    await store.write('session', {'user': seed.user, 'token': seed.token});
    seed.dispose();
    raw.failOnAccountWrite = raw.accountWrites + 2;
    final c = AppController(lockedApi(), store);
    await c.initialize();
    await idle(c);
    expect(c.error, contains('Chưa ghi được dữ liệu'));
    expect(c.notes.single.locked, true);
    expect(c.recoveries.values.single['content'], 'never lose this');
    expect((await store.read('account:A'))!['pending'], hasLength(1));
    await c.synchronize();
    expect(c.recoveries, hasLength(1));
    expect((await store.read('account:A'))!['pending'], isEmpty);
    expect((await store.read('account:A'))!['recoveries'], hasLength(1));
    c.dispose();
  });

  test(
    'Native legacy migration compacts obsolete plaintext from Sembast log',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'nt-vault-migrate-',
      );
      final path = '${directory.path}/legacy.db';
      final db = await databaseFactoryIo.openDatabase(path);
      try {
        final raw = SembastLocalStore(db);
        await raw.write('account:A', {
          'drafts': {'n': 'legacy sensitive sentence'},
        });
        expect(
          await File(path).readAsString(),
          contains('legacy sensitive sentence'),
        );
        final store = EncryptedAccountStore(raw, TestKeys());
        expect(
          (await store.read('account:A'))!['drafts']['n'],
          'legacy sensitive sentence',
        );
        expect(
          await File(path).readAsString(),
          isNot(contains('legacy sensitive sentence')),
        );
      } finally {
        await db.close();
        await File(path).delete();
        await directory.delete();
      }
    },
  );

  test('Encrypted Sembast file close/reopen retains draft and recovery key reference', () async {
    final directory = await Directory.systemTemp.createTemp(
      'nt-encrypted-reopen-',
    );
    final path = '${directory.path}/account.db';
    final keys = TestKeys();
    var db = await databaseFactoryIo.openDatabase(path);
    final payload = {
      'recoveries': {
        'r': {'content': 'Private file recovery'},
      },
    };
    await EncryptedAccountStore(
      SembastLocalStore(db),
      keys,
    ).write('account:A', payload);
    await db.close();
    expect(
      await File(path).readAsString(),
      isNot(contains('Private file recovery')),
    );
    db = await databaseFactoryIo.openDatabase(path);
    try {
      expect(
        await EncryptedAccountStore(
          SembastLocalStore(db),
          keys,
        ).read('account:A'),
        payload,
      );
    } finally {
      await db.close();
      await File(path).delete();
      await directory.delete();
    }
  });
}
