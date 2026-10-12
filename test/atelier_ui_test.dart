import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/dashboard.dart';
import 'package:note_together/ui/design_system.dart';

import 'support.dart';

void main() {
  test(
    'Secondary text meets 4.5:1 on the strongest container in both themes',
    () {
      for (final brightness in Brightness.values) {
        final colors = noteTheme(brightness).colorScheme;
        final a = colors.onSurfaceVariant.computeLuminance();
        final b = colors.surfaceContainerHighest.computeLuminance();
        final contrast = ((a > b ? a : b) + .05) / ((a < b ? a : b) + .05);
        expect(
          contrast,
          greaterThanOrEqualTo(4.5),
          reason: '$brightness secondary text',
        );
      }
    },
  );
  testWidgets(
    'Phone creation icon retains foreground contrast in the paper AppBar',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController()..user!['verified'] = true;
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      final icon = find.descendant(
        of: find.byKey(const Key('new-note')),
        matching: find.byType(Icon),
      );
      final context = tester.element(icon);
      expect(
        IconTheme.of(context).color,
        Theme.of(context).colorScheme.onPrimary,
      );
      expect(
        tester.getSize(find.byKey(const Key('new-note'))).height,
        greaterThanOrEqualTo(48),
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'Pinned shelf keeps server order and hides a locked cover ($dark)',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        final c = offlineController()..user!['verified'] = true;
        c.preferences['dark'] = dark;
        c.notes = [
          const Note(
            id: 'locked-cover',
            title: 'PRIVATE TITLE',
            content: 'PRIVATE BODY',
            labels: ['PRIVATE LABEL'],
            locked: true,
            shared: true,
            pinnedAt: '2026-10-12T12:00:00Z',
            updatedAt: '2026-10-12',
            revision: 2,
          ),
          const Note(
            id: 'open-cover',
            title: 'Kế hoạch làm việc',
            content: 'Ghi lại những ý tưởng đáng giữ.',
            pinnedAt: '2026-10-11T12:00:00Z',
            updatedAt: '2026-10-12',
            revision: 1,
          ),
        ];
        await tester.pumpWidget(NoteTogetherApp(controller: c));
        await tester.pumpAndSettle();
        await revealHome(tester, find.byType(PinnedShelf));
        final first = tester.getRect(
          find.byKey(const ValueKey('card-locked-cover')),
        );
        final second = tester.getRect(
          find.byKey(const ValueKey('card-open-cover')),
        );
        expect(first.left, lessThan(second.left));
        expect(first.width, greaterThan(second.width));
        expect(find.textContaining('PRIVATE'), findsNothing);
        expect(find.bySemanticsLabel(RegExp('PRIVATE')), findsNothing);
        expect(
          find.bySemanticsLabel(RegExp('Ghi chú được chia sẻ')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpAndSettle();
        expect(find.byType(PinnedShelf), findsNothing);
        await revealHome(
          tester,
          find.byKey(const ValueKey('card-locked-cover')),
        );
        expect(find.textContaining('PRIVATE'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        semantics.dispose();
        c.dispose();
      },
    );
  }
  testWidgets(
    'Pinned editorial shelf yields to natural height at 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = offlineController()..user!['verified'] = true;
      c.notes = List.generate(
        2,
        (i) => Note(
          id: '$i',
          title: 'Tiêu đề đủ dài để xuống dòng và vẫn dễ đọc',
          content: 'Nội dung ghi chú để kiểm tra khả năng đọc ở cỡ chữ lớn.',
          pinnedAt: '2026-10-12T12:00:00Z',
          updatedAt: '2026-10-12',
          revision: 1,
        ),
      );
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await revealHome(tester, find.byKey(const ValueKey('card-0')));
      expect(find.byType(PinnedShelf), findsNothing);
      expect(c.grid, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
