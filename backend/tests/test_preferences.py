from backend.tests.test_security import env, headers


def test_field_merge_and_replay_cannot_undo_newer_change(env):
    client, _, users = env
    owner = headers(users[0])
    old = {'op_id': 'old', 'dark': True}
    assert client.post('/me/preferences/sync', json=old, headers=owner).status_code == 200
    client.post('/me/preferences/sync', json={'op_id': 'grid', 'grid': False}, headers=owner)
    client.post('/me/preferences/sync', json={'op_id': 'new', 'dark': False}, headers=owner)
    assert client.post('/me/preferences/sync', json=old, headers=owner).json()['preferences'] == {
        'grid': False, 'dark': False, 'font_size': 16}
    assert client.post('/me/preferences/sync', json={'op_id': 'old', 'dark': False}, headers=owner).status_code == 409


def test_preferences_account_isolation_validation_and_restart(env):
    from backend.app import create_app
    from fastapi.testclient import TestClient
    client, app, users = env
    body = {'op_id': 'same-id', 'font_size': 22.0}
    assert client.post('/me/preferences/sync', json=body).status_code == 401
    assert client.post('/me/preferences/sync', json=body, headers=headers(users[0])).status_code == 200
    assert client.get('/me', headers=headers(users[1])).json()['preferences'] == {}
    assert client.post('/me/preferences/sync', json={'op_id': 'same-id', 'font_size': 18.0}, headers=headers(users[1])).status_code == 200
    for patch in [{'font_size': 25}, {'dark': 'true'}, {'owner_id': users[1]['user']['id']}, {'dark': None}, {}]:
        assert client.post('/me/preferences/sync', json={'op_id': 'invalid', **patch}, headers=headers(users[0])).status_code == 422
    with TestClient(create_app(app.state.database)) as reopened:
        assert reopened.get('/me', headers=headers(users[0])).json()['preferences']['font_size'] == 22
        assert reopened.post('/me/preferences/sync', json=body, headers=headers(users[0])).status_code == 200


def test_locale_field_merge_replay_and_legacy_client(env):
    client, _, users = env
    auth = headers(users[0])
    english = {'op_id': 'locale-en', 'locale': 'en'}
    assert client.post('/me/preferences/sync', json=english, headers=auth).json()['preferences']['locale'] == 'en'
    client.post('/me/preferences/sync', json={'op_id': 'theme', 'dark': True}, headers=auth)
    profile = client.patch('/me/preferences', json={'grid': False, 'dark': True, 'font_size': 20}, headers=auth).json()
    assert profile['preferences'] == {'grid': False, 'dark': True, 'font_size': 20, 'locale': 'en'}
    client.post('/me/preferences/sync', json={'op_id': 'locale-vi', 'locale': 'vi'}, headers=auth)
    assert client.post('/me/preferences/sync', json=english, headers=auth).json()['preferences']['locale'] == 'vi'
    assert client.post('/me/preferences/sync', json={**english, 'locale': 'vi'}, headers=auth).status_code == 409


def test_locale_validation_account_isolation_and_reopen(env):
    from backend.app import create_app
    from fastapi.testclient import TestClient
    client, app, users = env
    body = {'op_id': 'language', 'locale': 'en'}
    assert client.post('/me/preferences/sync', json=body).status_code == 401
    for index, user in enumerate(users):
        assert client.post('/me/preferences/sync', json={**body, 'locale': 'en' if index == 0 else 'vi'}, headers=headers(user)).status_code == 200
    for locale in ('fr', 'en-US', '', None, 1, True):
        assert client.post('/me/preferences/sync', json={'op_id': 'bad', 'locale': locale}, headers=headers(users[0])).status_code == 422
    assert client.post('/me/preferences/sync', json={**body, 'owner_id': users[1]['user']['id']}, headers=headers(users[0])).status_code == 422
    with TestClient(create_app(app.state.database)) as reopened:
        assert reopened.get('/me', headers=headers(users[0])).json()['preferences']['locale'] == 'en'
        assert reopened.get('/me', headers=headers(users[1])).json()['preferences']['locale'] == 'vi'


def test_palette_merge_replay_preserves_locale_and_legacy_client(env):
    client, _, users = env
    auth = headers(users[0])
    first = {'op_id': 'palette-first', 'palette': 'ocean'}
    assert client.post('/me/preferences/sync', json=first, headers=auth).status_code == 200
    for palette in ('atelier', 'iris', 'rose', 'amber', 'forest'):
        assert client.post('/me/preferences/sync', json={'op_id': f'palette-{palette}', 'palette': palette}, headers=auth).status_code == 200
    client.post('/me/preferences/sync', json={'op_id': 'language', 'locale': 'en'}, headers=auth)
    profile = client.patch('/me/preferences', json={'grid': False, 'dark': True, 'font_size': 20}, headers=auth).json()
    assert profile['preferences'] == {'grid': False, 'dark': True, 'font_size': 20, 'palette': 'forest', 'locale': 'en'}
    assert client.post('/me/preferences/sync', json=first, headers=auth).json()['preferences']['palette'] == 'forest'
    assert client.post('/me/preferences/sync', json={**first, 'palette': 'rose'}, headers=auth).status_code == 409


def test_palette_validation_account_isolation_and_reopen(env):
    from backend.app import create_app
    from fastapi.testclient import TestClient
    client, app, users = env
    body = {'op_id': 'palette', 'palette': 'iris'}
    assert client.post('/me/preferences/sync', json=body).status_code == 401
    assert client.post('/me/preferences/sync', json=body, headers=headers(users[0])).status_code == 200
    assert client.post('/me/preferences/sync', json={**body, 'palette': 'rose'}, headers=headers(users[1])).status_code == 200
    for value in ('random', 'Ocean', '', None, 1, True, {}):
        assert client.post('/me/preferences/sync', json={**body, 'palette': value}, headers=headers(users[0])).status_code == 422
    assert client.post('/me/preferences/sync', json={**body, 'owner_id': users[1]['user']['id']}, headers=headers(users[0])).status_code == 422
    with TestClient(create_app(app.state.database)) as reopened:
        assert reopened.get('/me', headers=headers(users[0])).json()['preferences']['palette'] == 'iris'
        assert reopened.get('/me', headers=headers(users[1])).json()['preferences']['palette'] == 'rose'
        assert reopened.get('/me', headers=headers(users[2])).json()['preferences'] == {}
