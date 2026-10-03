"""Actual HTTP assertions for the disposable Chrome maintenance fixture."""
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import Request, urlopen

HERE = Path(__file__).resolve().parent
BASE = 'http://127.0.0.1:8000'
TITLE = 'QA maintenance 2026-10-03'


def request(method, path, body=None, token=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    data = json.dumps(body).encode() if body is not None else None
    with urlopen(Request(BASE + path, data, headers, method=method), timeout=15) as response:
        assert response.status == 200
        return json.load(response)


auth = request('POST', '/auth/login', {'email': 'ui-upgrade-owner@example.test', 'password': 'UiEvidence-2026!'})
notes = request('GET', '/notes', token=auth['token'])
matches = [n for n in notes if n.get('title') == TITLE]
assert len(matches) == 1, 'Expected exactly one maintenance fixture note'
note = matches[0]
if sys.argv[1] == 'before':
    assert note['content'] == 'Bản online maintenance trước khi mất mạng.'
    state = {'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
             'id': note['id'], 'revision': note['revision'], 'account_note_count': len(notes)}
    (HERE / 'browser-note-before.json').write_text(json.dumps(state, indent=2), encoding='utf-8')
else:
    state = json.loads((HERE / 'browser-note-before.json').read_text(encoding='utf-8'))
    assert note['id'] == state['id']
    assert len(notes) == state['account_note_count']
    assert note['revision'] > state['revision']
    assert note['content'] == 'Bản offline maintenance 03/10 được giữ sau reload.'
    state.update({'verified_at_utc': datetime.now(timezone.utc).isoformat(),
                  'revision_after': note['revision'], 'passed': True})
    (HERE / 'browser-note-after.json').write_text(json.dumps(state, indent=2), encoding='utf-8')
request('POST', '/auth/logout', token=auth['token'])
print('PASS actual HTTP: ' + sys.argv[1] + ' maintenance note ID/count/content assertions; no token logged.')
