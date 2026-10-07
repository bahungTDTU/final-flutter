"""Disposable local QA accounts; no credentials/tokens persisted or printed.

Run prepare before registering the owner through the actual Web UI. The password
below is public fixture data, never use this command against a production server.
"""
import argparse
import json
import time
from pathlib import Path
from uuid import uuid4

import httpx

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / 'evidence/2026-10-02-sharing'
FIXTURE = EVIDENCE / 'web-fixture.json'
PASSWORD = 'local-sharing-fixture-123'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['prepare', 'audit', 'final-audit', 'locked-audit', 'viewer', 'editor', 'revoke', 'lock'])
    parser.add_argument('--api', default='http://127.0.0.1:8000')
    args = parser.parse_args()
    with httpx.Client(base_url=args.api, timeout=10) as client:
        def call(method, path, body=None, token=None):
            headers = {'Authorization': f'Bearer {token}'} if token else {}
            response = client.request(method, path, json=body, headers=headers)
            response.raise_for_status()
            return response.json()

        if args.action == 'prepare':
            stamp = time.time_ns()
            fixture = {role: f'web-share-{role}-{stamp}@example.test' for role in ['owner', 'recipient', 'other', 'stranger']}
            for role in ['recipient', 'other', 'stranger']:
                call('POST', '/auth/register', {'email': fixture[role], 'name': f'Web {role}', 'password': PASSWORD, 'confirmation': PASSWORD})
            FIXTURE.write_text(json.dumps(fixture, ensure_ascii=False, indent=2), encoding='utf-8')
            print('Created disposable recipient/other/stranger accounts. Owner registration is a browser step.')
            return
        fixture = json.loads(FIXTURE.read_text(encoding='utf-8'))
        def login(role):
            return call('POST', '/auth/login', {'email': fixture[role], 'password': PASSWORD})
        owner, recipient = login('owner'), login('recipient')
        token = owner['token']
        notes = call('GET', '/notes', token=token)
        if args.action == 'locked-audit':
            assert len(notes) == 1 and set(notes[0]) == {'id', 'locked', 'revision', 'role', 'pinned_at', 'shared'}
            assert notes[0]['locked'] and notes[0]['revision'] == 2 and notes[0]['role'] == 'owner'
            note_id = notes[0]['id']
            assert client.get(f'/notes/{note_id}/shares', headers={'Authorization': f'Bearer {token}'}).status_code == 423
            other = login('other')
            other_notes = call('GET', '/notes', token=other['token'])
            assert len(other_notes) == 1 and set(other_notes[0]) == {'id', 'locked', 'revision', 'role', 'pinned_at', 'shared'}
            assert other_notes[0]['role'] == 'viewer'
            assert client.get(f'/notes/{note_id}', headers={'Authorization': f'Bearer {recipient["token"]}'}).status_code == 404
            print(json.dumps({'check': 'PASS locked redaction', 'note_id': note_id, 'content_revision': 2, 'owner_catalogue': 423, 'revoked_recipient': 404, 'owner_list_fields': sorted(notes[0]), 'viewer_list_fields': sorted(other_notes[0])}))
            return
        note = next(n for n in notes if n.get('title') == 'Web sharing fixture')
        note_id = note['id']
        catalogue = call('GET', f'/notes/{note_id}/shares', token=token)
        if args.action == 'final-audit':
            assert len(catalogue['recipients']) == 1 and catalogue['revision'] == 3
            assert catalogue['recipients'][0]['email'] == fixture['other']
            assert note['revision'] == 1 and note['content'] == 'Original Web content'
            assert client.get(f'/notes/{note_id}', headers={'Authorization': f'Bearer {recipient["token"]}'}).status_code == 404
            print(json.dumps({'check': 'PASS after UI revoke', 'note_id': note_id, 'content_revision': note['revision'], 'share_revision': catalogue['revision'], 'recipient_count': 1, 'recipient_read': 404, 'content_unchanged': True}))
        elif args.action in ['viewer', 'editor', 'revoke']:
            action = 'revoke' if args.action == 'revoke' else 'role'
            result = call('POST', f'/notes/{note_id}/shares/sync', {'op_id': str(uuid4()), 'base_revision': catalogue['revision'], 'action': action, 'user_id': recipient['user']['id'], **({'role': args.action} if action == 'role' else {})}, token)
            print(json.dumps({'action': args.action, 'share_revision': result['revision'], 'recipient_count': len(result['recipients']), 'content_revision': note['revision']}))
        elif args.action == 'lock':
            result = call('POST', f'/notes/{note_id}/protection', {'current_password': '', 'password': 'local-note-sharing-lock', 'confirmation': 'local-note-sharing-lock'}, token)
            print(json.dumps({'action': 'lock', **result}))
        else:
            roles = {r['email']: r['role'] for r in catalogue['recipients']}
            assert len(roles) == 2
            shared = call('GET', f'/notes/{note_id}', token=recipient['token'])
            assert shared['shared_by']['name'] == 'Web owner' and shared['shared_at']
            stranger = login('stranger')
            assert client.get(f'/notes/{note_id}', headers={'Authorization': f'Bearer {stranger["token"]}'}).status_code == 404
            assert client.get(f'/notes/{note_id}/shares', headers={'Authorization': f'Bearer {recipient["token"]}'}).status_code == 403
            print(json.dumps({'check': 'PASS', 'note_id': note_id, 'content_revision': note['revision'], 'share_revision': catalogue['revision'], 'recipient_count': len(roles), 'owner_name': shared['shared_by']['name'], 'shared_at': shared['shared_at'], 'role': shared['role'], 'stranger': 404, 'recipient_catalogue': 403}, ensure_ascii=False))


if __name__ == '__main__':
    main()
