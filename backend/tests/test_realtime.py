"""Real TCP/SSE integration, including disconnect and authorization boundaries."""
import asyncio
from contextlib import asynccontextmanager
import json
import socket
import sqlite3
import threading
import time

import httpx
import pytest
import uvicorn

from backend.app import create_app
from backend.tests.mail_support import RecordingDelivery
from backend.tests.test_security import headers, operation


@pytest.fixture
def live(tmp_path):
    app = create_app(tmp_path / 'live.sqlite3', email_delivery=RecordingDelivery())
    sock = socket.socket()
    sock.bind(('127.0.0.1', 0))
    address = f'http://127.0.0.1:{sock.getsockname()[1]}'
    server = uvicorn.Server(uvicorn.Config(app, log_level='error', access_log=False,
                                         timeout_graceful_shutdown=1))
    thread = threading.Thread(target=server.run, kwargs={'sockets': [sock]}, daemon=True)
    thread.start()
    deadline = time.monotonic() + 5
    while not server.started and thread.is_alive() and time.monotonic() < deadline:
        time.sleep(.01)
    assert server.started
    yield app, address
    server.should_exit = True
    thread.join(5)
    sock.close()
    assert not thread.is_alive()


async def users(client):
    result = []
    for name in ['owner', 'editor', 'viewer', 'stranger']:
        response = await client.post('/auth/register', json={
            'email': name + '@example.test', 'name': name,
            'password': 'safe-password-123', 'confirmation': 'safe-password-123'})
        assert response.status_code == 201
        result.append(response.json())
    return result


@asynccontextmanager
async def feed(client, user):
    async with client.stream('GET', '/events', headers=headers(user)) as response:
        assert response.status_code == 200
        assert response.headers['cache-control'] == 'private, no-store'
        assert response.headers['content-type'].startswith('text/event-stream')
        lines = response.aiter_lines()

        async def next_frame():
            event, data = '', ''
            async for line in lines:
                if line.startswith('event: '):
                    event = line[7:]
                elif line.startswith('data: '):
                    data += line[6:]
                elif not line and data:
                    return event, json.loads(data)
            return None

        yield lambda: asyncio.wait_for(next_frame(), 3)


async def shared(client, owner, *recipients):
    op = operation()
    assert (await client.post('/sync', headers=headers(owner), json=op)).status_code == 200
    for user, role in recipients:
        assert (await client.post(f'/notes/{op["note_id"]}/shares', headers=headers(owner),
                                  json={'email': user['user']['email'], 'role': role})).status_code == 200
    return op['note_id']


def test_live_authorized_updates_no_sensitive_payload_or_stranger_events(live):
    async def run():
        async with httpx.AsyncClient(base_url=live[1], timeout=5) as client:
            owner, editor, viewer, stranger = await users(client)
            note = await shared(client, owner, (editor, 'editor'), (viewer, 'viewer'))
            async with feed(client, owner) as a, feed(client, editor) as b, feed(client, viewer) as v, feed(client, stranger) as s:
                versions = [(await f())[1]['version'] for f in (a, b, v)]
                assert await s() == ('ready', {'version': 0})
                assert (await client.post('/sync', headers=headers(viewer), json=operation(note, 1))).status_code == 403
                edit = operation(note, 1, title='Private edited title', content='Secret edited text')
                assert (await client.post('/sync', headers=headers(editor), json=edit)).status_code == 200
                for f, version in zip((a, b, v), versions):
                    event, data = await f()
                    assert event == 'changed' and set(data) == {'version'} and data['version'] > version
                assert (await client.get(f'/notes/{note}', headers=headers(owner))).json()['content'] == 'Secret edited text'
                assert (await client.get(f'/notes/{note}', headers=headers(stranger))).status_code == 404
                # Read timeout closes this stream; other accounts' traffic never arrives.
                with pytest.raises(asyncio.TimeoutError):
                    await asyncio.wait_for(s(), .6)
    asyncio.run(run())


def test_revoke_notifies_removed_account_then_stops_future_updates(live):
    async def run():
        async with httpx.AsyncClient(base_url=live[1], timeout=5) as client:
            owner, editor, *_ = await users(client)
            note = await shared(client, owner, (editor, 'editor'))
            async with feed(client, editor) as stream:
                await stream()
                assert (await client.delete(f'/notes/{note}/shares/{editor["user"]["id"]}', headers=headers(owner))).status_code == 200
                assert (await stream())[0] == 'changed'
                assert (await client.get('/notes', headers=headers(editor))).json() == []
                assert (await client.post('/sync', headers=headers(editor), json=operation(note, 1))).status_code == 404
                assert (await client.post('/sync', headers=headers(owner), json=operation(note, 1))).status_code == 200
                with pytest.raises(asyncio.TimeoutError):
                    await asyncio.wait_for(stream(), .6)
            async with feed(client, editor) as reconnected:
                assert (await reconnected())[0] == 'ready'
                assert (await client.get('/notes', headers=headers(editor))).json() == []
    asyncio.run(run())


def test_lock_and_session_revocation_redact_and_terminate_existing_stream(live):
    async def run():
        async with httpx.AsyncClient(base_url=live[1], timeout=5) as client:
            owner, editor, *_ = await users(client)
            note = await shared(client, owner, (editor, 'editor'))
            async with feed(client, editor) as stream:
                await stream()
                assert (await client.post(f'/notes/{note}/protection', headers=headers(owner), json={
                    'password': 'note-password-123', 'confirmation': 'note-password-123'})).status_code == 200
                event, data = await stream()
                assert event == 'changed' and set(data) == {'version'}
                assert (await client.get('/notes', headers=headers(editor))).json() == [
                    {'id': note, 'locked': True, 'role': 'editor', 'revision': 2}]
                assert (await client.get(f'/notes/{note}', headers=headers(editor))).status_code == 423
                assert (await client.post('/auth/logout', headers=headers(editor))).status_code == 200
                assert await stream() == ('expired', {})
                assert await stream() is None
            assert (await client.get('/events', headers=headers(editor))).status_code == 401
    asyncio.run(run())


def test_auth_origin_connection_limit_and_disconnect_cleanup(live):
    async def run():
        async with httpx.AsyncClient(base_url=live[1], timeout=5) as client:
            owner, *_ = await users(client)
            assert (await client.get('/events')).status_code == 401
            assert (await client.get('/events?token=' + owner['token'])).status_code == 401
            assert (await client.get('/events', headers={**headers(owner), 'Origin': 'https://evil.example'})).status_code == 403
            async with feed(client, owner) as a, feed(client, owner) as b, feed(client, owner) as c:
                for f in (a, b, c):
                    assert (await f())[0] == 'ready'
                assert (await client.get('/events', headers=headers(owner))).status_code == 429
            for _ in range(100):
                if not live[0].state.realtime_connections:
                    break
                await asyncio.sleep(.02)
            assert not live[0].state.realtime_connections
            async with feed(client, owner) as reopened:
                assert (await reopened())[0] == 'ready'
    asyncio.run(run())


def test_counter_transaction_rollback_idempotency_and_persistent_catchup(live):
    async def run():
        app, address = live
        async with httpx.AsyncClient(base_url=address, timeout=5) as client:
            owner, editor, *_ = await users(client)
            note = await shared(client, owner, (editor, 'editor'))
            async with feed(client, editor) as stream:
                initial = (await stream())[1]['version']
            with sqlite3.connect(app.state.database) as conn:
                conn.execute('UPDATE notes SET content=? WHERE id=?', ('Rolled back secret', note))
                conn.rollback()
                assert conn.execute('SELECT version FROM realtime_versions WHERE user_id=?', (editor['user']['id'],)).fetchone()[0] == initial
            op = operation(note, 1, content='Offline interval edit')
            assert (await client.post('/sync', headers=headers(owner), json=op)).status_code == 200
            assert (await client.post('/sync', headers=headers(owner), json=op)).status_code == 200
            assert (await client.post('/sync', headers=headers(owner), json=operation(note, 1))).status_code == 409
            # Reinitializing the database installs triggers idempotently and preserves counters.
            create_app(app.state.database, email_delivery=RecordingDelivery())
            async with feed(client, editor) as reopened:
                assert await reopened() == ('ready', {'version': initial + 1})
            assert (await client.get(f'/notes/{note}', headers=headers(editor))).json()['content'] == 'Offline interval edit'
    asyncio.run(run())
