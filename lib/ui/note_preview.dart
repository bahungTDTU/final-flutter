import 'package:flutter/material.dart';

import '../domain/note.dart';
import '../l10n/app_strings.dart';
import '../state/note_listing.dart';

/// Only the bounded visible excerpt is retained in this mounted row.
/// Content replacement/relock updates it immediately, with no exit transition.
class NotePreview extends StatefulWidget {
  const NotePreview({
    super.key,
    required this.note,
    required this.style,
    required this.maxLines,
  });
  final Note note;
  final TextStyle style;
  final int maxLines;
  @override
  State<NotePreview> createState() => _NotePreviewState();
}

class _NotePreviewState extends State<NotePreview> {
  late String excerpt;
  @override
  void initState() {
    super.initState();
    excerpt = noteCardPreview(widget.note);
  }

  @override
  void didUpdateWidget(covariant NotePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id ||
        oldWidget.note.locked != widget.note.locked ||
        oldWidget.note.content != widget.note.content) {
      excerpt = noteCardPreview(widget.note);
    }
  }

  @override
  Widget build(BuildContext context) => Text(
    widget.note.locked ? context.tr('Mở khóa để xem nội dung.') : excerpt,
    maxLines: widget.maxLines,
    overflow: TextOverflow.ellipsis,
    style: widget.style,
  );
}
