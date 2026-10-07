import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/editor.dart';
import 'package:note_together/ui/note_text_field.dart';
import 'package:note_together/ui/writing_studio.dart';

import 'support.dart';

void main() {
  setUpAll(() async {
    final fonts = FontLoader('NotoSans')
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    await fonts.load();
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1280, 900),
  ]) {
    testWidgets(
      'Writing labels, text and counters never overlap at $size / 200 percent',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final title = TextEditingController(
          text: 'Kế hoạch học tập và cộng tác – Tiếng Việt có dấu, tiêu đề nhiều dòng',
        );
        final content = TextEditingController(
          text: '# Mục tiêu\nNội dung nhiều dòng với ký tự tiếng Việt.\n- [ ] Việc cần làm',
        );
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(
            MaterialApp(
              theme: noteTheme(brightness),
              home: Scaffold(
                body: ReadingCanvas(
                  panel: false,
                  child: Column(
                    children: [
                      NoteTextField(
                        controller: title,
                        titleMode: true,
                        fieldKey: const Key('title'),
                        readOnly: false,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 16),
                      NoteTextField(
                        controller: content,
                        titleMode: false,
                        fieldKey: const Key('body'),
                        readOnly: false,
                        fontSize: 24,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final label in ['Tiêu đề', 'Nội dung']) {
            final section = find.byWidgetPredicate(
              (w) => w is NoteSection && w.label == label,
            );
            final labelRect = tester.getRect(
              find.descendant(of: section, matching: find.text(label)),
            );
            final textRect = tester.getRect(
              find.descendant(of: section, matching: find.byType(EditableText)),
            );
            final counterRect = tester.getRect(
              find.descendant(
                of: section,
                matching: find.textContaining(RegExp(r'/ .* ký tự$')),
              ),
            );
            expect(labelRect.bottom, lessThan(textRect.top));
            expect(textRect.bottom, lessThanOrEqualTo(counterRect.top));
            expect(labelRect.overlaps(textRect), false);
            expect(counterRect.overlaps(textRect), false);
            final sectionRect = tester.getRect(section);
            expect(labelRect.left, greaterThanOrEqualTo(sectionRect.left));
            expect(counterRect.right, lessThanOrEqualTo(sectionRect.right));
            expect(counterRect.bottom, lessThanOrEqualTo(sectionRect.bottom));
          }
          final sections = find.byType(NoteSection);
          expect(
            tester.getRect(sections.first).bottom,
            lessThan(tester.getRect(sections.last).top),
          );
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
        title.dispose();
        content.dispose();
      },
    );
  }

  testWidgets(
    'Outline title and guide keep separate paint areas with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final content = TextEditingController(
        text: '# Dàn ý\n- [ ] Nhiệm vụ dài với tiếng Việt',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: Scaffold(
            body: ReadingCanvas(
              panel: false,
              child: WritingToolsPanel(
                controller: content,
                readOnly: false,
                onToggle: (_, _) {},
                onHeading: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final title = tester.getRect(find.text('Dàn ý & checklist'));
      final guide = tester.getRect(
        find.text('Dùng # tiêu đề và - [ ] việc cần làm'),
      );
      expect(title.bottom + 5, lessThanOrEqualTo(guide.top));
      expect(title.overlaps(guide), false);
      final tile = tester.getRect(find.byType(ExpansionTile));
      expect(title.top, greaterThanOrEqualTo(tile.top));
      expect(guide.bottom, lessThanOrEqualTo(tile.bottom));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      content.dispose();
    },
  );

  testWidgets(
    'Section editing stays durable and preserves caret through scaled toolbar, theme and resize',
    (tester) async {
      final c = offlineController()
        ..notes = [
          const Note(
            id: 'n',
            title: 'Tiêu đề',
            content: 'Nội dung',
            revision: 7,
            updatedAt: '2026-10-06',
            labels: ['l'],
          ),
        ];
      c.labelCatalogue['l'] = {
        'name': 'Một nhãn dài để kiểm tra giao diện khi tăng cỡ chữ',
        'revision': 1,
      };
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      Widget app(Brightness b) => MaterialApp(
        theme: noteTheme(b),
        home: EditorScreen(controller: c, id: 'n'),
      );
      await tester.pumpWidget(app(Brightness.light));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('editor-tools-menu')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('note-content')));
      await tester.enterText(
        find.byKey(const Key('note-content')),
        'Bản nháp được giữ khi đổi giao diện',
      );
      final field = tester.widget<TextField>(
        find.byKey(const Key('note-content')),
      );
      field.controller!.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 8,
      );
      await tester.pumpWidget(app(Brightness.dark));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump(const Duration(milliseconds: 800));
      final current = tester.widget<TextField>(
        find.byKey(const Key('note-content')),
      );
      expect(identical(current.controller, field.controller), true);
      expect(
        current.controller!.selection,
        const TextSelection(baseOffset: 2, extentOffset: 8),
      );
      expect(c.pending.single['base_revision'], 7);
      expect(
        c.pending.single['content'],
        'Bản nháp được giữ khi đổi giao diện',
      );
      await tester.ensureVisible(find.text('Sắp xếp'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
