import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/app_controller.dart';

import 'support.dart';

class AuditKeys implements RecoveryKeyStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

http.Response response(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);

const original = Note(
  id: 'existing',
  title: 'Accepted title',
  content: 'Accepted content',
  revision: 3,
  updatedAt: '2026-10-20',
);

void main() {
  for (final queued in [false, true]) {
    test(
      'Owner remote deletion preserves ${queued ? "rejected edit" : "draft"} in encrypted recovery across reopen',
      () async {
        final records = MemoryStore();
        final local = EncryptedAccountStore(records, AuditKeys());
        final profile = {
          'id': 'A',
          'schema_version': 2,
          'preferences': <String, dynamic>{},
        };
        final api = Api(
          'http://test',
          client: MockClient((r) async {
            if (r.url.path == '/me') return response(profile);
            if (r.url.path == '/notes' || r.url.path == '/labels') {
              return response([]);
            }
            if (r.url.path == '/sync') {
              return response({'detail': 'Note not found'}, 404);
            }
            throw StateError('Unexpected request: ${r.method} ${r.url.path}');
          }),
        );
        final c = AppController(api, local)
          ..user = profile
          ..token = 'fixture-session'
          ..notes = [original];
        addTearDown(c.dispose);
        if (queued) {
          c.pending = [
            {
              'op_id': 'pending-edit',
              'note_id': original.id,
              'kind': 'upsert',
              'base_revision': 3,
              'title': 'Older queued edit',
              'content': 'Earlier unsent content',
              'labels': <String>[],
            },
          ];
        }
        await c.draft(
          original.id,
          'Latest private title',
          'Latest private edit',
        );
        await c.synchronize();
        expect(c.notes, isEmpty);
        expect(c.pending, isEmpty);
        expect(c.conflicts, isEmpty);
        expect(c.drafts.containsKey(original.id), false);
        expect(c.recoveries, hasLength(1));
        final recovery = c.recoveries.values.single as Map;
        expect(recovery['title'], 'Latest private title');
        expect(recovery['content'], 'Latest private edit');
        expect(recovery['reason'], 'deleted');
        expect(c.accessUnavailable, contains(original.id));
        expect(jsonEncode(records.values), isNot(contains('Latest private')));
        final reopened = AppController(api, local);
        addTearDown(reopened.dispose);
        await reopened.initialize();
        while (reopened.syncing) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(reopened.recoveries, hasLength(1));
        expect(reopened.accessUnavailable, contains(original.id));
        await reopened.save(
          original.id,
          'Should not recreate',
          'A deleted source',
        );
        expect(reopened.pending, isEmpty);
        final id = await reopened.restoreRecovery(
          reopened.recoveries.keys.single,
        );
        expect(id, isNot(original.id));
        expect(reopened.drafts[id]['content'], 'Latest private edit');
      },
    );
  }

  test(
    'A not-yet-created owner note rejected by validation remains repairable',
    () async {
      final c =
          AppController(
              Api(
                'http://test',
                client: MockClient((r) async {
                  if (r.url.path == '/me') return response({'id': 'A'});
                  if (r.url.path == '/notes') return response([]);
                  if (r.url.path == '/sync') {
                    return response({'detail': 'Invalid labels'}, 422);
                  }
                  throw StateError('Unexpected path: ${r.url.path}');
                }),
              ),
              MemoryStore(),
            )
            ..user = {'id': 'A'}
            ..token = 'fixture-session'
            ..notes = [
              const Note(
                id: 'new',
                title: 'New title',
                content: 'New content',
                revision: 1,
                updatedAt: '',
              ),
            ]
            ..pending = [
              {
                'op_id': 'new-operation',
                'note_id': 'new',
                'base_revision': 0,
                'kind': 'upsert',
                'title': 'New title',
                'content': 'New content',
                'labels': <String>[],
              },
            ];
      addTearDown(c.dispose);
      await c.synchronize();
      expect(c.notes.single.id, 'new');
      expect(c.pending.single['op_id'], 'new-operation');
      expect(c.conflicts['new']['status'], 422);
      expect(c.recoveries, isEmpty);
      expect(c.accessUnavailable, isNot(contains('new')));
    },
  );

  for (final queuedPreference in [false, true]) {
    test(
      'Sync ${queuedPreference ? "refreshes after preference ACK" : "avoids duplicate profile fetch"}',
      () async {
        var profileReads = 0, writes = 0;
        var preferences = <String, dynamic>{
          'dark': false,
          'locale': 'vi',
          'palette': 'atelier',
        };
        final c =
            AppController(
                Api(
                  'http://test',
                  client: MockClient((r) async {
                    if (r.url.path == '/me') {
                      profileReads++;
                      return response({'id': 'A', 'preferences': preferences});
                    }
                    if (r.url.path == '/me/preferences/sync') {
                      writes++;
                      preferences = {
                        'dark': true,
                        'locale': 'en',
                        'palette': 'iris',
                      };
                      return response({'ok': true});
                    }
                    if (r.url.path == '/notes') return response([]);
                    throw StateError('Unexpected path: ${r.url.path}');
                  }),
                ),
                MemoryStore(),
              )
              ..user = {'id': 'A'}
              ..token = 'fixture-session';
        addTearDown(c.dispose);
        if (queuedPreference) {
          c.pendingPreferences = [
            {'op_id': 'preferences-op', 'dark': true},
          ];
        }
        await c.synchronize();
        // ignore: avoid_print
        print(
          'PROFILE_FETCH_PROBE queued=$queuedPreference reads=$profileReads writes=$writes',
        );
        expect(profileReads, queuedPreference ? 2 : 1);
        expect(writes, queuedPreference ? 1 : 0);
        expect(c.pendingPreferences, isEmpty);
        expect(c.dark, queuedPreference);
        expect(c.language, queuedPreference ? 'en' : 'vi');
      },
    );
  }
}
