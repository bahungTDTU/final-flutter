import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/domain/note_plan.dart';
import 'package:note_together/l10n/app_strings.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/editor.dart';
import 'package:note_together/ui/note_filters.dart';
import 'package:note_together/ui/planner.dart';
import 'package:note_together/ui/sharing.dart';

import 'support.dart';

const auditNote = Note(
  id: 'audit',
  title: 'My note',
  content: 'Keep this content',
  revision: 4,
  updatedAt: '2026-10-20',
);

Widget shell(
  Widget home, {
  String language = 'vi',
  double scale = 1,
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppStrings.supportedLocales,
  localizationsDelegates: const [
    AppStrings.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  theme: noteTheme(brightness),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);

void main() {
  testWidgets(
    'Sharing clears recipients only after success in either language',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final language in ['en', 'vi']) {
        for (final (accepted, lostAck) in [
          (true, false),
          (false, false),
          (true, true),
        ]) {
          var requests = 0;
          final payloads = <String>[];
          final c =
              AppController(
                  Api(
                    'http://test',
                    client: MockClient((r) async {
                      Object body;
                      var status = 200;
                      if (r.url.path == '/notes/audit/shares/sync') {
                        requests++;
                        payloads.add(r.body);
                        if (lostAck && requests == 1) {
                          throw http.ClientException('lost ACK');
                        }
                        body = accepted
                            ? {'revision': 2, 'recipients': []}
                            : {'detail': 'Recipient not registered'};
                        if (!accepted) status = 404;
                      } else if (r.url.path.endsWith('/shares')) {
                        body = {'revision': 1, 'recipients': []};
                      } else if (r.url.path == '/notes') {
                        body = [auditNote.toJson()];
                      } else {
                        body = {
                          'id': 'A',
                          'email': 'owner@example.test',
                          'preferences': {'locale': language},
                        };
                      }
                      return http.Response(
                        jsonEncode(body),
                        status,
                        headers: {'content-type': 'application/json'},
                      );
                    }),
                  ),
                  MemoryStore(),
                )
                ..user = {'id': 'A', 'email': 'owner@example.test'}
                ..token = 'test-token'
                ..ready = true
                ..notes = [auditNote];
          await tester.pumpWidget(
            shell(
              ShareDialog(controller: c, noteId: 'audit'),
              language: language,
            ),
          );
          await tester.pumpAndSettle();
          final emails = find.byKey(const Key('share-emails'));
          await tester.enterText(emails, 'friend@example.test');
          await tester.ensureVisible(find.byKey(const Key('share-add')));
          await tester.tap(find.byKey(const Key('share-add')));
          await tester.pumpAndSettle();
          if (lostAck) {
            expect(
              tester.widget<TextFormField>(emails).controller!.text,
              'friend@example.test',
            );
            final retry = find.text(
              AppStrings(language).text('Thử lại thao tác'),
            );
            await tester.ensureVisible(retry);
            await tester.pumpAndSettle();
            await tester.tap(retry);
            await tester.pumpAndSettle();
            expect(payloads[1], payloads[0]);
          }
          expect(requests, lostAck ? 2 : 1);
          expect(
            tester.widget<TextFormField>(emails).controller!.text,
            accepted ? '' : 'friend@example.test',
            reason: '$language accepted=$accepted',
          );
          expect(
            find.text(
              AppStrings(language).text(
                accepted
                    ? 'Server đã cập nhật chia sẻ.'
                    : 'Một email chưa đăng ký. Chưa thêm người nhận nào.',
              ),
            ),
            findsOneWidget,
          );
          expect(c.pending, isEmpty);
          expect(c.notes.single.content, auditNote.content);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        }
      }
    },
  );

  testWidgets('Title validation is fully readable on a phone at 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final language in ['vi', 'en']) {
      final c = offlineController()..notes = [auditNote];
      await tester.pumpWidget(
        shell(
          EditorScreen(controller: c, id: 'audit'),
          language: language,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      final input = '👨‍👩‍👧‍👦' * 50;
      await tester.enterText(find.byKey(const Key('note-title')), input);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      final message = AppStrings(language)
          .text('Tiêu đề vượt giới hạn 200 mã Unicode. Bản nháp vẫn được giữ.');
      final inlineError = find.descendant(
        of: find.byKey(const Key('note-title')),
        matching: find.text(message),
      );
      expect(inlineError, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(inlineError).didExceedMaxLines,
        false,
        reason: language,
      );
      expect(c.drafts['audit']['title'], input);
      expect(c.pending, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });

  testWidgets('Planning controls keep large selected labels inside the field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = offlineController()..notes = [auditNote];
    final view = PlannerViewState();
    await tester.pumpWidget(
      shell(
        Scaffold(
          body: CustomScrollView(
            slivers: [PlannerSliver(controller: c, view: view, onOpen: (_) {})],
          ),
        ),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Thêm vào kế hoạch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm vào kế hoạch'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('My note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My note'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<PlanPriority>), findsOneWidget);
    final field = tester.getRect(find.byType(DropdownButton<PlanPriority>));
    final label = tester.getRect(find.text('Bình thường').first);
    expect(label.top, greaterThanOrEqualTo(field.top));
    expect(label.bottom, lessThanOrEqualTo(field.bottom));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(DropdownButton<PlanPriority>));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<PlanPriority>));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cao').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lưu kế hoạch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu kế hoạch'));
    await tester.pumpAndSettle();
    expect(c.workspace.plans['audit']!.priority, PlanPriority.high);
    expect(c.pending, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    view.dispose();
    c.dispose();
  });

  testWidgets(
    'Label filter actions remain reachable above a landscape keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(568, 320);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = offlineController()..labels = ['Project'];
      Set<String>? applied;
      await tester.pumpWidget(
        shell(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  applied = await showModalBottomSheet<Set<String>>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        NoteLabelFilter(controller: c, selected: {'Project'}),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
          scale: 2,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('apply-label-filter')));
      await tester.tap(find.byKey(const Key('apply-label-filter')));
      await tester.pumpAndSettle();
      expect(applied, {'Project'});
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
