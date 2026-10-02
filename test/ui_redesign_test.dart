import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/editor.dart';
import 'package:note_together/ui/password_dialog.dart';
import 'package:note_together/ui/design_system.dart';

import 'support.dart';

void main() {
  testWidgets(
    'Grid accommodates largest note font, long labels and conflict action',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController();
      c.preferences['font_size'] = 24.0;
      c.notes = [
        Note(
          id: 'n',
          title: 'Tiêu đề dài để kiểm tra bố cục của ghi chú',
          content: List.filled(
            20,
            'Nội dung tiếng Việt cần đọc được.',
          ).join(' '),
          revision: 1,
          updatedAt: '2026-10-01',
          labels: List.filled(
            2,
            'Một nhãn rất dài được đặt để sắp xếp ghi chú của nhóm',
          ),
        ),
      ];
      c.conflicts['n'] = {'message': 'Fixture revision conflict'};
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'Password dialog validates confirmation and retains form on service failure',
    (tester) async {
      final c = offlineController();
      await tester.pumpWidget(
        MaterialApp(home: PasswordChangeDialog(controller: c)),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Đổi mật khẩu'));
      await tester.pump();
      expect(find.text('Nhập mật khẩu hiện tại'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'current-password');
      await tester.enterText(fields.at(1), 'new-password-123');
      await tester.enterText(fields.at(2), 'different');
      await tester.tap(find.widgetWithText(FilledButton, 'Đổi mật khẩu'));
      await tester.pump();
      expect(find.text('Hai mật khẩu chưa khớp'), findsOneWidget);
      await tester.enterText(fields.at(2), 'new-password-123');
      await tester.tap(find.widgetWithText(FilledButton, 'Đổi mật khẩu'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa thể hoàn tất yêu cầu'), findsOneWidget);
      expect(c.user, isNotNull);
      expect(
        tester.widget<TextFormField>(fields.at(1)).controller!.text,
        'new-password-123',
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets('Home controls have labeled Android-sized touch targets', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final c = offlineController();
    c.user!['verified'] = true;
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await tester.pumpWidget(const SizedBox());
    handle.dispose();
    c.dispose();
  });
  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1280, 800),
    const Size(1440, 900),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('Home/auth/editor/settings fit $size at scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final c = offlineController();
        c.notes = [
          const Note(
            id: 'n',
            title: 'Bài học tiếng Việt có dấu và tiêu đề rất dài cần đọc được',
            content: 'Nội dung nhiều dòng để kiểm tra giao diện khi chữ lớn. Không thay dữ liệu khi đổi bố cục.',
            revision: 1,
            updatedAt: '2026-10-01',
          ),
        ];
        await tester.pumpWidget(NoteTogetherApp(controller: c));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // Settings remains scrollable with large text and small landscape.
        final settingsTooltip = find.byTooltip('Hồ sơ và tùy chỉnh');
        final settings = settingsTooltip.evaluate().isNotEmpty
            ? settingsTooltip
            : find.text('Hồ sơ và tùy chỉnh');
        if (settings.evaluate().isNotEmpty) {
          await tester.ensureVisible(settings);
          await tester.pumpAndSettle();
          await tester.tap(settings);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(
          MaterialApp(
            theme: noteTheme(Brightness.light),
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
              ),
              child: EditorScreen(controller: c, id: 'n'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await c.logout();
        await tester.pumpWidget(NoteTogetherApp(controller: c));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      });
    }
  }
  testWidgets(
    'Locked card never exposes title content or labels; viewer has no owner menu',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final c = offlineController();
      c.notes = [
        const Note(
          id: 'secret',
          title: 'SECRET TITLE',
          content: 'SECRET CONTENT',
          labels: ['SECRET LABEL'],
          locked: true,
          revision: 1,
          updatedAt: '2026-10-01',
        ),
        const Note(
          id: 'view',
          title: 'Shared note',
          content: 'Allowed text',
          role: 'viewer',
          revision: 1,
          updatedAt: '2026-10-01',
        ),
      ];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.textContaining('SECRET'), findsNothing);
      expect(find.byTooltip('Thao tác ghi chú'), findsNothing);
      final dump = tester.getSemantics(find.byType(Scaffold)).toStringDeep();
      expect(dump, isNot(contains('SECRET')));
      await tester.tap(find.text('Được chia sẻ'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉ xem'), findsOneWidget);
      expect(find.byTooltip('Thao tác ghi chú'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
      c.dispose();
    },
  );
  testWidgets(
    'Search clear and AND filter preserve note list and distinguish empty results',
    (tester) async {
      final c = offlineController();
      c.labels = ['Học tập', 'Nhóm'];
      c.notes = [
        const Note(
          id: 'a',
          title: 'Toán',
          content: 'Tích phân',
          labels: ['Học tập', 'Nhóm'],
          revision: 1,
          updatedAt: '2026-10-01',
        ),
        const Note(
          id: 'b',
          title: 'Văn',
          content: 'Ghi nhớ',
          labels: ['Học tập'],
          revision: 1,
          updatedAt: '2026-10-01',
        ),
      ];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Học tập'));
      await tester.tap(find.widgetWithText(FilterChip, 'Nhóm'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('card-a')),
        250,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Toán'), findsOneWidget);
      expect(find.text('Văn'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('note-search')),
        'không tồn tại',
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Không tìm thấy ghi chú phù hợp'), findsOneWidget);
      await tester.ensureVisible(find.text('Xóa tìm kiếm và bộ lọc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa tìm kiếm và bộ lọc'));
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.text('2 ghi chú'), findsOneWidget);
      expect(c.notes.length, 2);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'Resize and theme retain editor text selection, ID and frozen revision',
    (tester) async {
      final c = offlineController();
      c.notes = [
        const Note(
          id: 'n',
          title: 'Title',
          content: 'Original',
          revision: 1,
          updatedAt: '2026-10-01',
        ),
      ];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Title'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Title'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('note-content')),
        'Ý tưởng đang viết',
      );
      final field = tester.widget<TextField>(
        find.byKey(const Key('note-content')),
      );
      final selection = field.controller!.selection;
      await c.setPreferences({'dark': true});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(tester.widget<EditorScreen>(find.byType(EditorScreen)).id, 'n');
      expect(field.controller!.text, 'Ý tưởng đang viết');
      expect(field.controller!.selection, selection);
      expect(c.pending.single['base_revision'], 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
