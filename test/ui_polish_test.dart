import 'package:note_together/state/app_controller.dart';
import 'package:note_together/data/api.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/editor.dart';
import 'package:note_together/ui/home.dart';
import 'package:note_together/ui/note_protection.dart';

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
      for (final curve in [MotionTokens.enter, MotionTokens.exit]) {
        expect(curve.transform(0), closeTo(0, 1e-9));
        expect(curve.transform(1), closeTo(1, 1e-9));
      }
      // Smooth-out entrance is mostly done by mid-way; the flipped exit
      // leaves quickly from fully visible (value falls fastest near 1).
      expect(MotionTokens.enter.transform(.5), greaterThan(.85));
      expect(MotionTokens.exit.transform(.5), lessThan(.15));
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
      await tester.pump(const Duration(milliseconds: 80));
      final target = find.byKey(const Key('next'));
      double opacity() => tester
          .widget<Opacity>(
            find.ancestor(of: target, matching: find.byType(Opacity)).first,
          )
          .opacity;
      final beforeBack = opacity();
      expect(beforeBack, inExclusiveRange(0, 1));
      Navigator.of(tester.element(target)).pop();
      await tester.pump();
      expect(opacity(), closeTo(beforeBack, .001));
      await tester.pumpAndSettle();
      expect(target, findsNothing);

      await pushFrom(false);
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
    // Switching between login and register starts quiet again and keeps
    // the email already typed.
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('auth-email')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      'qa@example.test',
    );
    await tester.enterText(find.byKey(const Key('auth-email')), 'bad');
    await tester.pumpAndSettle();
    expect(find.text('Nhập email hợp lệ'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  Note note(String id, {bool locked = false, bool shared = false}) => Note(
    id: id,
    title: locked ? '' : 'Mạng máy tính $id',
    content: locked ? '' : 'OSI',
    revision: 1,
    updatedAt: '2026-11-20',
    locked: locked,
    shared: shared,
  );

  testWidgets('Populated library uses a one-line header of stable height', (
    tester,
  ) async {
    useDeskViewport(tester);
    final c = offlineController()
      ..user!['verified'] = true
      ..notes = [for (var i = 0; i < 6; i++) note('n$i')];
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    // Intro copy and art are for an empty library only.
    expect(
      find.text('Ý tưởng, bài học và kế hoạch — gọn trong một nơi.'),
      findsNothing,
    );
    final heights = <double>{};
    for (var i = 0; i < 4; i++) {
      c.online = i.isEven;
      c.notifyListeners();
      await tester.pump();
      heights.add(
        tester.getSize(find.byKey(const Key('dashboard-header'))).height,
      );
    }
    expect(heights, hasLength(1));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Unverified reminder can be hidden for the session', (
    tester,
  ) async {
    useDeskViewport(tester);
    final c = offlineController()..notes = [note('n')];
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.byType(UnverifiedBanner), findsOneWidget);
    await tester.tap(find.byKey(const Key('dismiss-unverified')));
    await tester.pumpAndSettle();
    expect(find.byType(UnverifiedBanner), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Settings open as a centred dialog on wide windows', (
    tester,
  ) async {
    useDeskViewport(tester);
    final c = offlineController()..user!['verified'] = true;
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hồ sơ và tùy chỉnh').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-dialog')), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Giao diện tối'), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng tùy chỉnh'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Phones keep the settings bottom sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = offlineController()..user!['verified'] = true;
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hồ sơ và tùy chỉnh').first);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byKey(const Key('settings-dialog')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Note lock dialog reveals passwords with the shared eye toggle', (
    tester,
  ) async {
    final c = offlineController()..notes = [note('n')];
    await tester.pumpWidget(
      MaterialApp(
        theme: noteTheme(Brightness.light),
        home: Scaffold(
          body: NoteProtectionDialog(
            controller: c,
            id: 'n',
            action: ProtectionAction.enable,
          ),
        ),
      ),
    );
    expect(find.byType(CheckboxListTile), findsNothing);
    bool obscured() => tester
        .widgetList<EditableText>(find.byType(EditableText))
        .every((e) => e.obscureText);
    expect(obscured(), isTrue);
    await tester.tap(find.byTooltip('Hiện mật khẩu').first);
    await tester.pump();
    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .every((e) => !e.obscureText),
      isTrue,
    );
    expect(find.byTooltip('Ẩn mật khẩu'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Locked shared notes offer revoke-all without unlocking', (
    tester,
  ) async {
    useDeskViewport(tester);
    final c = offlineController()
      ..user!['verified'] = true
      ..notes = [note('locked', locked: true, shared: true), note('plain')];
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    // Only the locked + shared owner note gets the emergency menu.
    expect(find.byKey(const Key('locked-menu-locked')), findsOneWidget);
    await tester.tap(find.byKey(const Key('locked-menu-locked')));
    await tester.pumpAndSettle();
    expect(find.text('Thu hồi mọi chia sẻ'), findsOneWidget);
    await tester.tap(find.text('Thu hồi mọi chia sẻ'));
    await tester.pumpAndSettle();
    expect(find.text('Thu hồi mọi chia sẻ?'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(c.notes.first.isShared, isTrue);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  test('late revoke response leaves the next account intact', () async {
    final response = Completer<http.Response>();
    final started = Completer<void>();
    final controller =
        AppController(
            Api(
              'http://test',
              client: MockClient((request) async {
                if (request.method == 'DELETE') {
                  started.complete();
                  return response.future;
                }
                return http.Response('{}', 200);
              }),
            ),
            MemoryStore(),
          )
          ..user = {'id': 'A'}
          ..token = 'token-a'
          ..notes = [note('shared', shared: true)];
    addTearDown(controller.dispose);
    final revoke = controller.revokeAllShares(controller.notes.single);
    await started.future;
    await controller.logout();
    controller
      ..user = {'id': 'B'}
      ..token = 'token-b'
      ..notes = [note('shared', shared: true)];
    response.complete(http.Response('{"revoked":1}', 200));
    expect(await revoke, 1);
    expect(controller.notes.single.isShared, isTrue);
  });

  test(
    'revokeAllShares calls the owner endpoint and clears the shared flag',
    () async {
      final calls = <String>[];
      final c =
          AppController(
              Api(
                'http://test',
                client: MockClient((r) async {
                  calls.add('${r.method} ${r.url.path}');
                  if (r.method == 'DELETE') {
                    return http.Response(
                      jsonEncode({'ok': true, 'revoked': 2}),
                      200,
                    );
                  }
                  throw http.ClientException('offline');
                }),
              ),
              MemoryStore(),
            )
            ..user = {
              'id': 'A',
              'name': 'T',
              'email': 't@example.test',
              'verified': true,
            }
            ..token = 'tok'
            ..ready = true
            ..notes = [note('locked', locked: true, shared: true)];
      expect(await c.revokeAllShares(c.notes.single), 2);
      expect(calls, contains('DELETE /notes/locked/shares'));
      expect(c.notes.single.isShared, isFalse);
      expect(c.notes.single.locked, isTrue);
      c.dispose();
    },
  );
}
