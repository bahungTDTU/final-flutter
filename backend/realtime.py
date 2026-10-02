"""Authenticated SSE invalidations. No note IDs, content, roles or recipient data.

SQLite triggers advance one durable counter per affected account in the mutation
transaction. Readers re-fetch through existing ACL/grant APIs; reconnect always
requests a full authorized refresh. No in-memory broadcast of sensitive snapshots.
"""
import asyncio
import json
import sqlite3
import time
from collections import Counter
from contextlib import closing

import anyio
from fastapi import Depends, HTTPException, Request
from fastapi.responses import StreamingResponse


def install_tracking(conn):
    conn.execute('CREATE TABLE IF NOT EXISTS realtime_versions ('
                 'user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE, version INTEGER NOT NULL)')

    def trigger(name, event, table, recipients, when=''):
        bump = ('INSERT INTO realtime_versions(user_id,version) '
                f'SELECT user_id,1 FROM ({recipients}) WHERE 1 '
                'ON CONFLICT(user_id) DO UPDATE SET version=version+1;')
        conn.execute(f'CREATE TRIGGER IF NOT EXISTS rt_{name} AFTER {event} ON {table} '
                     f'{when} BEGIN {bump} END')

    def readers(note):
        return (f'SELECT owner_id AS user_id FROM notes WHERE id={note} '
                f'UNION SELECT user_id FROM shares WHERE note_id={note}')

    trigger('note_insert', 'INSERT', 'notes', 'SELECT NEW.owner_id AS user_id')
    trigger('note_update', 'UPDATE', 'notes', readers('NEW.id'))
    for event, row in [('INSERT', 'NEW'), ('UPDATE', 'NEW'), ('DELETE', 'OLD')]:
        trigger('share_' + event.lower(), event, 'shares',
                f'{readers(row + ".note_id")} UNION SELECT {row}.user_id AS user_id')
        trigger('attachment_' + event.lower(), event, 'attachments', readers(row + '.note_id'))
        trigger('avatar_' + event.lower(), event, 'avatars', f'SELECT {row}.user_id AS user_id')
        trigger('label_' + event.lower(), event, 'labels',
                f'SELECT {row}.owner_id AS user_id UNION SELECT s.user_id FROM shares s '
                f'JOIN notes n ON n.id=s.note_id WHERE n.owner_id={row}.owner_id AND n.deleted=0')
    trigger('profile', 'UPDATE OF name', 'users',
            'SELECT NEW.id AS user_id UNION SELECT s.user_id FROM shares s '
            'JOIN notes n ON n.id=s.note_id WHERE n.owner_id=NEW.id AND n.deleted=0',
            'WHEN OLD.name != NEW.name')
    trigger('preferences', 'UPDATE OF preferences,verified', 'users', 'SELECT NEW.id AS user_id',
            'WHEN OLD.preferences != NEW.preferences OR OLD.verified != NEW.verified')


def account_version(database, identity):
    # A short read transaction gives one consistent session/counter snapshot;
    # never hold a write lock or a DB connection while awaiting the network.
    with closing(sqlite3.connect(database, timeout=10)) as conn:
        conn.execute('BEGIN')
        session = conn.execute('SELECT 1 FROM sessions WHERE digest=? AND user_id=? AND expires>?',
                               (identity[1], identity[0], time.time())).fetchone()
        if not session:
            return None
        row = conn.execute('SELECT version FROM realtime_versions WHERE user_id=?', (identity[0],)).fetchone()
        return row[0] if row else 0


def frame(event, data):
    return f'event: {event}\ndata: {json.dumps(data, separators=(",", ":"))}\n\n'


def install_realtime_routes(app, authenticate, origins):
    sessions, accounts = Counter(), Counter()
    app.state.realtime_connections = sessions

    async def reserve(identity=Depends(authenticate)):
        if sessions[identity[1]] >= 3 or accounts[identity[0]] >= 8:
            raise HTTPException(429, 'Too many event connections')
        sessions[identity[1]] += 1
        accounts[identity[0]] += 1
        try:
            yield identity
        finally:
            sessions[identity[1]] -= 1
            accounts[identity[0]] -= 1
            if not sessions[identity[1]]:
                del sessions[identity[1]]
            if not accounts[identity[0]]:
                del accounts[identity[0]]

    @app.get('/events', response_class=StreamingResponse)
    async def events(request: Request, identity=Depends(reserve)):
        # Explicit Origin gate supplements CORS. Native clients have no Origin.
        origin = request.headers.get('origin')
        if origin is not None and origin not in origins:
            raise HTTPException(403, 'Origin not allowed')

        async def stream():
            version, heartbeat = None, time.monotonic()
            while not await request.is_disconnected():
                current = await anyio.to_thread.run_sync(account_version, app.state.database, identity)
                if current is None:
                    yield frame('expired', {})
                    return
                if version is None or current != version:
                    yield frame('ready' if version is None else 'changed', {'version': current})
                    version = current
                    heartbeat = time.monotonic()
                elif time.monotonic() - heartbeat >= 10:
                    yield ': heartbeat\n\n'
                    heartbeat = time.monotonic()
                await asyncio.sleep(0.25)

        return StreamingResponse(stream(), media_type='text/event-stream', headers={
            'Cache-Control': 'private, no-store', 'X-Accel-Buffering': 'no',
            'X-Content-Type-Options': 'nosniff',
        })
