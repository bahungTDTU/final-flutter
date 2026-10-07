"""Actual loopback HTTP ACL for checklist text; disposable users, no stored tokens in evidence."""
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4
import json
import argparse
import httpx

BASE = 'http://127.0.0.1:8012'
PASSWORD = 'Studio-local-2026!'
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path,
                    default=Path('evidence/2026-10-06-writing-studio/http.json'))
args = parser.parse_args()
with httpx.Client(base_url=BASE, timeout=15) as api:
    def call(method, route, user=None, body=None, status=200):
        headers = {'Authorization': 'Bearer ' + user['token']} if user else {}
        response = api.request(method, route, headers=headers, json=body)
        assert response.status_code == status, (method, route, response.status_code, status)
        return response.json()

    users = {role: call('POST', '/auth/register', body={
        'email': f'studio-{role}-{uuid4()}@example.test', 'name': f'Studio {role}',
        'password': PASSWORD, 'confirmation': PASSWORD}, status=201)
        for role in ['owner', 'editor', 'viewer', 'stranger']}
    note_id = str(uuid4())
    def op(base, content):
        return {'op_id': str(uuid4()), 'note_id': note_id, 'kind': 'upsert',
                'base_revision': base, 'title': 'Checklist API', 'content': content,
                'labels': [], 'labels_format': 'ids'}
    original = '# Nhóm\n- [ ] Việc API'
    checked = original.replace('[ ]', '[x]')
    call('POST', '/sync', users['owner'], op(0, original))
    for role in ['editor', 'viewer']:
        call('POST', f'/notes/{note_id}/shares', users['owner'],
             {'email': users[role]['user']['email'], 'role': role})
    call('POST', '/sync', users['viewer'], op(1, checked), status=403)
    call('POST', '/sync', users['stranger'], op(1, checked), status=404)
    call('POST', '/sync', users['editor'], op(1, checked))
    call('POST', '/sync', users['owner'], op(1, original), status=409)
    detail = call('GET', f'/notes/{note_id}', users['owner'])
    assert detail['content'] == checked and detail['revision'] == 2
    call('DELETE', f'/notes/{note_id}/shares/{users["editor"]["user"]["id"]}', users['owner'])
    call('POST', '/sync', users['editor'], op(2, original), status=404)
    call('POST', f'/notes/{note_id}/protection', users['owner'],
         {'password': 'Studio-note-password!', 'confirmation': 'Studio-note-password!'})
    call('POST', '/sync', users['owner'], op(3, original), status=423)
    listed = call('GET', '/notes', users['owner'])
    assert len(listed) == 1 and set(listed[0]) == {'id', 'locked', 'role', 'revision', 'pinned_at', 'shared'}
    Path('tmp/studio-browser-account.json').write_text(json.dumps({
        'email': users['owner']['user']['email'], 'password': PASSWORD,
        'token': users['owner']['token'], 'locked_note': note_id}), encoding='utf-8')
    evidence = {'date_utc': datetime.now(timezone.utc).isoformat(), 'target': BASE,
        'result': 'PASS', 'owner': 'stale409/locked423', 'editor': 'check then revoke404',
        'viewer': '403', 'stranger': '404', 'locked_metadata': 'id/role/revision/locked/pinned_at/shared; no private fields',
        'release': 'not built; debug local only'}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(evidence, indent=2), encoding='utf-8')
    print(json.dumps(evidence))
