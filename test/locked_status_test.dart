import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/note_listing.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/note_protection.dart';

import 'support.dart';

const secret = Note(
  id: 'protected',
  title: 'Secret title',
  content: 'Secret body',
  revision: 2,
  updatedAt: '2026-10-07T10:00:00Z',
  locked: true,
  pinnedAt: '2026-10-07T01:00:00Z',
  labels: ['private-label'],
  labelNames: {'private-label': 'Secret label'},
  sharedCount: 12,
  sharedByName: 'Secret owner',
  sharedByEmail: 'secret@example.test',
  sharedAt: '2026-10-07T09:00:00Z',
);

void main() {
  test('Listing codec keeps only authorized public status; reader codec keeps full password-vault content', () {
    final row = secret.toListingJson();
    expect(row.keys.toSet(), {
      'id',
      'locked',
      'revision',
      'role',
      'pinned_at',
      'shared',
    });
    expect(row['shared'], true);
    final legacy = Note.fromListingJson(secret.toJson());
    expect(legacy.title, 'Ghi chú đã khóa');
    expect(legacy.content, isEmpty);
    expect(legacy.labels, isEmpty);
    expect(legacy.labelNames, isEmpty);
    expect(legacy.updatedAt, isEmpty);
    expect(legacy.sharedByName, isNull);
    expect(legacy.sharedByEmail, isNull);
    expect(legacy.sharedAt, isNull);
    expect(legacy.sharedCount, 0);
    expect(legacy.pinnedAt, secret.pinnedAt);
    expect(legacy.isShared, true);
    expect(Note.fromJson(secret.toJson()).content, 'Secret body');
  });

  test('Protected pins sort with ordinary pins and update after unpin; search/filter exclude private content', () {
    final cache = NoteListingCache();
    final ordinary = const Note(
      id: 'ordinary',
      title: 'Visible',
      content: 'Visible body',
      revision: 1,
      updatedAt: '2026-10-07',
      pinnedAt: '2026-10-07T00:00:00Z',
    );
    final unpinned = const Note(
      id: 'plain',
      title: 'Plain',
      content: 'Text',
      revision: 1,
      updatedAt: '2099',
    );
    NoteListing select(
      List<Note> notes, {
      String query = '',
      Set<String> labels = const {},
    }) => cache.select(
      account: 'A',
      notes: notes,
      query: query,
      shared: false,
      labels: labels,
      deletedLabels: {},
    );
    final notes = [unpinned, ordinary, secret];
    expect(select(notes).all.map((n) => n.id), [
      'protected',
      'ordinary',
      'plain',
    ]);
    expect(select(notes).pinned.map((n) => n.id), ['protected', 'ordinary']);
    expect(select(notes, query: 'Secret').all, isEmpty);
    expect(select(notes, labels: {'private-label'}).all, isEmpty);
    notes[2] = Note.fromListingJson({
      ...secret.toListingJson(),
      'pinned_at': null,
      'shared': false,
    });
    expect(select(notes).pinned.single.id, 'ordinary');
    expect(select(notes).all.last.isShared, false);
  });

  test('Account reopen migrates stale locked metadata and persists only public flags', () async {
    final store = MemoryStore();
    await store.write('session', {
      'user': {'id': 'A'},
      'token': 'offline-token',
    });
    await store.write('account:A', {
      'notes': [secret.toJson()],
    });
    final controller = offlineController(store: store);
    controller.setForeground(
      false,
    ); // Make the explicit synchronization awaitable.
    await controller.initialize();
    await controller.synchronize();
    final cached = jsonEncode(await store.read('account:A'));
    for (final text in [
      'Secret title',
      'Secret body',
      'Secret label',
      'secret@example.test',
    ]) {
      expect(cached, isNot(contains(text)));
    }
    expect(controller.notes.single.isShared, true);
    expect(controller.notes.single.pinnedAt, secret.pinnedAt);
    controller.dispose();
  });

  test('Protection cooldown has clear UI error for change and disable', () {
    expect(
      protectionError(ApiException(429, 'Try again later')),
      contains('Đợi một phút'),
    );
  });

  for (final grid in [true, false]) {
    testWidgets(
      'Locked status is accessible together in ${grid ? 'grid' : 'list'} without private metadata at 200 percent',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final semantics = tester.ensureSemantics();
        final c = offlineController()..user!['verified'] = true;
        c.preferences['grid'] = grid;
        c.notes = [
          secret,
        ]; // Intentionally stale/full: presentation must still redact.
        await tester.pumpWidget(NoteTogetherApp(controller: c));
        await tester.pumpAndSettle();
        final card = find.byKey(const ValueKey('card-protected'));
        await tester.scrollUntilVisible(
          card,
          200,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(card, findsOneWidget);
        expect(
          find.descendant(of: card, matching: find.text('Đã ghim')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: card,
            matching: find.byIcon(Icons.people_outline),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.byIcon(Icons.lock_outline)),
          findsWidgets,
        );
        final tree = tester.getSemantics(card).toStringDeep();
        expect(tree, contains('Đã ghim'));
        expect(tree, contains('Ghi chú được chia sẻ'));
        expect(tree, contains('Đã khóa'));
        for (final text in [
          'Secret title',
          'Secret body',
          'Secret label',
          'Secret owner',
          'secret@example.test',
          '12 người',
        ]) {
          expect(find.textContaining(text), findsNothing);
          expect(tree, isNot(contains(text)));
        }
        expect(tester.takeException(), isNull);
        c.notes = [
          Note.fromListingJson({
            ...secret.toListingJson(),
            'pinned_at': null,
            'shared': false,
          }),
        ];
        c.notifyListeners();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          card,
          200,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.text('Đã ghim'), findsNothing);
        expect(
          find.descendant(
            of: card,
            matching: find.byIcon(Icons.people_outline),
          ),
          findsNothing,
        );
        expect(find.text('Ghi chú đã khóa'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        semantics.dispose();
        c.dispose();
      },
    );
  }
}
