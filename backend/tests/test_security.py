import sqlite3
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from backend.app import create_app
from backend.tests.mail_support import RecordingDelivery


@pytest.fixture
def env(tmp_path):
    app = create_app(tmp_path / 'test.sqlite3', email_delivery=RecordingDelivery(), start_email_worker=False)
    with TestClient(app) as client:
        users = []
        for name in ['owner', 'recipient', 'stranger']:
            response = client.post('/auth/register', json={
                'email': name + '@example.com', 'name': name,
                'password': 'safe-password-123', 'confirmation': 'safe-password-123'})
            assert response.status_code == 201
            users.append(response.json())
            app.state.email_queue.run_once()
        yield client, app, users


def headers(user):
    return {'Authorization': 'Bearer ' + user['token']}


def operation(note_id=None, revision=0, **kwargs):
    return {'op_id': str(uuid4()), 'note_id': note_id or str(uuid4()),
            'base_revision': revision, 'kind': 'upsert', 'title': 'Private title',
            'content': 'Confidential content', **kwargs}


def make_note(client, user):
    op = operation()
    assert client.post('/sync', json=op, headers=headers(user)).status_code == 200
    return op['note_id']


def test_registration_unverified_can_use_all_core_apis(env):
    client, app, users = env
    owner = users[0]
    assert owner['user']['verified'] is False
    assert client.get('/me', headers=headers(owner)).status_code == 200
    make_note(client, owner)
    token = app.state.email_delivery.messages[0]['token']
    assert client.post('/auth/verify', json={'token': token}).status_code == 200
    assert client.get('/me', headers=headers(owner)).json()['verified'] is True
    assert client.post('/auth/verify', json={'token': token}).status_code == 400


def test_auth_guards_logout_and_hashes(env):
    client, app, users = env
    assert client.get('/notes').status_code == 401
    with sqlite3.connect(app.state.database) as conn:
        encoded = conn.execute('SELECT password FROM users LIMIT 1').fetchone()[0]
        assert encoded.startswith('$argon2id$')
        assert 'safe-password-123' not in encoded
    assert client.post('/auth/logout', headers=headers(users[0])).status_code == 200
    assert client.get('/me', headers=headers(users[0])).status_code == 401


def test_reset_requires_manual_login_and_invalidates_sessions(env):
    client, app, users = env
    client.post('/auth/forgot', json={'email': 'owner@example.com'})
    app.state.email_queue.run_once()
    token = app.state.email_delivery.messages[-1]['token']
    result = client.post('/auth/reset', json={'token': token,
        'password': 'new-password-123', 'confirmation': 'new-password-123'})
    assert result.json() == {'ok': True, 'login_required': True}
    assert client.get('/me', headers=headers(users[0])).status_code == 401
    assert client.post('/auth/login', json={'email': 'owner@example.com', 'password': 'new-password-123'}).status_code == 200
    assert client.post('/auth/reset', json={'token': token,
        'password': 'new-password-123', 'confirmation': 'new-password-123'}).status_code == 400


def test_expired_activation_rejected(env):
    client, app, _ = env
    with sqlite3.connect(app.state.database) as conn:
        conn.execute('UPDATE email_tokens SET expires=0')
    assert client.post('/auth/verify', json={'token': app.state.email_delivery.messages[0]['token']}).status_code == 400


def test_change_password_checks_old_and_revokes_session(env):
    client, _, users = env
    body = {'current_password': 'wrong', 'password': 'new-password-123', 'confirmation': 'new-password-123'}
    assert client.post('/auth/password', json=body, headers=headers(users[0])).status_code == 403
    body['current_password'] = 'safe-password-123'
    assert client.post('/auth/password', json=body, headers=headers(users[0])).status_code == 200
    assert client.get('/me', headers=headers(users[0])).status_code == 401


def test_idempotency_conflict_and_delete_vs_edit(env):
    client, _, users = env
    user = users[0]
    op = operation()
    first = client.post('/sync', json=op, headers=headers(user))
    assert first.status_code == 200
    assert client.post('/sync', json=op, headers=headers(user)).json() == first.json()
    changed = dict(op, content='changed')
    assert client.post('/sync', json=changed, headers=headers(user)).status_code == 409
    conflict = client.post('/sync', json=operation(op['note_id'], 0), headers=headers(user))
    assert conflict.status_code == 409
    assert conflict.json()['detail']['remote']['content'] == 'Confidential content'
    delete = operation(op['note_id'], 1, kind='delete')
    assert client.post('/sync', json=delete, headers=headers(user)).status_code == 200
    assert client.post('/sync', json=delete, headers=headers(user)).status_code == 200
    assert client.post('/sync', json=operation(op['note_id'], 2), headers=headers(user)).status_code == 409


def test_owner_viewer_editor_stranger_and_revoke(env):
    client, _, users = env
    owner, recipient, stranger = users
    note_id = make_note(client, owner)
    assert client.get('/notes/' + note_id, headers=headers(stranger)).status_code == 404
    url = '/notes/' + note_id + '/shares'
    assert client.post(url, json={'email': 'recipient@example.com', 'role': 'viewer'}, headers=headers(owner)).status_code == 200
    assert client.get('/notes/' + note_id, headers=headers(recipient)).status_code == 200
    assert client.post('/sync', json=operation(note_id, 1), headers=headers(recipient)).status_code == 403
    assert client.post(url, json={'email': 'recipient@example.com', 'role': 'editor'}, headers=headers(owner)).status_code == 200
    edit = operation(note_id, 1, content='Recipient edit')
    assert client.post('/sync', json=edit, headers=headers(recipient)).status_code == 200
    assert client.post('/sync', json=operation(note_id, 2, kind='delete'), headers=headers(recipient)).status_code == 403
    assert client.post(url, json={'email': 'stranger@example.com', 'role': 'editor'}, headers=headers(recipient)).status_code == 403
    assert client.delete(url + '/' + recipient['user']['id'], headers=headers(owner)).status_code == 200
    assert client.get('/notes/' + note_id, headers=headers(recipient)).status_code == 404
    assert client.post('/sync', json=edit, headers=headers(recipient)).status_code == 404


def test_locked_owner_no_content_and_session_bound_grants(env):
    client, _, users = env
    owner = users[0]
    note_id = make_note(client, owner)
    url = '/notes/' + note_id
    protection = {'password': 'note-password-123', 'confirmation': 'note-password-123'}
    assert client.post(url + '/protection', json=protection, headers=headers(owner)).status_code == 200
    assert client.get(url, headers=headers(owner)).status_code == 423
    assert client.post('/sync', json=operation(note_id, 2), headers=headers(owner)).status_code == 423
    metadata = client.get('/notes', headers=headers(owner)).json()
    assert metadata == [{'id': note_id, 'locked': True, 'revision': 2, 'role': 'owner'}]
    assert client.post(url + '/unlock', json={'password': 'wrong'}, headers=headers(owner)).status_code == 403
    assert client.post(url + '/unlock', json={'password': 'note-password-123'}, headers=headers(owner)).status_code == 200
    assert client.get(url, headers=headers(owner)).json()['content'] == 'Confidential content'
    second = client.post('/auth/login', json={'email': 'owner@example.com', 'password': 'safe-password-123'}).json()
    assert client.get(url, headers=headers(second)).status_code == 423
    assert client.post(url + '/protection', json={'current_password': 'note-password-123',
        'password': 'next-password-123', 'confirmation': 'next-password-123'}, headers=headers(owner)).status_code == 200
    assert client.get(url, headers=headers(owner)).status_code == 423


def test_expired_grant_and_failed_attempt_limit(env):
    client, app, users = env
    owner = users[0]
    note_id = make_note(client, owner)
    url = '/notes/' + note_id
    client.post(url + '/protection', json={'password': 'note-password-123', 'confirmation': 'note-password-123'}, headers=headers(owner))
    client.post(url + '/unlock', json={'password': 'note-password-123'}, headers=headers(owner))
    with sqlite3.connect(app.state.database) as conn:
        conn.execute('UPDATE grants SET expires=0')
    assert client.get(url, headers=headers(owner)).status_code == 423
    for _ in range(5):
        assert client.post(url + '/unlock', json={'password': 'wrong'}, headers=headers(owner)).status_code == 403
    assert client.post(url + '/unlock', json={'password': 'note-password-123'}, headers=headers(owner)).status_code == 429


def test_relock_only_revokes_calling_session_for_each_role(env):
    client, _, users = env
    owner, recipient, stranger = users
    for role in ['viewer', 'editor']:
        note_id = make_note(client, owner)
        url = '/notes/' + note_id
        assert client.post(url + '/shares', json={'email': 'recipient@example.com', 'role': role}, headers=headers(owner)).status_code == 200
        protected = client.post(url + '/protection', json={'password': 'note-password-123', 'confirmation': 'note-password-123'}, headers=headers(owner))
        assert protected.json() == {'ok': True, 'revision': 2, 'locked': True}
        second = client.post('/auth/login', json={'email': 'recipient@example.com', 'password': 'safe-password-123'}).json()
        for identity in [owner, recipient, second]:
            assert client.post(url + '/unlock', json={'password': 'note-password-123'}, headers=headers(identity)).status_code == 200
        assert client.post(url + '/lock', headers=headers(stranger)).status_code == 404
        assert client.post(url + '/lock').status_code == 401
        for _ in range(2):
            assert client.post(url + '/lock', headers=headers(recipient)).json() == {'ok': True}
        assert client.get(url, headers=headers(recipient)).status_code == 423
        assert client.get(url, headers=headers(second)).json()['content'] == 'Confidential content'
        assert client.get(url, headers=headers(owner)).status_code == 200
        assert client.post(url + '/protection', json={'password': None, 'current_password': 'note-password-123'}, headers=headers(recipient)).status_code == 403
        assert client.post(url + '/lock', headers=headers(owner)).status_code == 200
        assert client.get(url, headers=headers(owner)).status_code == 423
        disabled = client.post(url + '/protection', json={'password': None, 'current_password': 'note-password-123'}, headers=headers(owner))
        assert disabled.json() == {'ok': True, 'revision': 3, 'locked': False}
        assert client.get(url, headers=headers(recipient)).status_code == 200


def test_shared_locked_and_replay_does_not_leak_content(env):
    client, _, users = env
    owner, recipient, _ = users
    op = operation()
    client.post('/sync', json=op, headers=headers(owner))
    note_id = op['note_id']
    client.post('/notes/' + note_id + '/shares', json={'email': 'recipient@example.com', 'role': 'editor'}, headers=headers(owner))
    client.post('/notes/' + note_id + '/protection', json={'password': 'note-password-123', 'confirmation': 'note-password-123'}, headers=headers(owner))
    assert client.post('/sync', json=op, headers=headers(owner)).status_code == 423
    assert client.get('/notes/' + note_id, headers=headers(recipient)).status_code == 423
    assert client.get('/notes', headers=headers(recipient)).json() == [
        {'id': note_id, 'locked': True, 'revision': 2, 'role': 'editor'}]
    assert client.get('/notes', headers=headers(users[2])).json() == []
    assert client.post('/notes/' + note_id + '/unlock', json={'password': 'note-password-123'}, headers=headers(owner)).status_code == 200
    assert client.post('/notes/' + note_id + '/shares', json={'email': 'recipient@example.com', 'role': 'viewer'}, headers=headers(owner)).status_code == 200
    assert client.get('/notes', headers=headers(recipient)).json() == [
        {'id': note_id, 'locked': True, 'revision': 2, 'role': 'viewer'}]


def test_preferences_profile_persist(env):
    client, _, users = env
    owner = users[0]
    assert client.patch('/me', json={'name': 'Hung'}, headers=headers(owner)).json()['name'] == 'Hung'
    assert client.patch('/me/preferences', json={'grid': False, 'dark': True, 'font_size': 20}, headers=headers(owner)).status_code == 200
    assert client.get('/me', headers=headers(owner)).json()['preferences']['dark'] is True


def test_invalid_registration_and_share(env):
    client, _, users = env
    assert client.post('/auth/register', json={'email': 'bad', 'name': 'x', 'password': 'long-password', 'confirmation': 'long-password'}).status_code == 422
    note_id = make_note(client, users[0])
    for email, status in [('missing@example.com', 404), ('owner@example.com', 422)]:
        assert client.post('/notes/' + note_id + '/shares', json={'email': email, 'role': 'viewer'}, headers=headers(users[0])).status_code == status
