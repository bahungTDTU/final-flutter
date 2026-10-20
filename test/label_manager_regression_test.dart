import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/home.dart';
import 'package:note_together/ui/label_manager.dart';

import 'support.dart';

Future<void> openLabels(WidgetTester tester) async {
  await tester.ensureVisible(find.byTooltip('Quản lý nhãn').first);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Quản lý nhãn').first);
  await tester.pumpAndSettle();
  expect(find.byType(BottomSheet), findsOneWidget);
}

void main() {
  testWidgets(
    'Label management mounts only visible rows for a large catalogue',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController()
        ..labels = List.generate(1000, (i) => 'Nhãn $i');
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: HomeScreen(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      await openLabels(tester);
      final sheet = find.byType(BottomSheet);
      final rows = find.descendant(of: sheet, matching: find.byType(ListTile));
      // Measures mounted list rows, not FPS or native frame times.
      // ignore: avoid_print
      print('LABEL_ROWS mounted=${rows.evaluate().length} total=1000');
      expect(rows.evaluate().length, lessThan(30));
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('Long label conflicts fit a compact window with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = offlineController()
      ..labels = ['Dự án cần kiểm tra các mốc và phân công'];
    c.labelConflicts[c.labels.first] = {'name': 'Tên mới trên server'};
    await tester.pumpWidget(
      MaterialApp(
        theme: noteTheme(Brightness.dark),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: HomeScreen(controller: c),
      ),
    );
    await tester.pumpAndSettle();
    await openLabels(tester);
    tester.view.physicalSize = const Size(320, 720);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
    'Label search, rename validation and confirmed delete preserve note content',
    (tester) async {
      final c = offlineController()..labels = ['a', 'b'];
      c.labelCatalogue.addAll({
        'a': {'id': 'a', 'name': 'Học tập', 'revision': 1, 'deleted': false},
        'b': {'id': 'b', 'name': 'Dự án', 'revision': 1, 'deleted': false},
      });
      c.notes = [
        const Note(
          id: 'n',
          title: 'Giữ ghi chú',
          content: 'Nội dung nguyên bản',
          revision: 3,
          updatedAt: '2026-10-14',
          labels: ['a'],
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: Scaffold(body: LabelManager(controller: c)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('label-manager-search')),
        'Học',
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('managed-label-b')), findsNothing);
      await tester.tap(find.byTooltip('Thao tác với Học tập'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi tên'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('label-name-input')),
        'Dự án',
      );
      await tester.tap(find.text('Xác nhận'));
      await tester.pump();
      expect(find.text('Nhãn này đã tồn tại'), findsOneWidget);
      expect(c.pendingLabels, isEmpty);
      await tester.enterText(
        find.byKey(const Key('label-name-input')),
        'Học chuyên sâu',
      );
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(c.labelName('a'), 'Học chuyên sâu');
      final firstOp = Map<String, dynamic>.from(c.pendingLabels.single);
      await tester.tap(find.byTooltip('Thao tác với Học chuyên sâu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa nhãn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(c.labels, contains('a'));
      await tester.tap(find.byTooltip('Thao tác với Học chuyên sâu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa nhãn'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa nhãn'));
      await tester.pumpAndSettle();
      expect(c.labels, isNot(contains('a')));
      expect(c.pendingLabels.first, firstOp);
      expect(c.notes.single.content, 'Nội dung nguyên bản');
      expect(c.notes.single.revision, 3);
      await tester.tap(find.byTooltip('Xóa tìm nhãn'));
      await tester.pump();
      expect(find.byKey(const ValueKey('managed-label-b')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'Sync pulses retain rows; remote rename refreshes search; account change purges dialogs',
    (tester) async {
      final c = offlineController()..labels = ['a'];
      c.labelCatalogue['a'] = {
        'id': 'a',
        'name': 'Tên riêng',
        'revision': 1,
        'deleted': false,
      };
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.dark),
          home: Scaffold(body: LabelManager(controller: c)),
        ),
      );
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('managed-label-a'));
      final before = tester.widget(row);
      for (var i = 0; i < 20; i++) {
        c.notifyListeners();
        await tester.pump();
        expect(identical(tester.widget(row), before), true);
      }
      await tester.enterText(
        find.byKey(const Key('label-manager-search')),
        'mới',
      );
      await tester.pump();
      expect(row, findsNothing);
      c.labelCatalogue['a']!['name'] = 'Tên mới';
      c.notifyListeners();
      await tester.pump();
      expect(row, findsOneWidget);
      await tester.tap(find.byTooltip('Thao tác với Tên mới'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi tên'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('label-name-input')),
        'Tên riêng trong input',
      );
      c.user = {'id': 'B'};
      c.token = 'different-session';
      c.labels = ['secret-B'];
      c.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('label-name-input')), findsNothing);
      expect(find.text('Tên riêng trong input'), findsNothing);
      expect(find.text('secret-B'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Xác nhận'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(c.pendingLabels, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'Label actions remain reachable across themes, phone landscape and keyboard insets',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final c = offlineController()
        ..labels = ['Tên nhãn dài cần xuống dòng để dễ đọc'];
      for (final brightness in Brightness.values) {
        for (final size in [
          const Size(320, 720),
          const Size(844, 390),
          const Size(1180, 800),
        ]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            MaterialApp(
              theme: noteTheme(brightness),
              builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(
                  textScaler: TextScaler.linear(2),
                  viewInsets: EdgeInsets.only(
                    bottom: size.height > 600 ? 280 : 100,
                  ),
                ),
                child: child!,
              ),
              home: Scaffold(body: LabelManager(controller: c)),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$brightness $size');
          final add = find.widgetWithText(FilledButton, 'Thêm nhãn');
          expect(add.hitTestable(), findsOneWidget);
        }
      }
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
