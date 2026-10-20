import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/domain/note_document.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/dashboard.dart';
import 'package:note_together/ui/design_system.dart';

import 'support.dart';

class CountingPreviewNote extends Note {
  CountingPreviewNote({super.id = 'counted', String? body})
    : super(
        title: 'Ghi chú hiệu năng',
        content: body ?? 'Nội dung thử nghiệm cho dashboard.',
        revision: 1,
        updatedAt: '2026-10-14',
      );
  int projections = 0;
  @override
  String get plainContent {
    projections++;
    return super.plainContent;
  }
}

void main() {
  testWidgets(
    'Hover at the card edge settles without a stationary-pointer loop',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: noteTheme(Brightness.light),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: PrismCard(
                  onTap: () {},
                  child: const Center(child: Text('Thẻ thử nghiệm')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final bounds = tester.getRect(find.byType(PrismCard));
      final initialLabel = tester.getTopLeft(find.text('Thẻ thử nghiệm'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(Offset(bounds.center.dx, bounds.bottom - 1.5));
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(tester.binding.transientCallbackCount, 0);
      expect(
        tester.getTopLeft(find.text('Thẻ thử nghiệm')).dy,
        closeTo(initialLabel.dy - 2, .1),
      );
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Clear filters cancels a newer query still waiting for debounce',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController()..user!['verified'] = true;
      c.notes = [CountingPreviewNote()];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      final search = find.byKey(const Key('note-search'));
      await tester.enterText(search, 'không tồn tại');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.enterText(search, 'truy vấn đang chờ');
      await tester.ensureVisible(find.text('Xóa tìm kiếm và bộ lọc'));
      await tester.pump();
      await tester.tap(find.text('Xóa tìm kiếm và bộ lọc'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(find.text('Ghi chú hiệu năng'), findsOneWidget);
      expect(find.text('Không tìm thấy ghi chú phù hợp'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('Sync status pulses update without rebuilding the library', (
    tester,
  ) async {
    final c = offlineController()..user!['verified'] = true;
    final note = CountingPreviewNote();
    c.notes = [note];
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    final initial = note.projections;
    final header = tester.widget<DashboardHeader>(
      find.byKey(const Key('dashboard-header')),
    );
    var replacements = 0;
    for (var i = 0; i < 20; i++) {
      c.online = i.isEven;
      c.notifyListeners();
      await tester.pump();
      if (!identical(
        header,
        tester.widget<DashboardHeader>(
          find.byKey(const Key('dashboard-header')),
        ),
      )) {
        replacements++;
      }
    }
    // These counters measure UI work, not GPU FPS or device presentation.
    // ignore: avoid_print
    print(
      'DASHBOARD_PULSE_PROBE replacements=$replacements '
      'preview_projections=${note.projections - initial}',
    );
    expect(find.text('Offline · 0 thay đổi chờ'), findsOneWidget);
    expect(replacements, 0);
    expect(note.projections, initial);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('Pressed card retains the entire edge tap target', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: noteTheme(Brightness.light),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: PrismCard(
                onTap: () => taps++,
                child: const Text('Nhấn ở mép'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = tester.getRect(find.byType(PrismCard));
    final gesture = await tester.startGesture(
      Offset(before.left + 1.5, before.bottom - 1.5),
    );
    await tester.pump(const Duration(milliseconds: 240));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.getRect(find.byType(PrismCard)), before);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Keyboard focus is visible above the card and Enter activates it',
    (tester) async {
      for (final brightness in Brightness.values) {
        var taps = 0;
        final theme = noteTheme(brightness);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: PrismCard(
                    onTap: () => taps++,
                    child: const Text('Chọn bằng bàn phím'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final before = tester.getRect(find.byType(PrismCard));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final ring = find.byKey(const Key('prism-card-focus-ring'));
        expect(ring, findsOneWidget);
        final decoration =
            tester.widget<DecoratedBox>(ring).decoration as BoxDecoration;
        expect(
          decoration.border,
          Border.all(color: theme.colorScheme.primary, width: 2),
        );
        expect(tester.getRect(find.byType(PrismCard)), before);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(taps, 1);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'Preview survives theme/font changes and purges immediately on remote lock',
    (tester) async {
      final c = offlineController()..user!['verified'] = true;
      final note = CountingPreviewNote();
      c.notes = [note];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      final initial = note.projections;
      c.preferences['dark'] = true;
      c.notifyListeners();
      await tester.pumpAndSettle();
      c.preferences['font_size'] = 20.0;
      c.notifyListeners();
      await tester.pumpAndSettle();
      expect(note.projections, initial);
      final preview = tester.widget<Text>(find.text(note.content));
      expect(preview.style!.fontSize, 20);
      c.notes = [
        Note(
          id: note.id,
          title: 'Bản mới',
          content: 'Nội dung mới riêng tư',
          revision: 2,
          updatedAt: '2026-10-14',
        ),
      ];
      c.notifyListeners();
      await tester.pump();
      expect(find.text('Nội dung mới riêng tư'), findsOneWidget);
      c.notes = [
        Note(
          id: note.id,
          title: '',
          content: '',
          revision: 3,
          updatedAt: '',
          locked: true,
          pinnedAt: '2026-10-14',
          shared: true,
        ),
      ];
      c.notifyListeners();
      await tester.pump();
      expect(find.text('Nội dung mới riêng tư'), findsNothing);
      expect(find.text('Bản mới'), findsNothing);
      expect(find.text('Mở khóa để xem nội dung.'), findsOneWidget);
      expect(find.text('Đã ghim'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'Home still reacts to profile, label rename, deletion and pending-note changes',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = offlineController()..user!['verified'] = true;
      c.labels = ['topic'];
      c.labelCatalogue = {
        'topic': {'name': 'Chủ đề cũ', 'deleted': false},
      };
      c.notes = [
        const Note(
          id: 'metadata',
          title: 'Thông tin thay đổi',
          content: 'Nội dung',
          labels: ['topic'],
          revision: 1,
          updatedAt: '2026-10-14',
        ),
      ];
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.text('#Chủ đề cũ'), findsOneWidget);
      c.user!['name'] = 'Zara';
      c.labelCatalogue['topic']!['name'] = 'Chủ đề mới';
      c.pending = [
        {'note_id': 'metadata', 'op_id': 'pending-ui'},
      ];
      c.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('#Chủ đề cũ'), findsNothing);
      expect(find.text('#Chủ đề mới'), findsOneWidget);
      expect(find.text('Chờ đồng bộ'), findsOneWidget);
      c.labelCatalogue['topic']!['deleted'] = true;
      c.labels = [];
      c.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('#Chủ đề mới'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('500 rich notes remain lazy during sync pulses and view toggling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = offlineController()..user!['verified'] = true;
    final rich =
        noteDocumentPrefix +
        jsonEncode([
          for (var i = 0; i < 30; i++)
            {
              'insert': 'Đo dashboard $i. ',
              'attributes': {'bold': true},
            },
          {'insert': '\n'},
        ]);
    final notes = [
      for (var i = 0; i < 500; i++)
        CountingPreviewNote(id: 'rich-$i', body: rich),
    ];
    c.notes = notes;
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    await tester.pumpAndSettle();
    int projections() => notes.fold(0, (sum, note) => sum + note.projections);
    final initial = projections();
    expect(initial, lessThan(30));
    final watch = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      c.online = i.isEven;
      c.notifyListeners();
      await tester.pump();
    }
    watch.stop();
    // Scope: widget harness CPU wall time/work counts; not a frame/FPS benchmark.
    // ignore: avoid_print
    print(
      'DASHBOARD_500_PROBE visible_projections=$initial '
      'pulse_projections=${projections() - initial} pulse_wall_us=${watch.elapsedMicroseconds}',
    );
    expect(projections(), initial);
    c.preferences['grid'] = false;
    c.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('500 ghi chú'), findsOneWidget);
    expect(find.byType(PrismCard).evaluate().length, lessThan(30));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
