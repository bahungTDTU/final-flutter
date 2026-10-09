"""Seed disposable performance data through the real loopback API (no saved token)."""
import argparse
import json
import time
from pathlib import Path
from urllib.parse import urlparse
from uuid import uuid4

import httpx


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--url', default='http://127.0.0.1:8020')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if urlparse(args.url).hostname not in ('127.0.0.1', 'localhost'):
        parser.error('Only a disposable loopback backend is allowed')
    email = f'frames-{uuid4()}@example.test'
    password = 'Performance-fixture-2026!'
    timings = []
    with httpx.Client(base_url=args.url, timeout=30) as client:
        def call(method, route, body=None):
            started = time.perf_counter()
            response = client.request(method, route, json=body)
            response.raise_for_status()
            timings.append((time.perf_counter() - started) * 1000)
            return response.json()
        account = call('POST', '/auth/register', {
            'email': email, 'name': 'Performance local',
            'password': password, 'confirmation': password,
        })
        client.headers['Authorization'] = 'Bearer ' + account['token']
        labels = [str(uuid4()) for _ in range(30)]
        for index, label in enumerate(labels):
            call('POST', '/labels/sync', {
                'op_id': str(uuid4()), 'label_id': label, 'base_revision': 0,
                'kind': 'upsert', 'name': f'Benchmark {index:02}',
            })
        for index in range(500):
            call('POST', '/sync', {
                'op_id': str(uuid4()), 'note_id': str(uuid4()),
                'base_revision': 0, 'kind': 'upsert',
                'title': f'Benchmark note {index:03}',
                'content': '## Performance fixture\n' +
                           'Nội dung mẫu để đo cuộn ghi chú. ' * 30,
                'labels': [labels[index % 30]], 'labels_format': 'ids',
            })
        listing_start = time.perf_counter()
        notes = call('GET', '/notes')
        listing_ms = (time.perf_counter() - listing_start) * 1000
        assert len(notes) == 500
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({
        'email': email, 'notes': len(notes), 'labels': len(labels),
        'url': args.url, 'get_notes_ms': listing_ms,
        'seed_request_count': len(timings),
    }, indent=2), encoding='utf-8')
    print(f'Seeded 500 notes / 30 labels; GET /notes {listing_ms:.1f} ms')


if __name__ == '__main__':
    main()
