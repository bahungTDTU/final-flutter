import 'package:flutter/material.dart';
import 'package:note_together/ui/rich_note_field.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/data/realtime_feed.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/avatar_editor.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/editor.dart';

import 'support.dart';

void main() {
  testWidgets('Offline pending editor suppresses stale live transport badge', (
    tester,
  ) async {
    final source = offlineController();
    final c =
        AppController(
            source.api,
            source.local,
            realtime: RealtimeFeed('http://test'),
          )
          ..user = source.user
          ..token = source.token
          ..online = false
          ..realtimeStatus = RealtimeStatus.live
          ..notes = [
            const Note(
              id: 'n',
              title: 'Giữ bản local',
              content: 'Chưa gửi lên server',
              revision: 1,
              updatedAt: '2026-10-02',
            ),
          ];
    source.dispose();
    c.pending.add({'note_id': 'n', 'kind': 'upsert'});
    await tester.pumpWidget(
      MaterialApp(
        theme: noteTheme(Brightness.dark),
        home: EditorScreen(controller: c, id: 'n'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Đã lưu trên thiết bị. Sẽ đồng bộ khi có kết nối.'),
      findsOneWidget,
    );
    expect(find.text('Trực tiếp'), findsNothing);
    expect(find.text('Đang nối lại'), findsNothing);
    expect(
      tester
          .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
          .document
          .text,
      'Chưa gửi lên server',
    );
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('Production editor exposes Vietnamese character feedback', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final c = offlineController();
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-note')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-title')), 'Ý tưởng');
    await tester.pump();
    final context = tester.element(find.byKey(const Key('note-title')));
    expect(Localizations.localeOf(context).languageCode, 'vi');
    final feedback = MaterialLocalizations.of(context)
        .remainingTextFieldCharacterCount(10);
    expect(feedback, contains('ký tự'));
    expect(
      tester.getSemantics(find.byType(Scaffold).last).toStringDeep(),
      isNot(contains('characters remaining')),
    );
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    handle.dispose();
  });
  testWidgets('Ctrl F focuses search and clearing labels preserves the query', (
    tester,
  ) async {
    final c = offlineController();
    c.user!['verified'] = true;
    c.labels = ['Học tập'];
    c.notes = [
      const Note(
        id: 'n',
        title: 'Flutter',
        content: 'Bài học',
        revision: 1,
        updatedAt: '2026-10-02',
        labels: ['Học tập'],
      ),
    ];
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    final search = tester.widget<TextField>(
      find.byKey(const Key('note-search')),
    );
    expect(search.focusNode!.hasFocus, isTrue);
    await tester.enterText(find.byKey(const Key('note-search')), 'Flutter');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.widgetWithText(FilterChip, 'Học tập'));
    await tester.pump();
    await revealHome(tester, find.text('Bỏ bộ lọc nhãn'));
    await tester.tap(find.text('Bỏ bộ lọc nhãn'));
    await tester.pump();
    expect(search.controller!.text, 'Flutter');
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Học tập'))
          .selected,
      isFalse,
    );
    expect(c.notes.single.id, 'n');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
    'Reopened incomplete draft stays local and never claims synchronized',
    (tester) async {
      final c = offlineController();
      await c.draft('draft', '', 'Nội dung đã giữ');
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: EditorScreen(controller: c, id: 'draft'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Nhập tiêu đề và nội dung để tạo ghi chú'),
        findsOneWidget,
      );
      expect(find.text('Đã đồng bộ'), findsNothing);
      expect(
        tester
            .widget<NoteRichTextField>(find.byKey(const Key('note-content')))
            .document
            .text,
        'Nội dung đã giữ',
      );
      expect(c.pending, isEmpty);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(844, 390),
    const Size(1280, 600),
  ]) {
    testWidgets('Management sheets and auth fit $size with 200 percent text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = offlineController();
      c.labels = [
        'Nhãn tiếng Việt rất dài cần đọc được trên màn hình nhỏ',
        'Đồ án',
      ];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Quản lý nhãn'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Quản lý nhãn'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Đóng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.dark),
          home: AvatarEditor(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: TokenScreen(controller: c, initialReset: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('email-code-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('email-code-submit')));
      await tester.pump();
      expect(
        find.text('Nhập mã trong email (tối đa 128 ký tự).'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await c.logout();
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pumpAndSettle();
      expect(find.text('Bắt đầu không gian của bạn'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }

  testWidgets('Short desktop falls back to rail without sidebar overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = offlineController();
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
