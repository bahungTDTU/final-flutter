import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/l10n/app_strings.dart';
import 'package:note_together/ui/dashboard.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/ui/app.dart';

import 'support.dart';

import 'package:note_together/ui/design_system.dart';

void main() {
  test(
    'Soft studio composed surfaces retain readable text in all twelve themes',
    () {
      double contrast(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
      }

      for (final palette in AppPalette.values) {
        for (final mode in Brightness.values) {
          final theme = noteTheme(mode, palette: palette),
              colors = theme.colorScheme;
          final tones = theme.extension<PrismPalette>()!;
          final backgrounds = [
            ...StudioStyle.headingColors(colors),
            for (final tone in tones.tones) ...[
              Color.alphaBlend(
                tone.light.withValues(alpha: .085),
                colors.surface,
              ),
              Color.alphaBlend(
                tone.light.withValues(alpha: .045),
                tones.canvas,
              ),
            ],
          ];
          for (final background in backgrounds) {
            for (final ink in [colors.onSurface, colors.onSurfaceVariant]) {
              expect(
                contrast(ink, background),
                greaterThanOrEqualTo(4.5),
                reason: '$palette $mode composed surface',
              );
            }
          }
        }
      }
    },
  );

  testWidgets(
    'Studio header actions remain reachable with 200% text in both languages',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var syncs = 0;
      for (final language in ['vi', 'en']) {
        for (final mode in Brightness.values) {
          for (final size in [
            const Size(320, 740),
            const Size(844, 390),
            const Size(1440, 900),
          ]) {
            tester.view.physicalSize = size;
            await tester.pumpWidget(
              MaterialApp(
                locale: Locale(language),
                supportedLocales: AppStrings.supportedLocales,
                localizationsDelegates: const [
                  AppStrings.delegate,
                  ...GlobalMaterialLocalizations.delegates,
                ],
                theme: noteTheme(mode, palette: AppPalette.iris),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(2),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Builder(
                      builder: (context) => DashboardHeader(
                        title: context.tr('Ghi chú của bạn'),
                        detail: context.tr(
                          'Ý tưởng, bài học và kế hoạch — gọn trong một nơi.',
                        ),
                        count: 1000,
                        syncLabel: context.tr('Đồng bộ'),
                        online: true,
                        onSync: () {},
                        workbench: size.width >= 1180,
                        syncIndicator: TextButton.icon(
                          key: const Key('studio-test-sync'),
                          onPressed: () => syncs++,
                          icon: const Icon(Icons.sync),
                          label: Text(context.tr('Đồng bộ')),
                        ),
                        notice: StatusNotice(
                          message: context.tr(
                            'Email của bạn chưa được xác minh.',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final button = find.byKey(const Key('studio-test-sync'));
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
            final previous = syncs;
            await tester.tap(button);
            await tester.pumpAndSettle();
            expect(syncs, previous + 1);
            expect(
              tester.takeException(),
              isNull,
              reason: '$language $mode $size',
            );
            expect(tester.binding.transientCallbackCount, 0);
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Phone quick labels preserve filtering while the full filter stays visible',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = offlineController()
        ..labels = List.generate(6, (i) => 'Nhãn ${i + 1}')
        ..notes = [
          const Note(
            id: 'last',
            title: 'Tìm qua nhãn cuối',
            content: 'Nội dung',
            labels: ['Nhãn 6'],
            revision: 1,
            updatedAt: '2026-10-20',
          ),
        ];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      final filter = find.byKey(const Key('all-label-filters'));
      await revealHome(tester, filter);
      final buttonRect = tester.getRect(filter);
      expect(buttonRect.left, greaterThanOrEqualTo(0));
      expect(buttonRect.right, lessThanOrEqualTo(375));
      final quick = find.byKey(const Key('studio-quick-label-scroll'));
      expect(tester.getSize(quick).height, lessThanOrEqualTo(56));
      await tester.drag(quick, const Offset(-600, 0));
      await tester.pumpAndSettle();
      final last = find.widgetWithText(FilterChip, 'Nhãn 6');
      final scroll = tester
          .state<ScrollableState>(
            find.descendant(of: quick, matching: find.byType(Scrollable)).first,
          )
          .position;
      debugPrint(
        'QUICK_FILTER_PROBE ${tester.getRect(quick)} last=${tester.getRect(last)} filter=${tester.getRect(filter)} offset=${scroll.pixels}/${scroll.maxScrollExtent}',
      );
      expect(last.hitTestable(), findsOneWidget);
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(last).selected, true);
      expect(last.hitTestable(), findsOneWidget);
      expect(tester.getRect(filter), buttonRect);
      await tester.tap(filter);
      await tester.pumpAndSettle();
      expect(find.text('Bộ lọc nhãn'), findsWidgets);
      await tester.tap(find.byTooltip('Đóng bộ lọc'));
      await tester.pumpAndSettle();
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('studio-quick-label-scroll')), findsNothing);
      expect(tester.widget<FilterChip>(last).selected, true);
      expect(c.pending, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'Short landscape header keeps create and sync reachable without a tall empty panel',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(844, 390);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var creates = 0, syncs = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DashboardHeader(
                title: 'Ghi chú của bạn',
                detail: 'Nội dung',
                count: 8,
                syncLabel: 'Đồng bộ',
                online: true,
                onSync: () => syncs++,
                action: IconButton.filled(
                  key: const Key('landscape-create'),
                  onPressed: () => creates++,
                  tooltip: 'Ghi chú mới',
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const Key('studio-heading-surface'))).height,
        lessThan(110),
      );
      await tester.tap(find.byKey(const Key('landscape-create')));
      await tester.tap(find.widgetWithText(TextButton, 'Đồng bộ'));
      await tester.pumpAndSettle();
      expect(creates, 1);
      expect(syncs, 1);
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const Key('studio-heading-surface'))).height,
        lessThan(230),
      );
      await tester.tap(find.byKey(const Key('landscape-create')));
      await tester.pumpAndSettle();
      expect(creates, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
