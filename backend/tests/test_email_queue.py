import hashlib
import sqlite3
import threading
import time

import pytest
from fastapi.testclient import TestClient

from backend.app import create_app
from backend.email_delivery import DisabledDelivery
from backend.email_delivery import SmtpDelivery, SmtpSettings
from backend.tests.mail_support import RecordingDelivery
from backend.tests.smtp_sink import MailSink, make_certificate


def setup(tmp_path, transport=None, worker=False):
    transport = transport or RecordingDelivery()
    app = create_app(tmp_path / 'mail.sqlite3', email_delivery=transport, start_email_worker=worker)
    client = TestClient(app)
    return app, client, transport


def register(client, email='queue@example.test'):
    result = client.post('/auth/register', json={'email': email, 'name': 'Queue QA',
        'password': 'safe-password-123', 'confirmation': 'safe-password-123'})
    assert result.status_code == 201
    data = result.json()
    return {'Authorization': 'Bearer ' + data['token']}, data


def read(app, query, args=()):
    with sqlite3.connect(app.state.database) as conn:
        conn.row_factory = sqlite3.Row
        return conn.execute(query, args).fetchone()


def mutate(app, query, args=()):
    with sqlite3.connect(app.state.database) as conn:
        conn.execute(query, args)


def test_job_survives_restart_without_raw_code_or_key_in_sqlite(tmp_path):
    app, client, transport = setup(tmp_path)
    headers, data = register(client)
    assert data['email_delivery'] == 'queued'
    assert transport.messages == []
    assert client.get('/auth/email-status', headers=headers).json()['email_delivery'] == 'queued'
    restarted = create_app(app.state.database, email_delivery=transport, start_email_worker=False)
    assert restarted.state.email_queue.run_once()
    code = transport.messages[0]['token']
    key = restarted.state.email_queue.key_path.read_bytes()
    raw = open(app.state.database, 'rb').read()
    assert code.encode() not in raw and key not in raw
    job = read(app, 'SELECT * FROM email_jobs')
    assert job['nonce'] is None and job['status'] == 'test_only'
    assert job['token_digest'] == hashlib.sha256(code.encode()).hexdigest()
    assert client.post('/auth/verify', json={'token': code}).status_code == 200
    assert client.post('/auth/verify', json={'token': code}).status_code == 400


def test_failure_backoff_retries_same_code_then_accepts(tmp_path):
    app, client, transport = setup(tmp_path)
    headers, _ = register(client)
    clock = [time.time()]
    app.state.email_queue.clock = lambda: clock[0]
    transport.fail = True
    assert app.state.email_queue.run_once()
    first = read(app, 'SELECT * FROM email_jobs')
    assert first['status'] == 'retrying' and first['attempts'] == 1
    assert first['last_error'] == 'transport_failed'
    assert client.get('/auth/email-status', headers=headers).json()['email_delivery'] == 'retrying'
    assert not app.state.email_queue.run_once()
    clock[0] = first['next_attempt'] + 1
    transport.fail = False
    assert app.state.email_queue.run_once()
    code = transport.messages[-1]['token']
    assert hashlib.sha256(code.encode()).hexdigest() == first['token_digest']
    assert read(app, 'SELECT * FROM email_jobs')['nonce'] is None


def test_real_tls_retry_accepts_the_queued_code_and_verifies_after_restart(tmp_path):
    cert, key = make_certificate(tmp_path / 'tls')
    with MailSink(cert, key, reject=True) as sink:
        transport = SmtpDelivery(SmtpSettings('localhost', sink.port, 'sender@example.test', ca_file=str(cert)))
        app, client, _ = setup(tmp_path, transport)
        headers, _ = register(client)
        assert app.state.email_queue.run_once()
        assert client.get('/auth/email-status', headers=headers).json()['email_delivery'] == 'retrying'
        original = read(app, 'SELECT token_digest FROM email_jobs')['token_digest']
        sink.reject = False
        app.state.email_queue.clock = lambda: time.time() + 16
        assert app.state.email_queue.run_once()
        code = sink.code('queue@example.test', 'verify')
        assert hashlib.sha256(code.encode()).hexdigest() == original
        assert sink.messages[0]['tls'] is True
        restarted = TestClient(create_app(app.state.database, email_delivery=transport, start_email_worker=False))
        assert restarted.post('/auth/verify', json={'token': code}).status_code == 200
        assert sink.code('queue@example.test', 'reset') is None
        assert client.post('/auth/forgot', json={'email': 'queue@example.test'}).status_code == 200
        assert sink.code('queue@example.test', 'reset') is None
        assert app.state.email_queue.run_once()
        reset = sink.code('queue@example.test', 'reset')
        assert client.post('/auth/reset/check', json={'token': reset}).status_code == 200


def test_crashed_send_lease_replays_same_code_after_restart(tmp_path):
    app, client, transport = setup(tmp_path)
    headers, _ = register(client)
    original = read(app, 'SELECT * FROM email_jobs')
    mutate(app, "UPDATE email_jobs SET status='sending',leased_until=?,lease_owner='dead-worker',attempts=1",
           (time.time() + 120,))
    other = create_app(app.state.database, email_delivery=transport, start_email_worker=False)
    assert not other.state.email_queue.run_once()
    other.state.email_queue.clock = lambda: time.time() + 121
    assert other.state.email_queue.run_once()
    assert hashlib.sha256(transport.messages[-1]['token'].encode()).hexdigest() == original['token_digest']
    mutate(app, 'UPDATE attempts SET blocked_until=0')
    assert client.post('/auth/resend', headers=headers).status_code == 200
    mutate(app, "UPDATE email_jobs SET status='sending',attempts=6,leased_until=0,lease_owner='dead-worker' WHERE status='queued'")
    assert not other.state.email_queue.run_once()
    assert len(transport.messages) == 1
    assert read(app, "SELECT nonce FROM email_jobs WHERE status='failed'")['nonce'] is None


def test_resend_cancels_old_pending_and_expiry_does_not_send(tmp_path):
    app, client, transport = setup(tmp_path)
    headers, _ = register(client)
    first = read(app, 'SELECT * FROM email_jobs')['id']
    mutate(app, 'UPDATE attempts SET blocked_until=0')
    assert client.post('/auth/resend', headers=headers).json()['email_delivery'] == 'queued'
    assert read(app, 'SELECT status,nonce FROM email_jobs WHERE id=?', (first,))['nonce'] is None
    mutate(app, 'UPDATE email_tokens SET expires=0')
    assert not app.state.email_queue.run_once()
    assert transport.messages == []
    assert client.get('/auth/email-status', headers=headers).json()['email_delivery'] == 'expired'


def test_missing_key_preserves_job_and_public_forgot_does_not_enumerate(tmp_path):
    app, client, transport = setup(tmp_path)
    headers, _ = register(client)
    job = read(app, 'SELECT * FROM email_jobs')
    app.state.email_queue.key_path.unlink()
    other = create_app(app.state.database, email_delivery=transport, start_email_worker=False)
    other_client = TestClient(other)
    mutate(app, 'UPDATE attempts SET blocked_until=0')
    assert other_client.post('/auth/resend', headers=headers).status_code == 503
    assert not other.state.email_queue.key_path.exists()
    assert read(app, 'SELECT nonce FROM email_jobs')['nonce'] == job['nonce']
    failed = other_client.post('/auth/register', json={'email': 'new@example.test', 'name': 'New',
        'password': 'safe-password-123', 'confirmation': 'safe-password-123'})
    assert failed.status_code == 503
    assert read(app, 'SELECT count(*) AS n FROM users')['n'] == 1
    known = other_client.post('/auth/forgot', json={'email': 'queue@example.test'})
    unknown = other_client.post('/auth/forgot', json={'email': 'absent@example.test'})
    assert known.status_code == unknown.status_code == 200 and known.json() == unknown.json()
    assert other.state.email_queue.run_once()
    assert read(app, 'SELECT attempts FROM email_jobs')['attempts'] == 0
    assert transport.messages == []


def test_status_is_authenticated_and_scoped_to_current_account(tmp_path):
    app, client, _ = setup(tmp_path)
    owner, _ = register(client)
    stranger, _ = register(client, 'other@example.test')
    mutate(app, "UPDATE email_jobs SET status='failed' WHERE user_id=(SELECT id FROM users WHERE email='queue@example.test')")
    assert client.get('/auth/email-status').status_code == 401
    assert client.get('/auth/email-status', headers=owner).json()['email_delivery'] == 'failed'
    assert client.get('/auth/email-status', headers=stranger).json()['email_delivery'] == 'queued'
    client.post('/auth/logout', headers=owner)
    assert client.get('/auth/email-status', headers=owner).status_code == 401


def test_six_failed_attempts_stop_and_disabled_mode_has_no_jobs_or_key(tmp_path):
    app, client, transport = setup(tmp_path)
    register(client)
    transport.fail = True
    for _ in range(6):
        mutate(app, 'UPDATE email_jobs SET next_attempt=0')
        assert app.state.email_queue.run_once()
    job = read(app, 'SELECT * FROM email_jobs')
    assert job['status'] == 'failed' and job['attempts'] == 6 and job['nonce'] is None
    assert not app.state.email_queue.run_once()
    disabled_dir = tmp_path / 'disabled'
    disabled_dir.mkdir()
    disabled, disabled_client, _ = setup(disabled_dir, DisabledDelivery())
    _, response = register(disabled_client)
    assert response['email_delivery'] == 'not_configured'
    assert not disabled.state.email_queue.key_path.exists()
    assert read(disabled, 'SELECT count(*) AS n FROM email_jobs')['n'] == 0


def test_slow_smtp_does_not_block_registration_notes_or_second_worker(tmp_path):
    entered, release = threading.Event(), threading.Event()

    class SlowDelivery(RecordingDelivery):
        def send(self, *args):
            entered.set()
            assert release.wait(5)
            return super().send(*args)

    app, _, transport = setup(tmp_path, SlowDelivery(), worker=True)
    with TestClient(app) as client:
        try:
            headers, data = register(client)
            assert data['email_delivery'] == 'queued'
            assert entered.wait(2)
            assert client.get('/notes', headers=headers).status_code == 200
            other = create_app(app.state.database, email_delivery=transport, start_email_worker=False)
            assert not other.state.email_queue.run_once()
        finally:
            release.set()
    assert len(transport.messages) == 1
    assert read(app, 'SELECT status FROM email_jobs')['status'] == 'test_only'
