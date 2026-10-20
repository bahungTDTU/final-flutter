import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/l10n/app_strings.dart';
import 'package:note_together/l10n/strings_en.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/rich_note_field.dart';

import 'support.dart';

void main() {
  testWidgets(
    'English auth, settings and live editor fit a phone with 200% text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = offlineController()
        ..user!['verified'] = true
        ..notes = [
          const Note(
            id: 'large',
            title: 'My unchanged title',
            content: 'Original content',
            revision: 4,
            updatedAt: '2026-10-16',
          ),
        ];
      await c.setLanguage('en');
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Profile & preferences'));
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close preferences'));
      await tester.pumpAndSettle();
      await revealHome(tester, find.byKey(const ValueKey('card-large')));
      await tester.tap(find.byKey(const ValueKey('card-large')));
      await tester.pumpAndSettle();
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.byKey(const Key('editor-language-picker')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await c.logout();
      await c.setLanguage('en');
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language-picker')));
      await tester.pumpAndSettle();
      expect(find.text('English'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  test('Resources preserve placeholders and never translate argument data', () {
    final pattern = RegExp(r'\{\d+\}');
    for (final entry in englishMessages.entries) {
      expect(entry.value.trim(), isNotEmpty, reason: entry.key);
      expect(
        pattern.allMatches(entry.value).map((m) => m[0]).toList()..sort(),
        pattern.allMatches(entry.key).map((m) => m[0]).toList()..sort(),
        reason: entry.key,
      );
    }
    const en = AppStrings('en'), vi = AppStrings('vi');
    expect(
      en.text('Thao tác với {0}', ['Ghi chú mới {1}']),
      'Actions for Ghi chú mới {1}',
    );
    expect(
      en.message('Đồng bộ thất bại: ghi chú {0}'),
      'Sync failed: ghi chú {0}',
    );
    expect(
      vi.message('Sync failed: ghi chú {0}'),
      'Đồng bộ thất bại: ghi chú {0}',
    );
    final nested = en.message(
      'Chưa xác nhận lưu ảnh. Email hoặc mật khẩu chưa đúng.',
    );
    expect(nested, isNot(contains('Email hoặc')));
    expect(
      vi.message(nested),
      'Chưa xác nhận lưu ảnh. Email hoặc mật khẩu chưa đúng.',
    );
  });

  test('Public language reopens offline; account language and immutable queue stay isolated', () async {
    final store = MemoryStore();
    final c = offlineController(store: store)..user = null;
    await c.setLanguage('en');
    c.dispose();
    final reopened = AppController(
      Api(
        'http://test',
        client: MockClient((_) async => throw http.ClientException('offline')),
      ),
      store,
    );
    await reopened.initialize();
    expect(reopened.language, 'en');
    reopened.user = {'id': 'A'};
    reopened.token = 'a';
    expect(reopened.language, 'vi');
    await reopened.setLanguage('en');
    while (reopened.syncing) {
      await Future<void>.delayed(Duration.zero);
    }
    final op = Map<String, dynamic>.from(reopened.pendingPreferences.single);
    await reopened.logout();
    reopened.user = {'id': 'B'};
    reopened.token = 'b';
    expect(reopened.language, 'vi');
    expect(reopened.pendingPreferences, isEmpty);
    expect((await store.read('account:A'))!['pending_preferences'], [op]);
    await expectLater(reopened.setLanguage('fr'), throwsArgumentError);
    expect(reopened.pendingPreferences, isEmpty);
    reopened.dispose();
  });

  test('Locale changed during sync overlays the response without mutating the in-flight operation', () async {
    final response = Completer<http.Response>();
    final sent = <Map<String, dynamic>>[];
    final c =
        AppController(
            Api(
              'http://test',
              client: MockClient((r) async {
                if (r.url.path == '/me/preferences/sync') {
                  sent.add(Map<String, dynamic>.from(jsonDecode(r.body)));
                  return response.future;
                }
                if (r.url.path == '/notes') return http.Response('[]', 200);
                return http.Response(
                  jsonEncode({
                    'id': 'A',
                    'preferences': {'locale': 'en', 'dark': true},
                  }),
                  200,
                );
              }),
            ),
            MemoryStore(),
          )
          ..user = {'id': 'A'}
          ..token = 'a';
    await c.setLanguage('en');
    while (sent.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    final first = Map<String, dynamic>.from(sent.single);
    await c.setLanguage('vi');
    response.complete(http.Response('{}', 200));
    while (c.syncing) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(sent.single, first);
    expect(c.language, 'vi');
    expect(c.dark, true);
    expect(c.pendingPreferences.single['locale'], 'vi');
    c.dispose();
  });

  testWidgets(
    'Language picker works before sign-in and updates cached validation without losing input',
    (tester) async {
      final c = offlineController()
        ..user = null
        ..token = null;
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language-picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('auth-email')), 'my-email');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email'), findsOneWidget);
      await c.setLanguage('vi');
      await tester.pumpAndSettle();
      expect(find.text('Nhập email hợp lệ'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('auth-email')))
            .controller!
            .text,
        'my-email',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'Live locale switch preserves rich draft, selection, note identity and frozen revision',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController()
        ..user!['verified'] = true
        ..notes = [
          const Note(
            id: 'n',
            title: 'Ghi chú mới',
            content: 'Tiêu đề nội dung nguyên bản',
            revision: 7,
            updatedAt: '2026-10-15',
          ),
        ];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      await revealHome(tester, find.byKey(const ValueKey('card-n')));
      await tester.tap(find.byKey(const ValueKey('card-n')));
      await tester.pumpAndSettle();
      final field = find.byType(NoteRichTextField);
      final document = tester.widget<NoteRichTextField>(field).document;
      document.replaceVisibleText('Nội dung soạn dở không bị dịch');
      await tester.pump();
      document.selection = const TextSelection(baseOffset: 2, extentOffset: 8);
      final selected = document.selection;
      final original = document.source.text;
      await c.setLanguage('en');
      await tester.pumpAndSettle();
      expect(
        identical(tester.widget<NoteRichTextField>(field).document, document),
        true,
      );
      expect(document.source.text, original);
      expect(document.selection, selected);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      final title = tester
          .widget<TextField>(find.byKey(const Key('note-title')))
          .controller;
      expect(title!.text, 'Ghi chú mới');
      await tester.pump(const Duration(seconds: 2));
      expect(
        c.pending.where((op) => op['note_id'] == 'n').last['base_revision'],
        7,
      );
      await c.setLanguage('vi');
      await tester.pumpAndSettle();
      expect(document.source.text, original);
      expect(document.selection, selected);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'English Home retains user titles, private lock boundaries, query and layout across themes and resize',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final c = offlineController()
        ..user!['verified'] = true
        ..notes = [
          const Note(
            id: 'n',
            title: 'Ghi chú mới',
            content: 'Nội dung tiếng Việt',
            revision: 1,
            updatedAt: '2026-10-15',
          ),
          const Note(
            id: 'lock',
            title: 'Bí mật cấm hiển thị',
            content: 'Riêng tư cấm hiển thị',
            revision: 1,
            updatedAt: '2026-10-15',
            locked: true,
          ),
        ];
      await c.setLanguage('en');
      final semantics = tester.ensureSemantics();
      for (final dark in [false, true]) {
        c.preferences['dark'] = dark;
        c.notifyListeners();
        for (final size in [
          const Size(1280, 1000),
          const Size(375, 812),
          const Size(844, 390),
        ]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(NoteTogetherApp(controller: c));
          await tester.pumpAndSettle();
          expect(find.text('Your notes'), findsOneWidget);
          await revealHome(tester, find.byKey(const ValueKey('card-lock')));
          expect(find.textContaining('Bí mật cấm hiển thị'), findsNothing);
          expect(find.textContaining('Riêng tư cấm hiển thị'), findsNothing);
          expect(find.text('Unlock to view content.'), findsOneWidget);
          expect(
            tester.getSemantics(find.byType(Scaffold)).toStringDeep(),
            isNot(contains('Bí mật cấm hiển thị')),
          );
          expect(tester.takeException(), isNull, reason: '$size dark=$dark');
          tester
              .state<ScrollableState>(
                find
                    .descendant(
                      of: find.byType(CustomScrollView).first,
                      matching: find.byType(Scrollable),
                    )
                    .first,
              )
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
        }
      }
      await tester.enterText(
        find.byKey(const Key('note-search')),
        'Ghi chú mới',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await c.setLanguage('vi');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-search')))
            .controller!
            .text,
        'Ghi chú mới',
      );
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
      c.dispose();
    },
  );
}
