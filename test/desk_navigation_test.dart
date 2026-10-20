import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/ui/deskbook.dart';
import 'package:note_together/ui/design_system.dart';

const destinations = ['Ghi chú', 'Được chia sẻ', 'Hỏi ghi chú'];

void main() {
  testWidgets(
    'Desktop destinations support keyboard activation and selected semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var selected = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: noteTheme(Brightness.light),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 560,
                  child: StatefulBuilder(
                    builder: (context, update) => DeskDestinationStrip(
                      destinations: destinations,
                      selected: selected,
                      onSelected: (value) => update(() => selected = value),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final shared = find.byKey(const ValueKey('desk-destination-1'));
        final bounds = tester.getRect(shared);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(selected, 1);
        expect(tester.getRect(shared), bounds);
        expect(
          tester.getSemantics(shared),
          isSemantics(
            label: 'Được chia sẻ',
            isSelected: true,
            isButton: true,
            hasTapAction: true,
          ),
        );
        await tester.tap(find.byKey(const ValueKey('desk-destination-2')));
        await tester.pumpAndSettle();
        expect(selected, 2);
        expect(
          tester.getSemantics(find.byKey(const ValueKey('desk-destination-2'))),
          isSemantics(
            label: 'Hỏi ghi chú',
            isSelected: true,
            isButton: true,
            hasTapAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Navigation remains readable at desktop breakpoint and larger text in both themes',
    (tester) async {
      for (final brightness in Brightness.values) {
        for (final scale in [1.0, 1.4]) {
          for (var selected = 0; selected < 3; selected++) {
            await tester.pumpWidget(
              MaterialApp(
                theme: noteTheme(brightness),
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(
                    body: Center(
                      child: SizedBox(
                        width: 510,
                        child: DeskDestinationStrip(
                          destinations: destinations,
                          selected: selected,
                          onSelected: (_) {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            for (var i = 0; i < 3; i++) {
              final button = find.byKey(ValueKey('desk-destination-$i'));
              final rect = tester.getRect(button);
              final label = tester.getRect(find.text(destinations[i]));
              expect(rect.height, greaterThanOrEqualTo(48));
              expect(rect.contains(label.topLeft), true);
              expect(rect.contains(label.bottomRight), true);
            }
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );

  test('Navigation text and focus borders have contrast in both themes', () {
    double ratio(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
    }

    for (final mode in Brightness.values) {
      final c = noteTheme(mode).colorScheme;
      expect(ratio(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
      expect(
        ratio(c.onSurface, c.surfaceContainerLow),
        greaterThanOrEqualTo(4.5),
      );
      expect(ratio(c.primary, c.surfaceContainerLow), greaterThanOrEqualTo(3));
    }
  });
}
