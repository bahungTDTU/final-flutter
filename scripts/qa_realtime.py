"""Disposable localhost browser fixtures; tokens stay in RAM, never in output/files."""
import argparse
import json
from pathlib import Path
import time
from uuid import uuid4

import httpx

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / 'evidence/2026-10-02-realtime/web-fixture.json'
PASSWORD = 'local-realtime-fixture-123'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['prepare', 'peer', 'reconnect', 'concurrent', 'viewer', 'revoke', 'lock', 'audit', 'locked-audit'])
    args = parser.parse_args()
    with httpx.Client(base_url='http://127.0.0.1:8000', timeout=10) as client:
        def call(method, path, body=None, token=None):
            r = client.request(method, path, json=body, headers={'Authorization': 'Bearer ' + token} if token else {})
            r.raise_for_status()
            return r.json()
        if args.action == 'prepare':
            stamp = time.time_ns()
            fixture = {role: f'web-rt-{role}-{stamp}@example.test' for role in ['owner', 'editor', 'viewer', 'stranger']}
            users = {role: call('POST', '/auth/register', {'email': email, 'name': 'Web realtime ' + role,
                       'password': PASSWORD, 'confirmation': PASSWORD}) for role, email in fixture.items()}
            owner = users['owner']['token']
            for key in ['note', 'lock_note']:
                fixture[key] = str(uuid4())
                call('POST', '/sync', {'op_id': str(uuid4()), 'note_id': fixture[key], 'kind': 'upsert', 'base_revision': 0,
                    'title': 'Web realtime fixture' if key == 'note' else 'Web realtime lock fixture', 'content': 'Original shared content'}, owner)
                for role in ['editor', 'viewer']:
                    call('POST', f'/notes/{fixture[key]}/shares', {'email': fixture[role], 'role': role}, owner)
            FIXTURE.write_text(json.dumps(fixture, indent=2), encoding='utf-8')
            print('Prepared disposable browser accounts and two shared notes. Public fixture password is in script.')
            return
        fixture = json.loads(FIXTURE.read_text(encoding='utf-8'))
        users = {role: call('POST', '/auth/login', {'email': fixture[role], 'password': PASSWORD})
                 for role in ['owner', 'editor', 'viewer', 'stranger']}
        owner = users['owner']['token']
        note_id = fixture['lock_note'] if args.action in ['lock', 'locked-audit'] else fixture['note']
        if args.action == 'locked-audit':
            for role in ['owner', 'editor', 'viewer']:
                rows = call('GET', '/notes', token=users[role]['token'])
                locked = next(n for n in rows if n['id'] == note_id)
                assert set(locked) == {'id', 'locked', 'revision', 'role'} and locked['locked'] and locked['revision'] == 2
                assert client.get(f'/notes/{note_id}', headers={'Authorization': 'Bearer ' + users[role]['token']}).status_code == 423
            print(json.dumps({'action': 'locked-audit', 'revision': 2, 'fields': ['id', 'locked', 'revision', 'role'], 'owner_editor_viewer_read': 423}))
            return
        note = call('GET', f'/notes/{note_id}', token=owner)
        if args.action in ['peer', 'reconnect', 'concurrent']:
            contents = {'peer': 'Peer content arrives live in Chrome', 'reconnect': 'Catchup after real server restart',
                        'concurrent': 'Concurrent owner version in Chrome'}
            call('POST', '/sync', {'op_id': str(uuid4()), 'note_id': note_id, 'kind': 'upsert',
                'base_revision': note['revision'], 'title': note['title'], 'content': contents[args.action]}, owner)
            print(json.dumps({'action': args.action, 'content_revision': note['revision'] + 1, 'utc_epoch': time.time()}))
        elif args.action in ['viewer', 'revoke']:
            if args.action == 'viewer':
                call('POST', f'/notes/{note_id}/shares', {'email': fixture['editor'], 'role': 'viewer'}, owner)
            else:
                call('DELETE', f'/notes/{note_id}/shares/{users["editor"]["user"]["id"]}', token=owner)
            print(json.dumps({'action': args.action, 'content_revision_unchanged': note['revision']}))
        elif args.action == 'lock':
            result = call('POST', f'/notes/{note_id}/protection', {'password': 'local-realtime-note-lock', 'confirmation': 'local-realtime-note-lock'}, owner)
            print(json.dumps({'action': 'lock', 'revision': result['revision']}))
        else:
            editor = users['editor']['token']
            assert client.get(f'/notes/{note_id}', headers={'Authorization': 'Bearer ' + users['stranger']['token']}).status_code == 404
            viewer = users['viewer']['token']
            denied = client.post('/sync', headers={'Authorization': 'Bearer ' + viewer}, json={
                'op_id': str(uuid4()), 'note_id': note_id, 'kind': 'upsert', 'base_revision': note['revision'], 'title': 'Denied', 'content': 'Denied'})
            assert denied.status_code == 403
            print(json.dumps({'action': 'audit', 'revision': note['revision'], 'content': note['content'],
                'editor_read': client.get(f'/notes/{note_id}', headers={'Authorization': 'Bearer ' + editor}).status_code,
                'viewer_write': denied.status_code, 'stranger_read': 404}))


if __name__ == '__main__':
    main()
