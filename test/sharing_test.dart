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
import 'package:note_together/state/share_session.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/editor.dart';
import 'package:note_together/ui/sharing.dart';
import 'package:sembast/sembast_io.dart';

import 'support.dart';

http.Response answer(Object value, [int code = 200]) => http.Response(
  jsonEncode(value),
  code,
  headers: {'content-type': 'application/json'},
);
const ownerNote = Note(
  id: 'n',
  title: 'Note',
  content: 'Server content',
  revision: 4,
  updatedAt: '',
  role: 'owner',
);
const editNote = Note(
  id: 'n',
  title: 'Note',
  content: 'Server content',
  revision: 4,
  updatedAt: '',
  role: 'editor',
);
Map<String, dynamic> recipient() => {
  'user_id': 'B',
  'name': 'Recipient',
  'email': 'b@example.test',
  'role': 'viewer',
  'shared_at': '2026-10-02T00:00:00Z',
};
AppController controller(
  MockClient client, {
  LocalStore? store,
  Note note = ownerNote,
}) => AppController(Api('http://test', client: client), store ?? MemoryStore())
  ..user = {'id': 'A', 'email': 'a@example.test'}
  ..token = 'A-token'
  ..notes = [note]
  ..ready = true;
Future<void> idle(AppController c) async {
  while (c.syncing) {
    await Future<void>.delayed(Duration.zero);
  }
}

class FixtureKeys implements RecoveryKeyStore {
  final records = <String, String>{};
  @override
  Future<String?> read(String id) async => records[id];
  @override
  Future<void> write(String id, String key) async {
    records[id] = key;
  }
}

void main() {
  testWidgets(
    'Background manager cannot repopulate recipient emails from polling',
    (tester) async {
      var requests = 0;
      final c = controller(
        MockClient((_) async {
          requests++;
          return answer({
            'revision': 1,
            'recipients': [recipient()],
          });
        }),
      );
      final s = ShareSession(c, 'n');
      await s.refresh();
      expect(s.recipients, hasLength(1));
      s.setForeground(false);
      await tester.pump(const Duration(seconds: 31));
      expect(requests, 1);
      expect(s.recipients, isEmpty);
      expect(s.canManage, false);
      s.setForeground(true);
      expect(s.canManage, false);
      await s.refresh();
      expect(s.canManage, true);
      expect(requests, 2);
      s.dispose();
      c.dispose();
    },
  );
  test('Lost share acknowledgement retries immutable op even after catalogue changes', () async {
    final posts = <String>[];
    var fail = true;
    final c = controller(
      MockClient((r) async {
        if (r.url.path.endsWith('/shares/sync')) {
          posts.add(r.body);
          if (fail) {
            throw http.ClientException('lost ack');
          }
          return answer({
            'revision': 3,
            'recipients': [],
          }); // Server replay returns current revoked catalogue.
        }
        if (r.url.path.endsWith('/shares')) {
          return answer({'revision': posts.isEmpty ? 0 : 3, 'recipients': []});
        }
        if (r.url.path == '/notes') {
          return answer([ownerNote.toJson()]);
        }
        return answer({'id': 'A'});
      }),
    );
    final session = ShareSession(c, 'n');
    await session.refresh();
    await session.submit({
      'action': 'add',
      'recipients': [
        {'email': 'b@example.test', 'role': 'viewer'},
      ],
    });
    expect(session.pending, isNotNull);
    await session.refresh();
    await session.submit({
      'action': 'add',
      'recipients': [
        {'email': 'changed@example.test', 'role': 'editor'},
      ],
    });
    fail = false;
    await session.retry();
    expect(posts, hasLength(2));
    expect(posts[0], posts[1]);
    expect(session.recipients, isEmpty);
    expect(session.pending, isNull);
    expect(c.notes.single.revision, 4);
    expect(c.pending, isEmpty);
    session.dispose();
    c.dispose();
  });
  test(
    'Late recipient list cannot cross accounts and locked list clears names',
    () async {
      final reply = Completer<http.Response>();
      final c = controller(MockClient((_) => reply.future));
      final s = ShareSession(c, 'n');
      final read = s.refresh();
      c.user = {'id': 'B'};
      c.token = 'B-token';
      s.checkGate();
      reply.complete(
        answer({
          'revision': 1,
          'recipients': [recipient()],
        }),
      );
      await read;
      expect(s.recipients, isEmpty);
      expect(s.validated, false);
      s.dispose();
      c.dispose();
    },
  );
  test(
    'CAS conflict adopts catalogue but requires a new reviewed operation',
    () async {
      final c = controller(
        MockClient(
          (r) async => r.method == 'POST'
              ? answer({
                  'detail': {
                    'current': {
                      'revision': 2,
                      'recipients': [recipient()],
                    },
                  },
                }, 409)
              : answer({'revision': 0, 'recipients': []}),
        ),
      );
      final s = ShareSession(c, 'n');
      await s.refresh();
      await s.submit({
        'action': 'add',
        'recipients': [
          {'email': 'b@example.test', 'role': 'viewer'},
        ],
      });
      expect(s.revision, 2);
      expect(s.pending, isNull);
      expect(s.recipients, hasLength(1));
      expect(s.message, contains('Kiểm tra'));
      s.dispose();
      c.dispose();
    },
  );
  test('Revoked pending edit keeps latest encrypted draft across file database reopen', () async {
    final folder = await Directory.systemTemp.createTemp('notetogether-share-');
    final file = '${folder.path}/account.db';
    final keys = FixtureKeys();
    var reachable = false;
    final api = Api(
      'http://test',
      client: MockClient((r) async {
        if (!reachable) {
          throw http.ClientException('offline');
        }
        if (r.url.path == '/sync') {
          return answer({'detail': 'unavailable'}, 404);
        }
        if (r.url.path == '/notes') {
          return answer([]);
        }
        return answer({'id': 'A'});
      }),
    );
    var db = await databaseFactoryIo.openDatabase(file);
    var store = EncryptedAccountStore(SembastLocalStore(db), keys);
    final c = AppController(api, store)
      ..user = {'id': 'A'}
      ..token = 'A-token'
      ..notes = [editNote];
    await c.save('n', 'Queued', 'older edit');
    await idle(c);
    await c.draft('n', 'Latest', 'share-secret-latest-edit');
    reachable = true;
    await c.synchronize();
    expect(c.notes, isEmpty);
    expect(c.pending, isEmpty);
    expect(c.recoveries.values.single['content'], 'share-secret-latest-edit');
    expect(c.accessUnavailable, contains('n'));
    await c.save('n', 'Must not create', 'after revoke');
    expect(c.pending, isEmpty);
    c.dispose();
    await db.close();
    expect(
      await File(file).readAsString(),
      isNot(contains('share-secret-latest-edit')),
    );
    db = await databaseFactoryIo.openDatabase(file);
    store = EncryptedAccountStore(SembastLocalStore(db), keys);
    reachable = false;
    final reopened = AppController(api, store);
    await reopened.initialize();
    await idle(reopened);
    expect(
      reopened.recoveries.values.single['content'],
      'share-secret-latest-edit',
    );
    expect(reopened.notes, isEmpty);
    final copy = await reopened.restoreRecovery(
      reopened.recoveries.keys.single,
    );
    expect(copy, isNot('n'));
    expect(reopened.drafts[copy]['content'], 'share-secret-latest-edit');
    reopened.dispose();
    await db.close();
    expect(
      folder.absolute.path.startsWith(Directory.systemTemp.absolute.path),
      true,
    );
    await folder.delete(recursive: true);
  });
  testWidgets(
    'Downgrade while typing shows server read-only and preserves draft',
    (tester) async {
      final viewer = Note.fromJson({
        ...editNote.toJson(),
        'role': 'viewer',
        'revision': 5,
        'content': 'Current server content',
      });
      final c = controller(
        MockClient(
          (r) async => r.url.path == '/notes'
              ? answer([viewer.toJson()])
              : answer({'id': 'A'}),
        ),
        note: editNote,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: EditorScreen(controller: c, id: 'n'),
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Nội dung'),
        'Typed draft',
      );
      await tester.pump();
      await c.synchronize();
      await tester.pumpAndSettle();
      expect(c.notes.single.role, 'viewer');
      expect(c.recoveries.values.single['content'], 'Typed draft');
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Nội dung'))
            .readOnly,
        true,
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Nội dung'))
            .controller!
            .text,
        'Current server content',
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'Share form validation and remote lock hide revoke confirmation at scale2',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = controller(
        MockClient(
          (_) async => answer({
            'revision': 1,
            'recipients': [recipient()],
          }),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2),
            ),
            child: ShareDialog(controller: c, noteId: 'n'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thu hồi quyền'));
      await tester.tap(find.text('Thu hồi quyền'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'b@example.test sẽ không còn đọc hoặc sửa ghi chú qua server.',
        ),
        findsOneWidget,
      );
      c.notes = [
        const Note(
          id: 'n',
          title: '',
          content: '',
          revision: 5,
          updatedAt: '',
          locked: true,
        ),
      ];
      await c.setPreferences({'dark': true});
      await tester.pumpAndSettle();
      expect(
        find.text(
          'b@example.test sẽ không còn đọc hoặc sửa ghi chú qua server.',
        ),
        findsNothing,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Thu hồi'))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'Shared card identifies owner and time while locked card redacts them',
    (tester) async {
      final shared = Note.fromJson({
        ...editNote.toJson(),
        'shared_by': {'name': 'Original owner', 'email': 'owner@example.test'},
        'shared_at': '2026-10-02T00:00:00Z',
      });
      final c = controller(MockClient((_) async => answer({})), note: shared);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Được chia sẻ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Từ Original owner'), findsOneWidget);
      c.notes = [
        Note.fromJson({...shared.toJson(), 'locked': true}),
      ];
      await c.setPreferences({'dark': true});
      await tester.pumpAndSettle();
      expect(find.textContaining('Từ Original owner'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
