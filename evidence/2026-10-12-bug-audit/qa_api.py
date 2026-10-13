"""Isolated loopback fixtures and role/range probes. Tokens stay in RAM."""
import argparse
import json
from uuid import uuid4

import httpx

parser = argparse.ArgumentParser()
parser.add_argument('mode', choices=['setup', 'shorten', 'clear', 'verify'])
args = parser.parse_args()
with httpx.Client(base_url='http://127.0.0.1:8058', timeout=15) as client:
    actors = {}
    for role in ('owner', 'viewer', 'editor', 'stranger'):
        result = client.post('/auth/login', json={
            'email': f'ui-refresh-{role}@example.test', 'password': 'safe-password-123'})
        assert result.status_code == 200
        actors[role] = {'Authorization': 'Bearer ' + result.json()['token']}
    notes = client.get('/notes', headers=actors['owner']).json()
    if args.mode == 'setup' and not any(row.get('title') == 'Thiết kế NoteTogether' for row in notes):
        # Reopen only the pinned/shared synthetic fixture hidden by the browser
        # lock probe; this script is restricted to the loopback QA server.
        hidden = next(row for row in notes if row['locked'] and row.get('shared') and row.get('pinned_at'))
        reopened = client.post(f'/notes/{hidden["id"]}/protection', headers=actors['owner'],
                               json={'current_password': 'note-password-123', 'password': None})
        assert reopened.status_code == 200
        notes = client.get('/notes', headers=actors['owner']).json()
    note = next(row for row in notes if row.get('title') == 'Thiết kế NoteTogether')
    path = f'/notes/{note["id"]}'
    if args.mode == 'setup':
        attachment_id = str(uuid4())
        url = f'{path}/attachments/{attachment_id}'
        accepted = client.post(url, headers={**actors['owner'], 'Content-Type': 'text/plain'},
                               params={'name': 'range-fixture.txt', 'kind': 'file'}, content=b'private file')
        assert accepted.status_code == 200
        huge = '9' * 5000
        for role in ('owner', 'viewer', 'editor'):
            for value, status, body in [('bytes=2-' + huge, 206, b'ivate file'),
                                       ('bytes=-' + huge, 206, b'private file'),
                                       ('bytes=' + huge + '-', 416, None),
                                       ('bytes=' + '0' * 5000 + '2-5', 206, b'ivat')]:
                response = client.get(url, headers={**actors[role], 'Range': value})
                assert response.status_code == status
                assert response.headers['cache-control'] == 'private, no-store'
                if body is not None:
                    assert response.content == body
        assert client.get(url, headers={**actors['stranger'], 'Range': 'bytes=2-' + huge}).status_code == 404
        assert client.post(f'{path}/attachments/{uuid4()}', headers={**actors['viewer'], 'Content-Type': 'text/plain'},
                           params={'name': 'denied.txt', 'kind': 'file'}, content=b'denied').status_code == 403
        locked = next(row for row in notes if row['locked'])
        assert client.get(f'/notes/{locked["id"]}/attachments/{attachment_id}',
                          headers={**actors['owner'], 'Range': 'bytes=2-' + huge}).status_code == 423
        assert client.delete(url, headers=actors['owner']).status_code == 200
        content = 'NTDOC1:' + json.dumps([
            {'insert': 'Mục tiêu'}, {'insert': '\n', 'attributes': {'header': 2}},
            {'insert': 'Alpha middle Alpha end Alpha\n'},
        ], ensure_ascii=False, separators=(',', ':'))
    elif args.mode == 'shorten':
        content = 'Alpha'
    elif args.mode == 'clear':
        content = 'Không còn kết quả'
    else:
        assert note['content'] == 'Không còn kết quả'
        print(json.dumps({'result': 'PASS', 'fixtureNoteContentUnchangedByFind': True,
                          'revision': note['revision'], 'tokensRecorded': False}))
        raise SystemExit(0)
    response = client.post('/sync', headers=actors['editor'], json={
        'op_id': str(uuid4()), 'note_id': note['id'], 'base_revision': note['revision'],
        'kind': 'upsert', 'title': note['title'], 'content': content,
    })
    assert response.status_code == 200
    print(json.dumps({'mode': args.mode, 'result': 'PASS', 'revision': response.json()['revision'],
                      'roleRangeChecks': args.mode == 'setup', 'tokensRecorded': False}))
