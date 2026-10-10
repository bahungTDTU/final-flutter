import 'package:note_together/ui/rich_note_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/data/open_database.dart';
import 'package:note_together/data/realtime_feed.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';

import 'sharing_test.dart' show idle, until, type;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native live updates, reconnect, frozen-base conflict and realtime access recovery',
    (tester) async {
      var db = await openLocalDatabase();
      const endpoint = String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://127.0.0.1:8000',
      );
      final api = Api(endpoint);
      AppController make(Api transport) => AppController(
        transport,
        EncryptedAccountStore(
          SembastLocalStore(db),
          const DeviceRecoveryKeys(),
        ),
        realtime: RealtimeFeed(transport.baseUrl),
      );
      var c = make(api);
      await c.initialize();
      await idle(c);
      await c.logout();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      const password = 'native-realtime-password-123';
      Future<dynamic> register(String role) => api.call(
        'POST',
        '/auth/register',
        body: {
          'email': 'native-rt-$role-$stamp@example.test',
          'name': 'Realtime $role',
          'password': password,
          'confirmation': password,
        },
      );
      final owner = await register('owner');
      final recipient = await register('recipient');
      final viewer = await register('viewer');
      final stranger = await register('stranger');
      final ownerToken = owner['token'] as String;
      final recipientEmail = recipient['user']['email'] as String;
      final id = c.uuid.v4();
      Future<dynamic> edit(String content) async {
        final note = await api.call('GET', '/notes/$id', token: ownerToken);
        return api.call(
          'POST',
          '/sync',
          token: ownerToken,
          body: {
            'op_id': c.uuid.v4(),
            'note_id': id,
            'kind': 'upsert',
            'base_revision': note['revision'],
            'title': 'Native realtime fixture',
            'content': content,
          },
        );
      }

      await api.call(
        'POST',
        '/sync',
        token: ownerToken,
        body: {
          'op_id': c.uuid.v4(),
          'note_id': id,
          'kind': 'upsert',
          'base_revision': 0,
          'title': 'Native realtime fixture',
          'content': 'Original shared content',
        },
      );
      for (final entry in [(recipient, 'editor'), (viewer, 'viewer')]) {
        await api.call(
          'POST',
          '/notes/$id/shares',
          token: ownerToken,
          body: {'email': entry.$1['user']['email'], 'role': entry.$2},
        );
      }
      expect(
        await c.authenticate(
          register: false,
          email: recipientEmail,
          name: '',
          password: password,
        ),
        true,
      );
      await idle(c);
      final peer = make(api)
        ..user = Map<String, dynamic>.from(owner['user'])
        ..token = ownerToken;
      peer.setForeground(false);
      peer.setForeground(true);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await until(
        tester,
        () => c.realtimeLive && peer.realtimeLive && peer.notes.isNotEmpty,
      );
      await tester.tap(find.text('Được chia sẻ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Native realtime fixture'));
      await tester.pumpAndSettle();
      await edit('Peer content arrives live');
      await until(
        tester,
        () =>
            tester
                .widget<NoteRichTextField>(
                  find.byKey(const Key('note-content')),
                )
                .document
                .text ==
            'Peer content arrives live',
      );
      expect(
        tester
            .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
            .readOnly,
        true,
      );
      await tester.tap(find.text('Chỉnh sửa phiên bản mới'));
      await tester.pumpAndSettle();
      await type(
        tester,
        find.byKey(const Key('note-content')),
        'Native editor live save',
      );
      await until(
        tester,
        () =>
            peer.notes.single.content == 'Native editor live save' &&
            !c.hasPending(id),
      );
      expect(
        (await api.call('GET', '/notes/$id', token: ownerToken))['revision'],
        3,
      );
      // Explicit lifecycle disconnect/resume uses real sockets, no Wi-Fi/OS-kill claim.
      c.setForeground(false);
      expect(c.realtimeLive, false);
      await edit('Changed while stream disconnected');
      c.setForeground(true);
      await until(
        tester,
        () =>
            c.realtimeLive &&
            tester
                    .widget<NoteRichTextField>(
                      find.byKey(const Key('note-content')),
                    )
                    .document
                    .text ==
                'Changed while stream disconnected',
      );
      await tester.tap(find.text('Chỉnh sửa phiên bản mới'));
      await tester.pumpAndSettle();
      // Empty title leaves a durable draft while a remote editor saves a newer revision.
      await type(tester, find.byKey(const Key('note-title')), '');
      await type(
        tester,
        find.byKey(const Key('note-content')),
        'Native unsent concurrent text',
      );
      await edit('Concurrent owner version');
      await until(tester, () => c.notes.single.revision == 5);
      expect(
        tester
            .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
            .document
            .text,
        'Native unsent concurrent text',
      );
      await type(
        tester,
        find.byKey(const Key('note-title')),
        'Valid local title',
      );
      await until(tester, () => c.conflicts.containsKey(id));
      expect(c.pending.single['base_revision'], 4);
      expect(c.pending.single['content'], 'Native unsent concurrent text');
      expect(
        (await api.call('GET', '/notes/$id', token: ownerToken))['content'],
        'Concurrent owner version',
      );
      await api.call(
        'POST',
        '/notes/$id/shares',
        token: ownerToken,
        body: {'email': recipientEmail, 'role': 'viewer'},
      );
      await until(
        tester,
        () => c.notes.single.role == 'viewer' && c.recoveries.isNotEmpty,
      );
      expect(c.pending, isEmpty);
      expect(
        tester
            .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
            .readOnly,
        true,
      );
      expect(
        c.recoveries.values.first['content'],
        'Native unsent concurrent text',
      );
      await expectLater(
        api.call(
          'POST',
          '/sync',
          token: viewer['token'],
          body: {
            'op_id': c.uuid.v4(),
            'note_id': id,
            'kind': 'upsert',
            'base_revision': 5,
            'title': 'Denied',
            'content': 'Denied',
          },
        ),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
      await expectLater(
        api.call('GET', '/notes/$id', token: stranger['token']),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
      await api.call(
        'DELETE',
        '/notes/$id/shares/${recipient['user']['id']}',
        token: ownerToken,
      );
      await until(
        tester,
        () =>
            c.notes.isEmpty &&
            find.byKey(const Key('note-content')).evaluate().isEmpty,
      );
      expect(c.accessUnavailable.contains(id), true);
      await tester.pumpWidget(const SizedBox());
      await idle(peer);
      peer.dispose();
      // Two controllers share this test DB; persist the recipient session for reopen.
      await c.local.write('session', {'user': c.user, 'token': c.token});
      c.dispose();
      await db.close();
      db = await openLocalDatabase();
      c = make(Api('http://127.0.0.1:65530'));
      await c.initialize();
      await idle(c);
      expect(c.notes, isEmpty);
      expect(
        c.recoveries.values.first['content'],
        'Native unsent concurrent text',
      );
      expect(c.pending, isEmpty);
      c.dispose();
      await db.close();
      debugPrint(
        'PASS real SSE UI auto-refresh / editor save / lifecycle reconnect / frozen-base409 / viewer-revoke / encrypted reopen',
      );
    },
  );
}
