import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';

import 'support.dart';
import 'protected_editing_test.dart' as protected;

Future<void> settleSync(AppController c) async {
  while (c.syncing) {
    await Future<void>.delayed(Duration.zero);
  }
}

Note note(String id, {String title = 'Title', int revision = 1}) => Note(
  id: id,
  title: title,
  content: 'body',
  revision: revision,
  updatedAt: '2026-10-18',
);

void main() {
  testWidgets(
    'Editor keeps over-limit Unicode input as a draft and shows feedback',
    (tester) async {
      final c = offlineController()..notes = [note('n')];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await revealHome(tester, find.byKey(const ValueKey('card-n')));
      await tester.tap(find.byKey(const ValueKey('card-n')));
      await tester.pumpAndSettle();
      final title = '👨‍👩‍👧‍👦' * 50;
      await tester.enterText(find.byKey(const Key('note-title')), title);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(c.pending, isEmpty);
      expect(c.drafts['n']['title'], title);
      expect(c.notes.single.title, 'Title');
      expect(find.textContaining('Tiêu đề vượt giới hạn'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  test(
    'Protected 422 preserves immutable operation and exposes copy recovery',
    () async {
      final c = protected.controller(
        MemoryStore(),
        (request) async => request.url.path == '/sync'
            ? http.Response('{"detail":"invalid"}', 422)
            : protected.basic(request),
      );
      final r = protected.reader(c);
      addTearDown(() {
        r.dispose();
        c.dispose();
      });
      await r.unlock(protected.password);
      await r.edit('First draft', 'body');
      await r.flush();
      expect(r.conflicted, true);
      expect(r.error, contains('từ chối'));
      final sent = jsonEncode(r.operation);
      await r.edit('Latest draft', 'latest body');
      await r.flush();
      expect(jsonEncode(r.operation), sent);
      final copy = await r.copyDraft();
      expect(copy, isNotNull);
      expect(c.drafts[copy]['title'], 'Latest draft');
      expect(c.drafts[copy]['content'], 'latest body');
    },
  );

  test(
    'Unicode title boundaries use server code points; preserve invalid draft',
    () async {
      final store = MemoryStore();
      final c = offlineController(store: store);
      addTearDown(c.dispose);
      final family = '👨‍👩‍👧‍👦' * 50;
      expect(validNote(family, 'body'), false);
      expect(validNote('😀' * 200, 'body'), true);
      expect(validNote('e\u0301' * 100, 'body'), true);
      expect(validNote('e\u0301' * 101, 'body'), false);
      await c.save('invalid', family, 'body');
      expect(c.pending, isEmpty);
      expect(c.notes, isEmpty);
      expect(
        (await store.read('account:A'))!['drafts']['invalid']['title'],
        family,
      );
      await c.save('invalid', 'Corrected', 'body');
      await settleSync(c);
      expect(c.pending.single['title'], 'Corrected');
    },
  );

  test('422 is durable per-note quarantine; independent sync and ACL refresh continue', () async {
    final store = MemoryStore();
    final sent = <String>[];
    var refreshes = 0;
    final api = Api(
      'http://test',
      client: MockClient((request) async {
        if (request.url.path == '/sync') {
          final op = jsonDecode(request.body) as Map;
          sent.add(op['op_id'] as String);
          return op['note_id'] == 'bad'
              ? http.Response('{"detail":"invalid title"}', 422)
              : http.Response('{"revision":1}', 200);
        }
        if (request.url.path == '/notes') {
          refreshes++;
          return http.Response(
            jsonEncode([note('bad').toJson(), note('good').toJson()]),
            200,
          );
        }
        return http.Response('{"id":"A","preferences":{}}', 200);
      }),
    );
    var c = AppController(api, store)
      ..user = {'id': 'A'}
      ..token = 'token';
    Map<String, dynamic> op(String id, String key, int revision) => {
      'op_id': key,
      'note_id': id,
      'base_revision': revision,
      'kind': 'upsert',
      'title': id == 'bad' ? 'x' * 201 : 'Good',
      'content': 'body',
    };
    c.notes = [note('bad', title: 'latest local', revision: 3), note('good')];
    c.pending = [
      op('bad', 'rejected', 1),
      op('bad', 'dependent', 2),
      op('good', 'independent', 0),
    ];
    final original = jsonEncode(c.pending.take(2).toList());
    await c.draft('bad', 'latest draft', 'not lost');
    await c.synchronize();
    expect(sent, ['rejected', 'independent']);
    expect(refreshes, 1);
    expect(c.conflicts['bad']['status'], 422);
    expect(jsonEncode(c.pending), original);
    expect(c.drafts['bad']['content'], 'not lost');
    c.dispose();
    c = AppController(api, store);
    addTearDown(c.dispose);
    await c.initialize();
    await settleSync(c);
    expect(c.conflicts['bad']['status'], 422);
    expect(jsonEncode(c.pending), original);
    expect(sent, ['rejected', 'independent']);
    expect(refreshes, greaterThan(1));
  });

  test('Remote lock still archives local draft after a 422', () async {
    final c =
        AppController(
            Api(
              'http://test',
              client: MockClient((r) async {
                if (r.url.path == '/sync') {
                  return http.Response('{"detail":"invalid"}', 422);
                }
                if (r.url.path == '/notes') {
                  return http.Response(
                    '[{"id":"n","locked":true,"revision":4,"role":"owner","shared":false,"pinned_at":null}]',
                    200,
                  );
                }
                return http.Response('{"id":"A","preferences":{}}', 200);
              }),
            ),
            MemoryStore(),
          )
          ..user = {'id': 'A'}
          ..token = 'token';
    addTearDown(c.dispose);
    c.notes = [note('n')];
    c.pending = [
      {
        'op_id': 'rejected',
        'note_id': 'n',
        'base_revision': 1,
        'kind': 'upsert',
        'title': 'x' * 201,
        'content': 'body',
      },
    ];
    await c.draft('n', 'latest private title', 'latest private draft');
    await c.synchronize();
    expect(c.notes.single.locked, true);
    expect(c.notes.single.content, isEmpty);
    expect(c.pending, isEmpty);
    expect(c.recoveries.values.single['content'], 'latest private draft');
  });

  test('Conflict copy at the title limit is valid and gets a new immutable identity', () async {
    final c = offlineController();
    addTearDown(c.dispose);
    final title = 'a' * 200;
    c.notes = [note('n', title: title)];
    c.pending = [
      {
        'op_id': 'old',
        'note_id': 'n',
        'base_revision': 0,
        'kind': 'upsert',
        'title': title,
        'content': 'body',
      },
    ];
    c.conflicts['n'] = {'status': 409};
    await c.resolveConflict('n', keepCopy: true);
    final copy = c.pending.single;
    expect(copy['op_id'], isNot('old'));
    expect(copy['note_id'], isNot('n'));
    expect(copy['base_revision'], 0);
    expect((copy['title'] as String).runes.length, lessThanOrEqualTo(200));
    expect(copy['content'], 'body');
    expect(validNote(copy['title'] as String, copy['content'] as String), true);
    expect(
      recoveryNoteTitle('e\u0301' * 100),
      '${'e\u0301' * 92} (bản phục hồi)',
    );
  });

  test('31st label rejected before ordinary note or outbox mutation', () async {
    final c = offlineController();
    addTearDown(c.dispose);
    final labels = List.generate(30, (i) => 'label-$i');
    await c.save('n', 'Title', 'body', noteLabels: labels);
    await settleSync(c);
    final original = jsonEncode(c.pending);
    await expectLater(
      c.save('n', 'Title', 'body', noteLabels: [...labels, 'extra']),
      throwsArgumentError,
    );
    expect(c.notes.single.labels, labels);
    expect(jsonEncode(c.pending), original);
  });

  test(
    'Protected editor retains valid draft when a 31st label is requested',
    () async {
      final c = protected.controller(MemoryStore(), protected.basic);
      final r = protected.reader(c);
      addTearDown(() {
        r.dispose();
        c.dispose();
      });
      await r.unlock(protected.password);
      final labels = List.generate(30, (i) => 'label-$i');
      await r.edit('Title', 'draft', labels: labels);
      await r.edit('Title', 'changed', labels: [...labels, 'extra']);
      expect(r.draft!['labels'], labels);
      expect(r.draft!['content'], 'draft');
      expect(r.error, contains('30'));
    },
  );
}
