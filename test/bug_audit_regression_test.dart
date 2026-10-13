import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/document_workspace.dart';
import 'package:note_together/ui/editor.dart';
import 'package:note_together/ui/rich_note_field.dart';

import 'support.dart';

void main() {
  testWidgets(
    'Find clears private input when the source is hidden by its gate',
    (tester) async {
      var allowed = true;
      final source = TextEditingController(text: 'Private body');
      final document = NoteDocumentController(
        source: source,
        canEdit: () => allowed,
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
      await tester.enterText(find.byKey(const Key('document-find')), 'Private');
      await tester.enterText(
        find.byKey(const Key('document-replacement')),
        'Private replacement',
      );
      await tester.pump();
      allowed = false;
      source.clear();
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('document-find')))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('document-replacement')))
            .controller!
            .text,
        isEmpty,
      );
      expect(find.text('0 kết quả'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      document.dispose();
      source.dispose();
      focus.dispose();
    },
  );

  testWidgets('Open find disables replacements after a role-only downgrade', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = offlineController()
      ..notes = [
        const Note(
          id: 'n',
          title: 'Trang viết',
          content: 'Alpha Alpha',
          updatedAt: '2026-10-12',
          revision: 7,
        ),
      ];
    await tester.pumpWidget(
      MaterialApp(
        theme: noteTheme(Brightness.light),
        home: EditorScreen(controller: c, id: 'n'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tìm và thay thế (Ctrl+F)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('document-find')), 'Alpha');
    await tester.pump();
    c.notes = [
      const Note(
        id: 'n',
        title: 'Trang viết',
        content: 'Alpha Alpha',
        role: 'viewer',
        updatedAt: '2026-10-12',
        revision: 7,
      ),
    ];
    c.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('2 kết quả'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Thay tất cả'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('document-replacement')))
          .enabled,
      false,
    );
    expect(c.pending, isEmpty);
    expect(c.drafts, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Find previous starts at the last result and wraps both ways', (
    tester,
  ) async {
    final source = TextEditingController(text: 'match middle match end match');
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
    await tester.enterText(find.byKey(const Key('document-find')), 'match');
    await tester.pump();
    await tester.tap(find.text('Trước'));
    await tester.pump();
    expect(
      document.selection,
      const TextSelection(baseOffset: 23, extentOffset: 28),
    );
    await tester.tap(find.text('Tiếp'));
    await tester.pump();
    expect(
      document.selection,
      const TextSelection(baseOffset: 0, extentOffset: 5),
    );
    await tester.pumpWidget(const SizedBox());
    document.dispose();
    source.dispose();
    focus.dispose();
  });

  testWidgets(
    'Open find follows remote text changes without stale selections',
    (tester) async {
      final source = TextEditingController(
        text: 'prefix match and another match',
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
      await tester.enterText(find.byKey(const Key('document-find')), 'match');
      await tester.pump();
      await tester.tap(find.text('Tiếp'));
      await tester.pump();
      source.text = 'match';
      await tester.pump();
      expect(find.text('1 kết quả'), findsOneWidget);
      await tester.tap(find.text('Tiếp'));
      await tester.pump();
      expect(
        document.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      source.text = 'gone';
      await tester.pump();
      expect(find.text('0 kết quả'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Tiếp'))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      document.dispose();
      source.dispose();
      focus.dispose();
    },
  );

  testWidgets(
    'Desktop zoom with both drawers never overflows or rewrites a note',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController()
        ..notes = [
          const Note(
            id: 'n',
            title: 'Trang viết',
            content: '# Mục tiêu\nNội dung',
            updatedAt: '2026-10-12',
            revision: 7,
          ),
        ];
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: EditorScreen(controller: c, id: 'n'),
        ),
      );
      await tester.pumpAndSettle();
      final original = tester.widget<NoteRichTextField>(
        find.byKey(const Key('note-content')),
      );
      await tester.tap(find.byTooltip('Hiện/ẩn mục lục'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byTooltip('Phóng to tài liệu'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(
        identical(
          tester
              .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
              .document,
          original.document,
        ),
        true,
      );
      expect(c.pending, isEmpty);
      expect(c.drafts, isEmpty);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
