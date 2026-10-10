import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/domain/note_document.dart';
import 'package:note_together/domain/workspace.dart';
import 'package:note_together/domain/note_plan.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/workspace.dart';
import 'package:sembast/sembast_io.dart';

import 'support.dart';

Note note(
  String id, {
  String role = 'owner',
  String content = '- [ ] task\n- [x] done',
  bool locked = false,
  int revision = 1,
}) => Note(
  id: id,
  title: 'Title $id',
  content: content,
  revision: revision,
  updatedAt: '2026-10-10T10:00:00Z',
  role: role,
  locked: locked,
);

class Keys implements RecoveryKeyStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class DelayedStore extends MemoryStore {
  Completer<void>? wait, entered;
  bool failNext = false;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key.startsWith('account:')) {
      final pause = wait;
      wait = null;
      if (pause != null) {
        entered?.complete();
        await pause.future;
      }
      if (failNext) {
        failNext = false;
        throw StateError('disk full');
      }
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
  testWidgets(
    'quick find stays scrollable with keyboard at 200 percent in portrait and landscape',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = offlineController()
        ..notes = [note('visible'), note('hidden', locked: true)];
      for (final size in [const Size(390, 844), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        tester.view.viewInsets = const FakeViewPadding(bottom: 250);
        await tester.pumpWidget(
          MaterialApp(
            theme: noteTheme(Brightness.light),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showQuickFind(context, c),
                  child: const Text('Tìm nhanh'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Tìm nhanh'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('workspace-quick-query')),
          'visible',
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Title hidden'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      }
      c.dispose();
    },
  );
  testWidgets(
    'task controls have accessible labels and collection label picker stays lazy',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final c = offlineController()
        ..notes = [note('a')]
        ..labels = List.generate(1000, (i) => 'label-$i');
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: WorkspaceScreen(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Công việc'));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await tester.tap(find.text('Bộ sưu tập'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo bộ sưu tập'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn nhãn (0/30)'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile).evaluate().length, lessThan(25));
      await tester.enterText(
        find.byKey(const Key('label-filter-search')),
        '999',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'label-999'));
      await tester.tap(find.byKey(const Key('apply-label-filter')));
      await tester.pumpAndSettle();
      expect(find.text('label-999'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
      c.dispose();
    },
  );
  test(
    'portable roundtrip preserves Quill styles and checklist, strips metadata',
    () {
      final rich = storeDocumentDelta([
        {
          'insert': 'Styled',
          'attributes': {'bold': true},
        },
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
      ]);
      final source = note('private-id', content: rich);
      final encoded = encodeNoteBundle([source]);
      expect(
        jsonDecode(utf8.decode(encoded))['notes'][0].containsKey('id'),
        false,
      );
      expect(jsonDecode(utf8.decode(encoded))['notes'][0].keys.toSet(), {
        'title',
        'content',
      });
      final decoded = decodeNoteBundle(encoded).single;
      expect(decoded.content, rich);
      expect(decoded.title, source.title);
    },
  );
  test('bundle rejects permission injection, malformed rich content and size/count abuse', () {
    List<int> bundle(dynamic items) => utf8.encode(
      jsonEncode({
        'format': 'notetogether-notes',
        'version': 1,
        'notes': items,
      }),
    );
    for (final field in [
      'id',
      'owner_id',
      'role',
      'locked',
      'revision',
      'grant',
      'labels',
    ]) {
      expect(
        () => decodeNoteBundle(
          bundle([
            {'title': 'ok', 'content': 'body', field: 'injected'},
          ]),
        ),
        throwsFormatException,
      );
    }
    expect(
      () => decodeNoteBundle(
        bundle([
          {'title': 'ok', 'content': '${noteDocumentPrefix}invalid'},
        ]),
      ),
      throwsFormatException,
    );
    expect(
      () => decodeNoteBundle(
        bundle(List.generate(51, (_) => {'title': 'ok', 'content': 'body'})),
      ),
      throwsFormatException,
    );
    expect(
      () => decodeNoteBundle(List.filled(5 * 1024 * 1024 + 1, 32)),
      throwsFormatException,
    );
    expect(() => decodeNoteBundle(bundle([])), throwsFormatException);
  });
  test('export refuses protected and non-owner notes', () {
    for (final n in [
      note('lock', locked: true),
      note('viewer', role: 'viewer'),
      note('editor', role: 'editor'),
    ]) {
      expect(() => encodeNoteBundle([n]), throwsFormatException);
    }
  });
  test(
    'saved collection matches AND labels and source while excluding locked',
    () {
      final view = WorkspaceView(
        'v',
        'Tasks',
        'task',
        labels: {'one', 'two'},
        shared: true,
      );
      const candidate = Note(
        id: 'n',
        title: 'Plan',
        content: 'task',
        labels: ['one', 'two'],
        role: 'editor',
        revision: 1,
        updatedAt: '',
      );
      expect(view.matches(candidate), true);
      expect(view.matches(note('owner')), false);
      expect(view.matches(note('viewer', role: 'viewer')), false);
      expect(view.matches(note('lock', locked: true, role: 'editor')), false);
    },
  );
  test('task cache purges locked/revoked source and invalidates changed rich document', () {
    final cache = WorkspaceTaskCache();
    expect(cache.select([note('a')]).length, 2);
    expect(cache.select([note('a', locked: true)]), isEmpty);
    expect(cache.select([]), isEmpty);
    final rich = storeDocumentDelta([
      {'insert': 'new'},
      {
        'insert': '\n',
        'attributes': {'list': 'checked'},
      },
    ]);
    expect(cache.select([note('a', content: rich)]).single.task.done, true);
    expect(cache.select(List.generate(201, (i) => note('$i'))).length, 400);
  });
  test('concurrent favorites and recent writes preserve draft/vault and ordinary snapshots', () async {
    final store = DelayedStore();
    final c = offlineController(store: store);
    addTearDown(c.dispose);
    c.notes = [note('a'), note('b')];
    await c.draft('draft', 'Private draft', 'Keep this');
    final wait = Completer<void>();
    store.wait = wait;
    store.entered = Completer<void>();
    final favorite = c.toggleFavorite('a');
    await store.entered!.future;
    final recent = c.recordRecent('b');
    final ordinary = c.draft('draft', 'New draft', 'New body');
    final vault = c.storeProtectedEnvelope(
      'protected',
      'A',
      () async => {'ciphertext': 'vault-value'},
    );
    wait.complete();
    await Future.wait([favorite, recent, ordinary, vault]);
    final durable = (await store.read('account:A'))!;
    expect(durable['workspace']['favorites'], ['a']);
    expect(durable['workspace']['recent'], ['b']);
    expect(durable['drafts']['draft']['content'], 'New body');
    expect(
      durable['protected_vaults']['protected']['ciphertext'],
      'vault-value',
    );
    expect(c.workspace.favorites, {'a'});
  });
  test('workspace metadata contains IDs only; failed writes do not update favorites', () async {
    final store = DelayedStore();
    final c = offlineController(store: store);
    addTearDown(c.dispose);
    c.notes = [note('a')];
    await c.recordRecent('a');
    store.failNext = true;
    await expectLater(c.toggleFavorite('a'), throwsStateError);
    expect(c.workspace.favorites, isEmpty);
    expect(
      jsonEncode((await store.read('account:A'))!['workspace']),
      isNot(contains('Title a')),
    );
    c.notes = [note('a', locked: true)];
    await expectLater(c.toggleFavorite('a'), throwsStateError);
    await c.recordRecent('a');
    expect(c.workspaceNotes, isEmpty);
  });
  test('account switch during queued workspace write never publishes into another account', () async {
    final store = DelayedStore();
    final c = offlineController(store: store);
    addTearDown(c.dispose);
    c.notes = [note('a')];
    await c.recordRecent('a');
    final wait = Completer<void>();
    store.wait = wait;
    store.entered = Completer<void>();
    final favorite = c.toggleFavorite('a');
    final failed = expectLater(favorite, throwsStateError);
    await store.entered!.future;
    c.user = {'id': 'B'};
    c.workspace = WorkspaceData();
    wait.complete();
    await failed;
    expect(c.workspace.favorites, isEmpty);
    expect(await store.read('account:B'), isNull);
    expect((await store.read('account:A'))!['workspace']['favorites'], ['a']);
  });
  test('personal workspace is encrypted on disk and reopens across controller restart', () async {
    final dir = await Directory.systemTemp.createTemp(
      'notetogether-workspace-',
    );
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/local.db';
    final keys = Keys();
    var db = await databaseFactoryIo.openDatabase(path);
    var storage = EncryptedAccountStore(SembastLocalStore(db), keys);
    final api = Api(
      'http://test',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    final c = AppController(api, storage)
      ..user = {'id': 'A'}
      ..token = 'test'
      ..ready = true
      ..notes = [note('a')];
    await c.toggleFavorite('a');
    await c.recordRecent('a');
    await c.saveWorkspaceView('Secret collection', 'task', {});
    await c.saveNotePlan(
      'a',
      priority: PlanPriority.high,
      dueDay: '2031-02-28',
    );
    await c.savePersonalTemplate(
      'Secret template',
      'Private description',
      'Private template content',
    );
    await storage.write('session', {
      'user': {'id': 'A'},
      'token': 'test',
    });
    c.dispose();
    await db.close();
    final raw = await File(path).readAsString();
    for (final secret in [
      'Secret collection',
      'Secret template',
      'Private template content',
      'Title a',
      '2031-02-28',
    ]) {
      expect(raw, isNot(contains(secret)));
    }
    db = await databaseFactoryIo.openDatabase(path);
    storage = EncryptedAccountStore(SembastLocalStore(db), keys);
    final reopened = AppController(api, storage);
    await reopened.initialize();
    await idle(reopened);
    expect(reopened.workspace.favorites, {'a'});
    expect(reopened.workspace.recent, ['a']);
    expect(reopened.workspace.plans['a']!.priority, PlanPriority.high);
    expect(reopened.workspace.plans['a']!.dueDay, '2031-02-28');
    expect(
      reopened.workspace.templates.single.content,
      'Private template content',
    );
    expect(reopened.workspace.views.single.name, 'Secret collection');
    await reopened.logout();
    expect(reopened.workspace.templates, isEmpty);
    expect(reopened.workspace.plans, isEmpty);
    reopened.dispose();
    await db.close();
  });
  test('task toggle preserves frozen revision, labels and formatting; stale or pending input is refused', () async {
    final c = offlineController();
    addTearDown(c.dispose);
    final rich = storeDocumentDelta([
      {
        'insert': 'task',
        'attributes': {'bold': true},
      },
      {
        'insert': '\n',
        'attributes': {'list': 'unchecked'},
      },
    ]);
    c.notes = [note('a', content: rich, revision: 7)];
    final row = WorkspaceTaskCache().select(c.notes).single;
    await c.toggleWorkspaceTask(row);
    await idle(c);
    expect(c.pending.single['base_revision'], 7);
    expect(
      storedDocumentDelta(c.notes.single.content)![0]['attributes']['bold'],
      true,
    );
    expect(WorkspaceTaskCache().select(c.notes).single.task.done, true);
    await expectLater(c.toggleWorkspaceTask(row), throwsStateError);
  });
  test('viewer, dirty draft, conflict, revoked and changed revision cannot toggle tasks', () async {
    for (final condition in [
      'viewer',
      'draft',
      'conflict',
      'revoked',
      'revision',
      'locked',
    ]) {
      final c = offlineController();
      c.notes = [note('a')];
      final row = WorkspaceTaskCache().select(c.notes).first;
      switch (condition) {
        case 'viewer':
          c.notes = [note('a', role: 'viewer')];
        case 'draft':
          c.drafts['a'] = {'content': 'new draft'};
        case 'conflict':
          c.conflicts['a'] = {'status': 409};
        case 'revoked':
          c.accessUnavailable.add('a');
        case 'revision':
          c.notes = [note('a', revision: 2)];
        case 'locked':
          c.notes = [note('a', locked: true)];
      }
      await expectLater(c.toggleWorkspaceTask(row), throwsStateError);
      expect(c.pending, isEmpty);
      c.dispose();
    }
  });
  test('import is durable before network, uses fresh IDs and immutable retry operations', () async {
    final store = DelayedStore();
    var syncCalls = 0;
    final c =
        AppController(
            Api(
              'http://test',
              client: MockClient((req) async {
                if (req.url.path == '/sync') {
                  syncCalls++;
                }
                throw http.ClientException('offline');
              }),
            ),
            store,
          )
          ..user = {'id': 'A'}
          ..token = 'test'
          ..ready = true;
    addTearDown(c.dispose);
    final wait = Completer<void>();
    store.wait = wait;
    store.entered = Completer<void>();
    final imported = c.importNotes([
      const PortableNote('One', 'Body'),
      const PortableNote('Two', 'More'),
    ]);
    await store.entered!.future;
    expect(syncCalls, 0);
    expect(await store.read('account:A'), isNull);
    wait.complete();
    final ids = await imported;
    await idle(c);
    expect(ids.toSet().length, 2);
    expect(ids, everyElement(matches(RegExp(r'^[0-9a-f-]{36}$'))));
    final before = jsonEncode(c.pending);
    await c.synchronize();
    expect(jsonEncode(c.pending), before);
    final durable = (await store.read('account:A'))!;
    expect(durable['notes'].length, 2);
    expect(durable['pending'].length, 2);
    expect(
      c.pending.every(
        (op) =>
            op['base_revision'] == 0 &&
            !op.containsKey('owner_id') &&
            !op.containsKey('role'),
      ),
      true,
    );
  });
  test(
    'failed import rolls back only its batch and never starts network',
    () async {
      final store = DelayedStore();
      final c = offlineController(store: store);
      addTearDown(c.dispose);
      c.notes = [note('existing')];
      await c.recordRecent('existing');
      store.failNext = true;
      await expectLater(
        c.importNotes([const PortableNote('New', 'Body')]),
        throwsStateError,
      );
      expect(c.notes.single.id, 'existing');
      expect(c.pending, isEmpty);
      expect(c.syncing, false);
      expect((await store.read('account:A'))!['notes'].length, 1);
    },
  );
  test('template and collection CRUD update without duplicates and require validation', () async {
    final c = offlineController();
    addTearDown(c.dispose);
    await c.savePersonalTemplate('Meeting', 'Reusable', '## Plan');
    final id = c.workspace.templates.single.id;
    await c.savePersonalTemplate('Meeting v2', '', '## Next', id: id);
    expect(c.workspace.templates.length, 1);
    await expectLater(c.savePersonalTemplate('', '', 'body'), throwsStateError);
    await c.deletePersonalTemplate(id);
    expect(c.workspace.templates, isEmpty);
    await c.saveWorkspaceView('Tasks', 'task', {});
    final viewId = c.workspace.views.single.id;
    await c.saveWorkspaceView('Updated', '', {}, id: viewId);
    expect(c.workspace.views.length, 1);
    await expectLater(
      c.saveWorkspaceView('Bad', '', {'missing-label'}),
      throwsStateError,
    );
    await c.deleteWorkspaceView(viewId);
    expect(c.workspace.views, isEmpty);
  });

  testWidgets(
    'workspace tabs/dialogs fit 320px at 200% text and hide locked sources',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController();
      addTearDown(c.dispose);
      c.notes = [note('visible'), note('HIDDEN', locked: true)];
      c.workspace = WorkspaceData(
        favorites: {'visible', 'HIDDEN'},
        recent: ['HIDDEN', 'visible'],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 720),
              textScaler: TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: WorkspaceScreen(controller: c),
        ),
      );
      for (final title in [
        'Yêu thích',
        'Gần đây',
        'Bộ sưu tập',
        'Công việc',
        'Mẫu riêng',
        'Nhập / xuất',
      ]) {
        final navigation = find.byType(DropdownButton<int>).first;
        await tester.ensureVisible(navigation);
        await tester.tap(navigation);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(title).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(title).last);
        await tester.pumpAndSettle();
        expect(find.textContaining('HIDDEN'), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await tester.scrollUntilVisible(
        find.text('Xuất ghi chú'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xuất ghi chú'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Title visible'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Title visible'), findsOneWidget);
      expect(tester.takeException(), isNull);
      c.notes = [note('visible', locked: true), note('HIDDEN', locked: true)];
      c.notifyListeners();
      await tester.pump();
      expect(find.text('Title visible'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Ctrl+K palette favorites update live and purge protected content',
    (tester) async {
      final c = offlineController();
      addTearDown(c.dispose);
      c.notes = [note('visible'), note('hidden', locked: true)];
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: WorkspaceScreen(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workspace-quick-query')), findsOneWidget);
      expect(find.text('Title hidden'), findsNothing);
      await tester.tap(find.byTooltip('Yêu thích'));
      await tester.pumpAndSettle();
      expect(c.workspace.favorites, {'visible'});
      c.notes = [note('visible', locked: true)];
      c.notifyListeners();
      await tester.pump();
      expect(find.text('Title visible'), findsNothing);
      c.user = {'id': 'B'};
      c.notifyListeners();
      await tester.pump();
      expect(find.text('Phiên đăng nhập đã thay đổi.'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('task list builds only visible rows for a large workspace', (
    tester,
  ) async {
    final c = offlineController();
    addTearDown(c.dispose);
    c.notes = List.generate(
      200,
      (i) => note(
        '$i',
        content: List.generate(100, (j) => '- [ ] task $i:$j').join('\n'),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: noteTheme(Brightness.light),
        home: WorkspaceScreen(controller: c),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Công việc'));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox).evaluate().length, lessThan(20));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
