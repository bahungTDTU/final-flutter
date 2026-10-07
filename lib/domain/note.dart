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
    this.shared = false,
    this.sharedByName,
    this.sharedByEmail,
    this.sharedAt,
    this.protectionVersion = 0,
  });
  final String id, title, content, updatedAt, role;
  final int revision;
  final int protectionVersion;
  final String? pinnedAt;
  final List<String> labels;
  final Map<String, String> labelNames;
  final bool locked;
  final int sharedCount;
  final bool shared;
  bool get isShared => shared || role != 'owner' || sharedCount > 0;
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
    shared: json['shared'] as bool? ?? false,
    sharedByName: (json['shared_by'] as Map?)?['name'] as String?,
    sharedByEmail: (json['shared_by'] as Map?)?['email'] as String?,
    sharedAt: json['shared_at'] as String?,
    protectionVersion: json['protection_version'] as int? ?? 0,
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
    'shared': isShared,
    if (!locked) ...{
      'shared_count': sharedCount,
      'shared_by': {'name': sharedByName, 'email': sharedByEmail},
      'shared_at': sharedAt,
    },
  };

  /// Home/cache projection. Full protected content belongs only to a live
  /// reader and its password-encrypted envelope, never ordinary list records.
  Map<String, dynamic> toListingJson() => locked
      ? {
          'id': id,
          'locked': true,
          'revision': revision,
          'role': role,
          'pinned_at': pinnedAt,
          'shared': isShared,
        }
      : toJson();

  factory Note.fromListingJson(Map<String, dynamic> json) => Note.fromJson(
    json['locked'] == true
        ? {
            'id': json['id'],
            'locked': true,
            'revision': json['revision'],
            'role': json['role'],
            'pinned_at': json['pinned_at'],
            // Legacy caches may carry the old owner count. Keep only the flag.
            'shared':
                json['shared'] == true ||
                (json['shared_count'] as int? ?? 0) > 0,
          }
        : json,
  );

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
    shared: remote.isShared,
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
