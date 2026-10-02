import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/design_system.dart';

import 'support.dart';

void main() {
  Widget card({bool reduced = false}) => MaterialApp(
    theme: noteTheme(Brightness.light),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            height: 200,
            child: PrismCard(
              onTap: () {},
              tone: PrismPalette.forBrightness(Brightness.light).tones.first,
              child: const Center(child: Text('Một ý tưởng')),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'Hover lifts only the card, settles, and returns without a loop',
    (tester) async {
      await tester.pumpWidget(card());
      await tester.pumpAndSettle();
      final label = find.text('Một ý tưởng');
      final start = tester.getTopLeft(label);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));
      expect(tester.getTopLeft(label).dy, closeTo(start.dy - 2, .1));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.transientCallbackCount, 0);
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(label), start);
      await mouse.removePointer();
    },
  );

  testWidgets(
    'Reduced motion keeps hover geometry fixed and reveal immediately readable',
    (tester) async {
      await tester.pumpWidget(card(reduced: true));
      await tester.pumpAndSettle();
      final label = find.text('Một ý tưởng');
      final start = tester.getTopLeft(label);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(label));
      await tester.pump();
      expect(tester.getTopLeft(label), start);
      expect(tester.binding.transientCallbackCount, 0);
      await mouse.removePointer();
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: PrismReveal(child: Text('Đọc ngay')),
          ),
        ),
      );
      await tester.pump();
      expect(tester.widget<Opacity>(find.byType(Opacity).last).opacity, 1);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'Controller refresh does not restart decorative or theme animation',
    (tester) async {
      final c = offlineController();
      c.user!['verified'] = true;
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      c.notifyListeners();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  test('Prism text, tinted surfaces and controls retain measured contrast', () {
    double ratio(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
    }

    for (final mode in Brightness.values) {
      final theme = noteTheme(mode), scheme = theme.colorScheme;
      final palette = theme.extension<PrismPalette>()!;
      for (final tone in palette.tones) {
        // Conservative envelope covers the .08/.14/.22 chip tints and .13 card edge.
        for (final alpha in [.0, .08, .13, .14, .22]) {
          final background = Color.alphaBlend(
            tone.light.withValues(alpha: alpha),
            scheme.surface,
          );
          expect(ratio(tone.ink, background), greaterThanOrEqualTo(4.5));
          expect(
            ratio(scheme.onSurfaceVariant, background),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
      expect(
        ratio(scheme.onSurface, palette.canvas),
        greaterThanOrEqualTo(4.5),
      );
      expect(ratio(scheme.outline, scheme.surface), greaterThanOrEqualTo(3));
      expect(ratio(scheme.primary, scheme.surface), greaterThanOrEqualTo(3));
    }
    for (final color in PrismPalette.actionColors) {
      expect(ratio(Colors.white, color), greaterThanOrEqualTo(4.5));
    }
  });
}
