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
import 'package:note_together/state/note_listing.dart';
import 'package:note_together/ui/app.dart';
import 'package:sembast/sembast_io.dart';

import 'encrypted_recovery_test.dart' show TestKeys;
import 'support.dart';

Note hidden(String id, {String role = 'owner', String? pin}) =>
    Note.fromListingJson({
      'id': id,
      'revision': 2,
      'locked': true,
      'role': role,
      'pinned_at': pin,
      'shared': role != 'owner',
    });
Note ordinary(String id, String time, {String role = 'owner'}) => Note(
  id: id,
  title: id,
  content: 'Visible body',
  revision: 1,
  updatedAt: time,
  role: role,
);
NoteListing select(
  List<Note> notes, {
  bool shared = false,
  String query = '',
}) => NoteListingCache().select(
  account: 'A',
  notes: notes,
  query: query,
  shared: shared,
  labels: {},
  deletedLabels: {},
);

void main() {
  test('Mixed locked date order survives filtering and pin grouping without private dates', () {
    final notes = [
      hidden('new-locked'),
      ordinary('new-plain', '2025-03-01'),
      hidden('shared-new', role: 'editor'),
      hidden('tie-a'),
      ordinary('tie-b', '2025-02-01'),
      hidden('old-pin', pin: '2025-01-01'),
      hidden('shared-old', role: 'viewer'),
      ordinary('old-plain', '2025-01-01'),
    ];
    expect(select(notes).all.map((n) => n.id), [
      'old-pin',
      'new-locked',
      'new-plain',
      'tie-a',
      'tie-b',
      'old-plain',
    ]);
    expect(select(notes, shared: true).all.map((n) => n.id), [
      'shared-new',
      'shared-old',
    ]);
    expect(select(notes, query: 'body').all.map((n) => n.id), [
      'new-plain',
      'tie-b',
      'old-plain',
    ]);
    for (final note in notes.where((n) => n.locked)) {
      expect(note.updatedAt, isEmpty);
      expect(note.toListingJson().keys.toSet(), {
        'id',
        'locked',
        'revision',
        'role',
        'pinned_at',
        'shared',
      });
    }
    final cache = NoteListingCache();
    NoteListing cached(List<Note> source) => cache.select(
      account: 'A',
      notes: source,
      query: '',
      shared: false,
      labels: {},
      deletedLabels: {},
    );
    final first = cached(notes);
    expect(identical(first, cached(notes)), true);
    final updated = [notes.last, ...notes.take(notes.length - 1)];
    expect(cached(updated).remaining.first.id, 'old-plain');
  });

  test('Accepted order and offline optimistic edit survive encrypted file reopen and account switch', () async {
    final directory = await Directory.systemTemp.createTemp('note-ordering-');
    final filename = '${directory.path}/order.db';
    final keys = TestKeys();
    var db = await databaseFactoryIo.openDatabase(filename);
    final api = Api(
      'http://test',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    final initial = AppController(
      api,
      EncryptedAccountStore(SembastLocalStore(db), keys),
    );
    initial.setForeground(false);
    initial.user = {'id': 'A', 'name': 'A', 'email': 'a@example.test'};
    initial.token = 'fixture-session';
    initial.notes = [
      hidden('new-locked'),
      ordinary('older', '2025-01-01'),
      hidden('old-locked'),
    ];
    await initial.local.write('session', {
      'user': initial.user,
      'token': initial.token,
    });
    await initial.draft('scratch', 'Draft', 'Pending input');
    await initial.save(
      'older',
      'Edited offline',
      'Latest local text',
      baseRevision: 1,
    );
    await initial.synchronize();
    final immutable = jsonEncode(initial.pending);
    expect(select(initial.notes).remaining.map((n) => n.id), [
      'older',
      'new-locked',
      'old-locked',
    ]);
    initial.dispose();
    await db.close();
    final raw = await File(filename).readAsString();
    expect(raw, isNot(contains('Latest local text')));
    db = await databaseFactoryIo.openDatabase(filename);
    final reopened = AppController(
      api,
      EncryptedAccountStore(SembastLocalStore(db), keys),
    );
    reopened.setForeground(false);
    try {
      await reopened.initialize();
      await reopened.synchronize();
      expect(jsonEncode(reopened.pending), immutable);
      expect(select(reopened.notes).remaining.map((n) => n.id), [
        'older',
        'new-locked',
        'old-locked',
      ]);
      expect(
        reopened.notes.where((n) => n.locked).every((n) => n.updatedAt.isEmpty),
        true,
      );
      await reopened.logout();
      expect(reopened.notes, isEmpty);
      reopened.user = {'id': 'B', 'name': 'B', 'email': 'b@example.test'};
      reopened.token = 'other-fixture';
      await reopened.draft('b', 'B draft', 'B content');
      expect((await reopened.local.read('account:B'))!['notes'], isEmpty);
      expect((await reopened.local.read('account:A'))!['notes'].length, 3);
    } finally {
      reopened.dispose();
      await db.close();
      await directory.delete(recursive: true);
    }
  });

  test('In-flight refresh keeps late pending edit ahead, then ACK restores authoritative order', () async {
    final listingEntered = Completer<void>(),
        releaseListing = Completer<void>();
    var accepted = false;
    final locked = hidden('server-new');
    final old = ordinary('ordinary', '2025-01-01');
    final store = MemoryStore();
    final c = AppController(
      Api(
        'http://test',
        client: MockClient((request) async {
          if (request.url.path == '/me') {
            return http.Response(
              jsonEncode({'id': 'A', 'preferences': {}}),
              200,
            );
          }
          if (request.url.path == '/sync') return http.Response('{}', 200);
          if (request.url.path == '/notes') {
            if (!listingEntered.isCompleted) {
              listingEntered.complete();
              await releaseListing.future;
            }
            return http.Response(
              jsonEncode([
                locked.toListingJson(),
                (accepted ? ordinary('ordinary', '2025-02-01') : old)
                    .toListingJson(),
              ]),
              200,
            );
          }
          return http.Response('', 404);
        }),
      ),
      store,
    );
    c.setForeground(false);
    c.user = {'id': 'A', 'name': 'A'};
    c.token = 'fixture';
    c.notes = [locked, old];
    try {
      final sync = c.synchronize();
      await listingEntered.future;
      await c.save(
        'ordinary',
        'Local change',
        'Unacknowledged',
        baseRevision: 1,
      );
      final operation = jsonEncode(c.pending.single);
      releaseListing.complete();
      await sync;
      expect(select(c.notes).remaining.map((n) => n.id), [
        'ordinary',
        'server-new',
      ]);
      expect(jsonEncode(c.pending.single), operation);
      expect(c.notes.first.content, 'Unacknowledged');
      accepted = true;
      await c.synchronize();
      expect(c.pending, isEmpty);
      expect(select(c.notes).remaining.map((n) => n.id), [
        'server-new',
        'ordinary',
      ]);
      expect(
        (await store.read('account:A'))!['notes'][0]['updated_at'],
        isNull,
      );
    } finally {
      c.dispose();
    }
  });

  for (final grid in [true, false]) {
    testWidgets(
      'Home ${grid ? 'grid' : 'list'} renders locked newest before ordinary older',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final c = offlineController()..user!['verified'] = true;
        c.preferences['grid'] = grid;
        c.notes = [hidden('new-locked'), ordinary('old-plain', '2025-01-01')];
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(NoteTogetherApp(controller: c));
          await tester.pumpAndSettle();
          final locked = tester.getTopLeft(
            find.byKey(const ValueKey('card-new-locked')),
          );
          final plain = tester.getTopLeft(
            find.byKey(const ValueKey('card-old-plain')),
          );
          expect(
            locked.dy < plain.dy ||
                (locked.dy == plain.dy && locked.dx < plain.dx),
            true,
          );
          expect(find.text('2025-01-01'), findsNothing);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          semantics.dispose();
          c.dispose();
        }
      },
    );
  }
}
