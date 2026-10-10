import hashlib
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
after = call('GET', '/notes', token=token)
before = json.loads((root/'server-before-import.json').read_text(encoding='utf-8'))
previous = {n['id'] for n in before['notes']}
new = [n for n in after if not n['locked'] and n['id'] not in previous]
exported = json.loads((root/'exported.notetogether.json').read_text(encoding='utf-8'))
assert len(new) == 2, len(new)
assert set(exported) == {'format', 'version', 'notes'}
assert all(set(n) == {'title', 'content'} for n in exported['notes'])
for n in exported['notes']:
    matches = [v for v in new if v['title'] == n['title'] and v['content'] == n['content']]
    assert len(matches) == 1 and matches[0]['revision'] == 1 and matches[0]['role'] == 'owner'
journals = [n for n in after if n.get('title', '').startswith('Nhật ký ')]
assert len(journals) == 2 and len({n['id'] for n in journals}) == 2
report = {'target': base, 'before_count': before['count'], 'after_count': len(after),
          'imported_count': len(new), 'new_ids': [n['id'] for n in new],
          'exact_content_match': True, 'new_owner_revision_one': True,
          'same_day_journals_distinct_ids': True,
          'export_sha256': hashlib.sha256((root/'exported.notetogether.json').read_bytes()).hexdigest()}
(root/'roundtrip.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
