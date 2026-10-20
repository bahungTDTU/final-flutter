import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/l10n/app_strings.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/palette_picker.dart';
import 'package:note_together/ui/rich_note_field.dart';

import 'support.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
}

void main() {
  test('All six palettes meet text contrast in twelve themes; chrome stays distinct and cached', () {
    final primaries = <Color>{}, canvases = <Color>{};
    for (final p in AppPalette.values) {
      for (final brightness in Brightness.values) {
        final theme = noteTheme(brightness, palette: p), s = theme.colorScheme;
        expect(identical(theme, noteTheme(brightness, palette: p)), true);
        var minimum = 100.0;
        for (final surface in [
          theme.scaffoldBackgroundColor,
          s.surface,
          s.surfaceContainerLowest,
          s.surfaceContainerLow,
          s.surfaceContainer,
          s.surfaceContainerHigh,
          s.surfaceContainerHighest,
        ]) {
          for (final ink in [s.onSurface, s.onSurfaceVariant]) {
            final ratio = contrast(ink, surface);
            if (ratio < minimum) minimum = ratio;
            expect(
              ratio,
              greaterThanOrEqualTo(4.5),
              reason: '$p $brightness surface text',
            );
          }
        }
        for (final pair in [
          (s.onPrimary, s.primary),
          (s.onSecondary, s.secondary),
          (s.onTertiary, s.tertiary),
          (s.onPrimaryContainer, s.primaryContainer),
          (s.onSecondaryContainer, s.secondaryContainer),
          (s.onTertiaryContainer, s.tertiaryContainer),
          (s.onError, s.error),
          (s.onErrorContainer, s.errorContainer),
        ]) {
          expect(
            contrast(pair.$1, pair.$2),
            greaterThanOrEqualTo(4.5),
            reason: '$p $brightness action',
          );
        }
        for (final bg in theme.extension<PaletteTokens>()!.brand) {
          expect(contrast(Colors.white, bg), greaterThanOrEqualTo(4.5));
        }
        expect(contrast(s.outline, s.surface), greaterThanOrEqualTo(3));
        debugPrint(
          'PALETTE_CONTRAST ${p.name} ${brightness.name} body_min=${minimum.toStringAsFixed(2)}',
        );
      }
      primaries.add(
        noteTheme(Brightness.light, palette: p).colorScheme.primary,
      );
      canvases.add(
        noteTheme(Brightness.light, palette: p).scaffoldBackgroundColor,
      );
    }
    expect(primaries.length, 6);
    expect(canvases.length, 6);
  });
  test('Palette is durable offline and queues remain isolated after account switch', () async {
    final store = MemoryStore();
    final a = offlineController(store: store);
    await store.write('session', {'user': a.user, 'token': a.token});
    await a.setPreferences({'palette': 'iris', 'dark': true, 'locale': 'en'});
    while (a.syncing) {
      await Future<void>.delayed(Duration.zero);
    }
    final op = Map<String, dynamic>.from(a.pendingPreferences.single);
    a.dispose();
    final reopened = AppController(
      Api(
        'http://test',
        client: MockClient((_) async => throw http.ClientException('offline')),
      ),
      store,
    );
    await reopened.initialize();
    expect(reopened.palette, AppPalette.iris);
    expect(reopened.dark, true);
    expect(reopened.language, 'en');
    expect(reopened.pendingPreferences.single, op);
    await expectLater(
      reopened.setPreferences({'palette': 'random'}),
      throwsArgumentError,
    );
    await reopened.logout();
    expect(reopened.palette, AppPalette.atelier);
    reopened.user = {'id': 'B'};
    reopened.token = 'B';
    expect(reopened.palette, AppPalette.atelier);
    expect(reopened.pendingPreferences, isEmpty);
    expect((await store.read('account:A'))!['pending_preferences'], [op]);
    reopened.dispose();
  });
  test('Changing palette during sync preserves operation bytes and newer local overlay', () async {
    final reply = Completer<http.Response>(), sent = <Map<String, dynamic>>[];
    final c =
        AppController(
            Api(
              'http://test',
              client: MockClient((r) async {
                if (r.url.path == '/me/preferences/sync') {
                  sent.add(Map<String, dynamic>.from(jsonDecode(r.body)));
                  return reply.future;
                }
                if (r.url.path == '/notes') return http.Response('[]', 200);
                return http.Response(
                  jsonEncode({
                    'id': 'A',
                    'preferences': {
                      'palette': 'ocean',
                      'locale': 'en',
                      'dark': true,
                    },
                  }),
                  200,
                );
              }),
            ),
            MemoryStore(),
          )
          ..user = {'id': 'A'}
          ..token = 'a';
    await c.setPreferences({'palette': 'ocean'});
    while (sent.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    final first = Map<String, dynamic>.from(sent.single);
    await c.setPreferences({'palette': 'forest'});
    reply.complete(http.Response('{}', 200));
    while (c.syncing) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(sent.single, first);
    expect(c.palette, AppPalette.forest);
    expect(c.dark, true);
    expect(c.language, 'en');
    expect(c.pendingPreferences.single['palette'], 'forest');
    c.dispose();
  });
  testWidgets(
    'Picker wraps on small and landscape screens at 200% in both languages and themes',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = offlineController();
      for (final language in ['vi', 'en']) {
        for (final dark in [false, true]) {
          for (final size in [const Size(320, 640), const Size(844, 390)]) {
            tester.view.physicalSize = size;
            await tester.pumpWidget(
              MaterialApp(
                locale: Locale(language),
                supportedLocales: AppStrings.supportedLocales,
                localizationsDelegates: const [
                  AppStrings.delegate,
                  ...GlobalMaterialLocalizations.delegates,
                ],
                theme: noteTheme(
                  dark ? Brightness.dark : Brightness.light,
                  palette: AppPalette.rose,
                ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: PalettePicker(controller: c),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byType(PaletteThumbnail), findsNWidgets(6));
            expect(
              tester.takeException(),
              isNull,
              reason: '$size $language $dark',
            );
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'Native palette buttons expose selected state, work with keyboard and reject an account change',
    (tester) async {
      final semantics = tester.ensureSemantics(), c = offlineController();
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: Scaffold(
            body: SingleChildScrollView(child: PalettePicker(controller: c)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(c.palette, AppPalette.ocean);
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('palette-ocean')))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      c.user = {'id': 'B'};
      c.token = 'new';
      c.notifyListeners();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const ValueKey('palette-rose')))
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
      c.dispose();
    },
  );
  testWidgets(
    'Editor picker changes global colors without replacing document, selection or frozen base',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController()
        ..user!['verified'] = true
        ..notes = [
          const Note(
            id: 'n',
            title: 'Original title',
            content: 'Original body',
            revision: 7,
            updatedAt: '2026-10-16',
          ),
        ];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await revealHome(tester, find.byKey(const ValueKey('card-n')));
      await tester.tap(find.byKey(const ValueKey('card-n')));
      await tester.pumpAndSettle();
      final field = find.byType(NoteRichTextField),
          document = tester
              .widget<NoteRichTextField>(find.byType(NoteRichTextField))
              .document;
      document.replaceVisibleText('Draft keeps its formatting and selection');
      await tester.pump();
      document.selection = const TextSelection(baseOffset: 2, extentOffset: 8);
      final source = document.source.text, selection = document.selection;
      await tester.tap(find.byTooltip('Bảng màu giao diện'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('palette-iris')));
      await tester.pumpAndSettle();
      expect(c.palette, AppPalette.iris);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      expect(
        identical(tester.widget<NoteRichTextField>(field).document, document),
        true,
      );
      expect(document.source.text, source);
      expect(document.selection, selection);
      expect(PaletteTokens.of(tester.element(field)).id, AppPalette.iris);
      await tester.pump(const Duration(seconds: 2));
      expect(
        c.pending.where((op) => op['note_id'] == 'n').last['base_revision'],
        7,
      );
      expect(c.notes.single.title, 'Original title');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
