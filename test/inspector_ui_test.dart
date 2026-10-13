import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/data/protected_note_vault.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/note_inspector.dart';
import 'package:note_together/ui/note_protection.dart';
import 'package:note_together/ui/rich_note_field.dart';

import 'protected_editing_test.dart' as fixtures;
import 'support.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'Narrow inspector reflows long actions and keeps separate targets ($brightness)',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var activated = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: noteTheme(brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Center(
                  child: SizedBox(
                    width: 228,
                    child: InspectorSection(
                      title: 'Công cụ ghi chú',
                      icon: Icons.tune_outlined,
                      children: [
                        InspectorAction(
                          label: 'Tóm tắt AI',
                          icon: Icons.auto_awesome_outlined,
                          onPressed: () => activated++,
                        ),
                        InspectorAction(
                          label: 'Kiểm tra quyền và cập nhật',
                          icon: Icons.refresh,
                          onPressed: () => activated++,
                        ),
                        const InspectorAction(
                          label: 'Quản lý chia sẻ',
                          icon: Icons.people_outline,
                          onPressed: null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final actions = find.byType(InspectorAction);
        final first = tester.getRect(actions.at(0));
        for (var index = 0; index < 3; index++) {
          final rect = tester.getRect(actions.at(index));
          expect(rect.left, first.left);
          expect(rect.width, first.width);
          expect(rect.height, greaterThanOrEqualTo(48));
          if (index > 0) {
            expect(
              rect.top - tester.getRect(actions.at(index - 1)).bottom,
              greaterThanOrEqualTo(8),
            );
          }
        }
        expect(
          tester.getSize(actions.at(1)).height,
          greaterThan(tester.getSize(actions.at(0)).height),
        );
        await tester.ensureVisible(actions.first);
        await tester.tap(actions.first);
        await tester.pump();
        expect(activated, 1);
        await tester.ensureVisible(actions.last);
        await tester.tap(actions.last);
        await tester.pump();
        expect(activated, 1);
        expect(
          tester
              .getSemantics(find.text('Quản lý chia sẻ'))
              .getSemanticsData()
              .label,
          contains('Quản lý chia sẻ'),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'Protected inspector survives theme/resize and disappears immediately on relock',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = fixtures.controller(MemoryStore(), fixtures.basic)
        ..labels = ['Dự án', 'Học tập'];
      Widget app(Brightness brightness, double scale) => MaterialApp(
        theme: noteTheme(brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: ProtectedNoteScreen(
          controller: c,
          id: 'n',
          vault: ProtectedNoteVault('A', 'n', workFactor: 50),
        ),
      );
      await tester.pumpWidget(app(Brightness.light, 1));
      await tester.pumpAndSettle();
      expect(find.byType(InspectorSection), findsNothing);
      await tester.enterText(
        find.byKey(const Key('unlock-note-password')),
        fixtures.password,
      );
      await tester.tap(find.byKey(const Key('unlock-note')));
      await tester.pumpAndSettle();
      expect(find.byType(InspectorSection), findsNWidgets(4));
      await tester.ensureVisible(find.text('Chỉnh sửa'));
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      final original = tester.widget<NoteRichTextField>(
        find.byKey(const Key('protected-content-editor')),
      );
      original.document.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 7,
      );
      for (final (size, brightness, scale) in [
        (const Size(375, 812), Brightness.dark, 1.0),
        (const Size(844, 390), Brightness.light, 1.0),
        (const Size(375, 812), Brightness.dark, 2.0),
        (const Size(1536, 850), Brightness.light, 1.0),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(app(brightness, scale));
        await tester.pumpAndSettle();
        final next = tester.widget<NoteRichTextField>(
          find.byKey(const Key('protected-content-editor')),
        );
        expect(
          identical(next.document.controller, original.document.controller),
          true,
        );
        expect(
          next.document.selection,
          const TextSelection(baseOffset: 0, extentOffset: 7),
        );
        expect(c.pending, isEmpty);
        expect(c.drafts, isEmpty);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byTooltip('Khóa lại'));
      await tester.pumpAndSettle();
      expect(find.byType(InspectorSection), findsNothing);
      expect(find.byType(NoteRichTextField), findsNothing);
      expect(original.document.text, isEmpty);
      expect(c.notes.single.content, isEmpty);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('Role metadata reflows without announcing a checkbox', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: noteTheme(Brightness.dark),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: InspectorBadge('Có thể chỉnh sửa'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Có thể chỉnh sửa')),
      matchesSemantics(
        label: 'Có thể chỉnh sửa',
        isButton: false,
        hasCheckedState: false,
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });
}
