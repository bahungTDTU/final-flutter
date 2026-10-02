import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/avatar_picker.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/avatar_editor.dart';
import 'package:note_together/ui/home.dart';

import 'support.dart';

final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgaGgAAAGEAQFWjyAjAAAAAElFTkSuQmCC',
);
Map<String, dynamic> profile({int revision = 0}) => {
  'id': 'A',
  'name': 'Avatar test',
  'email': 'a@example.test',
  'verified': true,
  'schema_version': 2,
  'has_avatar': revision > 0,
  'avatar_revision': revision,
  'preferences': <String, dynamic>{},
};
http.Response jsonResponse(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);
AppController controller(MockClient client, MemoryStore store) =>
    AppController(Api('http://test', client: client), store)
      ..user = profile()
      ..token = 'A-token'
      ..ready = true;
Future<void> idle(AppController c) async {
  for (var i = 0; i < 200; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (!c.syncing) return;
  }
  fail('Controller did not finish sync');
}

void main() {
  test('Legacy account migration retains immutable queued operation and stable ID after reopen', () async {
    final store = MemoryStore();
    final old = {
      'op_id': 'old-operation',
      'note_id': 'note',
      'kind': 'upsert',
      'base_revision': 0,
      'title': 'Draft',
      'content': 'Do not lose this',
      'labels': ['Học tập'],
    };
    store.values['session'] = {'user': profile(), 'token': 'A-token'};
    store.values['account:A'] = {
      'labels': ['Học tập'],
      'pending': [old],
      'notes': [
        const Note(
          id: 'note',
          title: 'Draft',
          content: 'Do not lose this',
          revision: 1,
          updatedAt: '',
          labels: ['Học tập'],
        ).toJson(),
      ],
    };
    final client = MockClient(
      (_) async => throw http.ClientException('offline'),
    );
    final c = AppController(Api('http://test', client: client), store);
    await c.initialize();
    await idle(c);
    expect(c.labels.single, 'legacy_f97af412f45c5d2eb29769c3af770164');
    expect(c.pending.single, old);
    expect(c.notes.single.labels, c.labels);
    expect(c.labelName(c.labels.single), 'Học tập');
    expect(c.pendingLabels.single['base_revision'], 0);
    final firstId = c.pendingLabels.single['op_id'];
    c.dispose();
    final reopened = AppController(Api('http://test', client: client), store);
    await reopened.initialize();
    await idle(reopened);
    expect(reopened.pendingLabels.single['op_id'], firstId);
    expect(reopened.pending.single, old);
    reopened.dispose();
  });

  test('Offline rename/delete retain note revisions, draft and frozen operations across reopen', () async {
    final store = MemoryStore();
    final c = offlineController(store: store);
    await c.addLabel('Học');
    await idle(c);
    final id = c.labels.single;
    await c.save('note', 'Title', 'Latest valid text', noteLabels: [id]);
    await idle(c);
    await c.draft('note', 'Title', 'Unfinished draft');
    final originalOp = jsonEncode(c.pending.single),
        originalLabel = jsonEncode(c.pendingLabels.single),
        revision = c.notes.single.revision;
    await c.renameLabel(id, 'Tên mới');
    await idle(c);
    expect(c.labels.single, id);
    expect(c.labelName(id), 'Tên mới');
    expect(jsonEncode(c.pending.single), originalOp);
    expect(jsonEncode(c.pendingLabels.first), originalLabel);
    await c.removeLabel(id);
    await idle(c);
    expect(c.labels, isEmpty);
    expect(c.noteLabelIds(c.notes.single), isEmpty);
    expect(c.notes.single.revision, revision);
    expect(c.notes.single.content, 'Latest valid text');
    expect(c.drafts['note']['content'], 'Unfinished draft');
    await store.write('session', {'user': c.user, 'token': c.token});
    c.dispose();
    final reopened = AppController(
      Api(
        'http://test',
        client: MockClient((_) async => throw http.ClientException('offline')),
      ),
      store,
    );
    await reopened.initialize();
    await idle(reopened);
    expect(reopened.pendingLabels.map((op) => op['base_revision']), [0, 1, 2]);
    expect(jsonEncode(reopened.pending.single), originalOp);
    expect(reopened.drafts['note']['content'], 'Unfinished draft');
    reopened.dispose();
  });

  test('Label edit during send persists next immutable revision and does not rewind displayed name', () async {
    var offline = true;
    final sending = Completer<void>(), reply = Completer<void>();
    final bodies = <Map<String, dynamic>>[];
    var remote = <dynamic>[];
    final c = controller(
      MockClient((request) async {
        if (offline) throw http.ClientException('offline');
        if (request.url.path == '/me') return jsonResponse(profile());
        if (request.url.path == '/labels') return jsonResponse(remote);
        if (request.url.path == '/notes') return jsonResponse([]);
        if (request.url.path == '/labels/sync') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          bodies.add(body);
          if (bodies.length == 1) {
            sending.complete();
            await reply.future;
          }
          remote = [
            {
              'id': body['label_id'],
              'name': body['name'],
              'revision': bodies.length,
              'deleted': false,
            },
          ];
          return jsonResponse(remote.single);
        }
        throw StateError('Unexpected request');
      }),
      MemoryStore(),
    );
    await c.addLabel('Initial');
    await idle(c);
    final id = c.labels.single;
    final original = jsonEncode(c.pendingLabels.single);
    offline = false;
    final sync = c.synchronize();
    await sending.future;
    await c.renameLabel(id, 'Edited while sending');
    reply.complete();
    await sync;
    expect(c.labelName(id), 'Edited while sending');
    expect(c.pendingLabels.single['base_revision'], 1);
    expect(jsonEncode(bodies.first), original);
    await c.synchronize();
    expect(bodies.length, 2);
    expect(c.pendingLabels, isEmpty);
    expect(c.labelName(id), 'Edited while sending');
    c.dispose();
  });

  test('Explicit duplicate-label resolution replaces operation ID and keeps content/draft', () async {
    var offline = true;
    final saved = <Map<String, dynamic>>[];
    final c = controller(
      MockClient((request) async {
        if (offline) throw http.ClientException('offline');
        if (request.url.path == '/me') return jsonResponse(profile());
        if (request.url.path == '/labels') {
          return jsonResponse([
            {
              'id': 'peer',
              'name': 'Shared name',
              'revision': 1,
              'deleted': false,
            },
          ]);
        }
        if (request.url.path == '/labels/sync') {
          return jsonResponse({
            'detail': {
              'message': 'Label name already exists',
              'remote': null,
              'duplicate': {'id': 'peer'},
            },
          }, 409);
        }
        if (request.url.path == '/sync') {
          saved.add(jsonDecode(request.body) as Map<String, dynamic>);
          return saved.last['labels'].contains('peer')
              ? jsonResponse({'revision': 1})
              : jsonResponse({'detail': 'Label unavailable'}, 422);
        }
        if (request.url.path == '/notes') {
          return jsonResponse([
            const Note(
              id: 'note',
              title: 'Title',
              content: 'Current valid content',
              revision: 1,
              updatedAt: '',
              labels: ['peer'],
            ).toJson(),
          ]);
        }
        throw StateError('Unexpected request');
      }),
      MemoryStore(),
    );
    await c.addLabel('Shared name');
    await idle(c);
    final id = c.labels.single;
    await c.save('note', 'Title', 'Current valid content', noteLabels: [id]);
    await idle(c);
    await c.draft('note', 'Title', 'Typing continued');
    final old = Map<String, dynamic>.from(c.pending.single);
    offline = false;
    await c.synchronize();
    expect(c.labelConflicts.containsKey(id), isTrue);
    expect(saved, isEmpty);
    offline = true;
    await c.useRemoteLabel(id);
    await idle(c);
    expect(c.pending.single['op_id'], isNot(old['op_id']));
    expect(c.pending.single['labels'], ['peer']);
    expect(c.pending.single['content'], old['content']);
    expect(c.pending.single['base_revision'], old['base_revision']);
    expect(old['labels'], [id]);
    expect(c.drafts['note']['content'], 'Typing continued');
    offline = false;
    await c.synchronize();
    expect(c.pending, isEmpty);
    expect(c.notes.single.content, 'Current valid content');
    c.dispose();
  });

  test('Uncreated conflicted label keeps note queued but still discovers remote lock and recovers draft', () async {
    var offline = true;
    var noteRequests = 0;
    final c = controller(
      MockClient((request) async {
        if (offline) throw http.ClientException('offline');
        if (request.url.path == '/me') return jsonResponse(profile());
        if (request.url.path == '/labels/sync') {
          return jsonResponse({
            'detail': {'message': 'Label name already exists', 'remote': null},
          }, 409);
        }
        if (request.url.path == '/labels') return jsonResponse([]);
        if (request.url.path == '/sync') {
          noteRequests++;
          return jsonResponse({'detail': 'Label unavailable'}, 422);
        }
        if (request.url.path == '/notes') {
          return jsonResponse([
            {'id': 'note', 'locked': true, 'revision': 2, 'role': 'owner'},
          ]);
        }
        throw StateError('Unexpected request');
      }),
      MemoryStore(),
    );
    c.notes = [
      const Note(
        id: 'note',
        title: 'Title',
        content: 'Server original',
        revision: 1,
        updatedAt: '',
      ),
    ];
    await c.addLabel('Conflicting new label');
    await idle(c);
    await c.save(
      'note',
      'Title',
      'Queued edit',
      baseRevision: 1,
      noteLabels: [c.labels.single],
    );
    await idle(c);
    await c.draft('note', 'Title', 'Typing after queued edit');
    offline = false;
    await c.synchronize();
    expect(c.notes.single.locked, isTrue);
    expect(c.recoveries.values.single['content'], 'Typing after queued edit');
    expect(c.pending, isEmpty);
    expect(c.drafts, isEmpty);
    expect(c.pendingLabels, hasLength(1));
    expect(noteRequests, 0);
    c.dispose();
  });

  test(
    'Avatar response after logout cannot write or display in another account',
    () async {
      final sent = Completer<void>(), response = Completer<void>();
      final store = MemoryStore();
      final c = controller(
        MockClient((request) async {
          if (request.url.path == '/me/avatar') {
            sent.complete();
            await response.future;
            return jsonResponse(profile(revision: 1));
          }
          if (request.url.path == '/auth/logout') {
            return jsonResponse({'ok': true});
          }
          throw StateError('Unexpected request');
        }),
        store,
      );
      final upload = c.updateAvatar(png, 'image/png');
      await sent.future;
      await c.logout();
      c.user = {...profile(), 'id': 'B'};
      c.token = 'B-token';
      response.complete();
      await upload;
      expect(c.user!['id'], 'B');
      expect(c.avatarBytes, isNull);
      expect(store.values['account:B'], isNull);
      c.dispose();
    },
  );

  test(
    'Canonical avatar is cached per account and restores while offline',
    () async {
      var currentProfile = profile();
      final store = MemoryStore();
      final c = controller(
        MockClient((request) async {
          if (request.method == 'POST') {
            currentProfile = profile(revision: 1);
            return jsonResponse(currentProfile);
          }
          return http.Response.bytes(
            png,
            200,
            headers: {'content-type': 'image/png'},
          );
        }),
        store,
      );
      await c.updateAvatar(png, 'image/png');
      expect(c.avatarBytes, png);
      c.dispose();
      final reopened = AppController(
        Api(
          'http://test',
          client: MockClient(
            (_) async => throw http.ClientException('offline'),
          ),
        ),
        store,
      );
      await reopened.initialize();
      await idle(reopened);
      expect(reopened.avatarBytes, png);
      expect(reopened.cachedAvatarRevision, 1);
      reopened.dispose();
    },
  );

  testWidgets('Avatar cancel/denied picker retains image and never uploads', (
    tester,
  ) async {
    final c = offlineController();
    c.avatarBytes = png;
    c.user!['has_avatar'] = true;
    var denied = false, picks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvatarEditor(
            controller: c,
            picker: () async {
              picks++;
              if (denied) throw PlatformException(code: 'permission_denied');
              return null;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('avatar-pick')));
    await tester.pumpAndSettle();
    expect(picks, 1);
    expect(c.avatarBytes, png);
    denied = true;
    await tester.tap(find.byKey(const Key('avatar-pick')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kiểm tra quyền truy cập'), findsOneWidget);
    expect(c.avatarBytes, png);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('avatar-upload')))
          .onPressed,
      isNull,
    );
    c.dispose();
  });

  testWidgets(
    'Avatar invalid-size error and selected file survive upload failure; mobile scale2 fits',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController();
      var tooLarge = true;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: AvatarEditor(
              controller: c,
              picker: () async => SelectedAvatar(
                'fixture.png',
                tooLarge ? Uint8List(2 * 1024 * 1024 + 1) : png,
                'image/png',
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.byKey(const Key('avatar-pick')));
      await tester.tap(find.byKey(const Key('avatar-pick')));
      await tester.pumpAndSettle();
      expect(find.text('Chọn ảnh tối đa 2 MiB'), findsOneWidget);
      expect(tester.takeException(), isNull);
      tooLarge = false;
      await tester.ensureVisible(find.byKey(const Key('avatar-pick')));
      await tester.tap(find.byKey(const Key('avatar-pick')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('avatar-upload')));
      await tester.tap(find.byKey(const Key('avatar-upload')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa xác nhận lưu ảnh.'), findsOneWidget);
      expect(find.textContaining('fixture.png'), findsOneWidget);
      expect(tester.takeException(), isNull);
      c.dispose();
    },
  );

  testWidgets(
    'Renaming keeps selected AND filter; deleting clears it without removing notes',
    (tester) async {
      final c = offlineController();
      c.labelCatalogue = {
        'id': {'id': 'id', 'name': 'Học', 'revision': 1, 'deleted': false},
      };
      c.labels = ['id'];
      c.notes = [
        const Note(
          id: 'one',
          title: 'Filtered note',
          content: 'Content',
          revision: 1,
          updatedAt: '',
          labels: ['id'],
        ),
        const Note(
          id: 'two',
          title: 'Other note',
          content: 'Content',
          revision: 1,
          updatedAt: '',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: AnimatedBuilder(
            animation: c,
            builder: (_, _) => HomeScreen(controller: c),
          ),
        ),
      );
      await tester.tap(find.widgetWithText(FilterChip, 'Học'));
      await tester.pumpAndSettle();
      expect(find.text('Other note'), findsNothing);
      await c.renameLabel('id', 'Đổi tên');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Đổi tên'))
            .selected,
        isTrue,
      );
      expect(find.text('Other note'), findsNothing);
      await c.removeLabel('id');
      await tester.pumpAndSettle();
      expect(c.notes.length, 2);
      expect(c.labels, isEmpty);
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -260),
      );
      await tester.pumpAndSettle();
      expect(find.text('Filtered note'), findsOneWidget);
      expect(find.text('Other note'), findsOneWidget);
      c.dispose();
    },
  );
}
