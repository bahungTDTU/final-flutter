import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/home.dart';
import 'package:note_together/ui/editor.dart';
import 'package:note_together/domain/note.dart';

import 'support.dart';

class DelayedStore extends MemoryStore {
  final release = Completer<void>();
  bool failNextWrite = false;

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    await release.future;
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Write failed');
    }
    await super.write(key, value);
  }
}

void main() {
  testWidgets(
    'A failed older draft does not mark a newer saved draft as failed',
    (tester) async {
      final store = DelayedStore()..failNextWrite = true;
      final c = offlineController(store: store);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: EditorScreen(controller: c, id: 'n'),
        ),
      );
      final title = find.byKey(const Key('note-title'));
      await tester.enterText(title, 'First');
      await tester.enterText(title, 'Second');
      store.release.complete();
      await tester.pump();
      expect(store.values['account:A']!['drafts']['n']['title'], 'Second');
      expect(find.widgetWithText(TextButton, 'Thử lại'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Closing an editor with a pending draft retires its timer', (
    tester,
  ) async {
    final store = DelayedStore();
    final c = offlineController(store: store);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: EditorScreen(controller: c, id: 'n'),
      ),
    );
    await tester.enterText(find.byKey(const Key('note-title')), 'Draft');
    await tester.pumpWidget(const SizedBox());
    store.release.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(store.values['account:A']!['drafts']['n']['title'], 'Draft');
  });

  testWidgets('Repeated back while saving returns to the library once', (
    tester,
  ) async {
    final store = DelayedStore();
    final c = offlineController(store: store);
    addTearDown(c.dispose);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: nav, home: const Text('Root')),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('Library')),
    );
    await tester.pumpAndSettle();
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(controller: c, id: 'n'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-title')), 'Draft');
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.tap(find.byTooltip('Quay lại'));
    store.release.complete();
    await tester.pumpAndSettle();
    expect(find.text('Library'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Settings apply dark theme, show pending sync and reset at logout',
    (tester) async {
      final c = offlineController();
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.tap(find.byTooltip('Hồ sơ và tùy chỉnh'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Giao diện tối'));
      await tester.tap(find.text('Giao diện tối'));
      await tester.pumpAndSettle();
      expect(c.dark, true);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(find.textContaining('tùy chỉnh chờ đồng bộ'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await c.logout();
      expect(c.dark, false);
      c.dispose();
    },
  );
  testWidgets(
    'Editor preserves base revision when remote changes while typing',
    (tester) async {
      final c = offlineController();
      c.notes = [
        const Note(
          id: 'n',
          title: 'Title',
          content: 'Original',
          revision: 1,
          updatedAt: '2026-10-01',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: EditorScreen(controller: c, id: 'n'),
        ),
      );
      c.notes = [
        const Note(
          id: 'n',
          title: 'Title',
          content: 'Remote edit',
          revision: 2,
          updatedAt: '2026-10-02',
        ),
      ];
      await enterDocumentText(
        tester,
        find.byKey(const Key('note-content')),
        'Local edit',
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(c.pending.single['base_revision'], 1);
      expect(c.pending.single['content'], 'Local edit');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets('Unverified user sees banner and can open editor', (
    tester,
  ) async {
    final c = offlineController();
    await tester.pumpWidget(NoteTogetherApp(controller: c));
    expect(find.byType(UnverifiedBanner), findsOneWidget);
    await tester.tap(find.byKey(const Key('new-note')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-title')), findsOneWidget);
    final id = tester.widget<EditorScreen>(find.byType(EditorScreen)).id;
    await c.setPreferences({'dark': true});
    await tester.pumpAndSettle();
    expect(tester.widget<EditorScreen>(find.byType(EditorScreen)).id, id);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
    'Editor keeps invalid local draft, then auto-saves valid content',
    (tester) async {
      final c = offlineController();
      await tester.pumpWidget(
        MaterialApp(
          home: EditorScreen(controller: c, id: 'new'),
        ),
      );
      await enterDocumentText(
        tester,
        find.byKey(const Key('note-content')),
        'Remember this',
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(c.notes, isEmpty);
      expect(c.drafts['new']['content'], 'Remember this');
      await tester.enterText(find.byKey(const Key('note-title')), 'My note');
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(c.notes.single.title, 'My note');
      expect(c.pending.single['content'], 'Remember this');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'Delete dialog cancellation leaves note intact; confirmation deletes',
    (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await confirmDelete(context, 'My note');
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(result, false);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(result, true);
    },
  );
  testWidgets('Compact layout and scaled text do not overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = offlineController();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: NoteTogetherApp(controller: c),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
