"""Account label IDs, optimistic revisions and v1 name migration."""
import json
import unicodedata
from uuid import NAMESPACE_URL, uuid5

from fastapi import Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field


def label_name(value):
    name = unicodedata.normalize('NFC', value.strip())
    if not name or len(name) > 60 or any(unicodedata.category(c).startswith('C') for c in name):
        raise HTTPException(422, 'Label name must contain 1-60 visible characters')
    return name


def legacy_id(owner, name):
    return 'legacy_' + uuid5(NAMESPACE_URL, owner + '\0' + name.strip()).hex


def ensure_legacy(conn, owner, value, *, migration=False):
    label_id = legacy_id(owner, value)
    prior = conn.execute('SELECT * FROM labels WHERE id=?', (label_id,)).fetchone()
    if prior:
        return None if prior['deleted'] else prior['id']
    # Existing v1 data is retained even when the new name limit is stricter.
    name = unicodedata.normalize('NFC', value.strip()) if migration else label_name(value)
    if not name:
        return None
    row = conn.execute('SELECT * FROM labels WHERE owner_id=? AND name_key=? AND deleted=0',
                       (owner, name.casefold())).fetchone()
    if row:
        return row['id']
    conn.execute('INSERT INTO labels VALUES (?,?,?,?,1,0)', (label_id, owner, name, name.casefold()))
    return label_id


def migrate(conn):
    version = conn.execute('PRAGMA user_version').fetchone()[0]
    if version > 2:
        raise RuntimeError('Database schema is newer than this app')
    conn.execute('CREATE TABLE IF NOT EXISTS labels (id TEXT PRIMARY KEY, owner_id TEXT NOT NULL REFERENCES users(id), '
                 'name TEXT NOT NULL, name_key TEXT NOT NULL, revision INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0)')
    conn.execute('CREATE UNIQUE INDEX IF NOT EXISTS labels_owner_name ON labels(owner_id,name_key) WHERE deleted=0')
    conn.execute('CREATE TABLE IF NOT EXISTS label_operations (user_id TEXT NOT NULL REFERENCES users(id), '
                 'op_id TEXT NOT NULL, fingerprint TEXT NOT NULL, label_id TEXT NOT NULL, PRIMARY KEY(user_id,op_id))')
    conn.execute('CREATE TABLE IF NOT EXISTS avatars (user_id TEXT PRIMARY KEY REFERENCES users(id), '
                 'revision INTEGER NOT NULL, data BLOB)')
    if version < 2:
        for note in conn.execute('SELECT id,owner_id,labels FROM notes').fetchall():
            ids = list(dict.fromkeys(filter(None, (ensure_legacy(conn, note['owner_id'], value, migration=True)
                                                   for value in json.loads(note['labels'])))))
            conn.execute('UPDATE notes SET labels=? WHERE id=?', (json.dumps(ids), note['id']))
        conn.execute('PRAGMA user_version=2')


def note_labels(conn, note):
    ids, names = [], {}
    for label_id in json.loads(note['labels']):
        row = conn.execute('SELECT * FROM labels WHERE id=? AND owner_id=? AND deleted=0',
                           (label_id, note['owner_id'])).fetchone()
        if row:
            ids.append(label_id)
            names[label_id] = row['name']
    return ids, names


def normalize_labels(conn, owner, values, format):
    ids = []
    for value in values:
        row = conn.execute('SELECT * FROM labels WHERE id=?', (value,)).fetchone()
        if row:
            if row['owner_id'] != owner:
                raise HTTPException(422, 'Label unavailable')
            label_id = None if row['deleted'] else value
        elif format == 'ids':
            raise HTTPException(422, 'Label unavailable')
        else:
            label_id = ensure_legacy(conn, owner, value)
        if label_id and label_id not in ids:
            ids.append(label_id)
    return json.dumps(ids)


class LabelOperation(BaseModel):
    model_config = ConfigDict(extra='forbid', strict=True)
    op_id: str = Field(min_length=1, max_length=80)
    label_id: str = Field(min_length=1, max_length=80)
    base_revision: int = Field(ge=0)
    kind: str = Field(pattern='^(upsert|delete)$')
    name: str = Field(default='', max_length=120)


def install_label_routes(app, db, authenticate, validate_session, digest):
    def read(row):
        return {'id': row['id'], 'name': row['name'], 'revision': row['revision'], 'deleted': bool(row['deleted'])}

    @app.get('/labels')
    def catalogue(identity=Depends(authenticate)):
        with db() as conn:
            validate_session(conn, identity)
            return [read(row) for row in conn.execute('SELECT * FROM labels WHERE owner_id=? ORDER BY name_key,id', (identity[0],))]

    @app.post('/labels/sync')
    def sync_label(body: LabelOperation, identity=Depends(authenticate)):
        name = label_name(body.name) if body.kind == 'upsert' else ''
        fingerprint = digest(body.model_dump_json())
        with db() as conn:
            validate_session(conn, identity)
            row = conn.execute('SELECT * FROM labels WHERE id=?', (body.label_id,)).fetchone()
            if row and row['owner_id'] != identity[0]:
                raise HTTPException(404, 'Label unavailable')
            prior = conn.execute('SELECT * FROM label_operations WHERE user_id=? AND op_id=?', (identity[0], body.op_id)).fetchone()
            if prior:
                if prior['fingerprint'] != fingerprint:
                    raise HTTPException(409, 'Label operation ID reused with different data')
                return read(row)
            revision = row['revision'] if row else 0
            migration_match = (row and body.kind == 'upsert' and body.base_revision == 0 and
                               body.label_id.startswith('legacy_') and revision == 1 and not row['deleted'] and row['name'] == name)
            if not migration_match:
                if revision != body.base_revision or row and row['deleted']:
                    raise HTTPException(409, {'message': 'Label revision conflict', 'remote': read(row) if row else None})
                if body.kind == 'delete':
                    if not row:
                        raise HTTPException(404, 'Label unavailable')
                    # Tombstone filters associations without changing note content/revisions.
                    conn.execute('UPDATE labels SET deleted=1,revision=revision+1 WHERE id=?', (body.label_id,))
                else:
                    duplicate = conn.execute('SELECT * FROM labels WHERE owner_id=? AND name_key=? AND deleted=0 AND id<>?',
                                             (identity[0], name.casefold(), body.label_id)).fetchone()
                    if duplicate:
                        raise HTTPException(409, {'message': 'Label name already exists', 'remote': read(row) if row else None, 'duplicate': read(duplicate)})
                    if row:
                        conn.execute('UPDATE labels SET name=?,name_key=?,revision=revision+1 WHERE id=?', (name, name.casefold(), body.label_id))
                    else:
                        conn.execute('INSERT INTO labels VALUES (?,?,?,?,1,0)', (body.label_id, identity[0], name, name.casefold()))
            conn.execute('INSERT INTO label_operations VALUES (?,?,?,?)', (identity[0], body.op_id, fingerprint, body.label_id))
            return read(conn.execute('SELECT * FROM labels WHERE id=?', (body.label_id,)).fetchone())
