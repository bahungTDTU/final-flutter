import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:sembast/sembast_io.dart';

import 'support.dart';

class ControlledStore extends MemoryStore {
  bool failAccounts = false;
  Completer<void>? sessionGate;
  final sessionStarted = Completer<void>();
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key.startsWith('account:') && failAccounts) {
      throw StateError('disk full');
    }
    if (key == 'session' && sessionGate != null) {
      if (!sessionStarted.isCompleted) sessionStarted.complete();
      await sessionGate!.future;
    }
    await super.write(key, value);
  }
}

Future<void> idle(AppController c) async {
  while (c.syncing) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test(
    'Native file close/reopen preserves draft and exact outbox operation',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'notetogether-reopen-',
      );
      final path = '${directory.path}/notes.db';
      var database = await databaseFactoryIo.openDatabase(path);
      final api = Api(
        'http://test',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      final c = AppController(api, SembastLocalStore(database))
        ..user = {'id': 'A'}
        ..token = 'token';
      await c.save('n', 'Title', 'saved content');
      await idle(c);
      await c.draft('n', '', 'unfinished latest');
      final operation = Map<String, dynamic>.from(c.pending.single);
      await c.local.write('session', {'user': c.user, 'token': c.token});
      c.dispose();
      await database.close();
      database = await databaseFactoryIo.openDatabase(path);
      final reopened = AppController(api, SembastLocalStore(database));
      try {
        await reopened.initialize();
        await idle(reopened);
        expect(reopened.pending.single, operation);
        expect(reopened.drafts['n']['content'], 'unfinished latest');
        expect(reopened.notes.single.content, 'saved content');
      } finally {
        reopened.dispose();
        await database.close();
        await File(path).delete();
        await directory.delete();
      }
    },
  );

  test('Edit during acknowledgement survives stale remote refresh', () async {
    final ack = Completer<http.Response>();
    final started = Completer<void>();
    final sent = <Map<String, dynamic>>[];
    final store = MemoryStore();
    final c =
        AppController(
            Api(
              'http://test',
              client: MockClient((r) async {
                if (r.url.path == '/sync') {
                  sent.add(jsonDecode(r.body));
                  started.complete();
                  return ack.future;
                }
                if (r.url.path == '/notes') {
                  return http.Response(
                    jsonEncode([
                      {
                        'id': 'n',
                        'title': 'First',
                        'content': 'first text',
                        'revision': 1,
                        'role': 'owner',
                        'updated_at': '2026-10-01',
                      },
                    ]),
                    200,
                  );
                }
                return http.Response(jsonEncode({'id': 'A'}), 200);
              }),
            ),
            store,
          )
          ..user = {'id': 'A'}
          ..token = 'token';
    await c.save('n', 'First', 'first text');
    await started.future;
    await c.save('n', 'Second', 'latest text');
    final later = Map<String, dynamic>.from(c.pending.last);
    ack.complete(http.Response('{}', 200));
    await idle(c);
    expect(sent, hasLength(1));
    expect(c.pending, [later]);
    expect(c.notes.single.content, 'latest text');
    expect((await store.read('account:A'))!['pending'], [later]);
    c.dispose();
  });

  test(
    'Lost acknowledgement retries identical operation rather than new edit',
    () async {
      final sent = <Map<String, dynamic>>[];
      final c =
          AppController(
              Api(
                'http://test',
                client: MockClient((r) async {
                  if (r.url.path == '/sync') {
                    sent.add(jsonDecode(r.body));
                    if (sent.length == 1) {
                      throw http.ClientException('ack lost');
                    }
                    return http.Response('{}', 200);
                  }
                  if (r.url.path == '/notes') return http.Response('[]', 200);
                  return http.Response(jsonEncode({'id': 'A'}), 200);
                }),
              ),
              MemoryStore(),
            )
            ..user = {'id': 'A'}
            ..token = 'token';
      await c.save('n', 'Title', 'body');
      await idle(c);
      expect(c.pending, hasLength(1));
      await c.synchronize();
      expect(sent, hasLength(2));
      expect(sent[1], sent[0]);
      expect(c.pending, isEmpty);
      c.dispose();
    },
  );
  test(
    'Logout retires a blocked session write and sends no old queue',
    () async {
      final store = ControlledStore()..sessionGate = Completer<void>();
      var mutations = 0;
      final c =
          AppController(
              Api(
                'http://test',
                client: MockClient((r) async {
                  if (r.url.path == '/me/preferences/sync') mutations++;
                  return http.Response(jsonEncode({'id': 'A'}), 200);
                }),
              ),
              store,
            )
            ..user = {'id': 'A'}
            ..token = 'A-token';
      c.pendingPreferences = [
        {'op_id': 'old', 'dark': true},
      ];
      final sync = c.synchronize();
      await store.sessionStarted.future;
      final logout = c.logout();
      store.sessionGate!.complete();
      await Future.wait([sync, logout]);
      expect(await store.read('session'), isNull);
      expect(mutations, 0);
      expect(
        (await store.read('account:A'))!['pending_preferences'],
        hasLength(1),
      );
      c.dispose();
    },
  );

  test(
    'Disk failure prevents network send; retry keeps operation identity',
    () async {
      final store = ControlledStore()..failAccounts = true;
      final sent = <Map<String, dynamic>>[];
      final c =
          AppController(
              Api(
                'http://test',
                client: MockClient((r) async {
                  if (r.url.path == '/sync') sent.add(jsonDecode(r.body));
                  if (r.url.path == '/notes') return http.Response('[]', 200);
                  return http.Response(jsonEncode({'id': 'A'}), 200);
                }),
              ),
              store,
            )
            ..user = {'id': 'A'}
            ..token = 'token';
      await expectLater(c.save('n', 'Title', 'body'), throwsStateError);
      final operation = Map<String, dynamic>.from(c.pending.single);
      await c.synchronize();
      expect(sent, isEmpty);
      expect(c.error, contains('Chưa ghi được dữ liệu'));
      store.failAccounts = false;
      await c.synchronize();
      expect(sent, [operation]);
      expect(c.pending, isEmpty);
      c.dispose();
    },
  );

  test(
    'Conflict copy persists latest draft in the same transaction as retirement',
    () async {
      final store = MemoryStore();
      final c = offlineController(store: store);
      await c.save('old', 'Old title', 'saved text');
      await idle(c);
      await c.draft('old', 'Latest title', 'unsaved text');
      c.conflicts['old'] = {'status': 409};
      await c.resolveConflict('old', keepCopy: true);
      final snapshot = (await store.read('account:A'))!;
      expect(snapshot['conflicts'], isEmpty);
      expect(c.pending.single['base_revision'], 0);
      expect(c.pending.single['note_id'], isNot('old'));
      expect(c.pending.single['content'], 'unsaved text');
      await store.write('session', {'user': c.user, 'token': c.token});
      c.dispose();
      final reopened = offlineController(store: store);
      await reopened.initialize();
      expect(reopened.pending.single['content'], 'unsaved text');
      expect(reopened.notes.single.title, 'Latest title (bản phục hồi)');
      reopened.dispose();
    },
  );

  test(
    'Conflict write failure preserves original in memory and on disk',
    () async {
      final store = ControlledStore();
      final c = offlineController(store: store);
      await c.save('old', 'Title', 'body');
      await idle(c);
      await c.draft('old', 'Latest', 'draft');
      c.conflicts['old'] = {'status': 409};
      final before = await store.read('account:A');
      store.failAccounts = true;
      await expectLater(
        c.resolveConflict('old', keepCopy: true),
        throwsStateError,
      );
      expect(c.notes.single.id, 'old');
      expect(c.pending.single['note_id'], 'old');
      expect(c.drafts['old']['content'], 'draft');
      expect(c.conflicts['old']['status'], 409);
      expect(await store.read('account:A'), before);
      c.dispose();
    },
  );

  test(
    'Invalid conflict draft stays recoverable without sending an invalid note',
    () async {
      final store = MemoryStore();
      final c = offlineController(store: store);
      await c.save('old', 'Title', 'body');
      await idle(c);
      await c.draft('old', '', 'latest unfinished');
      c.conflicts['old'] = {'status': 409};
      await c.resolveConflict('old', keepCopy: true);
      expect(c.pending, isEmpty);
      expect(c.drafts.keys.single, isNot('old'));
      expect(c.drafts.values.single['content'], 'latest unfinished');
      expect((await store.read('account:A'))!['drafts'], c.drafts);
      c.dispose();
    },
  );
}
