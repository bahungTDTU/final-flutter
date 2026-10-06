import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/note_listing.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/design_system.dart';
import 'package:note_together/ui/editor.dart';
import 'package:note_together/ui/writing_studio.dart';

import 'support.dart';

Note fixture(
  String id, {
  String role = 'owner',
  String content = 'Ý chính',
  bool locked = false,
  List<String> labels = const ['l'],
  String? pin,
}) => Note(
  id: id,
  title: 'Ghi chú $id',
  content: content,
  role: role,
  labels: labels,
  locked: locked,
  pinnedAt: pin,
  revision: 5,
  updatedAt: '2026-10-06',
);

void main() {
  test('Listing reuses status-only view but invalidates in-place replacements, tombstones and accounts', () {
    final cache = NoteListingCache(),
        notes = [fixture('owner'), fixture('shared', role: 'editor')];
    NoteListing select({
      String account = 'A',
      Set<String> deleted = const {},
      bool shared = false,
    }) => cache.select(
      account: account,
      notes: notes,
      query: 'ý',
      shared: shared,
      labels: {'l'},
      deletedLabels: deleted,
    );
    final first = select();
    expect(first.all.single.id, 'owner');
    expect(identical(first, select()), true);
    expect(select(shared: true).all.single.id, 'shared');
    expect(select(deleted: {'l'}).all, isEmpty);
    expect(identical(first, select(account: 'B')), false);
    notes[0] = fixture('owner', locked: true, content: 'Hidden title');
    cache.invalidateSource('B', notes);
    expect(select(account: 'B').all, isEmpty);
    notes[0] = fixture('owner', content: 'Ý mới', pin: '2026-10-06');
    final newView = select(account: 'B');
    expect(newView.pinned.single.content, 'Ý mới');
    expect(newView.remaining, isEmpty);
    final boundary = const Note(
      id: 'b',
      title: 'C++ Cuối',
      content: 'Đầu .[a]',
      revision: 1,
      updatedAt: '2026-10-06',
    );
    for (final query in ['c++', 'cuối đầu', '.[a]', 'ĐẦU']) {
      expect(
        cache
            .select(
              account: 'B',
              notes: [boundary],
              query: query,
              shared: false,
              labels: {},
              deletedLabels: {},
            )
            .all
            .single
            .id,
        'b',
      );
    }
  });

  test('Card shaping input and semantics are bounded without splitting a surrogate or reading locked content', () {
    final text = '${'a' * 479}😀${'b' * 1000}';
    final preview = noteCardPreview(fixture('n', content: text));
    expect(preview, '${'a' * 479}…');
    expect(preview.runes, isNot(contains(0xd83d)));
    expect(
      noteCardPreview(fixture('n', locked: true, content: text)),
      'Mở khóa để xem nội dung.',
    );
  });

  testWidgets(
    'Typing avoids rebuilding note cards until debounce; search still matches beyond bounded preview',
    (tester) async {
      final c = offlineController()..user!['verified'] = true;
      c.notes = [fixture('n', content: '${'Nội dung ' * 2000}Từkhóaởcuối')];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('card-n'));
      final before = tester.widget<PrismCard>(card);
      expect(find.textContaining('Từkhóaởcuối'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('note-search')),
        'Từkhóaởcuối',
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(identical(tester.widget<PrismCard>(card), before), true);
      await tester.pump(const Duration(milliseconds: 220));
      expect(card, findsOneWidget);
      expect(c.notes.single.content, endsWith('Từkhóaởcuối'));
      c.notes = [fixture('n', locked: true, pin: '2026-10-06')];
      c.notifyListeners();
      await tester.pumpAndSettle();
      expect(card, findsNothing);
      await tester.tap(find.byTooltip('Xóa tìm kiếm'));
      await tester.pumpAndSettle();
      expect(find.text('Ghi chú đã khóa'), findsOneWidget);
      expect(find.text('Đã ghim'), findsNothing);
      expect(find.text('06/10/2026'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'Compact gallery footer leaves space in landscape at 200 percent; preview is reachable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 390);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.dark),
          home: const TemplateGallery(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Tạo bản nháp riêng · dùng được offline'), findsNothing);
      final footer = tester
          .widget<Scaffold>(find.byType(Scaffold))
          .bottomNavigationBar!;
      expect(
        tester.getSize(find.byWidget(footer)).height,
        lessThanOrEqualTo(120),
      );
      await tester.tap(find.byKey(const Key('preview-template')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('compact-template-preview')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Đóng xem trước'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('use-template')), findsOneWidget);
    },
  );

  testWidgets(
    'Shared canvas keeps caret and frozen draft base through short landscape/keyboard resize',
    (tester) async {
      final c = offlineController()..notes = [fixture('n')];
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: EditorScreen(controller: c, id: 'n'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('note-content')),
        'Bản nháp qua resize',
      );
      final content = tester
          .widget<TextField>(find.byKey(const Key('note-content')))
          .controller!;
      content.selection = const TextSelection(baseOffset: 1, extentOffset: 4);
      tester.view.viewInsets = const FakeViewPadding(bottom: 160);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ReadingCanvas), findsOneWidget);
      expect(
        content.selection,
        const TextSelection(baseOffset: 1, extentOffset: 4),
      );
      await tester.pump(const Duration(milliseconds: 800));
      expect(c.pending.first['base_revision'], 5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  test('Controlled NotoSans shaping and cached-query benchmark; timings are evidence, not FPS assertions', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('NotoSans')
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    await loader.load();
    final text = ('Tiếng Việt và ghi chú nhóm. ' * 4000).substring(0, 100000);
    final source = fixture('bench', content: text);
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 4,
      ellipsis: '…',
    );
    void shape(String value) {
      painter.text = TextSpan(
        text: value,
        style: const TextStyle(fontFamily: 'NotoSans', fontSize: 16),
      );
      painter.layout(maxWidth: 260);
    }

    int medianMicros(void Function() action) {
      for (var i = 0; i < 4; i++) {
        action();
      }
      final times = <int>[];
      for (var i = 0; i < 11; i++) {
        final watch = Stopwatch()..start();
        action();
        watch.stop();
        times.add(watch.elapsedMicroseconds);
      }
      times.sort();
      return times[times.length ~/ 2];
    }

    // Alternate painter inputs so identical-text paragraph reuse cannot bias either path.
    var fullFlip = false, shortFlip = false;
    final full = medianMicros(() {
      fullFlip = !fullFlip;
      shape('${source.content}${fullFlip ? ' ' : '\n'}');
    });
    final bounded = medianMicros(() {
      shortFlip = !shortFlip;
      shape('${noteCardPreview(source)}${shortFlip ? ' ' : '\n'}');
    });
    final notes = List.generate(500, (i) => fixture('$i', content: text));
    NoteListing query(NoteListingCache cache) => cache.select(
      account: 'A',
      notes: notes,
      query: 'việt',
      shared: false,
      labels: {},
      deletedLabels: {},
    );
    final baseline = medianMicros(() {
      final matches =
          notes
              .where(
                (n) => '${n.title} ${n.content}'.toLowerCase().contains('việt'),
              )
              .toList()
            ..sort(compareNotes);
      assert(matches.length == 500);
    });
    final cold = medianMicros(() => query(NoteListingCache()));
    final cache = NoteListingCache();
    query(cache);
    final cached = medianMicros(() => query(cache));
    expect(query(cache).all.length, 500);
    expect(noteCardPreview(source).length, lessThanOrEqualTo(481));
    // ignore: avoid_print
    print(
      'UI_BENCHMARK ${jsonEncode({'target': 'host Flutter test engine/NotoSans', 'iterations': 11, 'note_chars': text.length, 'preview_chars': noteCardPreview(source).length, 'paragraph_full_median_us': full, 'paragraph_preview_median_us': bounded, 'notes': 500, 'baseline_query_median_us': baseline, 'optimized_query_median_us': cold, 'cached_query_median_us': cached, 'fps_measured': false})}',
    );
    painter.dispose();
  });
}
