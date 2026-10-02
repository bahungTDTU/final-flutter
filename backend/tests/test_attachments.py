from io import BytesIO
import sqlite3
from uuid import uuid4
from concurrent.futures import ThreadPoolExecutor
from threading import Event

from fastapi.testclient import TestClient
from PIL import Image
import pytest

from backend.app import create_app
from backend.tests.test_security import env, headers, operation, make_note


def upload(client, user, note, *, id=None, name='fixture.txt', kind='file', mime='text/plain', data=b'private file'):
    id = id or str(uuid4())
    response = client.post(f'/notes/{note}/attachments/{id}', params={'name': name, 'kind': kind}, headers={**headers(user), 'Content-Type': mime}, content=data)
    return id, response


def test_private_file_roles_ranges_lock_grants_and_revoke(env):
    client, _, users = env
    owner, other, stranger = users
    note = make_note(client, owner)
    id, response = upload(client, owner, note)
    assert response.status_code == 200
    base = f'/notes/{note}/attachments'
    url = base + '/' + id
    assert client.get(url).status_code == 401
    assert client.get(base, headers=headers(stranger)).status_code == 404
    assert client.get(url, headers=headers(stranger)).status_code == 404
    client.post(f'/notes/{note}/shares', headers=headers(owner), json={'email': other['user']['email'], 'role': 'viewer'})
    assert client.get(url, headers=headers(other)).content == b'private file'
    assert upload(client, other, note)[1].status_code == 403
    assert client.delete(url, headers=headers(other)).status_code == 403
    ranged = client.get(url, headers={**headers(other), 'Range': 'bytes=2-5'})
    assert ranged.status_code == 206 and ranged.content == b'ivat' and ranged.headers['content-range'] == 'bytes 2-5/12'
    assert client.get(url, headers={**headers(other), 'Range': 'bytes=-4'}).content == b'file'
    assert client.get(url, headers={**headers(other), 'Range': 'bytes=99-'}).status_code == 416
    assert ranged.headers['cache-control'] == 'private, no-store'
    assert ranged.headers['content-disposition'].startswith('attachment;')
    client.post(f'/notes/{note}/shares', headers=headers(owner), json={'email': other['user']['email'], 'role': 'editor'})
    new, accepted = upload(client, other, note, data=b'editor file')
    assert accepted.status_code == 200
    client.post(f'/notes/{note}/protection', headers=headers(owner), json={'password': 'note-password-123', 'confirmation': 'note-password-123'})
    for user in (owner, other):
        assert client.get(base, headers=headers(user)).status_code == 423
        assert client.get(url, headers=headers(user)).status_code == 423
        assert upload(client, user, note)[1].status_code == 423
        assert client.delete(url, headers=headers(user)).status_code == 423
    assert 'attachments' not in client.get('/notes', headers=headers(owner)).json()[0]
    client.post(f'/notes/{note}/unlock', headers=headers(other), json={'password': 'note-password-123'})
    assert client.get(url, headers=headers(other)).status_code == 200
    second = client.post('/auth/login', json={'email': other['user']['email'], 'password': 'safe-password-123'}).json()
    assert client.get(url, headers=headers(second)).status_code == 423
    client.post(f'/notes/{note}/unlock', headers=headers(owner), json={'password': 'note-password-123'})
    client.delete(f'/notes/{note}/shares/{other["user"]["id"]}', headers=headers(owner))
    assert client.get(url, headers=headers(other)).status_code == 404
    assert upload(client, other, note, id=new, data=b'editor file')[1].status_code == 404


def test_retry_delete_note_cleanup_restart_preserves_note_revision(env):
    client, app, users = env
    owner = users[0]
    note = make_note(client, owner)
    id, result = upload(client, owner, note)
    assert upload(client, owner, note, id=id)[1].json() == result.json()
    assert upload(client, owner, note, id=id, data=b'changed')[1].status_code == 409
    with TestClient(create_app(app.state.database)) as reopened:
        assert reopened.get(f'/notes/{note}/attachments', headers=headers(owner)).json() == [result.json()]
        assert reopened.get(f'/notes/{note}', headers=headers(owner)).json()['revision'] == 1
        url = f'/notes/{note}/attachments/{id}'
        assert reopened.delete(url, headers=headers(owner)).status_code == 200
        assert reopened.delete(url, headers=headers(owner)).status_code == 200
        assert upload(reopened, owner, note, id=id)[1].status_code == 409
        assert reopened.get(url, headers=headers(owner)).status_code == 404
        second, _ = upload(reopened, owner, note)
        assert reopened.post('/sync', headers=headers(owner), json=operation(note, 1, kind='delete')).status_code == 200
        assert reopened.get(f'/notes/{note}/attachments/{second}', headers=headers(owner)).status_code == 404
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT COUNT(*) FROM attachments WHERE note_id=? AND data IS NOT NULL', (note,)).fetchone()[0] == 0


@pytest.mark.parametrize('name,kind,mime,data,status', [
    ('bad.svg', 'image', 'image/svg+xml', b'<svg/>', 415),
    ('broken.png', 'image', 'image/png', b'not a png', 422),
    ('bad.mp4', 'video', 'video/mp4', b'\0\0\0\x14ftypisom', 422),
    ('fake.pdf', 'file', 'application/pdf', b'no PDF', 422),
    ('nul.txt', 'file', 'text/plain', b'a\0b', 422),
    ('../bad.txt', 'file', 'text/plain', b'file', 422),
    ('big.txt', 'file', 'text/plain', b'a' * (20 * 1024 * 1024 + 1), 413),
], ids=['svg', 'damaged-image', 'damaged-mp4', 'fake-pdf', 'nul-text', 'path-name', 'oversize'])
def test_invalid_upload_is_atomic(env, name, kind, mime, data, status):
    client, app, users = env
    note = make_note(client, users[0])
    assert upload(client, users[0], note, name=name, kind=kind, mime=mime, data=data)[1].status_code == status
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT COUNT(*) FROM attachments').fetchone()[0] == 0


def test_image_canonical_and_per_note_count_limit(env):
    client, _, users = env
    note = make_note(client, users[0])
    buffer = BytesIO()
    Image.new('RGB', (2200, 1100), 'teal').save(buffer, 'JPEG', comment=b'private')
    id, accepted = upload(client, users[0], note, name='photo.jpg', kind='image', mime='image/jpeg', data=buffer.getvalue())
    assert accepted.status_code == 200 and accepted.json()['media_type'] == 'image/png'
    response = client.get(f'/notes/{note}/attachments/{id}', headers=headers(users[0]))
    with Image.open(BytesIO(response.content)) as image:
        assert image.format == 'PNG' and image.size == (2048, 1024) and not image.info
    for _ in range(9):
        assert upload(client, users[0], note)[1].status_code == 200
    assert upload(client, users[0], note)[1].status_code == 413
    assert len(client.get(f'/notes/{note}/attachments', headers=headers(users[0])).json()) == 10


def test_lock_during_decode_revalidates_before_commit(env, monkeypatch):
    from backend import attachments
    client, app, users = env
    owner = users[0]
    note = make_note(client, owner)
    entered, release = Event(), Event()
    original = attachments.normalize
    def gated(*args):
        entered.set()
        assert release.wait(10)
        return original(*args)
    monkeypatch.setattr(attachments, 'normalize', gated)
    with ThreadPoolExecutor() as pool:
        pending = pool.submit(upload, client, owner, note)
        assert entered.wait(10)
        client.post(f'/notes/{note}/protection', headers=headers(owner), json={'password': 'note-password-123', 'confirmation': 'note-password-123'})
        release.set()
        assert pending.result()[1].status_code == 423
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT COUNT(*) FROM attachments').fetchone()[0] == 0
