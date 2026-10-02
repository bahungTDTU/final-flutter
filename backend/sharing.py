"""Owner-only share catalogue, atomic batches and revision/idempotency independent of notes."""
import hashlib
import json

from fastapi import Depends, HTTPException, Response
from pydantic import BaseModel, ConfigDict, Field, model_validator

from backend.email_delivery import valid_email


class Recipient(BaseModel):
    model_config = ConfigDict(extra='forbid', strict=True)
    email: str = Field(min_length=1, max_length=254)
    role: str = Field(pattern='^(viewer|editor)$')


class ShareOperation(BaseModel):
    model_config = ConfigDict(extra='forbid', strict=True)
    op_id: str = Field(min_length=1, max_length=80)
    base_revision: int = Field(ge=0)
    action: str = Field(pattern='^(add|role|revoke)$')
    recipients: list[Recipient] = Field(default_factory=list, max_length=20)
    user_id: str | None = Field(default=None, min_length=1, max_length=80)
    role: str | None = Field(default=None, pattern='^(viewer|editor)$')

    @model_validator(mode='after')
    def shape(self):
        if self.action == 'add':
            if not self.recipients or self.user_id is not None or self.role is not None:
                raise ValueError('Add requires recipients only')
        elif self.recipients or self.user_id is None or (self.action == 'role') != (self.role is not None):
            raise ValueError('Role/revoke requires user_id and only role changes require role')
        return self


def share_revision(conn, note_id):
    row = conn.execute('SELECT revision FROM share_versions WHERE note_id=?', (note_id,)).fetchone()
    return row['revision'] if row else 0


def touch_shares(conn, note_id):
    conn.execute('INSERT INTO share_versions VALUES (?,1) ON CONFLICT(note_id) DO UPDATE SET revision=revision+1', (note_id,))


def share_catalogue(conn, note_id):
    rows = conn.execute('SELECT u.id AS user_id,u.name,u.email,s.role,s.shared_at FROM shares s '
                        'JOIN users u ON u.id=s.user_id WHERE s.note_id=? ORDER BY s.shared_at,u.id', (note_id,)).fetchall()
    return {'revision': share_revision(conn, note_id), 'recipients': [dict(row) for row in rows]}


def shared_metadata(conn, note, role):
    if role == 'owner':
        return {'shared_count': conn.execute('SELECT COUNT(*) FROM shares WHERE note_id=?', (note['id'],)).fetchone()[0]}
    owner = conn.execute('SELECT id,name,email FROM users WHERE id=?', (note['owner_id'],)).fetchone()
    # Caller supplies the recipient's own timestamp separately, never all recipients.
    return {'shared_by': dict(owner)}


def install_share_routes(app, db, authenticate, access, now):
    @app.get('/notes/{note_id}/shares')
    def listing(note_id: str, response: Response, identity=Depends(authenticate)):
        with db() as conn:
            access(conn, note_id, identity, 'owner')
            response.headers['Cache-Control'] = 'private, no-store'
            return share_catalogue(conn, note_id)

    @app.post('/notes/{note_id}/shares/sync')
    def mutate(note_id: str, body: ShareOperation, response: Response, identity=Depends(authenticate)):
        encoded = json.dumps({'note_id': note_id, **body.model_dump(exclude={'op_id'})}, sort_keys=True, ensure_ascii=False)
        fingerprint = hashlib.sha256(encoded.encode()).hexdigest()
        with db() as conn:
            access(conn, note_id, identity, 'owner')
            old = conn.execute('SELECT fingerprint FROM share_operations WHERE user_id=? AND op_id=?', (identity[0], body.op_id)).fetchone()
            response.headers['Cache-Control'] = 'private, no-store'
            if old:
                if old['fingerprint'] != fingerprint:
                    raise HTTPException(409, {'message': 'Operation ID reused', 'current': share_catalogue(conn, note_id)})
                return share_catalogue(conn, note_id)  # Never reapply a grant that was later revoked.
            if body.base_revision != share_revision(conn, note_id):
                raise HTTPException(409, {'message': 'Sharing changed; review current recipients', 'current': share_catalogue(conn, note_id)})
            targets = []
            if body.action == 'add':
                emails = [row.email.strip().lower() for row in body.recipients]
                if len(set(emails)) != len(emails) or not all(valid_email(email) for email in emails):
                    raise HTTPException(422, 'Invalid or duplicate recipient emails')
                count = conn.execute('SELECT COUNT(*) FROM shares WHERE note_id=?', (note_id,)).fetchone()[0]
                if count + len(emails) > 100:
                    raise HTTPException(422, 'Recipient limit is 100')
                for email, row in zip(emails, body.recipients):
                    user = conn.execute('SELECT id FROM users WHERE email=?', (email,)).fetchone()
                    if not user:
                        raise HTTPException(404, 'Recipient not registered')
                    if user['id'] == identity[0]:
                        raise HTTPException(422, 'Cannot share with yourself')
                    if conn.execute('SELECT 1 FROM shares WHERE note_id=? AND user_id=?', (note_id, user['id'])).fetchone():
                        raise HTTPException(409, {'message': 'Recipient already shared; use role change', 'current': share_catalogue(conn, note_id)})
                    targets.append((user['id'], row.role))
                stamp = now()
                for user_id, role in targets:
                    conn.execute('INSERT INTO shares VALUES (?,?,?,?)', (note_id, user_id, role, stamp))
            else:
                row = conn.execute('SELECT role FROM shares WHERE note_id=? AND user_id=?', (note_id, body.user_id)).fetchone()
                if body.action == 'role':
                    if not row:
                        raise HTTPException(409, {'message': 'Recipient was revoked', 'current': share_catalogue(conn, note_id)})
                    conn.execute('UPDATE shares SET role=? WHERE note_id=? AND user_id=?', (body.role, note_id, body.user_id))
                else:
                    conn.execute('DELETE FROM shares WHERE note_id=? AND user_id=?', (note_id, body.user_id))
                targets = [(body.user_id, body.role)]
            for user_id, _ in targets:
                conn.execute('DELETE FROM grants WHERE note_id=? AND session_digest IN (SELECT digest FROM sessions WHERE user_id=?)', (note_id, user_id))
            touch_shares(conn, note_id)
            conn.execute('INSERT INTO share_operations VALUES (?,?,?)', (identity[0], body.op_id, fingerprint))
            return share_catalogue(conn, note_id)
