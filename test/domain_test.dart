import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';

import 'support.dart';

void main() {
  test('Pinned time is descending, unpinned follows, tie-break is stable', () {
    Note note(String id, String time, [String? pin]) => Note(
      id: id,
      title: id,
      content: 'body',
      revision: 1,
      updatedAt: time,
      pinnedAt: pin,
    );
    final notes = [
      note('z', '2026-10-03'),
      note('b', '2026-10-01', '2026-10-02'),
      note('a', '2026-10-01', '2026-10-02'),
      note('c', '2026-10-01', '2026-10-01'),
    ];
    notes.sort(compareNotes);
    expect(notes.map((n) => n.id), ['a', 'b', 'c', 'z']);
  });
  test('Invalid draft persists without creating remote operations', () async {
    final store = MemoryStore(), c = offlineController();
    final controller = offlineController(store: store);
    await controller.draft('draft', '  ', 'body');
    await controller.save('draft', '  ', 'body');
    expect(controller.notes, isEmpty);
    expect(controller.pending, isEmpty);
    expect(
      (await store.read('account:A'))!['drafts']['draft']['content'],
      'body',
    );
    controller.dispose();
    c.dispose();
  });
  test('Offline operations preserve immutable payload and sequential base revisions', () async {
    final store = MemoryStore(), c = offlineController();
    final controller = offlineController(store: store);
    await controller.save('note', 'First', 'body');
    final first = Map<String, dynamic>.from(controller.pending.first);
    await controller.save('note', 'Second', 'updated');
    expect(controller.pending.first, first);
    expect(controller.pending.map((op) => op['base_revision']), [0, 1]);
    expect(controller.pending.map((op) => op['op_id']).toSet().length, 2);
    expect((await store.read('account:A'))!['notes'][0]['content'], 'updated');
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
    c.dispose();
  });
  test(
    'Accounts use separate local namespaces and logout clears visible state',
    () async {
      final store = MemoryStore();
      final a = offlineController(store: store),
          b = offlineController(store: store, id: 'B');
      await a.draft('a', 'A only', 'private');
      await b.draft('b', 'B only', 'other');
      expect((await store.read('account:A'))!['drafts'].keys, ['a']);
      expect((await store.read('account:B'))!['drafts'].keys, ['b']);
      await a.logout();
      expect(a.user, isNull);
      expect(a.notes, isEmpty);
      expect(a.drafts, isEmpty);
      a.dispose();
      b.dispose();
    },
  );
}
