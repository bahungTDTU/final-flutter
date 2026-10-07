import json
import sys
from pathlib import Path
from uuid import uuid4
from datetime import datetime, timezone
import httpx

fixture = json.loads(Path('tmp/priorities/browser-login.json').read_text())
with httpx.Client(base_url='http://127.0.0.1:8016', timeout=10) as api:
    def call(method, path, body=None):
        response = api.request(method, path, json=body, headers=auth)
        response.raise_for_status()
        return response.json()
    response = api.post('/auth/login', json={'email': fixture['email'], 'password': fixture['password']})
    response.raise_for_status()
    auth = {'Authorization': 'Bearer ' + response.json()['token']}
    note = fixture['note']
    call('POST', f'/notes/{note}/unlock', {'password': fixture['note_password']})
    current = call('GET', f'/notes/{note}')
    recipients = call('GET', f'/notes/{note}/shares')['recipients']
    if sys.argv[1] == 'clear':
        Path('tmp/priorities/recipients.json').write_text(json.dumps(recipients))
        for recipient in recipients:
            call('DELETE', f'/notes/{note}/shares/{recipient["user_id"]}')
        pin = None
    else:
        for recipient in json.loads(Path('tmp/priorities/recipients.json').read_text()):
            call('POST', f'/notes/{note}/shares', {'email': recipient['email'], 'role': recipient['role']})
        pin = '2026-10-07T02:00:00Z'
    call('POST', '/sync', {'op_id': str(uuid4()), 'note_id': note, 'kind': 'upsert',
        'base_revision': current['revision'], 'title': current['title'], 'content': current['content'],
        'labels': current['labels'], 'labels_format': 'ids', 'pinned_at': pin})
    call('POST', f'/notes/{note}/lock')
    row = next(n for n in call('GET', '/notes') if n['id'] == note)
    assert set(row) == {'id','locked','revision','role','pinned_at','shared'}
    result = {'date_utc': datetime.now(timezone.utc).isoformat(), 'action': sys.argv[1], 'locked_listing': row}
    Path(f'evidence/2026-10-07-protection-status/web-{sys.argv[1]}-api.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result))
