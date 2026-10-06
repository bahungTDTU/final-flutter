import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/domain/writing_tools.dart';
import 'package:note_together/state/focus_session.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/editor.dart';
import 'package:note_together/ui/writing_studio.dart';

import 'support.dart';

Note note({int revision = 5, String role = 'owner', bool locked = false}) =>
    Note(
      id: 'n',
      title: 'Việc nhóm',
      content: '# Ý chính\n😀 Bài học\n- [ ] Việc thật',
      updatedAt: '2026-10-06',
      revision: revision,
      role: role,
      locked: locked,
    );

Future<void> expandTools(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('writing-outline')));
  await tester.tap(find.byKey(const Key('writing-outline')));
  await tester.pumpAndSettle();
}

void main() {
  test('Analysis ignores fenced examples and edits exact UTF16 marker; refuses stale text', () {
    const text =
        '# C#\r\n😀 tiếng Việt\n```md\n# Fake\n- [ ] Fake\n````\n'
        '## Thật ###\n- [ ] Việc thật\n* [X] Xong\n~~~\n- [ ] Example\n~~~\n';
    final snapshot = WritingSnapshot(text);
    expect(snapshot.headings.map((h) => h.text), ['C#', 'Thật']);
    expect(snapshot.tasks.map((t) => t.text), ['Việc thật', 'Xong']);
    expect(snapshot.completed, 1);
    expect(text[snapshot.tasks.first.markerOffset], ' ');
    expect(
      toggleWritingTask(text, text, snapshot.tasks.first),
      text.replaceFirst('- [ ] Việc thật', '- [x] Việc thật'),
    );
    expect(
      toggleWritingTask(text, 'prefix\n$text', snapshot.tasks.first),
      isNull,
    );
    final large = WritingSnapshot(List.filled(120, '- [ ] Việc').join('\n'));
    expect(large.taskCount, 120);
    expect(large.tasks.length, 100);
  });

  testWidgets(
    'Template cancel is inert; explicit choice persists one editable account draft',
    (tester) async {
      final store = MemoryStore();
      final c = offlineController(store: store)..online = false;
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-templates')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(c.drafts, isEmpty);
      await tester.tap(find.byKey(const Key('note-templates')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('template-meeting')));
      await tester.tap(find.byKey(const Key('use-template')));
      await tester.pumpAndSettle();
      final id = c.drafts.keys.single;
      expect(c.notes, isEmpty);
      expect(c.pending, isEmpty);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-title')))
            .controller!
            .text,
        'Biên bản cuộc họp',
      );
      expect(
        (await store.read('account:A'))?['drafts'][id]['content'],
        contains('## Quyết định'),
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'Late template choice cannot create a draft in a different account',
    (tester) async {
      final c = offlineController();
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-templates')));
      await tester.pumpAndSettle();
      c.user = {...c.user!, 'id': 'B'};
      await tester.tap(find.byKey(const Key('use-template')));
      await tester.pumpAndSettle();
      expect(c.drafts, isEmpty);
      expect(find.byType(EditorScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'Checklist keeps frozen base and selection across peer update, focus, theme and resize',
    (tester) async {
      final c = offlineController()
        ..notes = [note()]
        ..online = false;
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: EditorScreen(controller: c, id: 'n'),
        ),
      );
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.byKey(const Key('note-content')),
      );
      await tester.enterText(
        find.byKey(const Key('note-content')),
        '${field.controller!.text}\nBản nháp',
      );
      field.controller!.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 7,
      );
      c.notes = [note(revision: 6)];
      // Notify via ordinary preference path, without rebasing the editor.
      await c.setPreferences({'dark': true});
      await tester.pump(const Duration(milliseconds: 190));
      await expandTools(tester);
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump(const Duration(milliseconds: 190));
      expect(field.controller!.text, contains('- [x] Việc thật'));
      expect(field.controller!.text, contains('Bản nháp'));
      expect(
        field.controller!.selection,
        const TextSelection(baseOffset: 2, extentOffset: 7),
      );
      await tester.tap(find.byKey(const Key('focus-mode')));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pump();
      expect(
        field.controller!.selection,
        const TextSelection(baseOffset: 2, extentOffset: 7),
      );
      await tester.tap(find.byKey(const Key('focus-mode')));
      await tester.pump(const Duration(milliseconds: 800));
      expect(
        c.pending.where((op) => op['note_id'] == 'n').first['base_revision'],
        5,
      );
      expect(c.notes.single.id, 'n');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'Viewer and clean newer revision cannot toggle source checklist',
    (tester) async {
      final c = offlineController()..notes = [note(role: 'viewer')];
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: EditorScreen(controller: c, id: 'n'),
        ),
      );
      await tester.pumpAndSettle();
      await expandTools(tester);
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      c.notes = [note()];
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: EditorScreen(controller: c, id: 'n'),
        ),
      );
      await tester.pumpAndSettle();
      c.notes = [note(revision: 6)];
      await c.setPreferences({'dark': true});
      await tester.pumpAndSettle();
      await expandTools(tester);
      expect(find.text('Chỉnh sửa phiên bản mới'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNull,
      );
      expect(c.pending.where((op) => op['note_id'] == 'n'), isEmpty);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'Focus pauses on background; remote lock removes text and tools from semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final c = offlineController()..notes = [note()];
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: EditorScreen(controller: c, id: 'n'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('focus-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('focus-start')));
      await tester.pump();
      final session = tester.widget<FocusBar>(find.byType(FocusBar)).session;
      expect(session.running, true);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(session.running, false);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      c.notes = [note(locked: true)];
      await c.setPreferences({'dark': true});
      await tester.pumpAndSettle();
      expect(find.byType(WritingToolsPanel), findsNothing);
      expect(find.byType(FocusBar), findsNothing);
      expect(
        tester.getSemantics(find.byType(Scaffold)).toStringDeep(),
        isNot(contains('Việc thật')),
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      semantics.dispose();
    },
  );

  testWidgets(
    'Template gallery and focus layout fit 320px at 200 percent text and reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget wrap(Widget child) => MaterialApp(
        theme: noteTheme(Brightness.dark),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 740),
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: child,
        ),
      );
      await tester.pumpWidget(wrap(const TemplateGallery()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const Key('template-idea')),
        300,
      );
      await tester.ensureVisible(find.byKey(const Key('template-idea')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('template-idea')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('template-preview')),
        300,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SelectableText>(find.byKey(const Key('template-preview')))
            .data,
        NoteTemplate.all.last.content,
      );
      expect(tester.takeException(), isNull);
      final c = offlineController()..notes = [note()];
      await tester.pumpWidget(wrap(EditorScreen(controller: c, id: 'n')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('focus-mode')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('Outline jumps to a Unicode heading without changing content', (
    tester,
  ) async {
    final c = offlineController()..notes = [note()];
    await tester.pumpWidget(
      MaterialApp(
        theme: noteTheme(Brightness.light),
        home: EditorScreen(controller: c, id: 'n'),
      ),
    );
    await tester.pumpAndSettle();
    await expandTools(tester);
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Ý chính'));
    await tester.tap(find.widgetWithText(TextButton, 'Ý chính'));
    await tester.pump();
    final field = tester.widget<TextField>(
      find.byKey(const Key('note-content')),
    );
    expect(field.focusNode!.hasFocus, true);
    expect(field.controller!.selection.baseOffset, 0);
    expect(field.controller!.text, note().content);
    expect(c.pending, isEmpty);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  test(
    'Focus completion and reset use monotonic time and dispose cancels tick',
    () async {
      final session = FocusSession(duration: const Duration(milliseconds: 15));
      session.start();
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(session.complete, true);
      session.pause();
      session.reset();
      expect(session.remaining, const Duration(milliseconds: 15));
      expect(session.running, false);
      session.start();
      session.dispose();
    },
  );
}
