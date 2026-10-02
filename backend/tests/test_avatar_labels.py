from concurrent.futures import ThreadPoolExecutor
from io import BytesIO
import json
import sqlite3
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from PIL import Image, PngImagePlugin

from backend.app import create_app
from backend.catalogue import legacy_id
from backend.tests.test_security import env, headers, operation


def label_op(label_id=None, revision=0, name='Học tập', kind='upsert'):
    return {'op_id': str(uuid4()), 'label_id': label_id or str(uuid4()), 'base_revision': revision, 'kind': kind, 'name': name}


def image_bytes(color='teal', format='PNG', size=(900, 450)):
    image = Image.new('RGB', size, color)
    buffer = BytesIO()
    metadata = PngImagePlugin.PngInfo()
    metadata.add_text('private-camera-field', 'must disappear')
    image.save(buffer, format, **({'pnginfo': metadata} if format == 'PNG' else {}))
    return buffer.getvalue()


def post_label(client, user, op):
    return client.post('/labels/sync', headers=headers(user), json=op)


def test_labels_rename_and_delete_keep_note_revision_content_and_late_queue(env):
    client, _, users = env
    owner = users[0]
    op = label_op()
    assert post_label(client, owner, op).status_code == 200
    notes = [operation(labels=[op['label_id']], labels_format='ids') for _ in range(2)]
    for note in notes:
        assert client.post('/sync', headers=headers(owner), json=note).status_code == 200
    protected = notes[1]['note_id']
    assert client.post(f'/notes/{protected}/protection', headers=headers(owner), json={
        'password': 'note-password-123', 'confirmation': 'note-password-123'}).status_code == 200
    assert post_label(client, owner, label_op(op['label_id'], 1, 'Đã đổi tên')).status_code == 200
    visible = client.get('/notes', headers=headers(owner)).json()
    plain = next(n for n in visible if n['id'] == notes[0]['note_id'])
    assert plain['label_names'] == {op['label_id']: 'Đã đổi tên'} and plain['revision'] == 1
    locked = next(n for n in visible if n['id'] == protected)
    assert 'labels' not in locked and 'label_names' not in locked
    client.post(f'/notes/{protected}/unlock', headers=headers(owner), json={'password': 'note-password-123'})
    read = client.get(f'/notes/{protected}', headers=headers(owner)).json()
    assert read['label_names'][op['label_id']] == 'Đã đổi tên' and read['revision'] == 2
    assert post_label(client, owner, label_op(op['label_id'], 2, kind='delete')).status_code == 200
    for note in notes:
        read = client.get('/notes/' + note['note_id'], headers=headers(owner)).json()
        assert read['labels'] == [] and read['content'] == note['content'] and not read['deleted']
    late = operation(notes[0]['note_id'], 1, labels=[op['label_id']], labels_format='ids', content='Late valid edit')
    assert client.post('/sync', headers=headers(owner), json=late).status_code == 200
    assert client.get('/notes/' + notes[0]['note_id'], headers=headers(owner)).json()['labels'] == []


def test_labels_account_acl_shared_names_and_editor_cannot_change_associations(env):
    client, _, users = env
    owner, recipient, stranger = users
    op = label_op()
    post_label(client, owner, op)
    note = operation(labels=[op['label_id']], labels_format='ids')
    client.post('/sync', headers=headers(owner), json=note)
    note_id = note['note_id']
    share = '/notes/' + note_id + '/shares'
    client.post(share, headers=headers(owner), json={'email': recipient['user']['email'], 'role': 'viewer'})
    assert client.get('/labels', headers=headers(recipient)).json() == []
    assert client.get('/notes/' + note_id, headers=headers(recipient)).json()['label_names'][op['label_id']] == 'Học tập'
    assert post_label(client, recipient, label_op(op['label_id'], 1, 'Stolen')).status_code == 404
    assert post_label(client, stranger, label_op(op['label_id'], 1, kind='delete')).status_code == 404
    assert client.post('/sync', headers=headers(recipient), json=operation(note_id, 1)).status_code == 403
    client.post(share, headers=headers(owner), json={'email': recipient['user']['email'], 'role': 'editor'})
    own_label = label_op(name='Recipient only')
    post_label(client, recipient, own_label)
    edited = operation(note_id, 1, labels=[own_label['label_id']], labels_format='ids', pinned_at='malicious')
    assert client.post('/sync', headers=headers(recipient), json=edited).status_code == 200
    result = client.get('/notes/' + note_id, headers=headers(owner)).json()
    assert result['labels'] == [op['label_id']] and result['pinned_at'] is None
    foreign = operation(labels=[op['label_id']], labels_format='ids')
    assert client.post('/sync', headers=headers(stranger), json=foreign).status_code == 422
    assert client.get('/labels').status_code == 401
    assert client.post('/labels/sync', json=label_op()).status_code == 401


def test_label_cas_race_idempotency_validation_and_restart(env):
    client, app, users = env
    owner = users[0]
    create = label_op()
    post_label(client, owner, create)
    changes = [label_op(create['label_id'], 1, name) for name in ('First writer', 'Second writer')]
    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(pool.map(lambda op: post_label(client, owner, op), changes))
    assert sorted(r.status_code for r in responses) == [200, 409]
    winner = next(r.json() for r in responses if r.status_code == 200)
    assert winner['revision'] == 2
    assert post_label(client, owner, create).json() == winner
    assert post_label(client, owner, dict(create, name='Changed replay')).status_code == 409
    for name in (' ', 'x' * 61, 'bad\nname'):
        assert post_label(client, owner, label_op(name=name)).status_code == 422
    assert post_label(client, owner, label_op(name='École')).status_code == 200
    assert post_label(client, owner, label_op(name='E\u0301COLE')).status_code == 409
    with TestClient(create_app(app.state.database)) as reopened:
        assert post_label(reopened, owner, create).json() == winner
        assert len(reopened.get('/labels', headers=headers(owner)).json()) == 2


def test_v1_migration_preserves_notes_and_prior_operation_fingerprint(env):
    client, app, users = env
    owner = users[0]
    op = operation(labels=['Học tập'])  # v1 immutable payload without labels_format.
    client.post('/sync', headers=headers(owner), json=op)
    long_name = 'Tên cũ ' + 'x' * 100
    with sqlite3.connect(app.state.database) as conn:
        conn.execute('UPDATE notes SET labels=? WHERE id=?', (json.dumps(['Học tập', long_name]), op['note_id']))
        conn.execute('PRAGMA user_version=1')
    with TestClient(create_app(app.state.database)) as reopened:
        read = reopened.get('/notes/' + op['note_id'], headers=headers(owner)).json()
        assert read['revision'] == 1 and read['content'] == op['content']
        assert read['labels'] == [legacy_id(owner['user']['id'], 'Học tập'), legacy_id(owner['user']['id'], long_name)]
        assert long_name in read['label_names'].values()
        assert reopened.post('/sync', headers=headers(owner), json=op).status_code == 200
        assert len(reopened.get('/labels', headers=headers(owner)).json()) == 2
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('PRAGMA user_version').fetchone()[0] == 2


@pytest.mark.parametrize('format,mime', [('PNG', 'image/png'), ('JPEG', 'image/jpeg')])
def test_avatar_normalization_private_access_cas_delete_and_restart(env, format, mime):
    client, app, users = env
    owner, recipient, _ = users
    data = image_bytes(format=format)
    result = client.post('/me/avatar?base_revision=0', headers={**headers(owner), 'Content-Type': mime}, content=data)
    assert result.status_code == 200 and result.json()['avatar_revision'] == 1
    read = client.get('/me/avatar?revision=1', headers=headers(owner))
    assert read.status_code == 200 and read.headers['cache-control'] == 'private, no-store'
    with Image.open(BytesIO(read.content)) as image:
        assert image.size == (512, 256) and image.format == 'PNG' and not image.info
    assert client.get('/me/avatar', headers=headers(recipient)).status_code == 404
    assert client.get('/me/avatar').status_code == 401
    assert client.get('/users/' + owner['user']['id'] + '/avatar', headers=headers(recipient)).status_code == 404
    assert client.post('/me/avatar?base_revision=0', headers={**headers(owner), 'Content-Type': mime}, content=data).status_code == 409
    with TestClient(create_app(app.state.database)) as reopened:
        assert reopened.get('/me/avatar', headers=headers(owner)).content == read.content
    assert client.delete('/me/avatar?base_revision=0', headers=headers(owner)).status_code == 409
    assert client.delete('/me/avatar?base_revision=1', headers=headers(owner)).json()['has_avatar'] is False
    assert client.get('/me/avatar', headers=headers(owner)).status_code == 404
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT revision,data FROM avatars WHERE user_id=?', (owner['user']['id'],)).fetchone() == (2, None)


def test_avatar_rejects_bad_files_and_unauthenticated_upload_without_replacing(env):
    client, _, users = env
    owner = users[0]
    for data, mime, status in [(b'<svg/>', 'image/svg+xml', 415), (b'<svg/>', 'image/png', 422),
                               (b'bad-image', 'image/jpeg', 422), (image_bytes(), 'image/jpeg', 422),
                               (b'x' * (2 * 1024 * 1024 + 1), 'image/png', 413),
                               (image_bytes(size=(8193, 1)), 'image/png', 422)]:
        assert client.post('/me/avatar?base_revision=0', headers={**headers(owner), 'Content-Type': mime}, content=data).status_code == status
    assert client.post('/me/avatar?base_revision=0', headers={'Content-Type': 'image/png'}, content=image_bytes()).status_code == 401
    assert client.get('/me', headers=headers(owner)).json()['avatar_revision'] == 0
