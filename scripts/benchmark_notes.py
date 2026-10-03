"""Local SQLite/ASGI list benchmark; fixture inserts are not user contributions."""
import argparse
import json
import sqlite3
import statistics
import sys
import tempfile
import time
from contextlib import closing
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from fastapi.testclient import TestClient
from backend.app import create_app, digest


def measure(count, repeats):
    with tempfile.TemporaryDirectory(prefix='note-benchmark-') as directory:
        app = create_app(Path(directory) / 'notes.sqlite3')
        stamp = datetime.now(timezone.utc).isoformat()
        with closing(sqlite3.connect(app.state.database)) as conn:
            for name in ('owner', 'viewer'):
                conn.execute('INSERT INTO users(id,email,name,password) VALUES (?,?,?,?)',
                             (name, name + '@example.test', name, 'fixture-no-login'))
                conn.execute('INSERT INTO sessions VALUES (?,?,?)',
                             (digest('benchmark-' + name), name, time.time() + 600))
            for i in range(3):
                conn.execute('INSERT INTO labels VALUES (?,?,?,?,1,0)',
                             (f'label-{i}', 'owner', f'Label {i}', f'label {i}'))
            for i in range(count):
                conn.execute('INSERT INTO notes(id,owner_id,title,content,revision,updated_at,labels,password) VALUES (?,?,?,?,1,?,?,?)',
                             (f'note-{i}', 'owner', 'Benchmark note', 'Content ' * 100,
                              stamp, json.dumps(['label-0', 'label-1', 'label-2']),
                              'fixture-locked' if i % 20 == 0 else None))
                conn.execute('INSERT INTO shares VALUES (?,?,?,?)',
                             (f'note-{i}', 'viewer', 'viewer', stamp))
            conn.commit()
        original = sqlite3.connect
        selects = []

        def traced(*args, **kwargs):
            conn = original(*args, **kwargs)
            conn.set_trace_callback(lambda sql: selects.append(sql)
                                    if sql.lstrip().upper().startswith('SELECT') else None)
            return conn

        results = []
        with TestClient(app) as client:
            sqlite3.connect = traced
            try:
                for role in ('owner', 'viewer'):
                    timings, query_counts = [], []
                    for attempt in range(repeats + 1):
                        selects.clear()
                        start = time.perf_counter()
                        response = client.get('/notes', headers={'Authorization': 'Bearer benchmark-' + role})
                        elapsed = (time.perf_counter() - start) * 1000
                        assert response.status_code == 200
                        notes = response.json()
                        assert len(notes) == count
                        for note in notes:
                            if note['locked']:
                                assert set(note) == {'id', 'locked', 'revision', 'role'}
                            else:
                                assert len(note['labels']) == 3
                                assert note['role'] == role
                        if attempt:  # Exclude one warm-up.
                            timings.append(elapsed)
                            query_counts.append(len(selects))
                    results.append({'notes': count, 'role': role, 'repeats': repeats,
                                    'median_ms': round(statistics.median(timings), 3),
                                    'min_ms': round(min(timings), 3), 'max_ms': round(max(timings), 3),
                                    'selects_min': min(query_counts), 'selects_max': max(query_counts)})
            finally:
                sqlite3.connect = original
        return results


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--repeats', type=int, default=7)
    parser.add_argument('--counts', type=int, nargs='+', default=[10, 1000])
    args = parser.parse_args()
    assert args.repeats > 0 and all(n > 0 for n in args.counts)
    result = {'measured_at_utc': datetime.now(timezone.utc).isoformat(),
              'target': 'local TestClient ASGI + real temporary SQLite; not network/device/FPS',
              'fixture': '3 labels/note; 5% locked; owner and shared viewer',
              'results': [row for n in args.counts for row in measure(n, args.repeats)]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result))
