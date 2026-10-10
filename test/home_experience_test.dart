import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/note_filters.dart';

import 'support.dart';

Note note(String id, {String? title, List<String> labels = const []}) => Note(
  id: id,
  title: title ?? 'Bài học $id',
  content: 'Nội dung tiếng Việt để kiểm tra giao diện và tìm kiếm.',
  revision: 1,
  updatedAt: '2026-10-09',
  labels: labels,
);

Finder homeScroll() => find
    .descendant(
      of: find.byType(CustomScrollView).first,
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  setUpAll(() async {
    await (FontLoader('NotoSans')
          ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf')))
        .load();
  });

  testWidgets('Controller pulses update Home without rebuilding the app shell', (
    tester,
  ) async {
    final c = offlineController()..user!['verified'] = true;
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    var shell = tester.widget<MaterialApp>(find.byType(MaterialApp));
    var replacements = 0;
    for (var i = 0; i < 20; i++) {
      c.online = i.isEven;
      c.notifyListeners();
      await tester.pump();
      final next = tester.widget<MaterialApp>(find.byType(MaterialApp));
      if (!identical(shell, next)) replacements++;
      shell = next;
    }
    // This measures widget replacement, not paint time, jank or FPS.
    // ignore: avoid_print
    print(
      'SHELL_PROBE ${jsonEncode({'pulses': 20, 'shell_replacements': replacements, 'fps_measured': false})}',
    );
    expect(replacements, 0);
    expect(find.text('Offline · 0 thay đổi chờ'), findsOneWidget);
    c.preferences['dark'] = true;
    c.notifyListeners();
    await tester.pumpAndSettle();
    final themed = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(themed.themeMode, ThemeMode.dark);
    expect(identical(themed.theme, shell.theme), true);
    expect(identical(themed.darkTheme, shell.darkTheme), true);
    c.user = null;
    c.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth-email')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Hidden Home skips rebuilds and refreshes after editor return', (
    tester,
  ) async {
    final c = offlineController()
      ..user!['verified'] = true
      ..notes = [note('n')];
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('card-n'));
    await revealHome(tester, card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    final hidden = find.byKey(const ValueKey('card-n'), skipOffstage: false);
    final before = tester.widget<PrismCard>(hidden);
    for (var i = 0; i < 20; i++) {
      c.notifyListeners();
      await tester.pump();
      expect(identical(tester.widget<PrismCard>(hidden), before), true);
    }
    c.notes = [note('n', title: 'Phiên bản mới nhận từ server')];
    c.notifyListeners();
    await tester.pump();
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    await revealHome(tester, card);
    expect(find.text('Phiên bản mới nhận từ server'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
    'Large label catalogue is lazy; Apply and Cancel preserve search',
    (tester) async {
      final c = offlineController()
        ..user!['verified'] = true
        ..labels = List.generate(1000, (i) => 'Nhãn $i')
        ..notes = [
          note('both', labels: ['Nhãn 0', 'Nhãn 999']),
          note('one', labels: ['Nhãn 999']),
          note('other', labels: ['Nhãn 0']),
          const Note(
            id: 'locked',
            title: 'Bài học bí mật',
            content: 'Dữ liệu bí mật',
            labels: ['Nhãn 999'],
            locked: true,
            revision: 1,
            updatedAt: '2026-10-09',
          ),
        ];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.byType(FilterChip), findsNWidgets(6));
      await tester.enterText(find.byKey(const Key('note-search')), 'Bài học');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.byKey(const Key('all-label-filters')));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile).evaluate().length, lessThan(25));
      await tester.enterText(
        find.byKey(const Key('label-filter-search')),
        '999',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Nhãn 999'));
      await tester.tap(find.byKey(const Key('apply-label-filter')));
      await tester.pumpAndSettle();
      final search = tester.widget<TextField>(
        find.byKey(const Key('note-search')),
      );
      expect(search.controller!.text, 'Bài học');
      expect(find.text('2 ghi chú'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Nhãn 0'));
      await tester.pumpAndSettle();
      expect(find.text('1 ghi chú'), findsOneWidget);
      expect(find.textContaining('bí mật'), findsNothing);
      await tester.tap(find.byKey(const Key('all-label-filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ chọn'));
      await tester.tap(find.byTooltip('Đóng bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.text('1 ghi chú'), findsOneWidget);
      expect(find.text('Khớp tất cả 2 nhãn đã chọn'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('Deleted selections disappear while filter is open', (
    tester,
  ) async {
    final c = offlineController()..labels = ['A', 'B'];
    Set<String>? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: noteTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<Set<String>>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) =>
                      NoteLabelFilter(controller: c, selected: {'B'}),
                );
              },
              child: const Text('Mở bộ lọc'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở bộ lọc'));
    await tester.pumpAndSettle();
    c.labels = ['A'];
    c.notifyListeners();
    await tester.pump();
    expect(find.widgetWithText(CheckboxListTile, 'B'), findsNothing);
    await tester.tap(find.byKey(const Key('apply-label-filter')));
    await tester.pumpAndSettle();
    expect(result, isEmpty);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
    'Label search remains usable above the mobile keyboard at 200 percent',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = offlineController()..labels = ['Học tập', 'Nhóm'];
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.dark),
          home: Material(
            child: NoteLabelFilter(controller: c, selected: {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('label-filter-search')),
        'Học',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('label-filter-search')))
            .controller!
            .text,
        'Học',
      );
      expect(find.byKey(const Key('apply-label-filter')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('Remote lock purges private Home widgets behind the editor', (
    tester,
  ) async {
    final c = offlineController()
      ..user!['verified'] = true
      ..notes = [note('n', title: 'PRIVATE retained title')];
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('card-n'));
    await revealHome(tester, card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('card-n'), skipOffstage: false),
        matching: find.text('PRIVATE retained title', skipOffstage: false),
      ),
      findsOneWidget,
    );
    c.notes = [
      const Note(
        id: 'n',
        title: '',
        content: '',
        locked: true,
        revision: 2,
        updatedAt: '',
      ),
    ];
    c.notifyListeners();
    await tester.pump();
    expect(find.textContaining('PRIVATE', skipOffstage: false), findsNothing);
    expect(find.text('Ghi chú đã khóa', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1280, 900),
  ]) {
    testWidgets('Home and label filter adapt at $size with 200 percent text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = offlineController()
        ..user!['verified'] = true
        ..preferences['font_size'] = 24.0
        ..labels = List.generate(
          12,
          (i) => 'Tên nhãn dài $i ${'tiếng Việt ' * 8}',
        )
        ..notes = [note('n', title: 'Tiêu đề tiếng Việt rất dài để kiểm tra')];
      for (final dark in [false, true]) {
        c.preferences['dark'] = dark;
        await tester.pumpWidget(NoteTogetherApp(controller: c));
        await tester.pumpAndSettle();
        final card = find.byKey(const ValueKey('card-n'));
        await tester.scrollUntilVisible(card, 160, scrollable: homeScroll());
        expect(tester.takeException(), isNull);
        expect(c.grid, true);
        await tester.scrollUntilVisible(
          find.byKey(const Key('all-label-filters')),
          -160,
          scrollable: homeScroll(),
        );
        await tester.tap(find.byKey(const Key('all-label-filters')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Đóng bộ lọc'));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      }
      c.dispose();
    });
  }
}
