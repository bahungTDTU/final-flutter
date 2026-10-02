import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/previews.dart';

void main() {
  testWidgets(
    'Dependency previews clearly disclose fixtures and contain no enabled submit',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: const DependencyPreview(),
        ),
      );
      expect(find.text('PREVIEW · dữ liệu minh họa'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
