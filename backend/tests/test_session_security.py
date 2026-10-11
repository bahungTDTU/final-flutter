import sqlite3
import time
from concurrent.futures import ThreadPoolExecutor
from uuid import uuid4

from fastapi.testclient import TestClient

from backend.app import create_app, digest
from backend.realtime import account_version
from backend.tests.mail_support import RecordingDelivery
from backend.tests.test_security import env, headers, make_note, operation

PASSWORD = 'safe-password-123'


def login(client, user, ua='Mozilla/5.0 Android Chrome/130.0'):
    r = client.post('/auth/login', json={'email': user['user']['email'], 'password': PASSWORD},
                    headers={'User-Agent': ua})
    assert r.status_code == 200
    return r.json()


def rows(client, user):
    r = client.get('/me/sessions', headers=headers(user))
    assert r.status_code == 200
    return r.json()


def revoke(client, user, session_id=None, password=PASSWORD):
    body = {'scope': 'one' if session_id else 'others', 'password': password}
    if session_id:
        body['session_id'] = session_id
    return client.post('/me/sessions/revoke', headers=headers(user), json=body)


def test_private_projection_revoke_one_cascades_grants_and_expires_feed(env):
    client, app, users = env
    owner, other, _ = users
    second = login(client, owner)
    note = make_note(client, owner)
    assert client.post(f'/notes/{note}/protection', headers=headers(owner),
                       json={'password': 'note-password-123', 'confirmation': 'note-password-123'}).status_code == 200
    assert client.post(f'/notes/{note}/unlock', headers=headers(second),
                       json={'password': 'note-password-123'}).status_code == 200
    catalog = rows(client, owner)
    assert catalog['total'] == 2 and catalog['limit'] == 20
    assert [r['is_current'] for r in catalog['sessions']] == [True, False]
    assert all(set(r) == {'id', 'label', 'created_at', 'expires_at', 'is_current'} for r in catalog['sessions'])
    target = catalog['sessions'][1]['id']
    assert catalog['sessions'][1]['label'] == 'Chrome · Android'
    assert digest(second['token']) not in str(catalog) and second['token'] not in str(catalog)
    assert revoke(client, owner, target).json() == {'ok': True, 'revoked': 1}
    assert revoke(client, owner, target).json() == {'ok': True, 'revoked': 0}
    assert client.get('/me', headers=headers(second)).status_code == 401
    assert account_version(app.state.database, (owner['user']['id'], digest(second['token']))) is None
    assert client.get('/me', headers=headers(owner)).status_code == 200
    assert client.get('/me', headers=headers(other)).status_code == 200
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT 1 FROM grants WHERE session_digest=?', (digest(second['token']),)).fetchone() is None
        assert conn.execute('SELECT 1 FROM session_details WHERE id=?', (target,)).fetchone() is None


def test_foreign_current_and_payload_targets_are_safe(env):
    client, _, users = env
    owner, other, _ = users
    current = rows(client, owner)['sessions'][0]['id']
    foreign = rows(client, other)['sessions'][0]['id']
    assert revoke(client, owner, foreign).json() == {'ok': True, 'revoked': 0}
    assert client.get('/me', headers=headers(other)).status_code == 200
    assert revoke(client, owner, current).status_code == 409
    for body in [
        {'scope': 'others', 'password': PASSWORD, 'user_id': other['user']['id']},
        {'scope': 'one', 'password': PASSWORD},
        {'scope': 'others', 'password': PASSWORD, 'session_id': foreign},
        {'scope': 'one', 'password': 'x' * 129, 'session_id': foreign},
    ]:
        assert client.post('/me/sessions/revoke', headers=headers(owner), json=body).status_code == 422
    assert revoke(client, owner).json() == {'ok': True, 'revoked': 0}
    assert client.get('/me', headers=headers(owner)).status_code == 200


def test_reauth_shared_counter_commit_restart_and_fresh_cooldown(env, monkeypatch):
    client, app, users = env
    owner = users[0]
    login(client, owner)
    clock = [time.time()]
    monkeypatch.setattr('backend.app.time.time', lambda: clock[0])
    for i in range(5):
        if i % 2:
            response = client.post('/auth/password', headers=headers(owner), json={
                'current_password': 'wrong', 'password': 'next-password-123', 'confirmation': 'next-password-123'})
        else:
            response = revoke(client, owner, password='wrong')
        assert response.status_code == 403
    r = revoke(client, owner)
    assert r.status_code == 429 and 1 <= int(r.headers['retry-after']) <= 60
    restarted = create_app(app.state.database, email_delivery=RecordingDelivery(), start_email_worker=False)
    with TestClient(restarted) as other_client:
        assert revoke(other_client, owner).status_code == 429
    clock[0] += 61
    assert revoke(client, owner, password='wrong').status_code == 403
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT failures,blocked_until FROM attempts WHERE scope=?',
                            ('account-password:' + owner['user']['id'],)).fetchone() == (1, 0)
    assert revoke(client, owner).json() == {'ok': True, 'revoked': 1}
    assert client.get('/me', headers=headers(owner)).status_code == 200


def test_login_validation_hash_scope_and_elapsed_cooldown(env, monkeypatch):
    client, app, users = env
    clock = [time.time()]
    monkeypatch.setattr('backend.app.time.time', lambda: clock[0])
    for body in [{'email': 'x' * 255, 'password': 'wrong'},
                 {'email': 'missing@example.com', 'password': 'x' * 129}]:
        assert client.post('/auth/login', json=body).status_code == 422
    email = 'missing@example.com'
    for _ in range(5):
        assert client.post('/auth/login', json={'email': email, 'password': 'wrong'}).status_code == 401
    r = client.post('/auth/login', json={'email': email, 'password': 'wrong'})
    assert r.status_code == 429 and r.headers['retry-after'] == '60'
    clock[0] += 61
    assert client.post('/auth/login', json={'email': email, 'password': 'wrong'}).status_code == 401
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT failures FROM attempts WHERE scope=?', ('login:' + digest(email),)).fetchone()[0] == 1
        assert conn.execute("SELECT 1 FROM attempts WHERE scope LIKE 'login:%@%'").fetchone() is None


def test_legacy_migration_stable_handles_no_fake_date_or_lost_cooldown(env):
    client, app, users = env
    owner = users[0]
    with sqlite3.connect(app.state.database) as conn:
        conn.execute('DELETE FROM session_details WHERE session_digest=?', (digest(owner['token']),))
        conn.execute('INSERT INTO attempts VALUES (?,?,?)', ('login:' + owner['user']['email'], 5, time.time() + 60))
    restarted = create_app(app.state.database, email_delivery=RecordingDelivery(), start_email_worker=False)
    with TestClient(restarted) as second:
        row = rows(second, owner)['sessions'][0]
        assert row['label'] == 'Phiên cũ' and row['created_at'] is None
        again = create_app(app.state.database, email_delivery=RecordingDelivery(), start_email_worker=False)
        with TestClient(again) as third:
            assert rows(third, owner)['sessions'][0]['id'] == row['id']
            assert third.post('/auth/login', json={'email': owner['user']['email'], 'password': PASSWORD}).status_code == 429


def test_session_cap_expired_cleanup_and_current_retained_at_tied_times(env, monkeypatch):
    client, app, users = env
    owner, other, _ = users
    clock = time.time()
    monkeypatch.setattr('backend.app.time.time', lambda: clock)
    # Seed a legacy account with >20 sessions; list stays bounded before next login.
    with sqlite3.connect(app.state.database) as conn:
        for i in range(25):
            d = digest('legacy-' + str(i))
            conn.execute('INSERT INTO sessions VALUES (?,?,?)', (d, owner['user']['id'], clock + 10000))
            conn.execute('INSERT INTO session_details VALUES (?,?,?,?)', (str(uuid4()), d, 'Phiên cũ', clock))
        expired = digest('expired-fixture')
        conn.execute('INSERT INTO sessions VALUES (?,?,?)', (expired, owner['user']['id'], clock - 1))
    assert rows(client, owner)['total'] == 26 and len(rows(client, owner)['sessions']) == 20
    new = login(client, owner)
    assert rows(client, new)['total'] == 20
    assert client.get('/me', headers=headers(new)).status_code == 200
    assert client.get('/me', headers=headers(other)).status_code == 200
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT 1 FROM sessions WHERE digest=?', (expired,)).fetchone() is None
        plan = conn.execute('EXPLAIN QUERY PLAN SELECT digest FROM sessions WHERE user_id=? AND expires>?',
                            (owner['user']['id'], clock)).fetchall()
        assert any('sessions_user_expiry' in str(r) for r in plan)


def test_read_auth_avoids_writer_reservation_but_mutations_revalidate(env):
    client, app, users = env
    owner = users[0]
    with sqlite3.connect(app.state.database) as writer:
        writer.execute('BEGIN IMMEDIATE')
        with ThreadPoolExecutor(max_workers=1) as pool:
            response = pool.submit(client.get, '/me/sessions', headers=headers(owner)).result(timeout=2)
        assert response.status_code == 200  # Would wait for writer's lock with old auth BEGIN IMMEDIATE.
    identity = (owner['user']['id'], digest(owner['token']))
    with sqlite3.connect(app.state.database) as conn:
        conn.execute('DELETE FROM sessions WHERE digest=?', (identity[1],))
    sync_route = next(r for r in app.routes if r.path == '/sync')
    authenticate = sync_route.dependant.dependencies[0].call
    app.dependency_overrides[authenticate] = lambda: identity
    try:
        assert client.post('/sync', headers=headers(owner), json=operation()).status_code == 401
        assert client.post('/me/sessions/revoke', headers=headers(owner), json={
            'scope': 'others', 'password': PASSWORD}).status_code == 401
    finally:
        app.dependency_overrides.clear()


def test_private_headers_cover_errors_and_authenticated_payloads(env):
    client, _, users = env
    for response in [client.get('/me'), client.get('/me/sessions', headers=headers(users[0])),
                     client.post('/auth/login', json={'email': '', 'password': ''})]:
        assert response.headers['cache-control'] == 'private, no-store'
        assert response.headers['x-content-type-options'] == 'nosniff'
        assert response.headers['referrer-policy'] == 'no-referrer'


def test_validation_does_not_echo_passwords_tokens_or_the_full_body(env):
    client, _, users = env
    private = 'validation-private-marker'
    payloads = [
        ('/auth/login', {'email': 'owner@example.com', 'password': private * 8}),
        ('/auth/reset', {'token': private, 'password': 'new-password-123', 'confirmation': private * 8}),
        ('/me/sessions/revoke', {'scope': 'one', 'password': private}),
    ]
    for path, payload in payloads:
        response = client.post(path, json=payload, headers=headers(users[0]))
        assert response.status_code == 422
        assert private not in response.text
        assert all(set(error) == {'loc', 'msg', 'type'} for error in response.json()['detail'])
        assert response.headers['cache-control'] == 'private, no-store'
