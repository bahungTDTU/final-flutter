"""Local-first backend foundation. See STATUS.md for production limitations."""
import hashlib
import json
import os
import secrets
import sqlite3
import time
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

from argon2 import PasswordHasher
from argon2.exceptions import VerificationError, InvalidHashError
from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field, ConfigDict, model_validator

from backend.email_delivery import delivery_from_environment, valid_email
from backend.avatars import install_avatar_routes
from backend.attachments import install_attachment_routes
from backend.sharing import install_share_routes, touch_shares, shared_metadata
from backend.realtime import install_tracking, install_realtime_routes
from backend.catalogue import migrate, install_label_routes, normalize_labels, note_labels
from backend.note_listing import list_visible_notes

hasher = PasswordHasher()
bearer = HTTPBearer(auto_error=False)


def digest(value):
    return hashlib.sha256(value.encode()).hexdigest()


def now():
    return datetime.now(timezone.utc).isoformat()


def check_password(encoded, password):
    try:
        return hasher.verify(encoded, password)
    except (VerificationError, InvalidHashError):
        return False


class Registration(BaseModel):
    email: str = Field(max_length=254)
    name: str = Field(min_length=1, max_length=100)
    password: str = Field(min_length=10, max_length=128)
    confirmation: str


class Login(BaseModel):
    email: str
    password: str


class EmailRequest(BaseModel):
    email: str = Field(max_length=254)


class TokenRequest(BaseModel):
    token: str = Field(min_length=1, max_length=128)


class ResetRequest(TokenRequest):
    password: str = Field(min_length=10, max_length=128)
    confirmation: str


class ChangePassword(BaseModel):
    current_password: str
    password: str = Field(min_length=10, max_length=128)
    confirmation: str


class ProfileUpdate(BaseModel):
    name: str = Field(min_length=1, max_length=100)


class Preferences(BaseModel):
    grid: bool = True
    dark: bool = False
    font_size: float = Field(default=16, ge=14, le=24)


class PreferenceOperation(BaseModel):
    model_config = ConfigDict(extra='forbid', strict=True)
    op_id: str = Field(min_length=1, max_length=80)
    grid: bool | None = None
    dark: bool | None = None
    font_size: float | None = Field(default=None, ge=14, le=24)

    @model_validator(mode='after')
    def valid_patch(self):
        changes = self.model_dump(exclude_unset=True, exclude={'op_id'})
        if not changes or any(value is None for value in changes.values()):
            raise ValueError('At least one non-null preference is required')
        return self


class Operation(BaseModel):
    op_id: str = Field(min_length=1, max_length=80)
    note_id: str = Field(min_length=1, max_length=80)
    base_revision: int = Field(ge=0)
    kind: str = Field(pattern='^(upsert|delete)$')
    title: str = Field(default='', max_length=200)
    content: str = Field(default='', max_length=100000)
    pinned_at: str | None = None
    labels: list[str] = Field(default_factory=list, max_length=30)
    labels_format: str = Field(default='legacy', pattern='^(legacy|ids)$')


class Protection(BaseModel):
    current_password: str = ''
    password: str | None = Field(default=None, min_length=10, max_length=128)
    confirmation: str | None = None


class Unlock(BaseModel):
    password: str


class Share(BaseModel):
    email: str
    role: str = Field(pattern='^(viewer|editor)$')


def create_app(db_path=None, *, email_delivery=None):
    database = str(db_path or os.environ.get('NOTETOGETHER_DB', 'backend/state/app.sqlite3'))
    Path(database).parent.mkdir(parents=True, exist_ok=True)

    @contextmanager
    def db():
        conn = sqlite3.connect(database, timeout=10)
        conn.row_factory = sqlite3.Row
        conn.execute('PRAGMA foreign_keys=ON')
        try:
            # Serialize authorization checks with mutations in this small single-DB service.
            conn.execute('BEGIN IMMEDIATE')
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    with db() as conn:
        conn.executescript(Path(__file__).with_name('schema.sql').read_text())
        conn.execute('BEGIN IMMEDIATE')
        migrate(conn)
        install_tracking(conn)

    app = FastAPI(title='NoteTogether', version='0.2.0')
    app.state.database = database
    app.state.email_delivery = email_delivery if email_delivery is not None else delivery_from_environment(os.environ)
    origins = [value.strip() for value in os.environ.get('WEB_ORIGINS', 'http://localhost:7357,http://127.0.0.1:7357').split(',')]
    app.add_middleware(CORSMiddleware,
        allow_origins=origins,
        allow_methods=['GET', 'POST', 'PATCH', 'DELETE'], allow_headers=['Authorization', 'Content-Type'])

    def authenticate(credentials: HTTPAuthorizationCredentials | None = Depends(bearer)):
        if not credentials or credentials.scheme.lower() != 'bearer':
            raise HTTPException(401, 'Authentication required')
        session_digest = digest(credentials.credentials)
        with db() as conn:
            row = conn.execute('SELECT user_id FROM sessions WHERE digest=? AND expires>?',
                               (session_digest, time.time())).fetchone()
        if not row:
            raise HTTPException(401, 'Session expired')
        return row['user_id'], session_digest

    def validate_session(conn, identity):
        if not conn.execute('SELECT 1 FROM sessions WHERE digest=? AND user_id=? AND expires>?',
                            (identity[1], identity[0], time.time())).fetchone():
            raise HTTPException(401, 'Session expired')

    def profile(conn, user_id):
        row = conn.execute('SELECT * FROM users WHERE id=?', (user_id,)).fetchone()
        avatar = conn.execute('SELECT revision,data IS NOT NULL AS present FROM avatars WHERE user_id=?', (user_id,)).fetchone()
        return {'id': row['id'], 'email': row['email'], 'name': row['name'],
                'verified': bool(row['verified']), 'preferences': json.loads(row['preferences']),
                'avatar_revision': avatar['revision'] if avatar else 0, 'has_avatar': bool(avatar and avatar['present']), 'schema_version': 2}

    def session(conn, user_id):
        token = secrets.token_urlsafe(32)
        conn.execute('INSERT INTO sessions VALUES (?,?,?)', (digest(token), user_id, time.time() + 86400))
        return {'token': token, 'user': profile(conn, user_id)}

    def email_token(conn, user_id, kind):
        token = secrets.token_urlsafe(32)
        conn.execute('UPDATE email_tokens SET used=1 WHERE user_id=? AND kind=?', (user_id, kind))
        conn.execute('INSERT INTO email_tokens VALUES (?,?,?,?,0)',
                     (digest(token), user_id, kind, time.time() + 1800))
        return token

    def email_cooldown(conn, scope):
        attempt = conn.execute('SELECT blocked_until FROM attempts WHERE scope=?', (scope,)).fetchone()
        if attempt and attempt['blocked_until'] > time.time():
            raise HTTPException(429, 'Try again later')
        conn.execute('INSERT OR REPLACE INTO attempts VALUES (?,0,?)', (scope, time.time() + 60))

    def send_code(recipient, kind, token):
        try:
            return app.state.email_delivery.send(recipient, kind, token)
        except Exception:
            return 'delivery_failed'

    def take_token(conn, token, kind):
        row = conn.execute('SELECT * FROM email_tokens WHERE digest=? AND kind=? AND used=0 AND expires>?',
                           (digest(token), kind, time.time())).fetchone()
        if not row:
            raise HTTPException(400, 'Invalid, expired or reused token')
        conn.execute('UPDATE email_tokens SET used=1 WHERE digest=?', (digest(token),))
        return row['user_id']

    def access(conn, note_id, identity, mode='read', unlocked=True):
        validate_session(conn, identity)
        note = conn.execute('SELECT * FROM notes WHERE id=? AND deleted=0', (note_id,)).fetchone()
        if not note:
            raise HTTPException(404, 'Note unavailable')
        role = 'owner' if note['owner_id'] == identity[0] else None
        if not role:
            shared = conn.execute('SELECT role FROM shares WHERE note_id=? AND user_id=?',
                                  (note_id, identity[0])).fetchone()
            role = shared['role'] if shared else None
        if not role:
            raise HTTPException(404, 'Note unavailable')
        if mode == 'owner' and role != 'owner' or mode == 'edit' and role == 'viewer':
            raise HTTPException(403, 'Insufficient permission')
        if unlocked and note['password']:
            grant = conn.execute('SELECT 1 FROM grants WHERE session_digest=? AND note_id=? AND version=? AND expires>?',
                                 (identity[1], note_id, note['protection_version'], time.time())).fetchone()
            if not grant:
                raise HTTPException(423, 'Unlock required')
        return note, role

    def serialize(conn, note, role, identity=None):
        ids, names = note_labels(conn, note)
        result = {'id': note['id'], 'owner_id': note['owner_id'], 'title': note['title'],
                'content': note['content'], 'revision': note['revision'], 'updated_at': note['updated_at'],
                'pinned_at': note['pinned_at'], 'labels': ids, 'label_names': names,
                'locked': bool(note['password']), 'role': role, 'deleted': bool(note['deleted'])}
        result.update(shared_metadata(conn, note, role))
        if role != 'owner' and identity is not None:
            row = conn.execute('SELECT shared_at FROM shares WHERE note_id=? AND user_id=?', (note['id'], identity[0])).fetchone()
            result['shared_at'] = row['shared_at'] if row else None
        return result

    @app.get('/health')
    def health():
        return {'status': 'ok', 'email_delivery': app.state.email_delivery.mode, 'ai': 'not_configured'}

    install_avatar_routes(app, db, authenticate, validate_session, profile)
    install_label_routes(app, db, authenticate, validate_session, digest)
    install_attachment_routes(app, db, authenticate, access, now)
    install_share_routes(app, db, authenticate, access, now)
    install_realtime_routes(app, authenticate, origins)

    @app.post('/auth/register', status_code=201)
    def register(body: Registration):
        email = body.email.strip().lower()
        if not valid_email(email) or not body.name.strip():
            raise HTTPException(422, 'Invalid email or display name')
        if body.password != body.confirmation:
            raise HTTPException(422, 'Passwords do not match')
        user_id = str(uuid4())
        with db() as conn:
            if conn.execute('SELECT 1 FROM users WHERE email=?', (email,)).fetchone():
                raise HTTPException(409, 'Account already exists')
            conn.execute('INSERT INTO users (id,email,name,password) VALUES (?,?,?,?)',
                         (user_id, email, body.name.strip(), hasher.hash(body.password)))
            code = email_token(conn, user_id, 'verify')
            email_cooldown(conn, 'verify:' + user_id)
            result = session(conn, user_id)
        result['email_delivery'] = send_code(email, 'verify', code)
        return result

    @app.post('/auth/login')
    def login(body: Login):
        scope = 'login:' + body.email.strip().lower()
        with db() as conn:
            attempt = conn.execute('SELECT * FROM attempts WHERE scope=?', (scope,)).fetchone()
            if attempt and attempt['blocked_until'] > time.time():
                raise HTTPException(429, 'Try again later')
            user = conn.execute('SELECT * FROM users WHERE email=?', (body.email.strip().lower(),)).fetchone()
            valid = check_password(user['password'], body.password) if user else check_password(dummy_hash, body.password)
            if not user or not valid:
                failures = (attempt['failures'] if attempt else 0) + 1
                conn.execute('INSERT OR REPLACE INTO attempts VALUES (?,?,?)',
                             (scope, failures, time.time() + 60 if failures >= 5 else 0))
                # Return after commit so failed attempts survive the response.
                result = None
            else:
                conn.execute('DELETE FROM attempts WHERE scope=?', (scope,))
                result = session(conn, user['id'])
        if result is None:
            raise HTTPException(401, 'Invalid email or password')
        return result

    dummy_hash = hasher.hash(secrets.token_urlsafe(32))

    @app.post('/auth/logout')
    def logout(identity=Depends(authenticate)):
        with db() as conn:
            conn.execute('DELETE FROM sessions WHERE digest=?', (identity[1],))
        return {'ok': True}

    @app.get('/me')
    def me(identity=Depends(authenticate)):
        with db() as conn:
            validate_session(conn, identity)
            return profile(conn, identity[0])

    @app.patch('/me')
    def update_profile(body: ProfileUpdate, identity=Depends(authenticate)):
        if not body.name.strip():
            raise HTTPException(422, 'Display name required')
        with db() as conn:
            validate_session(conn, identity)
            conn.execute('UPDATE users SET name=? WHERE id=?', (body.name.strip(), identity[0]))
            return profile(conn, identity[0])

    @app.patch('/me/preferences')
    def preferences(body: Preferences, identity=Depends(authenticate)):
        with db() as conn:
            validate_session(conn, identity)
            conn.execute('UPDATE users SET preferences=? WHERE id=?', (body.model_dump_json(), identity[0]))
            return profile(conn, identity[0])

    @app.post('/me/preferences/sync')
    def sync_preferences(body: PreferenceOperation, identity=Depends(authenticate)):
        # Per-field last server-accepted change wins. Retries cannot overwrite newer changes.
        patch = body.model_dump(exclude_unset=True, exclude={'op_id'})
        fingerprint = digest(json.dumps(patch, sort_keys=True))
        with db() as conn:
            validate_session(conn, identity)
            prior = conn.execute('SELECT fingerprint FROM preference_operations WHERE user_id=? AND op_id=?',
                                 (identity[0], body.op_id)).fetchone()
            if prior and prior['fingerprint'] != fingerprint:
                raise HTTPException(409, 'Preference operation ID reused with different data')
            if not prior:
                current = {'grid': True, 'dark': False, 'font_size': 16}
                current.update(profile(conn, identity[0])['preferences'])
                current.update(patch)
                conn.execute('UPDATE users SET preferences=? WHERE id=?', (json.dumps(current), identity[0]))
                conn.execute('INSERT INTO preference_operations VALUES (?,?,?)', (identity[0], body.op_id, fingerprint))
            return profile(conn, identity[0])

    @app.post('/auth/verify')
    def verify(body: TokenRequest):
        with db() as conn:
            user_id = take_token(conn, body.token, 'verify')
            conn.execute('UPDATE users SET verified=1 WHERE id=?', (user_id,))
        return {'ok': True}

    @app.post('/auth/resend')
    def resend(identity=Depends(authenticate)):
        with db() as conn:
            validate_session(conn, identity)
            user = profile(conn, identity[0])
            if user['verified']:
                return {'email_delivery': 'already_verified'}
            email_cooldown(conn, 'verify:' + identity[0])
            code = email_token(conn, identity[0], 'verify')
        return {'email_delivery': send_code(user['email'], 'verify', code)}

    @app.post('/auth/forgot')
    def forgot(body: EmailRequest):
        email = body.email.strip().lower()
        if not valid_email(email):
            raise HTTPException(422, 'Invalid email')
        code = None
        with db() as conn:
            # Same cooldown and response for known and unknown addresses.
            email_cooldown(conn, 'forgot:' + digest(email))
            user = conn.execute('SELECT id FROM users WHERE email=?', (email,)).fetchone()
            if user:
                code = email_token(conn, user['id'], 'reset')
        if code:
            send_code(email, 'reset', code)
        return {'message': 'If the account exists, recovery is requested.',
                'email_delivery': 'not_configured' if app.state.email_delivery.mode == 'not_configured' else 'requested'}

    @app.post('/auth/reset/check')
    def check_reset(body: TokenRequest):
        with db() as conn:
            if not conn.execute('SELECT 1 FROM email_tokens WHERE digest=? AND kind=? AND used=0 AND expires>?',
                                (digest(body.token), 'reset', time.time())).fetchone():
                raise HTTPException(400, 'Invalid, expired or reused token')
        return {'valid': True}

    @app.post('/auth/reset')
    def reset(body: ResetRequest):
        if body.password != body.confirmation:
            raise HTTPException(422, 'Passwords do not match')
        with db() as conn:
            user_id = take_token(conn, body.token, 'reset')
            conn.execute('UPDATE users SET password=? WHERE id=?', (hasher.hash(body.password), user_id))
            conn.execute('DELETE FROM sessions WHERE user_id=?', (user_id,))
        return {'ok': True, 'login_required': True}

    @app.post('/auth/password')
    def change_password(body: ChangePassword, identity=Depends(authenticate)):
        if body.password != body.confirmation:
            raise HTTPException(422, 'Passwords do not match')
        with db() as conn:
            validate_session(conn, identity)
            user = conn.execute('SELECT password FROM users WHERE id=?', (identity[0],)).fetchone()
            if not check_password(user['password'], body.current_password):
                raise HTTPException(403, 'Current password incorrect')
            conn.execute('UPDATE users SET password=? WHERE id=?', (hasher.hash(body.password), identity[0]))
            conn.execute('DELETE FROM sessions WHERE user_id=?', (identity[0],))
        return {'ok': True, 'login_required': True}

    @app.get('/notes')
    def list_notes(identity=Depends(authenticate)):
        with db() as conn:
            validate_session(conn, identity)
            return list_visible_notes(conn, identity[0])

    @app.get('/notes/{note_id}')
    def read_note(note_id: str, identity=Depends(authenticate)):
        with db() as conn:
            note, role = access(conn, note_id, identity)
            return serialize(conn, note, role, identity)

    @app.post('/sync')
    def sync(body: Operation, identity=Depends(authenticate)):
        # Preserve fingerprints for immutable operations created by the v1 client.
        fingerprint = digest(body.model_dump_json(exclude={'labels_format'} if 'labels_format' not in body.model_fields_set else set()))
        with db() as conn:
            validate_session(conn, identity)
            old = conn.execute('SELECT * FROM notes WHERE id=?', (body.note_id,)).fetchone()
            # Re-authorize before idempotency replay; revoke/lock must invalidate content replay too.
            role = 'owner'
            if old and not old['deleted']:
                old, role = access(conn, body.note_id, identity, 'owner' if body.kind == 'delete' else 'edit')
            elif old and old['owner_id'] != identity[0]:
                raise HTTPException(404, 'Note unavailable')
            prior = conn.execute('SELECT * FROM operations WHERE user_id=? AND op_id=?',
                                 (identity[0], body.op_id)).fetchone()
            if prior:
                if prior['fingerprint'] != fingerprint:
                    raise HTTPException(409, 'Operation ID reused with different data')
                # Replays contain metadata only; never return stale protected content.
                return json.loads(prior['result'])
            if old and old['deleted']:
                raise HTTPException(409, {'message': 'Remote note deleted', 'deleted': True})
            revision = old['revision'] if old else 0
            if revision != body.base_revision:
                raise HTTPException(409, {'message': 'Revision conflict', 'remote': serialize(conn, old, role) if old else None})
            if body.kind == 'delete':
                if not old:
                    raise HTTPException(404, 'Note unavailable')
                conn.execute('UPDATE notes SET deleted=1,revision=revision+1,updated_at=? WHERE id=?', (now(), body.note_id))
                conn.execute('DELETE FROM shares WHERE note_id=?', (body.note_id,))
                conn.execute('DELETE FROM grants WHERE note_id=?', (body.note_id,))
                conn.execute('UPDATE attachments SET data=NULL,size=0,deleted=1 WHERE note_id=?', (body.note_id,))
            else:
                if not body.title.strip() or not body.content.strip():
                    raise HTTPException(422, 'Title and content required')
                if old:
                    # Editor may change title/content only; owner manages pins/labels.
                    pinned = body.pinned_at if role == 'owner' else old['pinned_at']
                    labels = normalize_labels(conn, identity[0], body.labels, body.labels_format) if role == 'owner' else old['labels']
                    conn.execute('UPDATE notes SET title=?,content=?,revision=revision+1,updated_at=?,pinned_at=?,labels=? WHERE id=?',
                                 (body.title.strip(), body.content, now(), pinned, labels, body.note_id))
                else:
                    conn.execute('INSERT INTO notes (id,owner_id,title,content,revision,updated_at,pinned_at,labels) VALUES (?,?,?,?,1,?,?,?)',
                                 (body.note_id, identity[0], body.title.strip(), body.content, now(), body.pinned_at, normalize_labels(conn, identity[0], body.labels, body.labels_format)))
            result = {'id': body.note_id, 'revision': revision + 1, 'deleted': body.kind == 'delete'}
            conn.execute('INSERT INTO operations VALUES (?,?,?,?)',
                         (identity[0], body.op_id, fingerprint, json.dumps(result)))
            return result

    @app.post('/notes/{note_id}/protection')
    def protection(note_id: str, body: Protection, identity=Depends(authenticate)):
        if body.password is not None and body.password != body.confirmation:
            raise HTTPException(422, 'Passwords do not match')
        with db() as conn:
            note, _ = access(conn, note_id, identity, 'owner', unlocked=False)
            if note['password'] and not check_password(note['password'], body.current_password):
                raise HTTPException(403, 'Current note password incorrect')
            conn.execute('UPDATE notes SET password=?,protection_version=protection_version+1,revision=revision+1,updated_at=? WHERE id=?',
                         (hasher.hash(body.password) if body.password is not None else None, now(), note_id))
            conn.execute('DELETE FROM grants WHERE note_id=?', (note_id,))
        return {'ok': True, 'revision': note['revision'] + 1, 'locked': body.password is not None}

    @app.post('/notes/{note_id}/unlock')
    def unlock(note_id: str, body: Unlock, identity=Depends(authenticate)):
        with db() as conn:
            note, _ = access(conn, note_id, identity, unlocked=False)
            scope = 'unlock:' + identity[0] + ':' + note_id
            attempt = conn.execute('SELECT * FROM attempts WHERE scope=?', (scope,)).fetchone()
            if attempt and attempt['blocked_until'] > time.time():
                raise HTTPException(429, 'Try again later')
            valid = bool(note['password']) and check_password(note['password'], body.password)
            if valid:
                conn.execute('DELETE FROM attempts WHERE scope=?', (scope,))
                conn.execute('INSERT OR REPLACE INTO grants VALUES (?,?,?,?)',
                             (identity[1], note_id, note['protection_version'], time.time() + 300))
            else:
                failures = (attempt['failures'] if attempt else 0) + 1
                conn.execute('INSERT OR REPLACE INTO attempts VALUES (?,?,?)',
                             (scope, failures, time.time() + 60 if failures >= 5 else 0))
        if not valid:
            raise HTTPException(403, 'Note password incorrect')
        return {'ok': True, 'expires_in': 300}

    @app.post('/notes/{note_id}/lock')
    def relock(note_id: str, identity=Depends(authenticate)):
        with db() as conn:
            access(conn, note_id, identity, unlocked=False)
            conn.execute('DELETE FROM grants WHERE session_digest=? AND note_id=?', (identity[1], note_id))
        return {'ok': True}

    @app.post('/notes/{note_id}/shares')
    def share(note_id: str, body: Share, identity=Depends(authenticate)):
        with db() as conn:
            access(conn, note_id, identity, 'owner')
            user = conn.execute('SELECT id FROM users WHERE email=?', (body.email.strip().lower(),)).fetchone()
            if not user:
                raise HTTPException(404, 'Recipient not registered')
            if user['id'] == identity[0]:
                raise HTTPException(422, 'Cannot share with yourself')
            # Upsert is also the deliberate role-change endpoint.
            conn.execute('INSERT INTO shares VALUES (?,?,?,?) ON CONFLICT(note_id,user_id) DO UPDATE SET role=excluded.role',
                         (note_id, user['id'], body.role, now()))
            touch_shares(conn, note_id)
            conn.execute('DELETE FROM grants WHERE note_id=? AND session_digest IN (SELECT digest FROM sessions WHERE user_id=?)',
                         (note_id, user['id']))
        return {'ok': True}

    @app.delete('/notes/{note_id}/shares/{user_id}')
    def revoke(note_id: str, user_id: str, identity=Depends(authenticate)):
        with db() as conn:
            access(conn, note_id, identity, 'owner')
            conn.execute('DELETE FROM shares WHERE note_id=? AND user_id=?', (note_id, user_id))
            touch_shares(conn, note_id)
            conn.execute('DELETE FROM grants WHERE note_id=? AND session_digest IN (SELECT digest FROM sessions WHERE user_id=?)',
                         (note_id, user_id))
        return {'ok': True}

    return app
