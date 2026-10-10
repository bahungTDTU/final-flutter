import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note_plan.dart';
import 'package:note_together/domain/workspace.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/planner.dart';
import 'package:note_together/ui/workspace.dart';

import 'support.dart';
import 'workspace_test.dart' show note;
import 'workspace_polish_test.dart' show ControlledStore;

void main() {
  test('calendar deadlines reject normalization and use inclusive seven calendar days', () {
    expect(validPlanDay('2026-02-30'), false);
    expect(validPlanDay('2026-13-01'), false);
    expect(validPlanDay('2028-02-29'), true);
    final now = DateTime(2026, 10, 10, 23, 59);
    expect(const NotePlan('a', dueDay: '2026-10-09').overdue(now), true);
    expect(
      const NotePlan(
        'a',
        stage: PlanStage.done,
        dueDay: '2026-10-09',
      ).overdue(now),
      false,
    );
    expect(
      const NotePlan('a', dueDay: '2026-10-16').matches(PlanWindow.week, now),
      true,
    );
    expect(
      const NotePlan('a', dueDay: '2026-10-17').matches(PlanWindow.week, now),
      false,
    );
    expect(const NotePlan('a').matches(PlanWindow.today, now), false);
    final values = [
      const NotePlan('b'),
      const NotePlan('a'),
      const NotePlan('c', priority: PlanPriority.high),
      const NotePlan('d', dueDay: '2026-10-11'),
    ]..sort(comparePlans);
    expect(values.map((p) => p.noteId), ['c', 'd', 'a', 'b']);
    final restored = WorkspaceData.fromJson({
      'plans': [
        values[0].toJson(),
        {...values[0].toJson(), 'title': 'never stored'},
        {...values[1].toJson(), 'dueDay': '2026-02-30'},
        {...values[2].toJson(), 'stage': 'unknown'},
        1,
      ],
    });
    expect(restored.plans.keys, ['c']);
    expect(jsonEncode(restored.toJson()), isNot(contains('never stored')));
    expect(
      WorkspaceData.fromJson({'plans': 'bad legacy field'}).plans,
      isEmpty,
    );
  });

  test('plan failure retries durably; move merges latest deadline and preserves draft/focus', () async {
    final store = ControlledStore();
    final c = offlineController(store: store)
      ..notes = [note('a', role: 'viewer')];
    addTearDown(c.dispose);
    await c.recordRecent('a');
    await c.startFocus(5);
    final session = c.workspace.focus.session!.id;
    store.fail = true;
    await expectLater(
      c.saveNotePlan('a', dueDay: '2026-10-10'),
      throwsStateError,
    );
    expect(c.workspace.plans, isEmpty);
    await c.saveNotePlan(
      'a',
      priority: PlanPriority.high,
      dueDay: '2026-10-10',
    );
    final gate = Completer<void>();
    store.gate = gate;
    store.entered = Completer<void>();
    final edit = c.saveNotePlan(
      'a',
      priority: PlanPriority.low,
      dueDay: '2026-10-11',
    );
    await store.entered!.future;
    final move = c.moveNotePlan('a', PlanStage.active);
    final draft = c.draft('draft', 'Retain draft', 'Keep this body');
    gate.complete();
    await Future.wait([edit, move, draft]);
    final root = (await store.read('account:A'))!;
    final reopened = WorkspaceData.fromJson(
      jsonDecode(jsonEncode(root['workspace'])),
    );
    expect(reopened.plans['a']!.stage, PlanStage.active);
    expect(reopened.plans['a']!.priority, PlanPriority.low);
    expect(reopened.plans['a']!.dueDay, '2026-10-11');
    expect(reopened.focus.session!.id, session);
    expect(root['drafts']['draft']['content'], 'Keep this body');
    expect(c.notes.single.role, 'viewer');
    expect(c.notes.single.revision, 1);
    expect(c.pending, isEmpty);
    expect(jsonEncode(root['workspace']), isNot(contains('Title a')));
    await c.removeNotePlan('a');
    await c.removeNotePlan('a');
    await expectLater(c.moveNotePlan('a', PlanStage.done), throwsStateError);
    expect(c.notes, hasLength(1));
  });

  test('queued plan validates lock/revoke; account switch cannot publish into another account', () async {
    for (final condition in ['lock', 'revoke', 'account']) {
      final store = ControlledStore();
      final c = offlineController(store: store)..notes = [note('a')];
      await c.recordRecent('a');
      final gate = Completer<void>();
      store.gate = gate;
      store.entered = Completer<void>();
      final first = c.setFocusGoal(7);
      final firstResult = condition == 'account'
          ? expectLater(first, throwsStateError)
          : first;
      await store.entered!.future;
      final plan = c.saveNotePlan('a');
      final rejected = expectLater(plan, throwsStateError);
      if (condition == 'lock') c.notes = [note('a', locked: true)];
      if (condition == 'revoke') c.accessUnavailable.add('a');
      if (condition == 'account') {
        c.user = {'id': 'B'};
        c.workspace = WorkspaceData();
      }
      gate.complete();
      await firstResult;
      await rejected;
      expect(c.workspace.plans, isEmpty);
      expect(await store.read('account:B'), isNull);
      c.dispose();
    }
  });

  testWidgets(
    'plan form keeps priority/deadline after disk failure; move and remove are personal',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1100);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final store = ControlledStore();
      final c = offlineController(store: store)
        ..notes = [note('a', role: 'viewer')];
      addTearDown(c.dispose);
      await c.recordRecent('a');
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: WorkspaceScreen(controller: c),
        ),
      );
      await tester.tap(find.text('Kế hoạch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm vào kế hoạch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Title a'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<PlanPriority>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cao').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hôm nay').last);
      await tester.pumpAndSettle();
      store.fail = true;
      await tester.tap(find.text('Lưu kế hoạch'));
      await tester.pumpAndSettle();
      expect(find.text('Không đủ dung lượng.'), findsOneWidget);
      expect(find.text('Cao'), findsOneWidget);
      expect(find.textContaining('Hạn:'), findsOneWidget);
      await tester.tap(find.text('Lưu kế hoạch'));
      await tester.pumpAndSettle();
      expect(c.workspace.plans['a']!.priority, PlanPriority.high);
      expect(c.workspace.plans['a']!.dueDay, planDay(DateTime.now()));
      final menu = find.byTooltip('Thao tác kế hoạch Title a');
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chuyển sang Đang làm'));
      await tester.pumpAndSettle();
      expect(c.workspace.plans['a']!.stage, PlanStage.active);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ khỏi kế hoạch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(c.workspace.plans, hasLength(1));
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ khỏi kế hoạch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ khỏi kế hoạch').last);
      await tester.pumpAndSettle();
      expect(c.workspace.plans, isEmpty);
      expect(c.notes, hasLength(1));
      expect(c.pending, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'remote lock immediately removes private cards during entry and clears open calendar',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1100);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final c = offlineController()..notes = [note('private')];
      addTearDown(c.dispose);
      await c.saveNotePlan(
        'private',
        stage: PlanStage.done,
        dueDay: '2031-02-28',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.dark),
          home: WorkspaceScreen(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kế hoạch'));
      await tester.pump(const Duration(milliseconds: 40));
      c.notes = [note('private', locked: true)];
      c.notifyListeners();
      await tester.pump();
      expect(find.text('Title private', skipOffstage: false), findsNothing);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0,
      );
      expect(
        find.textContaining('28/2/2031', skipOffstage: false),
        findsNothing,
      );
      c.notes = [note('private')];
      c.notifyListeners();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Thao tác kế hoạch Title private'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ưu tiên và ngày hạn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hạn: 28/2/2031'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      c.accessUnavailable.add('private');
      c.notifyListeners();
      await tester.pump();
      expect(find.byType(DatePickerDialog, skipOffstage: false), findsNothing);
      expect(
        find.textContaining('28/2/2031', skipOffstage: false),
        findsNothing,
      );
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(
        find.byType(DropdownButton<PlanPriority>, skipOffstage: false),
        findsNothing,
      );
      expect(
        c.workspace.plans,
        hasLength(1),
      ); // IDs/metadata remain encrypted, content excluded.
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'mobile doubled text with keyboard remains scrollable; picker purges locked content',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final c = offlineController()..notes = [note('a'), note('b')];
      addTearDown(c.dispose);
      final view = PlannerViewState();
      addTearDown(view.dispose);
      await c.saveNotePlan('a', dueDay: '2026-10-10');
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.dark),
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 720),
              textScaler: TextScaler.linear(2),
              viewInsets: EdgeInsets.only(bottom: 180),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: PlannerSliver(
                    controller: c,
                    view: view,
                    onOpen: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thêm vào kế hoạch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm vào kế hoạch'));
      await tester.pumpAndSettle();
      expect(find.text('Title b'), findsOneWidget);
      c.notes = [note('a'), note('b', locked: true)];
      c.notifyListeners();
      await tester.pump();
      expect(find.text('Title b', skipOffstage: false), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextField, 'Tìm ghi chú để lên kế hoạch'),
        'Private account A query',
      );
      c.user = {'id': 'B'};
      c.notifyListeners();
      await tester.pump();
      expect(
        find.widgetWithText(
          TextField,
          'Private account A query',
          skipOffstage: false,
        ),
        findsNothing,
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'desktop columns build rows lazily and motion settles; filters survive tab changes',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 960);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final c = offlineController()
        ..notes = List.generate(500, (i) => note('n$i'));
      addTearDown(c.dispose);
      c.workspace = WorkspaceData(
        plans: {for (final n in c.notes) n.id: NotePlan(n.id)},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: WorkspaceScreen(controller: c),
        ),
      );
      await tester.tap(find.text('Kế hoạch'));
      await tester.pumpAndSettle();
      expect(find.byType(PrismCard).evaluate().length, lessThan(30));
      expect(find.text('Title n99'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextField, 'Tìm trong kế hoạch'),
        'n99',
      );
      await tester.pumpAndSettle();
      expect(find.text('Title n99'), findsOneWidget);
      await tester.tap(find.text('Yêu thích'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kế hoạch'));
      await tester.pumpAndSettle();
      expect(find.text('Title n99'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
