import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/ui/dashboard.dart';
import 'package:note_together/ui/design_system.dart';

void main() {
  testWidgets('Phone dashboard keeps the summary compact on a tall screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: noteTheme(Brightness.light),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: DashboardHeader(
              title: 'Ghi chú của bạn',
              detail: 'Ý tưởng, bài học và kế hoạch — gọn trong một nơi.',
              count: 9,
              syncLabel: 'Trực tiếp',
              online: true,
              onSync: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Ghi chú của bạn'), findsOneWidget);
    expect(find.text('9 ghi chú'), findsOneWidget);
    expect(find.text('KHÔNG GIAN GHI CHÚ'), findsNothing);
    expect(
      find.text('Ý tưởng, bài học và kế hoạch — gọn trong một nơi.'),
      findsNothing,
    );
    expect(tester.getSize(find.byType(DashboardHeader)).height, lessThan(220));
  });

  testWidgets(
    'Dashboard actions stay below large headings in a narrow desktop pane',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: DashboardHeader(
                    title: 'Được chia sẻ với bạn',
                    detail: 'Cùng theo dõi những điều quan trọng.',
                    count: 4,
                    syncLabel: 'Đã đồng bộ',
                    online: true,
                    onSync: () {},
                    action: FilledButton(
                      onPressed: () {},
                      child: const Text('Ghi chú mới'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final heading = tester.getRect(find.text('Được chia sẻ với bạn'));
      final action = tester.getRect(
        find.widgetWithText(FilledButton, 'Ghi chú mới'),
      );
      expect(action.top, greaterThan(heading.bottom));
      expect(action.right, lessThanOrEqualTo(320));
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'Feature intro wraps description and actions at 320px with large text ($brightness)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            theme: noteTheme(brightness),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: PageIntro(
                  title: 'Bạn kiểm soát phiên đăng nhập',
                  detail: 'Xem các phiên đang hoạt động và kết thúc phiên bạn không còn sử dụng.',
                  eyebrow: 'TRUNG TÂM BẢO MẬT',
                  icon: Icons.shield_outlined,
                  trailing: FilledButton(
                    onPressed: () {},
                    child: const Text('Tải lại phiên'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final action = find.widgetWithText(FilledButton, 'Tải lại phiên');
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        final rect = tester.getRect(action);
        expect(rect.left, greaterThanOrEqualTo(16));
        expect(rect.right, lessThanOrEqualTo(304));
        expect(rect.height, greaterThanOrEqualTo(48));
      },
    );
  }
}
