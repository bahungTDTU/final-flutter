"""Account-owned session controls; public handles are never bearer digests."""
import math
import time
from datetime import datetime, timezone
from uuid import uuid4

from fastapi import Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field, model_validator

SESSION_LIMIT = 20


def client_label(user_agent):
    ua = user_agent[:512].lower()
    browser = next((name for marker, name in [
        ('edg/', 'Edge'), ('firefox/', 'Firefox'), ('chrome/', 'Chrome'),
        ('safari/', 'Safari')] if marker in ua), 'Ứng dụng')
    platform = next((name for marker, name in [
        ('android', 'Android'), ('iphone', 'iOS'), ('ipad', 'iOS'),
        ('windows', 'Windows'), ('macintosh', 'macOS'), ('linux', 'Linux')]
        if marker in ua), None)
    return browser + (' · ' + platform if platform else '')


def install_session_catalogue(conn, digest):
    conn.execute('DELETE FROM sessions WHERE expires<=?', (time.time(),))
    missing = conn.execute('SELECT s.digest FROM sessions s LEFT JOIN session_details d '
                           'ON d.session_digest=s.digest WHERE d.id IS NULL').fetchall()
    for row in missing:
        conn.execute('INSERT INTO session_details VALUES (?,?,?,NULL)',
                     (str(uuid4()), row['digest'], 'Phiên cũ'))
    old = conn.execute("SELECT * FROM attempts WHERE scope LIKE 'login:%' AND instr(scope,'@')>0").fetchall()
    for row in old:
        scope = 'login:' + digest(row['scope'][6:])
        conn.execute('INSERT INTO attempts VALUES (?,?,?) ON CONFLICT(scope) DO UPDATE SET '
                     'failures=MAX(failures,excluded.failures),blocked_until=MAX(blocked_until,excluded.blocked_until)',
                     (scope, row['failures'], row['blocked_until']))
        conn.execute('DELETE FROM attempts WHERE scope=?', (row['scope'],))


def record_session(conn, session_digest, user_id, user_agent):
    conn.execute('DELETE FROM sessions WHERE user_id=? AND expires<=?', (user_id, time.time()))
    conn.execute('INSERT INTO session_details VALUES (?,?,?,?)',
                 (str(uuid4()), session_digest, client_label(user_agent), time.time()))
    conn.execute('DELETE FROM sessions WHERE digest IN ('
                 'SELECT s.digest FROM sessions s LEFT JOIN session_details d ON d.session_digest=s.digest '
                 'WHERE s.user_id=? AND s.digest!=? ORDER BY d.created_at DESC,s.expires DESC,s.digest '
                 'LIMIT -1 OFFSET ?)', (user_id, session_digest, SESSION_LIMIT - 1))


def failure_window(conn, scope):
    attempt = conn.execute('SELECT * FROM attempts WHERE scope=?', (scope,)).fetchone()
    clock = time.time()
    if attempt and attempt['blocked_until'] > clock:
        raise HTTPException(429, 'Try again later', headers={
            'Retry-After': str(max(1, math.ceil(attempt['blocked_until'] - clock)))})
    return attempt['failures'] if attempt and attempt['blocked_until'] == 0 else 0


def verify_account_password(conn, user_id, password, check_password):
    scope = 'account-password:' + user_id
    failures = failure_window(conn, scope)
    row = conn.execute('SELECT password FROM users WHERE id=?', (user_id,)).fetchone()
    if row and check_password(row['password'], password):
        conn.execute('DELETE FROM attempts WHERE scope=?', (scope,))
        return True
    failures += 1
    conn.execute('INSERT OR REPLACE INTO attempts VALUES (?,?,?)',
                 (scope, failures, time.time() + 60 if failures >= 5 else 0))
    return False  # Caller must commit failures before returning 403.


def stamp(value):
    return datetime.fromtimestamp(value, timezone.utc).isoformat() if value is not None else None


class SessionRevocation(BaseModel):
    model_config = ConfigDict(extra='forbid', strict=True)
    scope: str = Field(pattern='^(one|others)$')
    session_id: str | None = Field(default=None, min_length=1, max_length=80)
    password: str = Field(min_length=1, max_length=128)

    @model_validator(mode='after')
    def valid_target(self):
        if (self.scope == 'one') != (self.session_id is not None):
            raise ValueError('One session needs an ID; other sessions must not specify an ID')
        return self


def install_session_routes(app, db, read_db, authenticate, validate_session, check_password):
    @app.get('/me/sessions')
    def list_sessions(identity=Depends(authenticate)):
        with read_db() as conn:
            validate_session(conn, identity)
            clock = time.time()
            total = conn.execute('SELECT COUNT(*) FROM sessions WHERE user_id=? AND expires>?',
                                 (identity[0], clock)).fetchone()[0]
            rows = conn.execute('SELECT d.id,d.label,d.created_at,s.expires,s.digest=? AS current '
                                'FROM sessions s JOIN session_details d ON d.session_digest=s.digest '
                                'WHERE s.user_id=? AND s.expires>? '
                                'ORDER BY current DESC,d.created_at DESC,s.expires DESC,d.id LIMIT ?',
                                (identity[1], identity[0], clock, SESSION_LIMIT)).fetchall()
            return {'total': total, 'limit': SESSION_LIMIT, 'sessions': [
                {'id': r['id'], 'label': r['label'], 'created_at': stamp(r['created_at']),
                 'expires_at': stamp(r['expires']), 'is_current': bool(r['current'])} for r in rows]}

    @app.post('/me/sessions/revoke')
    def revoke_sessions(body: SessionRevocation, identity=Depends(authenticate)):
        revoked = 0
        with db() as conn:
            validate_session(conn, identity)
            valid = verify_account_password(conn, identity[0], body.password, check_password)
            if valid:
                if body.scope == 'one':
                    target = conn.execute('SELECT s.digest FROM sessions s JOIN session_details d '
                                          'ON d.session_digest=s.digest WHERE d.id=? AND s.user_id=?',
                                          (body.session_id, identity[0])).fetchone()
                    if target and target['digest'] == identity[1]:
                        raise HTTPException(409, 'Use logout to end your current session')
                    if target:
                        revoked = conn.execute('DELETE FROM sessions WHERE digest=? AND user_id=?',
                                               (target['digest'], identity[0])).rowcount
                else:
                    revoked = conn.execute('DELETE FROM sessions WHERE user_id=? AND digest!=?',
                                           (identity[0], identity[1])).rowcount
        if not valid:
            raise HTTPException(403, 'Incorrect account password')
        return {'ok': True, 'revoked': revoked}
