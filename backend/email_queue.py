"""Durable mail jobs. DB stores a nonce + digest, never a raw verification code.

The code is a HMAC-SHA256 PRF of a random nonce and user/kind, using a private
server key outside SQLite. Delivery is at-least-once, not an inbox receipt.
"""
import base64
import hashlib
import hmac
import json
import os
from pathlib import Path
import secrets
import threading
import time
from uuid import uuid4


class EmailQueue:
    def __init__(self, db, delivery, key_path, *, clock=time.time):
        self.db, self.delivery = db, delivery
        self.key_path = Path(key_path)
        self.clock = clock
        self._key_bytes = None
        self._wake = threading.Event()
        self._stopping = threading.Event()
        self._thread = None
        self._processing = threading.Lock()

    def key(self, conn):
        if self._key_bytes is None:
            if not self.key_path.exists():
                if conn.execute('SELECT 1 FROM email_jobs LIMIT 1').fetchone():
                    raise ValueError('Mail key unavailable')
                self.key_path.parent.mkdir(parents=True, exist_ok=True)
                try:
                    fd = os.open(self.key_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
                    with os.fdopen(fd, 'wb') as file:
                        file.write(secrets.token_bytes(32))
                        file.flush()
                        os.fsync(file.fileno())
                except FileExistsError:
                    pass  # Another worker published the key first.
            value = self.key_path.read_bytes()
            if len(value) != 32:
                raise ValueError('Mail key unavailable')
            self._key_bytes = value
        return self._key_bytes

    def code(self, conn, user_id, kind, nonce):
        message = json.dumps(['NoteTogether:mail:v1', user_id, kind, nonce.hex()],
                             separators=(',', ':')).encode()
        return base64.urlsafe_b64encode(hmac.digest(self.key(conn), message, 'sha256')).decode().rstrip('=')

    def issue(self, conn, user_id, kind):
        enabled = self.delivery.mode != 'not_configured'
        nonce = secrets.token_bytes(32)
        code = self.code(conn, user_id, kind, nonce) if enabled else secrets.token_urlsafe(32)
        digest = hashlib.sha256(code.encode()).hexdigest()
        timestamp = self.clock()
        conn.execute('UPDATE email_tokens SET used=1 WHERE user_id=? AND kind=?', (user_id, kind))
        conn.execute("UPDATE email_jobs SET status='cancelled',nonce=NULL,lease_owner=NULL,leased_until=0 "
                     "WHERE user_id=? AND kind=? AND status IN ('queued','retrying','sending')", (user_id, kind))
        conn.execute('INSERT INTO email_tokens VALUES (?,?,?,?,0)', (digest, user_id, kind, timestamp + 1800))
        if enabled:
            conn.execute('INSERT INTO email_jobs (id,user_id,kind,token_digest,nonce,status,next_attempt,created_at) '
                         "VALUES (?,?,?,?,?,'queued',?,?)", (str(uuid4()), user_id, kind, digest, nonce, timestamp, timestamp))
            self._wake.set()
        return 'queued' if enabled else 'not_configured'

    def status(self, conn, user_id):
        if conn.execute('SELECT verified FROM users WHERE id=?', (user_id,)).fetchone()['verified']:
            return {'email_delivery': 'already_verified', 'retry_after': 0}
        if self.delivery.mode == 'not_configured':
            return {'email_delivery': 'not_configured', 'retry_after': 0}
        row = conn.execute("SELECT j.status,j.next_attempt,t.used,t.expires FROM email_jobs j "
                           "JOIN email_tokens t ON t.digest=j.token_digest WHERE j.user_id=? AND j.kind='verify' "
                           'ORDER BY j.created_at DESC,j.rowid DESC LIMIT 1', (user_id,)).fetchone()
        if not row:
            return {'email_delivery': 'not_requested', 'retry_after': 0}
        expired = row['used'] or row['expires'] <= self.clock()
        value = 'expired' if expired else ('queued' if row['status'] == 'sending' else row['status'])
        delay = max(0, int(row['next_attempt'] - self.clock())) if value == 'retrying' else 0
        return {'email_delivery': value, 'retry_after': delay}

    def run_once(self):
        if self.delivery.mode == 'not_configured' or not self._processing.acquire(blocking=False):
            return False
        try:
            return self._run_one()
        finally:
            self._processing.release()

    def _run_one(self):
        timestamp = self.clock()
        owner = str(uuid4())
        with self.db() as conn:
            conn.execute("UPDATE email_jobs SET status='cancelled',nonce=NULL,lease_owner=NULL,leased_until=0 "
                         "WHERE status IN ('queued','retrying','sending') AND token_digest IN "
                         '(SELECT digest FROM email_tokens WHERE used=1 OR expires<=?)', (timestamp,))
            conn.execute("DELETE FROM email_jobs WHERE created_at<? AND status NOT IN ('queued','retrying','sending')",
                         (timestamp - 86400,))
            conn.execute("UPDATE email_jobs SET status='failed',nonce=NULL,lease_owner=NULL,leased_until=0,last_error='retry_limit' "
                         "WHERE status='sending' AND leased_until<=? AND attempts>=6", (timestamp,))
            row = conn.execute("SELECT j.*,u.email FROM email_jobs j JOIN users u ON u.id=j.user_id "
                               "WHERE (j.status IN ('queued','retrying') AND j.next_attempt<=?) "
                               "OR (j.status='sending' AND j.leased_until<=?) "
                               'ORDER BY j.created_at LIMIT 1', (timestamp, timestamp)).fetchone()
            if not row:
                return False
            conn.execute("UPDATE email_jobs SET status='sending',attempts=attempts+1,leased_until=?,lease_owner=? WHERE id=?",
                         (timestamp + 120, owner, row['id']))
        key_error = False
        try:
            with self.db() as conn:
                code = self.code(conn, row['user_id'], row['kind'], bytes(row['nonce']))
                if not hmac.compare_digest(hashlib.sha256(code.encode()).hexdigest(), row['token_digest']):
                    raise ValueError('Mail key unavailable')
                active = conn.execute("SELECT 1 FROM email_jobs j JOIN email_tokens t ON t.digest=j.token_digest "
                                      "WHERE j.id=? AND j.status='sending' AND j.lease_owner=? AND t.used=0 AND t.expires>?",
                                      (row['id'], owner, self.clock())).fetchone()
            if not active:
                return True
        except (ValueError, OSError):
            key_error = True
            result = 'key_unavailable'
        else:
            try:
                result = self.delivery.send(row['email'], row['kind'], code)
            except Exception:
                result = 'delivery_failed'  # Never store/log provider exception text.
        attempts = row['attempts'] + 1
        accepted = result in ('smtp_accepted', 'test_only')
        status = result if accepted else ('failed' if attempts >= 6 and not key_error else 'retrying')
        delays = [15, 60, 180, 600, 900, 900]
        delay = 60 if key_error else delays[min(attempts - 1, 5)]
        with self.db() as conn:
            conn.execute('UPDATE email_jobs SET status=?,next_attempt=?,nonce=CASE WHEN ? THEN NULL ELSE nonce END,'
                         'leased_until=0,lease_owner=NULL,last_error=?,attempts=attempts-? '
                         "WHERE id=? AND status='sending' AND lease_owner=?", (
                             status, self.clock() + delay, accepted or status == 'failed',
                             None if accepted else ('key_unavailable' if key_error else 'transport_failed'),
                             int(key_error), row['id'], owner))
        return True

    def start(self):
        if self.delivery.mode == 'not_configured' or self._thread is not None:
            return
        self._stopping.clear()
        self._thread = threading.Thread(target=self._loop, name='notetogether-mail', daemon=True)
        self._thread.start()

    def _loop(self):
        while not self._stopping.is_set():
            try:
                worked = self.run_once()
            except Exception:
                worked = False  # Storage failure preserves durable lease/job; no private log.
            if not worked:
                self._wake.wait(1)
                self._wake.clear()

    def stop(self):
        self._stopping.set()
        self._wake.set()
        if self._thread is not None:
            self._thread.join(timeout=25)
            if not self._thread.is_alive():
                self._thread = None
