import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/data/protected_note_vault.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/state/protected_reader.dart';
import 'package:note_together/ui/note_protection.dart';
import 'package:sembast/sembast_io.dart';

import 'support.dart';

class QuietController extends AppController {
  QuietController(super.api, super.local);
  @override
  Future<void> synchronize() async {} // Only isolates the route unit under test.
}

class Keys implements RecoveryKeyStore {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }
}

const password = 'protected-password-123';
Map<String, dynamic> serverNote({
  int revision = 1,
  String content = 'Private original',
  String role = 'owner',
}) => {
  'id': 'n',
  'title': 'Private title',
  'content': content,
  'revision': revision,
  'updated_at': '2026-10-05',
  'role': role,
  'locked': true,
  'protection_version': 1,
  'pinned_at': '2026-10-01',
  'labels': [],
};
http.Response response(Object data, [int status = 200]) =>
    http.Response(jsonEncode(data), status);
QuietController controller(
  LocalStore store,
  Future<http.Response> Function(http.Request) handler, {
  String account = 'A',
}) => QuietController(Api('http://test', client: MockClient(handler)), store)
  ..user = {
    'id': account,
    'name': 'Test',
    'email': 'test@example.test',
    'verified': false,
  }
  ..token = 'token-$account'
  ..ready = true
  ..notes = [
    const Note(
      id: 'n',
      title: 'Ghi chú đã khóa',
      content: '',
      revision: 1,
      updatedAt: '',
      locked: true,
    ),
  ];
ProtectedReader reader(AppController c, {bool recovery = false}) =>
    ProtectedReader(
      c,
      'n',
      recoveryMode: recovery,
      vault: ProtectedNoteVault(c.user!['id'] as String, 'n', workFactor: 50),
    ); // Explicit crypto test factor; app uses600000.
Future<http.Response> basic(http.Request r) async => response(
  r.url.path.endsWith('/unlock')
      ? {'expires_in': 300}
      : r.url.path.endsWith('/lock')
      ? {'ok': true}
      : serverNote(),
);
Future<void> idle(ProtectedReader r) async {
  for (var i = 0; i < 200 && r.saving; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(r.saving, false);
}

void main() {
  testWidgets(
    'Protected editor autosaves; revoked delete confirmation removes name and disables action',
    (tester) async {
      var remote = serverNote();
      final sent = <Map<String, dynamic>>[];
      final c = controller(MemoryStore(), (request) async {
        if (request.url.path.endsWith('/unlock')) {
          return response({'expires_in': 300});
        }
        if (request.url.path.endsWith('/lock')) return response({'ok': true});
        if (request.url.path == '/sync') {
          final op = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
          sent.add(op);
          remote = {...remote, ...op, 'revision': 2, 'locked': true};
          return response({'id': 'n', 'revision': 2});
        }
        return response(remote);
      });
      await tester.pumpWidget(
        MaterialApp(
          home: ProtectedNoteScreen(
            controller: c,
            id: 'n',
            vault: ProtectedNoteVault('A', 'n', workFactor: 50),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('unlock-note-password')),
        password,
      );
      await tester.tap(find.byKey(const Key('unlock-note')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Chỉnh sửa'));
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('protected-content-editor')),
        'Protected widget latest',
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(sent.single['content'], 'Protected widget latest');
      expect(c.pending, isEmpty);
      expect(c.drafts, isEmpty);
      await tester.ensureVisible(find.byKey(const Key('protected-delete')));
      await tester.tap(find.byKey(const Key('protected-delete')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('Private title'),
        ),
        findsOneWidget,
      );
      c.notes = [];
      c.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.textContaining('Private title'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('protected-delete-confirm')),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'Protected viewer keeps metadata visible after unlock and has no mutation controls',
    (tester) async {
      final c = controller(MemoryStore(), (request) async {
        if (request.url.path.endsWith('/unlock')) {
          return response({'expires_in': 300});
        }
        if (request.url.path.endsWith('/lock')) return response({'ok': true});
        return response({
          ...serverNote(role: 'viewer'),
          'shared_by': {'name': 'Peer owner'},
          'shared_at': '2026-10-05',
        });
      });
      c.notes = [
        Note.fromJson({
          'id': 'n',
          'revision': 1,
          'locked': true,
          'role': 'viewer',
        }),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: ProtectedNoteScreen(
            controller: c,
            id: 'n',
            vault: ProtectedNoteVault('A', 'n', workFactor: 50),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('unlock-note-password')),
        password,
      );
      await tester.tap(find.byKey(const Key('unlock-note')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Peer owner'), findsOneWidget);
      expect(find.text('Đã ghim'), findsOneWidget);
      expect(find.byKey(const Key('protected-delete')), findsNothing);
      expect(find.text('Chỉnh sửa'), findsNothing);
      expect(find.text('Xem đính kèm'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  test('Production PBKDF2 envelope authenticates password/account/note and fresh AES nonce', () async {
    final vault = ProtectedNoteVault('A', 'n');
    final lease = await vault.create(password, {});
    final data = {
      'note': serverNote(),
      'draft': {'title': 'Secret draft', 'content': 'Secret unfinished'},
      'base_revision': 1,
    };
    final first = await vault.seal(lease, data),
        second = await vault.seal(lease, data);
    expect(first['iterations'], 600000);
    expect(first['nonce'], isNot(second['nonce']));
    expect(jsonEncode(first), isNot(contains('Secret unfinished')));
    expect(
      (await vault.open(first, password)).data['draft']['content'],
      'Secret unfinished',
    );
    await expectLater(
      vault.open(first, 'wrong-password-123'),
      throwsStateError,
    );
    await expectLater(
      ProtectedNoteVault('B', 'n').open(first, password),
      throwsStateError,
    );
    await expectLater(
      ProtectedNoteVault('A', 'other').open(first, password),
      throwsStateError,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Delete conflict requires new confirmation and revoked delete hides content', () async {
    var revision = 1, deletes = 0;
    final operations = <Map<String, dynamic>>[];
    final c = controller(MemoryStore(), (request) async {
      if (request.url.path.endsWith('/unlock')) {
        return response({'expires_in': 300});
      }
      if (request.url.path == '/sync') {
        operations.add(jsonDecode(request.body) as Map<String, dynamic>);
        deletes++;
        if (deletes == 1) {
          revision = 2;
          return response({'detail': 'Conflict'}, 409);
        }
        return response({'detail': 'Forbidden'}, 403);
      }
      return response(serverNote(revision: revision));
    });
    final r = reader(c);
    await r.unlock(password);
    expect(await r.deleteNote(), isFalse);
    expect(r.note!.revision, 2);
    expect(r.error, contains('xác nhận xóa lại'));
    expect(await r.deleteNote(), isFalse);
    expect(operations.last['base_revision'], 2);
    expect(operations.last['op_id'], isNot(operations.first['op_id']));
    expect(r.note, isNull);
    expect(r.serverGate, isFalse);
    r.dispose();
    c.dispose();
  });

  test('Offline draft survives encrypted Sembast close/reopen and never enters ordinary outbox', () async {
    final directory = await Directory.systemTemp.createTemp(
      'protected-durability-',
    );
    final keys = Keys();
    final path = '${directory.path}/data.db';
    var db = await databaseFactoryIo.openDatabase(path);
    var c = controller(
      EncryptedAccountStore(SembastLocalStore(db), keys),
      basic,
    );
    var r = reader(c);
    await r.unlock(password);
    c.online = false;
    c.notifyListeners();
    expect(r.note, isNull);
    await r.unlock(password);
    await r.edit('Private draft', 'Protected offline latest');
    expect(c.pending, isEmpty);
    expect(c.drafts, isEmpty);
    expect(c.notes.single.content, isEmpty);
    await r.drainWrites();
    r.dispose();
    c.dispose();
    await db.close();
    expect(
      utf8.decode(await File(path).readAsBytes(), allowMalformed: true),
      isNot(contains('Protected offline latest')),
    );
    db = await databaseFactoryIo.openDatabase(path);
    c = controller(EncryptedAccountStore(SembastLocalStore(db), keys), basic)
      ..online = false;
    r = reader(c);
    await r.unlock(password);
    expect(r.draft?['content'], 'Protected offline latest');
    expect(r.baseRevision, 1);
    expect(r.serverGate, false);
    r.dispose();
    c.dispose();
    await db.close();
    await directory.delete(recursive: true);
  });

  test('A copied old-password draft permits new-password unlock without losing the private copy', () async {
    var changed = false;
    final c = controller(MemoryStore(), (request) async {
      if (request.url.path.endsWith('/unlock')) {
        return response({'expires_in': 300});
      }
      return response({
        ...serverNote(revision: changed ? 2 : 1),
        'protection_version': changed ? 2 : 1,
      });
    });
    var r = reader(c);
    await r.unlock(password);
    c.online = false;
    c.notifyListeners();
    await r.unlock(password);
    await r.edit('Old private title', 'Old private draft');
    await r.drainWrites();
    r.dispose();
    changed = true;
    c.online = true;
    r = reader(c);
    await r.unlock('changed-password-123');
    expect(r.note, isNull);
    expect(r.error, contains('mật khẩu cũ'));
    r.dispose();
    final recovery = reader(c, recovery: true);
    await recovery.unlock(password);
    final copy = (await recovery.copyDraft())!;
    recovery.dispose();
    expect(c.drafts[copy]['content'], 'Old private draft');
    r = reader(c);
    await r.unlock('changed-password-123');
    expect(r.serverGate, isTrue);
    expect(r.note!.protectionVersion, 2);
    expect(r.dirty, isFalse);
    expect(c.drafts[copy]['content'], 'Old private draft');
    expect(c.pending, isEmpty);
    r.dispose();
    c.dispose();
  });

  test(
    'Lost acknowledgement replays the same immutable operation after reopen',
    () async {
      final store = MemoryStore();
      var remote = serverNote();
      final sent = <Map<String, dynamic>>[];
      Future<http.Response> handler(http.Request request) async {
        if (request.url.path.endsWith('/unlock')) {
          return response({'expires_in': 300});
        }
        if (request.url.path.endsWith('/lock')) return response({'ok': true});
        if (request.url.path == '/sync') {
          final op = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
          sent.add(op);
          if (sent.length == 1) {
            remote = serverNote(revision: 2, content: op['content']);
            throw http.ClientException('lost ack');
          }
          return response({'id': 'n', 'revision': 2});
        }
        return response(remote);
      }

      var c = controller(store, handler);
      var r = reader(c);
      await r.unlock(password);
      await r.edit('Private title', 'New protected content');
      await r.flush();
      expect(r.operation, isNotNull);
      final immutable = Map<String, dynamic>.from(sent.single);
      r.dispose();
      c.dispose();
      await Future<void>.delayed(Duration.zero);
      c = controller(store, handler);
      r = reader(c);
      await r.unlock(password);
      await idle(r);
      expect(sent, hasLength(2));
      expect(sent.last, immutable);
      expect(r.dirty, false);
      expect(c.pending, isEmpty);
      expect(c.drafts, isEmpty);
      r.dispose();
      c.dispose();
    },
  );

  test('Typing while protected operation is inflight keeps newest draft and chains own ack', () async {
    final delayed = Completer<http.Response>();
    final sent = <Map<String, dynamic>>[];
    final c = controller(MemoryStore(), (request) async {
      if (request.url.path.endsWith('/unlock')) {
        return response({'expires_in': 300});
      }
      if (request.url.path.endsWith('/lock')) return response({'ok': true});
      if (request.url.path == '/sync') {
        sent.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
        return sent.length == 1
            ? delayed.future
            : response({'id': 'n', 'revision': 3});
      }
      return response(serverNote());
    });
    final r = reader(c);
    await r.unlock(password);
    await r.edit('Private title', 'First', updatePin: true, pinnedAt: null);
    final saving = r.flush();
    while (sent.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    await r.edit('Private title', 'Latest while inflight');
    delayed.complete(response({'id': 'n', 'revision': 2}));
    await saving;
    await idle(r);
    expect(sent[0]['content'], 'First');
    expect(sent[1]['content'], 'Latest while inflight');
    expect(sent[0]['pinned_at'], isNull);
    expect(sent[1]['pinned_at'], isNull);
    expect(sent.map((s) => s['base_revision']), [1, 2]);
    expect(r.dirty, false);
    r.dispose();
    c.dispose();
  });

  test('Realtime clean content updates keep frozen base; dirty content remains on conflict', () async {
    var remote = serverNote();
    final c = controller(MemoryStore(), (request) async {
      if (request.url.path.endsWith('/unlock')) {
        return response({'expires_in': 300});
      }
      if (request.url.path.endsWith('/lock')) return response({'ok': true});
      if (request.url.path == '/sync') {
        return response({
          'detail': {'message': 'Revision conflict', 'remote': remote},
        }, 409);
      }
      return response(remote);
    });
    final r = reader(c);
    await r.unlock(password);
    remote = serverNote(revision: 2, content: 'Peer content');
    await r.refresh();
    expect(r.note?.content, 'Peer content');
    expect(r.baseRevision, 1);
    expect(r.requiresReopen, true);
    r.beginFreshEdit();
    await r.edit('Private title', 'My latest');
    remote = serverNote(revision: 3, content: 'Peer next');
    await r.refresh();
    await r.flush();
    expect(r.draft?['content'], 'My latest');
    expect(r.baseRevision, 2);
    expect(r.conflicted, true);
    await r.useRemote();
    expect(r.note?.content, 'Peer next');
    expect(r.baseRevision, 3);
    expect(r.dirty, false);
    r.dispose();
    c.dispose();
  });

  test('Revoke hides content and preserves password-bound recovery; copy never mutates source', () async {
    final store = MemoryStore();
    final c = controller(store, basic);
    final r = reader(c);
    await r.unlock(password);
    await r.edit('Private local title', 'My revoked draft');
    c.notes = [];
    c.notifyListeners();
    await c.readProtectedEnvelope('n', 'A');
    expect(r.note, isNull);
    expect((await c.readProtectedEnvelope('n', 'A'))?['recovery_only'], true);
    final recovery = reader(c, recovery: true);
    await recovery.unlock(password);
    expect(recovery.canEdit, false);
    expect(recovery.serverGate, false);
    final id = await recovery.copyDraft();
    expect(id, isNot('n'));
    expect(c.drafts[id]?['content'], 'My revoked draft');
    expect(await recovery.copyDraft(), id);
    expect(c.pending, isEmpty);
    recovery.dispose();
    r.dispose();
    c.dispose();
  });

  test('Encrypted field merge survives ordinary snapshot capture and account switch mid-write', () async {
    final store = MemoryStore();
    final c = controller(store, basic);
    final gate = Completer<Map<String, dynamic>>();
    final encrypted = c.storeProtectedEnvelope('n', 'A', () => gate.future);
    final preference = c.setPreferences({'dark': true});
    gate.complete({'version': 1, 'ciphertext': 'cipher-only', 'dirty': true});
    await encrypted;
    await preference;
    expect(
      (await store.read('account:A'))?['protected_vaults']['n']['ciphertext'],
      'cipher-only',
    );
    final next = Completer<Map<String, dynamic>>();
    final pending = c.storeProtectedEnvelope('n', 'A', () => next.future);
    c.user = {'id': 'B'};
    c.protectedVaults = {};
    next.complete({'version': 1, 'ciphertext': 'new-cipher-A', 'dirty': true});
    await pending;
    expect(c.protectedVaults, isEmpty);
    expect(
      (await store.read('account:A'))?['protected_vaults']['n']['ciphertext'],
      'new-cipher-A',
    );
    c.dispose();
  });

  test('Delegated picker obscures content and rechecks grant before showing it again', () async {
    var revoked = false;
    final c = controller(MemoryStore(), (request) async {
      if (request.url.path.endsWith('/unlock')) {
        return response({'expires_in': 300});
      }
      if (request.url.path.endsWith('/lock')) return response({'ok': true});
      return revoked
          ? response({'detail': 'Unlock required'}, 423)
          : response(serverNote());
    });
    final r = reader(c);
    await r.unlock(password);
    await r.setPicking(true);
    c.setForeground(false);
    expect(r.obscured, true);
    expect(r.serverGate, false);
    c.setForeground(true);
    await r.setPicking(false);
    expect(r.obscured, false);
    expect(r.serverGate, true);
    await r.setPicking(true);
    c.setForeground(false);
    revoked = true;
    c.setForeground(true);
    await r.setPicking(false);
    expect(r.note, isNull);
    expect(r.serverGate, false);
    r.dispose();
    c.dispose();
  });
}
