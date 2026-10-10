import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/focus_session.dart';
import 'package:note_together/domain/workspace.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/focus_panel.dart';
import 'package:note_together/ui/workspace.dart';

import 'support.dart';
import 'workspace_test.dart' show note;

class ControlledStore extends MemoryStore {
  bool fail = false;
  Completer<void>? gate, entered;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (key.startsWith('account:')) {
      final wait = gate;
      gate = null;
      if (wait != null) {
        entered?.complete();
        await wait.future;
      }
      if (fail) {
        fail = false;
        throw StateError('Không đủ dung lượng.');
      }
    }
    await super.write(key, value);
  }
}

void main() {
  test(
    'timer survives serialized reopen and pause excludes elapsed paused time',
    () async {
      final store = ControlledStore();
      final c = offlineController(store: store);
      addTearDown(c.dispose);
      final start = DateTime(2026, 10, 10, 23, 58);
      await c.startFocus(5, now: start);
      final original = c.workspace.focus.session!;
      await c.changeFocus(
        original.id,
        'pause',
        now: start.add(const Duration(minutes: 2)),
      );
      expect(
        c.workspace.focus.session!.remaining(
          start.add(const Duration(days: 1)),
        ),
        180,
      );
      final raw = (await store.read('account:A'))!['workspace'];
      final reopened = WorkspaceData.fromJson(jsonDecode(jsonEncode(raw)));
      expect(reopened.focus.session!.id, original.id);
      expect(reopened.focus.session!.running, false);
      final resume = start.add(const Duration(hours: 1));
      await c.changeFocus(original.id, 'resume', now: resume);
      await c.changeFocus(
        original.id,
        'finish',
        now: resume.add(const Duration(minutes: 3)),
      );
      await c.changeFocus(
        original.id,
        'finish',
        now: resume.add(const Duration(days: 1)),
      );
      expect(c.workspace.focus.completed, hasLength(1));
      expect(c.workspace.focus.onDay(DateTime(2026, 10, 11)), hasLength(1));
      expect(c.workspace.focus.onDay(DateTime(2026, 10, 10)), isEmpty);
    },
  );
  test('late reopen counts deadline day; unfinished reset and breaks earn no completion', () async {
    final c = offlineController();
    addTearDown(c.dispose);
    final start = DateTime(2026, 10, 10, 12);
    await c.startFocus(5, now: start);
    var id = c.workspace.focus.session!.id;
    await c.changeFocus(
      id,
      'finish',
      now: start.add(const Duration(minutes: 1)),
    );
    expect(c.workspace.focus.completed, isEmpty);
    await c.changeFocus(id, 'finish', now: start.add(const Duration(days: 2)));
    expect(c.workspace.focus.onDay(start), hasLength(1));
    await c.startFocus(5, breakTime: true, now: start);
    id = c.workspace.focus.session!.id;
    await c.changeFocus(
      id,
      'finish',
      now: start.add(const Duration(minutes: 6)),
    );
    expect(c.workspace.focus.completed, hasLength(1));
    await c.startFocus(25, now: start);
    await c.changeFocus(c.workspace.focus.session!.id, 'reset', now: start);
    expect(c.workspace.focus.completed, hasLength(1));
    await expectLater(c.startFocus(100), throwsStateError);
    await expectLater(c.setFocusGoal(0), throwsStateError);
  });
  test('completion failure retries durably and stale callbacks cannot finish a newer timer', () async {
    final store = ControlledStore();
    final c = offlineController(store: store);
    addTearDown(c.dispose);
    final start = DateTime(2026, 10, 10);
    await c.startFocus(5, now: start);
    final id = c.workspace.focus.session!.id;
    store.fail = true;
    await expectLater(
      c.changeFocus(id, 'finish', now: start.add(const Duration(minutes: 6))),
      throwsStateError,
    );
    expect(c.workspace.focus.session!.id, id);
    expect(c.workspace.focus.completed, isEmpty);
    await c.changeFocus(
      id,
      'finish',
      now: start.add(const Duration(minutes: 6)),
    );
    await c.startFocus(25, now: start);
    final next = c.workspace.focus.session!.id;
    await c.changeFocus(id, 'finish', now: start.add(const Duration(days: 1)));
    expect(c.workspace.focus.session!.id, next);
    expect(c.workspace.focus.completed, hasLength(1));
  });
  test('queued timer changes preserve drafts and cannot publish across account switch', () async {
    final store = ControlledStore();
    final c = offlineController(store: store);
    addTearDown(c.dispose);
    await c.startFocus(25);
    final id = c.workspace.focus.session!.id;
    store.gate = Completer<void>();
    final gate = store.gate!;
    store.entered = Completer<void>();
    final paused = c.changeFocus(id, 'pause');
    await store.entered!.future;
    final draft = c.draft('draft', 'Keep', 'New draft');
    gate.complete();
    await Future.wait([paused, draft]);
    final root = (await store.read('account:A'))!;
    expect(root['drafts']['draft']['content'], 'New draft');
    expect(root['workspace']['focus']['session']['ends_at'], isNull);
    store.gate = Completer<void>();
    final switchedGate = store.gate!;
    store.entered = Completer<void>();
    final change = c.setFocusGoal(8);
    final rejection = expectLater(change, throwsStateError);
    await store.entered!.future;
    c.user = {'id': 'B'};
    c.workspace = WorkspaceData();
    switchedGate.complete();
    await rejection;
    expect(c.workspace.focus.dailyGoal, 4);
    expect(await store.read('account:B'), isNull);
  });
  test('legacy workspace migrates and malformed timer data cannot create invalid progress', () {
    expect(WorkspaceData.fromJson({}).focus.dailyGoal, 4);
    final data = FocusData.fromJson({
      'goal': 100,
      'session': {
        'id': 'x',
        'break': false,
        'seconds': 0,
        'remaining': -1,
        'ends_at': 'wrong',
      },
      'completed': [
        {'id': 'x', 'at': 1, 'seconds': 300},
        {'id': 'x', 'at': 2, 'seconds': 300},
      ],
    });
    expect(data.session, isNull);
    expect(data.dailyGoal, 4);
    expect(data.completed, hasLength(1));
  });
  testWidgets(
    'failed template save retains input, retries and deletion requires confirmation',
    (tester) async {
      final store = ControlledStore();
      final c = offlineController(store: store)..notes = [note('a')];
      addTearDown(c.dispose);
      await c.recordRecent('a');
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: WorkspaceScreen(controller: c),
        ),
      );
      await tester.tap(find.text('Mẫu riêng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo mẫu riêng'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Mẫu giữ lại');
      store.fail = true;
      await tester.tap(find.text('Lưu mẫu'));
      await tester.pumpAndSettle();
      expect(find.text('Không đủ dung lượng.'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Mẫu giữ lại'), findsOneWidget);
      expect(c.workspace.templates, isEmpty);
      await tester.tap(find.text('Lưu mẫu'));
      await tester.pumpAndSettle();
      expect(c.workspace.templates.single.title, 'Mẫu giữ lại');
      await tester.tap(find.text('Xóa mẫu'));
      await tester.pumpAndSettle();
      expect(c.workspace.templates, hasLength(1));
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(c.workspace.templates, hasLength(1));
      await tester.tap(find.text('Xóa mẫu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(c.workspace.templates, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'task search and source scope preserve privacy and aggregate all statuses',
    (tester) async {
      final c = offlineController()
        ..notes = [
          note('own'),
          note('shared', role: 'viewer'),
          note('secret', locked: true),
        ];
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: WorkspaceScreen(controller: c),
        ),
      );
      await tester.tap(find.text('Công việc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tất cả trạng thái'));
      await tester.tap(find.text('Được chia sẻ'));
      await tester.pumpAndSettle();
      expect(find.text('1/2 hoàn thành · 2 kết quả'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('workspace-task-search')),
        'Title shared',
      );
      await tester.pumpAndSettle();
      expect(find.text('1/2 hoàn thành · 2 kết quả'), findsOneWidget);
      c.notes = [
        note('own'),
        note('shared', locked: true),
        note('secret', locked: true),
      ];
      c.notifyListeners();
      await tester.pump();
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0,
      );
      await tester.pumpAndSettle();
      expect(find.text('0/0 hoàn thành · 0 kết quả'), findsOneWidget);
      expect(find.textContaining('Title secret'), findsNothing);
      expect(
        find
            .text('Title shared', skipOffstage: false)
            .evaluate()
            .where((e) => e.widget is Text),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'mobile navigation and focus panel fit doubled text with keyboard; ticks do not pulse controller',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final c = offlineController();
      addTearDown(c.dispose);
      var pulses = 0;
      c.addListener(() => pulses++);
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.dark),
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 720),
              textScaler: TextScaler.linear(2),
              viewInsets: EdgeInsets.only(bottom: 200),
            ),
            child: child!,
          ),
          home: WorkspaceScreen(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<int>).first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Tập trung'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tập trung').last);
      await tester.pumpAndSettle();
      expect(find.byType(FocusPanel), findsOneWidget);
      final before = pulses;
      await tester.pump(const Duration(seconds: 2));
      expect(pulses, before);
      expect(tester.takeException(), isNull);
      c.user = {'id': 'B'};
      c.notifyListeners();
      await tester.pump();
      expect(find.byType(FocusPanel), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
