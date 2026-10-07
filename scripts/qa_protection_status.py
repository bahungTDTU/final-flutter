"""Actual loopback-only HTTP QA with disposable accounts; no secret values in evidence."""
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4
from urllib.parse import urlparse

import httpx

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--url', default='http://127.0.0.1:8016')
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
assert urlparse(args.url).hostname in ('127.0.0.1', 'localhost')
PASSWORD = 'Priority-local-2026!'
NOTE_PASSWORD = 'Priority-note-2026!'
with httpx.Client(base_url=args.url, timeout=15) as client:
    def call(method, path, user=None, body=None, status=200):
        response = client.request(method, path, json=body,
            headers={'Authorization': 'Bearer ' + user['token']} if user else {})
        assert response.status_code == status, (method, path, response.status_code, status)
        return response

    users = {role: call('POST', '/auth/register', body={
        'email': f'priority-{role}-{uuid4()}@example.test', 'name': f'QA {role}',
        'password': PASSWORD, 'confirmation': PASSWORD}, status=201).json()
        for role in ['owner', 'viewer', 'editor', 'stranger']}
    owner = users['owner']
    note, ordinary, limited = [str(uuid4()) for _ in range(3)]
    def op(key, base, **patch):
        return {'op_id': str(uuid4()), 'note_id': key, 'base_revision': base, 'kind': 'upsert',
                'title': 'Private status title', 'content': 'Private status content',
                'labels': [], 'labels_format': 'ids', **patch}
    def protect(key):
        call('POST', f'/notes/{key}/protection', owner,
             {'password': NOTE_PASSWORD, 'confirmation': NOTE_PASSWORD})
    pin = '2026-10-07T02:00:00Z'
    call('POST', '/sync', owner, op(note, 0, pinned_at=pin))
    call('POST', '/sync', owner, op(ordinary, 0, title='Ordinary earlier pin', pinned_at='2026-10-07T01:00:00Z'))
    call('POST', '/sync', owner, op(limited, 0))
    for role in ['viewer', 'editor']:
        call('POST', f'/notes/{note}/shares', owner,
             {'email': users[role]['user']['email'], 'role': role})
    protect(note)
    protect(limited)
    fields = {'id', 'locked', 'revision', 'role', 'pinned_at', 'shared'}
    for role in ['owner', 'viewer', 'editor']:
        row = next(n for n in call('GET', '/notes', users[role]).json() if n['id'] == note)
        assert set(row) == fields and row['pinned_at'] == pin and row['shared'] is True
        assert row['role'] == role
        call('GET', f'/notes/{note}', users[role], status=423)
    assert call('GET', '/notes', users['stranger']).json() == []
    call('GET', f'/notes/{note}', users['stranger'], status=404)
    call('POST', '/sync', users['viewer'], op(note, 2), status=403)
    call('POST', f'/notes/{note}/unlock', owner, {'password': NOTE_PASSWORD})
    call('POST', f'/notes/{note}/unlock', users['editor'], {'password': NOTE_PASSWORD})
    call('POST', '/sync', users['editor'], op(note, 2, pinned_at='2099'))
    detail = call('GET', f'/notes/{note}', owner).json()
    assert detail['pinned_at'] == pin  # Editor cannot manage owner pin.
    call('POST', '/sync', owner, op(note, 3, pinned_at=None))
    assert next(n for n in call('GET', '/notes', owner).json() if n['id'] == note)['pinned_at'] is None
    for role in ['viewer', 'editor']:
        call('DELETE', f'/notes/{note}/shares/{users[role]["user"]["id"]}', owner)
        assert call('GET', '/notes', users[role]).json() == []
    assert next(n for n in call('GET', '/notes', owner).json() if n['id'] == note)['shared'] is False
    # Restore a pre-unlock fixture for actual Web screenshots.
    call('POST', '/sync', owner, op(note, 4, pinned_at=pin))
    for role in ['viewer', 'editor']:
        call('POST', f'/notes/{note}/shares', owner,
             {'email': users[role]['user']['email'], 'role': role})
    call('POST', f'/notes/{note}/lock', owner)
    for action in ['unlock', 'change', 'disable', 'unlock', 'disable']:
        body = {'password': 'wrong'} if action == 'unlock' else {'current_password': 'wrong'}
        if action == 'change':
            body.update(password='next-priority-password', confirmation='next-priority-password')
        call('POST', f'/notes/{limited}/' + ('unlock' if action == 'unlock' else 'protection'),
             owner, body, status=403)
    for action in ['unlock', 'change', 'disable']:
        body = {'password': NOTE_PASSWORD} if action == 'unlock' else {'current_password': NOTE_PASSWORD}
        if action == 'change':
            body.update(password='next-priority-password', confirmation='next-priority-password')
        response = call('POST', f'/notes/{limited}/' + ('unlock' if action == 'unlock' else 'protection'),
                        owner, body, status=429)
        assert int(response.headers['retry-after']) > 0
    assert call('GET', f'/notes/{limited}', owner, status=423).json()['detail'] == 'Unlock required'
    result = {'date_utc': datetime.now(timezone.utc).isoformat(), 'target': args.url, 'result': 'PASS',
              'owner': 'mixed-password attempts persisted; all three actions429; unpin/re-pin/share/revoke',
              'editor': 'content edit200; owner pin preserved', 'viewer': 'write403', 'stranger': 'read404/list empty',
              'locked_fields': sorted(fields), 'fixture_note': note, 'ordinary_pin': ordinary,
              'privacy': 'no title/content/labels/identities/counts in locked list; direct content423',
              'mail_or_llm_calls': False, 'release': False}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    Path('tmp/priorities/browser-login.json').write_text(json.dumps({
        'email': owner['user']['email'], 'password': PASSWORD, 'note_password': NOTE_PASSWORD,
        'note': note, 'ordinary': ordinary}), encoding='utf-8')
    print(json.dumps(result))
