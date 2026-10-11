"""Compare the actual auth dependency with the former transaction shape, not FPS."""
import hashlib
import json
import os
import sqlite3
import statistics
import tempfile
import time
from contextlib import closing
from pathlib import Path

from fastapi.security import HTTPAuthorizationCredentials
from fastapi.testclient import TestClient

from backend.app import create_app
from backend.email_delivery import DisabledDelivery


def main():
    os.environ['GEMINI_API_KEY'] = ''
    os.environ['GEMINI_API_KEY_FILE'] = ''
    with tempfile.TemporaryDirectory(prefix='nt-auth-benchmark-') as directory:
        path = str(Path(directory) / 'auth.sqlite3')
        app = create_app(path, email_delivery=DisabledDelivery(), start_email_worker=False)
        with TestClient(app) as client:
            login = client.post('/auth/register', json={
                'email': 'auth-benchmark@example.test', 'name': 'Local benchmark',
                'password': 'benchmark-only-password', 'confirmation': 'benchmark-only-password',
            }).json()
            token = login['token']
            user = login['user']['id']
            identity = HTTPAuthorizationCredentials(scheme='Bearer', credentials=token)
            digest = hashlib.sha256(token.encode()).hexdigest()
            with closing(sqlite3.connect(path)) as conn, conn:
                conn.executemany('INSERT INTO sessions VALUES (?,?,?)', [
                    (hashlib.sha256(f'fixture-{i}'.encode()).hexdigest(), user, time.time() + 3600)
                    for i in range(5000)
                ])
            route = next(r for r in app.routes if getattr(r, 'path', None) == '/me/sessions')
            authenticate = route.dependant.dependencies[0].call
            def legacy():
                with closing(sqlite3.connect(path, timeout=.05)) as conn, conn:
                    conn.execute('BEGIN IMMEDIATE')
                    row = conn.execute('SELECT user_id FROM sessions WHERE digest=? AND expires>?',
                                       (digest, time.time())).fetchone()
                    assert row[0] == user
            def current():
                assert authenticate(identity) == (user, digest)
            def sample(fn):
                for _ in range(20):
                    fn()
                values = []
                for _ in range(300):
                    start = time.perf_counter()
                    fn()
                    values.append((time.perf_counter() - start) * 1000)
                return {'p50_ms': round(statistics.median(values), 4),
                        'p95_ms': round(sorted(values)[284], 4), 'samples': len(values)}
            result = {'target': 'Windows local SQLite; isolated auth dependency; 5001 active sessions',
                      'legacy_begin_immediate': sample(legacy), 'current_query_only_begin': sample(current)}
            writer = sqlite3.connect(path)
            writer.execute('BEGIN IMMEDIATE')
            try:
                start = time.perf_counter()
                current()
                result['reserved_writer_current_read_ms'] = round((time.perf_counter() - start) * 1000, 4)
                try:
                    legacy()
                    raise AssertionError('Former transaction unexpectedly acquired reserved write lock')
                except sqlite3.OperationalError as error:
                    assert 'locked' in str(error)
                    result['reserved_writer_legacy'] = 'blocked; 50 ms timeout, as expected'
            finally:
                writer.rollback()
                writer.close()
            # Trace the actual dependency rather than infer its transaction from timing.
            original = sqlite3.connect
            statements = []
            def traced(*args, **kwargs):
                conn = original(*args, **kwargs)
                conn.set_trace_callback(statements.append)
                return conn
            sqlite3.connect = traced
            try:
                current()
            finally:
                sqlite3.connect = original
            result['current_reserved_write_transactions_per_auth'] = sum(
                s.strip().upper() == 'BEGIN IMMEDIATE' for s in statements)
            result['current_query_only'] = 'PRAGMA QUERY_ONLY=ON' in [s.upper() for s in statements]
            assert result['current_reserved_write_transactions_per_auth'] == 0
            assert result['current_query_only']
            print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
