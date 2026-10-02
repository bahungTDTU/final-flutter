"""Read actual local API after final Chrome offline edit; no tokens in output."""
import json
from datetime import datetime, timezone
from urllib.request import Request, urlopen

BASE = 'http://127.0.0.1:8000'


def call(method, path, body=None, token=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    data = None if body is None else json.dumps(body).encode()
    with urlopen(Request(BASE + path, data, headers, method=method), timeout=10) as res:
        return json.load(res)


auth = call('POST', '/auth/login', dict(email='ui-upgrade-owner@example.test',
                                     password='UiEvidence-2026!'))
token = auth['token']
notes = call('GET', '/notes', token=token)
rows = [n for n in notes if n.get('title') == 'UI Web bản nháp offline']
assert len(rows) == 1, f'Expected one fixture note, got {len(rows)}'
note = call('GET', '/notes/' + rows[0]['id'], token=token)
assert note['content'] == 'Nội dung vẫn được giữ khi mất mạng; trạng thái kết nối được hiển thị đúng.'
assert note['revision'] == 2, note['revision']
print(datetime.now(timezone.utc).isoformat())
print('PASS final Chrome offline edit -> reconnect: exactly 1 fixture server note, exact content, revision2.')
print('No tokens or account data logged; local fixture only.')
