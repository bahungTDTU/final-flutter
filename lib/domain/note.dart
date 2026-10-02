class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.revision,
    required this.updatedAt,
    this.pinnedAt,
    this.labels = const [],
    this.labelNames = const {},
    this.role = 'owner',
    this.locked = false,
    this.sharedCount = 0,
    this.sharedByName,
    this.sharedByEmail,
    this.sharedAt,
  });
  final String id, title, content, updatedAt, role;
  final int revision;
  final String? pinnedAt;
  final List<String> labels;
  final Map<String, String> labelNames;
  final bool locked;
  final int sharedCount;
  final String? sharedByName, sharedByEmail, sharedAt;
  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Ghi chú đã khóa',
    content: json['content'] as String? ?? '',
    revision: json['revision'] as int,
    updatedAt: json['updated_at'] as String? ?? '',
    pinnedAt: json['pinned_at'] as String?,
    labels: (json['labels'] as List? ?? []).cast<String>(),
    labelNames: Map<String, String>.from(json['label_names'] as Map? ?? {}),
    role: json['role'] as String? ?? 'viewer',
    locked: json['locked'] as bool? ?? false,
    sharedCount: json['shared_count'] as int? ?? 0,
    sharedByName: (json['shared_by'] as Map?)?['name'] as String?,
    sharedByEmail: (json['shared_by'] as Map?)?['email'] as String?,
    sharedAt: json['shared_at'] as String?,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'revision': revision,
    'updated_at': updatedAt,
    'pinned_at': pinnedAt,
    'labels': labels,
    'label_names': labelNames,
    'role': role,
    'locked': locked,
    if (!locked) ...{
      'shared_count': sharedCount,
      'shared_by': {'name': sharedByName, 'email': sharedByEmail},
      'shared_at': sharedAt,
    },
  };

  /// Preserve the optimistic content/base while accepting server permissions.
  Note withAccessFrom(Note remote) => Note(
    id: id,
    title: title,
    content: content,
    revision: revision,
    updatedAt: updatedAt,
    pinnedAt: pinnedAt,
    labels: labels,
    labelNames: labelNames,
    role: remote.role,
    sharedCount: remote.sharedCount,
    sharedByName: remote.sharedByName,
    sharedByEmail: remote.sharedByEmail,
    sharedAt: remote.sharedAt,
  );
}

int compareNotes(Note a, Note b) {
  if ((a.pinnedAt != null) != (b.pinnedAt != null)) {
    return a.pinnedAt != null ? -1 : 1;
  }
  final time = (b.pinnedAt ?? b.updatedAt).compareTo(a.pinnedAt ?? a.updatedAt);
  return time != 0 ? time : a.id.compareTo(b.id);
}

bool validNote(String title, String content) =>
    title.trim().isNotEmpty && content.trim().isNotEmpty;
