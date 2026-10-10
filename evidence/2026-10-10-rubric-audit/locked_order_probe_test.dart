import 'package:flutter_test/flutter_test.dart';
import 'package:note_together/domain/note.dart';
import 'package:note_together/state/note_listing.dart';

void main() {
  test('Rubric 17: newest unpinned protected note retains date order', () {
    // Fixture of API projection: the protected note was most recently updated
    // on the server, but its public listing intentionally carries no date.
    final newestProtected = Note.fromListingJson({
      'id': 'protected-new', 'locked': true, 'revision': 2, 'role': 'owner',
      'pinned_at': null, 'shared': false,
    });
    const olderOrdinary = Note(
      id: 'ordinary-old', title: 'Older ordinary fixture', content: 'Body',
      revision: 1, updatedAt: '2026-10-08T00:00:00Z',
    );
    // Input is already newest-first, as an ordered server result could be.
    final result = NoteListingCache().select(
      account: 'audit-fixture', notes: [newestProtected, olderOrdinary],
      query: '', shared: false, labels: {}, deletedLabels: {},
    );
    expect(result.all.map((note) => note.id).toList(),
        ['protected-new', 'ordinary-old']);
  });
}
