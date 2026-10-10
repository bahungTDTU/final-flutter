import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/domain/note_document.dart';
import 'package:note_together/domain/writing_tools.dart';
import 'package:note_together/state/note_listing.dart';
import 'package:note_together/ui/document_workspace.dart';
import 'package:note_together/ui/editor.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/rich_note_field.dart';

import 'support.dart';

void main() {
  testWidgets('Ctrl F from rich input opens document search without saving', (
    tester,
  ) async {
    final c = offlineController()
      ..notes = [
        const Note(
          id: 'n',
          title: 'Document',
          content: 'Visible text',
          revision: 1,
          updatedAt: '2026-10-09',
        ),
      ];
    await tester.pumpWidget(
      MaterialApp(
        home: EditorScreen(controller: c, id: 'n'),
      ),
    );
    await tester.pumpAndSettle();
    final field = tester.widget<NoteRichTextField>(
      find.byKey(const Key('note-content')),
    );
    field.document.requestKeyboard(field.focusNode);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byType(DocumentFindDialog), findsOneWidget);
    expect(c.pending, isEmpty);
    expect(c.drafts, isEmpty);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
    'Web replacement without terminal newline remains visible and supports range formatting',
    (tester) async {
      final source = TextEditingController(text: 'Previous body');
      final document = NoteDocumentController(
        source: source,
        canEdit: () => true,
        onChanged: () {},
      );
      final focus = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteRichTextField(
              key: const Key('body'),
              document: document,
              focusNode: focus,
              readOnly: false,
            ),
          ),
        ),
      );
      document.requestKeyboard(focus);
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'New visible body',
          selection: TextSelection.collapsed(offset: 16),
        ),
      );
      await tester.pump();
      expect(document.controller.document.toPlainText(), 'New visible body\n');
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('New visible body'),
        ),
        findsWidgets,
      );
      document.selection = const TextSelection(baseOffset: 0, extentOffset: 3);
      document.format('bold', true);
      await tester.pump();
      expect(
        storedDocumentDelta(source.text)!.first['attributes']['bold'],
        true,
      );
      await tester.pumpWidget(const SizedBox());
      document.dispose();
      source.dispose();
      focus.dispose();
    },
  );
  test('Whole-value web input retains unrelated formatting and rejects revoked edits', () async {
    var allowed = true;
    final source = TextEditingController(
      text: storeDocumentDelta([
        {
          'insert': 'Bold ',
          'attributes': {'bold': true},
        },
        {'insert': 'tail\n'},
      ]),
    );
    final document = NoteDocumentController(
      source: source,
      canEdit: () => allowed,
      onChanged: () {},
    );
    document.replaceVisibleText('Bold changed tail');
    await Future<void>.delayed(Duration.zero);
    expect(document.text, 'Bold changed tail');
    expect(storedDocumentDelta(source.text)!.first['attributes']['bold'], true);
    final accepted = source.text;
    allowed = false;
    document.replaceVisibleText('Forbidden mutation');
    await Future<void>.delayed(Duration.zero);
    expect(source.text, accepted);
    document.dispose();
    source.dispose();
  });
  test('One checkbox in a combined Delta operation leaves neighbouring tasks unchanged', () {
    final encoded = storeDocumentDelta([
      {
        'insert': 'First\nSecond\nThird\n',
        'attributes': {'list': 'unchecked'},
      },
    ]);
    final tasks = WritingSnapshot(encoded).tasks;
    final toggled = toggleWritingTask(encoded, encoded, tasks[1])!;
    expect(plainNoteContent(toggled), 'First\nSecond\nThird');
    expect(WritingSnapshot(toggled).tasks.map((task) => task.done), [
      false,
      true,
      false,
    ]);
  });

  testWidgets(
    'Format undo/redo survives actual input and oversized edits preserve the accepted draft',
    (tester) async {
      final source = TextEditingController(text: 'Safe draft');
      var writes = 0;
      final document = NoteDocumentController(
        source: source,
        canEdit: () => true,
        onChanged: () => writes++,
      );
      final focus = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteRichTextField(
              key: const Key('field'),
              document: document,
              focusNode: focus,
              readOnly: false,
            ),
          ),
        ),
      );
      await enterDocumentText(
        tester,
        find.byKey(const Key('field')),
        'Actual input',
      );
      document.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
      document.format('bold', true);
      await tester.pump();
      expect(
        storedDocumentDelta(source.text)!.first['attributes']['bold'],
        true,
      );
      document.controller.undo();
      await tester.pump();
      expect(source.text, 'Safe draft');
      document.controller.redo();
      await tester.pump();
      final accepted = source.text;
      final before = writes;
      document.controller.replaceText(
        0,
        document.text.length,
        'X' * 100001,
        null,
      );
      await tester.pump();
      expect(source.text, accepted);
      expect(document.text, 'Actual input');
      expect(writes, before);
      expect(document.problem, isNotNull);
      await tester.pumpWidget(const SizedBox());
      document.dispose();
      source.dispose();
      focus.dispose();
    },
  );
  test(
    'Rich spans join words for search/preview and hide formatting metadata',
    () {
      final encoded = storeDocumentDelta([
        {
          'insert': 'Sinh',
          'attributes': {'bold': true, 'color': '#5c43c9'},
        },
        {'insert': ' học thú vị\n'},
      ]);
      final note = Note(
        id: 'n',
        title: 'Tài liệu',
        content: encoded,
        revision: 7,
        updatedAt: '2026-10-09',
      );
      final cache = NoteListingCache();
      List<Note> search(String query) => cache
          .select(
            account: 'A',
            notes: [note],
            query: query,
            shared: false,
            labels: {},
            deletedLabels: {},
          )
          .all;
      expect(search('Sinh học'), [note]);
      expect(search('attributes'), isEmpty);
      expect(search('5c43c9'), isEmpty);
      expect(noteCardPreview(note), 'Sinh học thú vị');
      expect(
        validNote(
          'Title',
          storeDocumentDelta([
            {
              'insert': '\n',
              'attributes': {'align': 'center'},
            },
          ]),
        ),
        false,
      );
    },
  );

  test('Plain notes retain exact unicode/trailing lines and reserved prefix remains literal', () {
    for (final text in [
      'Xin chào 👩🏽‍💻',
      'Một dòng\n',
      'Hai dòng\n\n',
      'NTDOC1:literal',
    ]) {
      final encoded = storeDocumentDelta(editableDocumentDelta(text));
      expect(plainNoteContent(encoded), text);
    }
    expect(plainNoteContent('NTDOC1:broken'), 'NTDOC1:broken');
  });

  test(
    'Rich outline/checklist use visible offsets and stale clicks refuse edits',
    () {
      final encoded = storeDocumentDelta([
        {'insert': 'Mục tiêu'},
        {
          'insert': '\n',
          'attributes': {'header': 2},
        },
        {'insert': 'Cần làm'},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked'},
        },
      ]);
      final snapshot = WritingSnapshot(encoded);
      expect(snapshot.headings.single.text, 'Mục tiêu');
      expect(snapshot.tasks.single.markerOffset, 9);
      final toggled = toggleWritingTask(
        encoded,
        encoded,
        snapshot.tasks.single,
      )!;
      expect(WritingSnapshot(toggled).completed, 1);
      expect(plainNoteContent(toggled), plainNoteContent(encoded));
      expect(
        toggleWritingTask(encoded, toggled, snapshot.tasks.single),
        isNull,
      );
    },
  );

  test(
    'Opening legacy markup makes a formatted view without a migration write',
    () {
      final source = TextEditingController(
        text: '## Mục tiêu\n- [ ] Việc cần làm',
      );
      var writes = 0;
      final document = NoteDocumentController(
        source: source,
        canEdit: () => false,
        onChanged: () => writes++,
      );
      expect(document.text, 'Mục tiêu\nViệc cần làm');
      expect(WritingSnapshot(document.snapshotSource).headings.single.level, 2);
      expect(source.text, '## Mục tiêu\n- [ ] Việc cần làm');
      expect(writes, 0);
      document.dispose();
      source.dispose();
    },
  );

  testWidgets(
    'Desktop formats directly, saves frozen base, and retains controller/caret on phone resize',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController()
        ..notes = [
          const Note(
            id: 'n',
            title: 'Tài liệu',
            content: 'Nội dung',
            revision: 7,
            updatedAt: '2026-10-09',
          ),
        ];
      Widget app(Brightness brightness) => MaterialApp(
        theme: noteTheme(brightness),
        home: EditorScreen(controller: c, id: 'n'),
      );
      await tester.pumpWidget(app(Brightness.light));
      await tester.pumpAndSettle();
      expect(find.text('Mục lục'), findsOneWidget);
      await enterDocumentText(
        tester,
        find.byKey(const Key('note-content')),
        'Xin chào tài liệu',
      );
      final field = tester.widget<NoteRichTextField>(
        find.byKey(const Key('note-content')),
      );
      field.document.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 8,
      );
      await tester.pump();
      await tester.tap(find.byTooltip('In đậm (Ctrl+B)'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      final encoded = c.pending.single['content'] as String;
      expect(plainNoteContent(encoded), 'Xin chào tài liệu');
      expect(storedDocumentDelta(encoded)!.first['attributes']['bold'], true);
      expect(c.pending.single['base_revision'], 7);
      final selection = field.document.selection;
      await tester.pumpWidget(app(Brightness.dark));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final phone = tester.widget<NoteRichTextField>(
        find.byKey(const Key('note-content')),
      );
      expect(
        identical(phone.document.controller, field.document.controller),
        true,
      );
      expect(phone.document.selection, selection);
      expect(find.text('Mục lục'), findsNothing);
      expect(find.byTooltip('Định dạng khác'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'Selection and zoom never create a draft; revoked editor cannot format',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController()
        ..notes = [
          const Note(
            id: 'n',
            title: 'Tài liệu',
            content: 'Nội dung',
            revision: 1,
            updatedAt: '2026-10-09',
          ),
        ];
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: EditorScreen(controller: c, id: 'n'),
        ),
      );
      await tester.pumpAndSettle();
      final field = tester.widget<NoteRichTextField>(
        find.byKey(const Key('note-content')),
      );
      field.document.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 4,
      );
      await tester.tap(find.byTooltip('Phóng to tài liệu'));
      await tester.pumpAndSettle();
      expect(c.drafts, isEmpty);
      expect(c.pending, isEmpty);
      c.notes = [
        const Note(
          id: 'n',
          title: 'Tài liệu',
          content: 'Bản máy chủ',
          revision: 2,
          role: 'viewer',
          updatedAt: '2026-10-09',
        ),
      ];
      c.notifyListeners();
      await tester.pumpAndSettle();
      field.document.format('bold', true);
      await tester.pumpAndSettle();
      expect(field.document.text, 'Bản máy chủ');
      expect(c.pending, isEmpty);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'Find and replace operates on visible text and retains unrelated formatting',
    (tester) async {
      final source = TextEditingController(
        text: storeDocumentDelta([
          {
            'insert': 'Alpha ',
            'attributes': {'bold': true},
          },
          {'insert': 'beta Alpha\n'},
        ]),
      );
      final document = NoteDocumentController(
        source: source,
        canEdit: () => true,
        onChanged: () {},
      );
      final focus = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: DocumentFindDialog(
            document: document,
            focusNode: focus,
            readOnly: false,
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('document-find')), 'Alpha');
      await tester.pump();
      expect(find.text('2 kết quả'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('document-replacement')),
        'Gamma',
      );
      await tester.tap(find.text('Thay tất cả'));
      await tester.pumpAndSettle();
      expect(document.text, 'Gamma beta Gamma');
      expect(
        storedDocumentDelta(source.text)!.first['attributes']['bold'],
        true,
      );
      await tester.pumpWidget(const SizedBox());
      document.dispose();
      source.dispose();
      focus.dispose();
    },
  );
}
