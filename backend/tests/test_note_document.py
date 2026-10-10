import json
import sqlite3

import pytest

from backend.note_document import PREFIX
from backend.tests.test_security import env, headers, operation
from backend.tests.test_ai import configure, share


def rich(text='Sinh học là môn học thú vị.'):
    return PREFIX + json.dumps([
        {'insert': text[:4], 'attributes': {'bold': True, 'color': '#5c43c9'}},
        {'insert': text[4:]}, {'insert': '\n', 'attributes': {'align': 'center'}},
    ], ensure_ascii=False, separators=(',', ':'))


def test_rich_document_roundtrip_idempotency_roles_and_lock_gate(env):
    client, app, (owner, editor, stranger) = env
    viewer = client.post('/auth/register', json={'email': 'viewer-rich@example.test', 'name': 'Viewer',
        'password': 'safe-password-123', 'confirmation': 'safe-password-123'}).json()
    encoded = rich()
    op = operation(content=encoded)
    for _ in range(2):
        assert client.post('/sync', json=op, headers=headers(owner)).status_code == 200
    key = op['note_id']
    share(client, owner, editor, key, 'editor')
    share(client, owner, viewer, key)
    for user in (owner, editor, viewer):
        assert client.get(f'/notes/{key}', headers=headers(user)).json()['content'] == encoded
    assert client.get(f'/notes/{key}', headers=headers(stranger)).status_code == 404
    update = operation(key, revision=1, content=rich('Nội dung đã định dạng lại.'))
    assert client.post('/sync', json=update, headers=headers(viewer)).status_code == 403
    assert client.post('/sync', json=update, headers=headers(editor)).status_code == 200
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT count(*) FROM operations').fetchone()[0] == 2
    password = 'rich-note-password'
    assert client.post(f'/notes/{key}/protection', headers=headers(owner),
        json={'password': password, 'confirmation': password}).status_code == 200
    for user in (owner, editor, viewer):
        assert client.get(f'/notes/{key}', headers=headers(user)).status_code == 423
        listing = client.get('/notes', headers=headers(user)).json()
        serialized = json.dumps(listing)
        assert PREFIX not in serialized and 'Nội dung' not in serialized
    assert client.post(f'/notes/{key}/unlock', headers=headers(owner), json={'password': password}).status_code == 200
    assert client.get(f'/notes/{key}', headers=headers(owner)).json()['content'] == update['content']


def test_ai_reads_visible_text_without_delta_metadata_or_split_word_loss(env):
    client, app, (owner, _, _) = env
    provider = configure(app)
    op = operation(content=rich())
    assert client.post('/sync', json=op, headers=headers(owner)).status_code == 200
    response = client.post(f"/notes/{op['note_id']}/ai/summary", headers=headers(owner))
    assert response.status_code == 200
    context = provider.calls[-1][2][0]['context']
    assert context == 'Sinh học là môn học thú vị.'
    assert 'attributes' not in context and '#5c43c9' not in context
    question = client.post('/ai/questions', headers=headers(owner), json={'question': 'Sinh học thú vị'})
    assert question.status_code == 200 and question.json()['sources'][0]['id'] == op['note_id']
    before = len(provider.calls)
    metadata = client.post('/ai/questions', headers=headers(owner), json={'question': 'attributes center color'})
    assert metadata.status_code == 200 and metadata.json()['sources'] == []
    assert len(provider.calls) == before


@pytest.mark.parametrize('ops', [
    [], [{'insert': 'missing terminal newline'}],
    [{'insert': {'image': 'https://example.test/private.png'}}, {'insert': '\n'}],
    [{'insert': 'unsafe', 'attributes': {'link': 'javascript:alert(1)'}}, {'insert': '\n'}],
    [{'insert': 'unsafe', 'attributes': {'link': 'file:///private'}}, {'insert': '\n'}],
    [{'retain': 1}, {'insert': '\n'}],
    [{'insert': 'bad attrs', 'attributes': {'bold': {'nested': True}}}, {'insert': '\n'}],
    [{'insert': 'bad size', 'attributes': {'size': 'NaN'}}, {'insert': '\n'}],
    [{'insert': 'huge size', 'attributes': {'size': '999999999'}}, {'insert': '\n'}],
    [{'insert': 'bad header\n', 'attributes': {'header': 0}}],
    [{'insert': 'bad height\n', 'attributes': {'line-height': 'Infinity'}}],
    [{'insert': '\n', 'attributes': {'align': 'center'}}],
])
def test_invalid_or_empty_rich_document_cannot_create_note_or_outbox_record(env, ops):
    client, app, (owner, _, _) = env
    encoded = PREFIX + json.dumps(ops)
    response = client.post('/sync', headers=headers(owner), json=operation(content=encoded))
    assert response.status_code == 422
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT count(*) FROM notes').fetchone()[0] == 0
        assert conn.execute('SELECT count(*) FROM operations').fetchone()[0] == 0
