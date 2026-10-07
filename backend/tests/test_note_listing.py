import json
import sqlite3

import pytest

from backend.tests.test_security import env, headers, operation


@pytest.mark.parametrize('count', [5, 150])
def test_listing_has_bounded_queries_and_matches_authorized_detail(env, monkeypatch, count):
    client, app, users = env
    owner, recipient, stranger = users
    owner_id = owner['user']['id']
    with sqlite3.connect(app.state.database) as conn:
        conn.execute('INSERT INTO labels VALUES (?,?,?,?,1,0)', ('a', owner_id, 'First', 'first'))
        conn.execute('INSERT INTO labels VALUES (?,?,?,?,1,0)', ('b', owner_id, 'Second', 'second'))
        for i in range(count):
            conn.execute('INSERT INTO notes(id,owner_id,title,content,revision,updated_at,labels) VALUES (?,?,?,?,1,?,?)',
                         (f'n{i}', owner_id, 'Title', 'Text', '2026-10-03', json.dumps(['b', 'a'])))
            conn.execute('INSERT INTO shares VALUES (?,?,?,?)',
                         (f'n{i}', recipient['user']['id'], 'viewer' if i % 2 else 'editor', '2026-10-03'))
    conn.close()
    original, queries = sqlite3.connect, []

    def traced(*args, **kwargs):
        connection = original(*args, **kwargs)
        connection.set_trace_callback(lambda sql: queries.append(sql)
                                      if sql.lstrip().upper().startswith('SELECT') else None)
        return connection

    monkeypatch.setattr(sqlite3, 'connect', traced)
    for user in (owner, recipient):
        queries.clear()
        response = client.get('/notes', headers=headers(user))
        assert response.status_code == 200
        assert len(queries) <= 4  # Includes session authentication and revalidation.
        listed = {note['id']: note for note in response.json()}
        assert len(listed) == count
        for note_id in ('n0', f'n{count - 1}'):
            detail = client.get(f'/notes/{note_id}', headers=headers(user))
            assert detail.status_code == 200 and listed[note_id] == detail.json()
            assert listed[note_id]['labels'] == ['b', 'a']
    assert client.get('/notes', headers=headers(stranger)).json() == []


def test_listing_lock_revoke_deleted_labels_and_current_owner_identity(env):
    client, app, users = env
    owner, recipient, stranger = users
    op = operation()
    assert client.post('/sync', json=op, headers=headers(owner)).status_code == 200
    note_id = op['note_id']
    assert client.post(f'/notes/{note_id}/shares', headers=headers(owner),
                       json={'email': recipient['user']['email'], 'role': 'viewer'}).status_code == 200
    owner_id = owner['user']['id']
    with sqlite3.connect(app.state.database) as conn:
        conn.execute('INSERT INTO labels VALUES (?,?,?,?,1,0)', ('live', owner_id, 'Renamed', 'renamed'))
        conn.execute('INSERT INTO labels VALUES (?,?,?,?,1,1)', ('gone', owner_id, 'Deleted', 'deleted'))
        conn.execute('INSERT INTO labels VALUES (?,?,?,?,1,0)', ('foreign', stranger['user']['id'], 'Secret', 'secret'))
        conn.execute('UPDATE notes SET labels=? WHERE id=?',
                     (json.dumps(['gone', 'live', 'foreign']), note_id))
    conn.close()
    assert client.patch('/me', json={'name': 'Current owner'}, headers=headers(owner)).status_code == 200
    visible = client.get('/notes', headers=headers(recipient)).json()[0]
    assert visible['labels'] == ['live'] and visible['label_names'] == {'live': 'Renamed'}
    assert visible['shared_by']['name'] == 'Current owner' and 'shared_count' not in visible
    assert client.post(f'/notes/{note_id}/protection', headers=headers(owner), json={
        'password': 'note-password-123', 'confirmation': 'note-password-123'}).status_code == 200
    assert client.post(f'/notes/{note_id}/unlock', headers=headers(owner),
                       json={'password': 'note-password-123'}).status_code == 200
    for user, role in ((owner, 'owner'), (recipient, 'viewer')):
        locked = client.get('/notes', headers=headers(user)).json()[0]
        assert locked == {'id': note_id, 'locked': True, 'revision': 2, 'role': role,
                          'pinned_at': None, 'shared': True}
    assert client.delete(f'/notes/{note_id}/shares/{recipient["user"]["id"]}', headers=headers(owner)).status_code == 200
    assert client.get('/notes', headers=headers(recipient)).json() == []
    assert client.get('/notes', headers=headers(stranger)).json() == []
    with sqlite3.connect(app.state.database) as conn:
        conn.execute('UPDATE notes SET deleted=1 WHERE id=?', (note_id,))
    conn.close()
    assert client.get('/notes', headers=headers(owner)).json() == []


def test_locked_public_pin_and_sharing_flags_follow_authorized_changes_without_private_fields(env):
    client, _, users = env
    owner, viewer, stranger = users
    editor = client.post('/auth/register', json={
        'email': 'listing-editor@example.com', 'name': 'Editor',
        'password': 'safe-password-123', 'confirmation': 'safe-password-123'}).json()
    op = operation(pinned_at='2026-10-07T01:00:00Z', labels=['Hidden label'])
    note = op['note_id']
    assert client.post('/sync', headers=headers(owner), json=op).status_code == 200
    for user, role in [(viewer, 'viewer'), (editor, 'editor')]:
        assert client.post(f'/notes/{note}/shares', headers=headers(owner),
                           json={'email': user['user']['email'], 'role': role}).status_code == 200
    assert client.post(f'/notes/{note}/protection', headers=headers(owner), json={
        'password': 'note-password-123', 'confirmation': 'note-password-123'}).status_code == 200

    def listing(user, role, revision, pin, shared=True):
        result = client.get('/notes', headers=headers(user)).json()
        assert result == [{'id': note, 'locked': True, 'revision': revision,
                           'role': role, 'pinned_at': pin, 'shared': shared}]
        for secret in ['Private title', 'Confidential content', 'Hidden label', 'owner@example.com']:
            assert secret not in json.dumps(result)
        return result[0]

    for user, role in [(owner, 'owner'), (viewer, 'viewer'), (editor, 'editor')]:
        listing(user, role, 2, op['pinned_at'])
        assert client.get(f'/notes/{note}', headers=headers(user)).status_code == 423
    assert client.get('/notes', headers=headers(stranger)).json() == []
    assert client.get(f'/notes/{note}', headers=headers(stranger)).status_code == 404
    assert client.post('/sync', headers=headers(viewer), json=operation(note, 2)).status_code == 403
    for user in [owner, editor]:
        assert client.post(f'/notes/{note}/unlock', headers=headers(user),
                           json={'password': 'note-password-123'}).status_code == 200
    listing(owner, 'owner', 2, op['pinned_at'])  # Unlock never expands a list row.
    latest_pin = '2026-10-07T02:00:00Z'
    assert client.post('/sync', headers=headers(owner), json=operation(note, 2, pinned_at=latest_pin)).status_code == 200
    assert client.post('/sync', headers=headers(editor), json=operation(note, 3, pinned_at='2099-01-01')).status_code == 200
    listing(owner, 'owner', 4, latest_pin)  # Editor cannot manage the owner's pin.
    assert client.post('/sync', headers=headers(owner), json=operation(note, 4, pinned_at=None)).status_code == 200
    listing(owner, 'owner', 5, None)
    for user in [viewer, editor]:
        assert client.delete(f'/notes/{note}/shares/{user["user"]["id"]}', headers=headers(owner)).status_code == 200
        assert client.get('/notes', headers=headers(user)).json() == []
    listing(owner, 'owner', 5, None, shared=False)
