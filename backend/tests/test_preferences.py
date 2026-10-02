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
