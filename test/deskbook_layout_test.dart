import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/editor.dart';
import 'package:note_together/ui/rich_note_field.dart';
import 'package:note_together/ui/workspace.dart';

import 'support.dart';

void main() {
  testWidgets(
    'Desk navigation and tool drawer survive rail/phone transitions with filters',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController()
        ..user!['verified'] = true
        ..labels = ['Dự án']
        ..notes = [
          const Note(
            id: 'n',
            title: 'Bản nháp',
            content: 'Nội dung',
            labels: ['Dự án'],
            revision: 7,
            updatedAt: '2026-10-12',
          ),
        ];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('desk-masthead')), findsOneWidget);
      expect(find.byKey(const Key('desk-tool-drawer')), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byTooltip('Quản lý nhãn'), findsOneWidget);
      expect(find.byTooltip('Tìm nhanh · Ctrl+K'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('note-search')), 'Bản');
      await revealHome(tester, find.widgetWithText(FilterChip, 'Dự án'));
      await tester.tap(find.widgetWithText(FilterChip, 'Dự án'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('desk-destination-1')));
      await tester.pumpAndSettle();
      expect(find.text('Được chia sẻ với bạn'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('desk-destination-0')));
      await tester.pumpAndSettle();
      for (final size in [
        const Size(1440, 600),
        const Size(390, 844),
        const Size(1180, 800),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        final search = tester.widget<TextField>(
          find.byKey(const Key('note-search')),
        );
        expect(search.controller!.text, 'Bản');
        await revealHome(tester, find.widgetWithText(FilterChip, 'Dự án'));
        expect(
          tester
              .widget<FilterChip>(find.widgetWithText(FilterChip, 'Dự án'))
              .selected,
          true,
        );
        expect(tester.takeException(), isNull);
      }
      expect(c.pending, isEmpty);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('Phone reveals working tools without hiding label filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = offlineController()
      ..user!['verified'] = true
      ..labels = ['Dự án'];
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    await revealHome(tester, find.byKey(const Key('library-tools')));
    expect(find.byKey(const Key('all-label-filters')), findsOneWidget);
    expect(find.byTooltip('Quản lý nhãn'), findsOneWidget);
    await tester.tap(find.byKey(const Key('library-tools')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Không gian làm việc'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
    'Document drawers preserve rich selection, draft and frozen revision',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
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
            updatedAt: '2026-10-12',
          ),
        ];
      Widget app(Brightness brightness) => MaterialApp(
        theme: noteTheme(brightness),
        home: EditorScreen(controller: c, id: 'n'),
      );
      await tester.pumpWidget(app(Brightness.light));
      await tester.pumpAndSettle();
      final fieldFinder = find.byKey(const Key('note-content'));
      await enterDocumentText(tester, fieldFinder, 'Bản viết đang tiếp tục');
      final original = tester.widget<NoteRichTextField>(fieldFinder);
      original.document.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 7,
      );
      final selection = original.document.selection;
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      final saved = c.pending.single['content'];
      for (final tooltip in [
        'Hiện/ẩn mục lục',
        'Hiện/ẩn thông tin',
        'Hiện/ẩn mục lục',
        'Hiện/ẩn thông tin',
      ]) {
        await tester.tap(find.byTooltip(tooltip));
        await tester.pumpAndSettle();
        final next = tester.widget<NoteRichTextField>(fieldFinder);
        expect(
          identical(next.document.controller, original.document.controller),
          true,
        );
        expect(next.document.selection, selection);
        expect(c.pending.single['content'], saved);
        expect(c.pending.single['base_revision'], 7);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(app(Brightness.dark));
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('document-desk-tabs')), findsNothing);
      expect(
        tester.widget<NoteRichTextField>(fieldFinder).document.selection,
        selection,
      );
      expect(c.pending.single['content'], saved);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
