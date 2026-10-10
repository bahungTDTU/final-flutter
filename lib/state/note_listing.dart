import 'package:flutter/foundation.dart';

import '../domain/note.dart';

class NoteListing {
  NoteListing(List<Note> notes)
    : all = List.unmodifiable(notes),
      pinned = List.unmodifiable(notes.where((n) => n.pinnedAt != null)),
      remaining = List.unmodifiable(notes.where((n) => n.pinnedAt == null));
  final List<Note> all, pinned, remaining;
}

/// Route-local view cache. Immutable note replacement, label tombstones and
/// account changes invalidate it; no lowercased private text index is retained.
class NoteListingCache {
  List<Note> _notes = [];
  Set<String> _labels = {}, _deleted = {};
  String? _account, _query;
  bool _shared = false;
  NoteListing? _result;
  bool invalidateSource(String? account, List<Note> notes) {
    final changed = _account != account || !listEquals(_notes, notes);
    if (changed) clear();
    return changed;
  }

  NoteListing select({
    required String? account,
    required List<Note> notes,
    required String query,
    required bool shared,
    required Set<String> labels,
    required Set<String> deletedLabels,
  }) {
    if (_result != null &&
        _account == account &&
        _query == query &&
        _shared == shared &&
        listEquals(_notes, notes) &&
        setEquals(_labels, labels) &&
        setEquals(_deleted, deletedLabels)) {
      return _result!;
    }
    _account = account;
    _query = query;
    _shared = shared;
    _notes = List.of(notes);
    _labels = Set.of(labels);
    _deleted = Set.of(deletedLabels);
    final pattern = query.isEmpty
        ? null
        : RegExp(RegExp.escape(query), caseSensitive: false, unicode: true);
    bool contains(Note note) {
      if (pattern == null) return true;
      if (note.locked) return false;
      final content = note.plainContent;
      if (pattern.hasMatch(note.title) || pattern.hasMatch(content)) {
        return true;
      }
      final start = (note.title.length - query.length).clamp(
        0,
        note.title.length,
      );
      final end = query.length.clamp(0, content.length);
      return pattern.hasMatch(
        '${note.title.substring(start)} ${content.substring(0, end)}',
      );
    }

    // The API array carries last-modified order without exposing locked dates.
    // Persisted account arrays preserve it; local pending edits are prepended.
    // Never derive locked ordering from redacted/legacy private timestamps.
    final sourceOrder = {for (var i = 0; i < notes.length; i++) notes[i].id: i};
    final hasHiddenDates = notes.any((n) => n.locked && n.pinnedAt == null);
    final matches =
        notes
            .where(
              (n) =>
                  (shared ? n.role != 'owner' : n.role == 'owner') &&
                  contains(n) &&
                  (labels.isEmpty ||
                      !n.locked &&
                          labels.every(
                            (label) =>
                                !deletedLabels.contains(label) &&
                                n.labels.contains(label),
                          )),
            )
            .toList()
          ..sort(
            (a, b) => _compareVisibleNotes(a, b, sourceOrder, hasHiddenDates),
          );
    return _result = NoteListing(matches);
  }

  void clear() {
    _notes = [];
    _labels = {};
    _deleted = {};
    _result = null;
    _account = null;
    _query = null;
  }
}

int _compareVisibleNotes(
  Note a,
  Note b,
  Map<String, int> sourceOrder,
  bool hasHiddenDates,
) {
  final aPin = a.pinnedAt, bPin = b.pinnedAt;
  if ((aPin != null) != (bPin != null)) return aPin != null ? -1 : 1;
  if (aPin == null && hasHiddenDates) {
    return sourceOrder[a.id]!.compareTo(sourceOrder[b.id]!);
  }
  final aTime = aPin ?? a.updatedAt;
  final bTime = bPin ?? b.updatedAt;
  final time = bTime.compareTo(aTime);
  return time != 0 ? time : a.id.compareTo(b.id);
}

/// Bound both shaping input and card semantics. Full content remains in editor
/// and full-text search. Do not split a UTF-16 surrogate pair at the boundary.
String noteCardPreview(Note note) {
  if (note.locked) return 'Mở khóa để xem nội dung.';
  const limit = 480;
  final content = note.plainContent;
  if (content.length <= limit) return content;
  final unit = content.codeUnitAt(limit - 1);
  final end = unit >= 0xd800 && unit <= 0xdbff ? limit - 1 : limit;
  return '${content.substring(0, end)}…';
}
