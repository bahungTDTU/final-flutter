import json
from pathlib import Path
from urllib.request import Request, urlopen

root = Path(__file__).parent
base = 'http://127.0.0.1:8033'
def call(method, path, body=None, token=None):
    headers = {'Content-Type': 'application/json'}
    if token: headers['Authorization'] = 'Bearer ' + token
    with urlopen(Request(base + path, data=json.dumps(body).encode() if body is not None else None, headers=headers, method=method), timeout=10) as res:
        return json.loads(res.read())
token = call('POST', '/auth/login', {'email': 'workspace-owner@example.test', 'password': 'workspace-password-123'})['token']
note_id = json.loads((root/'fixture.json').read_text(encoding='utf-8'))['notes']['private']
result = call('POST', f'/notes/{note_id}/protection', {'password': 'workspace-note-123', 'confirmation': 'workspace-note-123'}, token)
assert result['locked'] is True
listed = call('GET', '/notes', token=token)
public = next(n for n in listed if n['id'] == note_id)
assert set(public) == {'id', 'locked', 'revision', 'role', 'pinned_at', 'shared'}
(root/'remote-lock.json').write_text(json.dumps({'result': result, 'public_fields': sorted(public)}, indent=2), encoding='utf-8')
print('Remote lock accepted; exact six-field public projection PASS.')
