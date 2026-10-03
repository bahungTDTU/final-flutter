"""Request-local note projection: ACL, labels and metadata in two bounded queries."""
def list_visible_notes(conn, user_id):
    # The caller validates the session in this same transaction. The recipient
    # join proves access; no owner/role/permission values come from a payload.
    rows = conn.execute('''
        SELECT n.*, CASE WHEN n.owner_id=? THEN 'owner' ELSE s.role END AS role,
               s.shared_at, u.name AS owner_name, u.email AS owner_email,
               (SELECT COUNT(*) FROM shares recipients WHERE recipients.note_id=n.id) AS shared_count
        FROM notes n
        JOIN users u ON u.id=n.owner_id
        LEFT JOIN shares s ON s.note_id=n.id AND s.user_id=?
        WHERE n.deleted=0 AND (n.owner_id=? OR s.user_id IS NOT NULL)
    ''', (user_id, user_id, user_id)).fetchall()
    if not rows:
        return []
    # Resolve only labels on visible, unprotected notes. JSON array position
    # preserves label order; foreign-owner/deleted label IDs remain excluded.
    labels = {}
    for row in conn.execute('''
        SELECT n.id AS note_id, l.id, l.name
        FROM notes n
        LEFT JOIN shares s ON s.note_id=n.id AND s.user_id=?
        JOIN json_each(n.labels) j
        JOIN labels l ON l.id=j.value AND l.owner_id=n.owner_id AND l.deleted=0
        WHERE n.deleted=0 AND (n.password IS NULL OR n.password='')
              AND (n.owner_id=? OR s.user_id IS NOT NULL)
        ORDER BY n.id, j.key
    ''', (user_id, user_id)):
        ids, names = labels.setdefault(row['note_id'], ([], {}))
        ids.append(row['id'])
        names[row['id']] = row['name']
    result = []
    for note in rows:
        if note['password']:
            # Even a valid unlock grant never expands list/cache metadata.
            result.append({'id': note['id'], 'locked': True,
                           'revision': note['revision'], 'role': note['role']})
            continue
        ids, names = labels.get(note['id'], ([], {}))
        item = {'id': note['id'], 'owner_id': note['owner_id'], 'title': note['title'],
                'content': note['content'], 'revision': note['revision'], 'updated_at': note['updated_at'],
                'pinned_at': note['pinned_at'], 'labels': ids, 'label_names': names,
                'locked': False, 'role': note['role'], 'deleted': False}
        if note['role'] == 'owner':
            item['shared_count'] = note['shared_count']
        else:
            item['shared_by'] = {'id': note['owner_id'], 'name': note['owner_name'], 'email': note['owner_email']}
            item['shared_at'] = note['shared_at']
        result.append(item)
    return result
