import 'dart:convert';

import 'note.dart';
import 'note_document.dart';
import 'writing_tools.dart';
import 'focus_session.dart';
import 'note_plan.dart';

/// Personal organization. References retain IDs only, never note snapshots.
class WorkspaceData {
  WorkspaceData({
    Set<String>? favorites,
    List<String>? recent,
    List<WorkspaceView>? views,
    List<NoteTemplate>? templates,
    FocusData? focus,
    Map<String, NotePlan>? plans,
  }) : favorites = Set.unmodifiable(favorites ?? {}),
       recent = List.unmodifiable(recent ?? []),
       views = List.unmodifiable(views ?? []),
       templates = List.unmodifiable(templates ?? []),
       focus = focus ?? FocusData(),
       plans = Map.unmodifiable(plans ?? {});
  final Set<String> favorites;
  final List<String> recent;
  final List<WorkspaceView> views;
  final List<NoteTemplate> templates;
  final FocusData focus;
  final Map<String, NotePlan> plans;

  factory WorkspaceData.fromJson(Map? value) {
    final v = value ?? {};
    final templates = <NoteTemplate>[];
    final plans = <String, NotePlan>{};
    for (final value
        in (v['plans'] is List ? v['plans'] as List : const []).take(500)) {
      final plan = NotePlan.parse(value);
      if (plan != null) plans.putIfAbsent(plan.noteId, () => plan);
    }
    for (final item
        in (v['templates'] as List? ?? []).take(30).whereType<Map>()) {
      if (item['id'] is String &&
          item['description'] is String &&
          validPortable(item['title'], item['content'])) {
        templates.add(
          NoteTemplate(
            item['id'],
            item['title'],
            item['description'],
            item['content'],
          ),
        );
      }
    }
    return WorkspaceData(
      favorites: (v['favorites'] as List? ?? [])
          .whereType<String>()
          .take(500)
          .toSet(),
      recent: (v['recent'] as List? ?? [])
          .whereType<String>()
          .take(20)
          .toList(),
      views: (v['views'] as List? ?? [])
          .take(20)
          .whereType<Map>()
          .where(
            (i) =>
                i['id'] is String &&
                i['name'] is String &&
                i['query'] is String,
          )
          .map(
            (i) => WorkspaceView(
              i['id'],
              i['name'],
              i['query'],
              labels: (i['labels'] as List? ?? []).whereType<String>().toSet(),
              shared: i['shared'] == true,
            ),
          )
          .toList(),
      templates: templates,
      focus: FocusData.fromJson(v['focus']),
      plans: plans,
    );
  }
  WorkspaceData copy({
    Set<String>? favorites,
    List<String>? recent,
    List<WorkspaceView>? views,
    List<NoteTemplate>? templates,
    FocusData? focus,
    Map<String, NotePlan>? plans,
  }) => WorkspaceData(
    favorites: favorites ?? this.favorites,
    recent: recent ?? this.recent,
    views: views ?? this.views,
    templates: templates ?? this.templates,
    focus: focus ?? this.focus,
    plans: plans ?? this.plans,
  );
  Map<String, dynamic> toJson() => {
    'version': 1,
    'focus': focus.toJson(),
    'plans': plans.values.map((p) => p.toJson()).toList(),
    'favorites': favorites.toList(),
    'recent': recent,
    'views': views.map((v) => v.toJson()).toList(),
    'templates': templates
        .map(
          (t) => {
            'id': t.id,
            'title': t.title,
            'description': t.description,
            'content': t.content,
          },
        )
        .toList(),
  };
}

class WorkspaceView {
  WorkspaceView(
    this.id,
    this.name,
    this.query, {
    Set<String>? labels,
    this.shared = false,
  }) : labels = Set.unmodifiable(labels ?? {});
  final String id, name, query;
  final Set<String> labels;
  final bool shared;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'query': query,
    'labels': labels.toList(),
    'shared': shared,
  };
  bool matches(Note n) =>
      !n.locked &&
      (shared ? n.role != 'owner' : n.role == 'owner') &&
      labels.every(n.labels.contains) &&
      (query.isEmpty ||
          '${n.title}\n${n.plainContent}'.toLowerCase().contains(
            query.toLowerCase(),
          ));
}

class WorkspaceTask {
  const WorkspaceTask(this.note, this.task);
  final Note note;
  final WritingTask task;
  String get key => '${note.id}:${task.markerOffset}';
}

/// Route-local bounded cache; purge hidden/revoked sources on every selection.
class WorkspaceTaskCache {
  final _entries = <String, (String, WritingSnapshot)>{};
  void purge(List<Note> visible) {
    final ids = visible
        .where((n) => !n.locked)
        .take(200)
        .map((n) => n.id)
        .toSet();
    _entries.removeWhere((id, _) => !ids.contains(id));
  }

  List<WorkspaceTask> select(List<Note> visible) {
    final source = visible.where((n) => !n.locked).take(200).toList();
    final ids = source.map((n) => n.id).toSet();
    _entries.removeWhere((id, _) => !ids.contains(id));
    final rows = <WorkspaceTask>[];
    for (final note in source) {
      var entry = _entries[note.id];
      if (entry == null || entry.$1 != note.content) {
        entry = (note.content, WritingSnapshot(note.content));
        _entries[note.id] = entry;
      }
      rows.addAll(entry.$2.tasks.map((task) => WorkspaceTask(note, task)));
    }
    return rows;
  }

  void clear() => _entries.clear();
}

class PortableNote {
  const PortableNote(this.title, this.content);
  final String title, content;
  Map<String, dynamic> toJson() => {'title': title, 'content': content};
}

bool validPortable(dynamic title, dynamic content) =>
    title is String &&
    content is String &&
    title.trim().length <= 200 &&
    content.length <= 100000 &&
    validNote(title, content) &&
    (!content.startsWith(noteDocumentPrefix) ||
        storedDocumentDelta(content) != null);

/// Portable content only. Permission/owner/ID/revision/grants are never imported.
List<PortableNote> decodeNoteBundle(List<int> bytes) {
  if (bytes.length > 5 * 1024 * 1024) {
    throw const FormatException('File vượt quá 5 MiB.');
  }
  final dynamic data = jsonDecode(utf8.decode(bytes));
  if (data is! Map ||
      data['format'] != 'notetogether-notes' ||
      data['version'] != 1 ||
      data.keys.any((k) => !['format', 'version', 'notes'].contains(k)) ||
      data['notes'] is! List ||
      (data['notes'] as List).isEmpty ||
      (data['notes'] as List).length > 50) {
    throw const FormatException(
      'File NoteTogether không hợp lệ (1–50 ghi chú).',
    );
  }
  final result = <PortableNote>[];
  for (final item in data['notes'] as List) {
    if (item is! Map ||
        item.keys.any((k) => !['title', 'content'].contains(k)) ||
        !validPortable(item['title'], item['content'])) {
      throw const FormatException(
        'Ghi chú có nội dung, định dạng hoặc trường dữ liệu không hợp lệ.',
      );
    }
    result.add(PortableNote((item['title'] as String).trim(), item['content']));
  }
  return result;
}

List<int> encodeNoteBundle(List<Note> notes) {
  if (notes.isEmpty ||
      notes.length > 50 ||
      notes.any(
        (n) =>
            n.locked || n.role != 'owner' || !validPortable(n.title, n.content),
      )) {
    throw const FormatException('Chỉ xuất 1–50 ghi chú của bạn chưa khóa.');
  }
  final bytes = utf8.encode(
    jsonEncode({
      'format': 'notetogether-notes',
      'version': 1,
      'notes': notes
          .map((n) => PortableNote(n.title, n.content).toJson())
          .toList(),
    }),
  );
  if (bytes.length > 5 * 1024 * 1024) {
    throw const FormatException(
      'Bản xuất vượt quá 5 MiB; hãy chọn ít ghi chú hơn.',
    );
  }
  return bytes;
}

NoteTemplate journalTemplate(DateTime now) {
  final day =
      '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  return NoteTemplate(
    'journal',
    'Nhật ký $day',
    'Một khoảng lặng để nhìn lại ngày hôm nay.',
    '# Nhật ký $day\n\n## Điều quan trọng hôm nay\n- [ ] Một việc muốn hoàn thành\n\n## Ý tưởng và ghi nhận\nViết điều bạn muốn giữ lại.\n\n## Điều biết ơn\n- Một điều nhỏ làm ngày hôm nay tốt hơn\n\n## Ngày mai\n- [ ] Ưu tiên tiếp theo',
  );
}
