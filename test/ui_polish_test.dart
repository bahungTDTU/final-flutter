import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/editor.dart';

import 'support.dart';

void main() {
  void useDeskViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('Route motion follows the shared motion scale', () {
    const builder = PrismPageTransitions();

    test('exit is shorter than entrance', () {
      expect(builder.transitionDuration, MotionTokens.fast);
      expect(builder.reverseTransitionDuration, MotionTokens.quick);
      expect(
        builder.reverseTransitionDuration < builder.transitionDuration,
        isTrue,
      );
    });

    test('entrance and exit curves settle at their endpoints', () {
      for (final status in [AnimationStatus.forward, AnimationStatus.reverse]) {
        expect(PrismPageTransitions.progress(0, status), closeTo(0, 1e-9));
        expect(PrismPageTransitions.progress(1, status), closeTo(1, 1e-9));
      }
      // Smooth-out entrance is mostly done by mid-way; the flipped exit
      // leaves quickly from fully visible (value falls fastest near 1).
      expect(
        PrismPageTransitions.progress(.5, AnimationStatus.forward),
        greaterThan(.85),
      );
      expect(
        PrismPageTransitions.progress(.5, AnimationStatus.reverse),
        lessThan(.15),
      );
    });

    testWidgets('pushes rise 8dp and fade, and are static with reduced motion', (
      tester,
    ) async {
      Future<void> pushFrom(bool reduced) async {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(reduced),
            theme: noteTheme(Brightness.light),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: child!,
            ),
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const Scaffold(body: Text('next', key: Key('next'))),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
      }

      await pushFrom(false);
      final translate = find.ancestor(
        of: find.byKey(const Key('next')),
        matching: find.byType(Transform),
      );
      expect(translate, findsWidgets);
      final dy = tester
          .widgetList<Transform>(translate)
          .map((t) => t.transform.getTranslation().y)
          .firstWhere((y) => y > 0);
      expect(dy, lessThanOrEqualTo(MotionTokens.rise));
      await tester.pump(MotionTokens.fast);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('next')), findsOneWidget);

      await pushFrom(true);
      // Reduced motion: the incoming page is fully visible on its first frame.
      final opacities = tester
          .widgetList<Opacity>(
            find.ancestor(
              of: find.byKey(const Key('next')),
              matching: find.byType(Opacity),
            ),
          )
          .map((o) => o.opacity);
      expect(opacities.every((o) => o == 1), isTrue);
      await tester.pumpAndSettle();
    });
  });

  testWidgets(
    'Empty notes offer a primary create action that opens the editor',
    (tester) async {
      useDeskViewport(tester);
      final c = offlineController()..user!['verified'] = true;
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      final cta = find.byKey(const Key('empty-new-note'));
      expect(cta, findsOneWidget);
      expect(find.text('Tạo ghi chú đầu tiên'), findsOneWidget);
      await tester.ensureVisible(cta);
      await tester.tap(cta);
      await tester.pumpAndSettle();
      expect(find.byType(EditorScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('Filtered empty results keep the clear action, not create', (
    tester,
  ) async {
    useDeskViewport(tester);
    final c = offlineController()
      ..user!['verified'] = true
      ..notes = [
        const Note(
          id: 'n',
          title: 'Mạng máy tính',
          content: 'OSI',
          revision: 1,
          updatedAt: '2026-11-20',
        ),
      ];
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('empty-new-note')), findsNothing);
    await tester.enterText(find.byKey(const Key('note-search')), 'zzzz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Xóa tìm kiếm và bộ lọc'), findsOneWidget);
    expect(find.byKey(const Key('empty-new-note')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Note menu separates and marks the destructive delete action', (
    tester,
  ) async {
    useDeskViewport(tester);
    final c = offlineController()
      ..user!['verified'] = true
      ..notes = [
        const Note(
          id: 'n',
          title: 'Mạng máy tính',
          content: 'OSI',
          revision: 1,
          updatedAt: '2026-11-20',
        ),
      ];
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuDivider), findsOneWidget);
    final error = Theme.of(tester.element(find.text('Xóa'))).colorScheme.error;
    expect(tester.widget<Text>(find.text('Xóa')).style?.color, error);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    for (final label in ['Chia sẻ', 'Ghim', 'Bật khóa ghi chú']) {
      expect(find.text(label), findsOneWidget);
      expect(tester.widget<Text>(find.text(label)).style?.color, isNull);
    }
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Auth errors clear as each field is corrected after submit', (
    tester,
  ) async {
    useDeskViewport(tester);
    final c = offlineController()
      ..user = null
      ..token = null;
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text('Nhập email hợp lệ'), findsNothing);
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Nhập email hợp lệ'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'qa@example.test',
    );
    await tester.pumpAndSettle();
    expect(find.text('Nhập email hợp lệ'), findsNothing);
    // Switching between login and register starts quiet again.
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('auth-email')), 'bad');
    await tester.pumpAndSettle();
    expect(find.text('Nhập email hợp lệ'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
