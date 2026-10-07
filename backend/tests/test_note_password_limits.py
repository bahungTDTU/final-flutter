import sqlite3
import time

import pytest
from fastapi.testclient import TestClient

from backend.app import create_app
from backend.tests.mail_support import RecordingDelivery
from backend.tests.test_security import env, headers, make_note


PASSWORD = 'note-password-123'


def attempt(client, user, note, action, password):
    body = {'password': password} if action == 'unlock' else {'current_password': password}
    if action == 'change':
        body.update(password='next-note-password', confirmation='next-note-password')
    return client.post(f'/notes/{note}/' + ('unlock' if action == 'unlock' else 'protection'),
                       headers=headers(user), json=body)


def protect(client, user, note):
    assert client.post(f'/notes/{note}/protection', headers=headers(user), json={
        'password': PASSWORD, 'confirmation': PASSWORD}).status_code == 200


@pytest.mark.parametrize('first_action', ['unlock', 'change', 'disable'])
def test_mixed_failures_block_every_password_entry_across_sessions_and_restart(env, first_action):
    client, app, users = env
    owner, viewer, stranger = users
    editor = client.post('/auth/register', json={
        'email': 'editor@example.com', 'name': 'Editor',
        'password': 'safe-password-123', 'confirmation': 'safe-password-123'}).json()
    note = make_note(client, owner)
    for user, role in [(viewer, 'viewer'), (editor, 'editor')]:
        assert client.post(f'/notes/{note}/shares', headers=headers(owner),
                           json={'email': user['user']['email'], 'role': role}).status_code == 200
    protect(client, owner, note)
    for action in [first_action, 'unlock', 'change', 'disable', first_action]:
        assert attempt(client, owner, note, action, 'wrong').status_code == 403
    scope = f'unlock:{owner["user"]["id"]}:{note}'
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT failures FROM attempts WHERE scope=?', (scope,)).fetchone()[0] == 5
        assert conn.execute('SELECT revision,protection_version FROM notes WHERE id=?', (note,)).fetchone() == (2, 1)
    for action in ['unlock', 'change', 'disable']:
        response = attempt(client, owner, note, action, PASSWORD)
        assert response.status_code == 429 and 1 <= int(response.headers['retry-after']) <= 61
    second = client.post('/auth/login', json={
        'email': owner['user']['email'], 'password': 'safe-password-123'}).json()
    assert attempt(client, second, note, 'disable', PASSWORD).status_code == 429
    restarted = create_app(app.state.database, email_delivery=RecordingDelivery(), start_email_worker=False)
    with TestClient(restarted) as other_client:
        assert attempt(other_client, second, note, 'change', PASSWORD).status_code == 429
    for user in [viewer, editor]:
        assert attempt(client, user, note, 'unlock', PASSWORD).status_code == 200
        for action in ['change', 'disable']:
            assert attempt(client, user, note, action, PASSWORD).status_code == 403
    for action in ['unlock', 'change', 'disable']:
        assert attempt(client, stranger, note, action, PASSWORD).status_code == 404
    assert client.get(f'/notes/{note}', headers=headers(owner)).status_code == 423
    other_note = make_note(client, owner)
    protect(client, owner, other_note)
    assert attempt(client, owner, other_note, 'unlock', PASSWORD).status_code == 200


def test_elapsed_cooldown_starts_fresh_window_and_success_clears_shared_counter(env, monkeypatch):
    client, app, users = env
    owner = users[0]
    note = make_note(client, owner)
    protect(client, owner, note)
    clock = [time.time()]
    monkeypatch.setattr('backend.app.time.time', lambda: clock[0])
    for _ in range(5):
        assert attempt(client, owner, note, 'disable', 'wrong').status_code == 403
    assert attempt(client, owner, note, 'unlock', PASSWORD).status_code == 429
    clock[0] += 61
    assert attempt(client, owner, note, 'change', 'wrong').status_code == 403
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT failures,blocked_until FROM attempts WHERE scope=?',
                            (f'unlock:{owner["user"]["id"]}:{note}',)).fetchone() == (1, 0)
    assert attempt(client, owner, note, 'unlock', PASSWORD).status_code == 200
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT 1 FROM attempts WHERE scope=?',
                            (f'unlock:{owner["user"]["id"]}:{note}',)).fetchone() is None
    assert attempt(client, owner, note, 'change', PASSWORD).status_code == 200
    assert client.get(f'/notes/{note}', headers=headers(owner)).status_code == 423
    assert attempt(client, owner, note, 'unlock', PASSWORD).status_code == 403
    assert attempt(client, owner, note, 'disable', 'next-note-password').status_code == 200
    assert client.get(f'/notes/{note}', headers=headers(owner)).status_code == 200
