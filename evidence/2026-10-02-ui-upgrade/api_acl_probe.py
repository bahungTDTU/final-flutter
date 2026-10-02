"""Actual local HTTP permissions checks after presentation changes."""
import json
from datetime import datetime, timezone
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from uuid import uuid4

BASE = 'http://127.0.0.1:8000'


def request(method, path, body=None, token=None, expected=200):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    data = None if body is None else json.dumps(body).encode()
    try:
        with urlopen(Request(BASE + path, data, headers, method=method), timeout=20) as response:
            status, payload = response.status, json.load(response)
    except HTTPError as error:
        status, payload = error.code, json.load(error)
    assert status == expected, (method, path, status, payload)
    return payload


suffix = uuid4().hex
accounts = {}
for role in ('owner', 'viewer', 'editor', 'stranger'):
    email = f'ui-acl-{role}-{suffix}@example.test'
    auth = request('POST', '/auth/register', dict(email=email, name=role,
                   password='ui-acl-evidence-123', confirmation='ui-acl-evidence-123'), expected=201)
    accounts[role] = dict(token=auth['token'], email=email, id=auth['user']['id'])

nid = str(uuid4())


def edit(role, revision, content, expected=200, **extra):
    return request('POST', '/sync', dict(op_id=str(uuid4()), note_id=nid,
                   base_revision=revision, kind='upsert', title='UI ACL fixture',
                   content=content, **extra), accounts[role]['token'], expected)


edit('owner', 0, 'First version')
for role in ('viewer', 'editor'):
    request('POST', f'/notes/{nid}/shares', dict(email=accounts[role]['email'], role=role), accounts['owner']['token'])
for role in ('owner', 'viewer', 'editor'):
    assert request('GET', f'/notes/{nid}', token=accounts[role]['token'])['content'] == 'First version'
request('GET', f'/notes/{nid}', token=accounts['stranger']['token'], expected=404)
edit('viewer', 1, 'Forbidden', expected=403)
edit('editor', 1, 'Editor accepted')
request('POST', f'/notes/{nid}/shares', dict(email=accounts['stranger']['email'], role='viewer'), accounts['editor']['token'], expected=403)
request('POST', f'/notes/{nid}/protection', dict(password='protected-ui-123', confirmation='protected-ui-123'), accounts['editor']['token'], expected=403)
request('POST', f'/notes/{nid}/protection', dict(password='protected-ui-123', confirmation='protected-ui-123'), accounts['owner']['token'])
for role in ('owner', 'viewer', 'editor'):
    request('GET', f'/notes/{nid}', token=accounts[role]['token'], expected=423)
    rows = request('GET', '/notes', token=accounts[role]['token'])
    locked = next(row for row in rows if row['id'] == nid)
    assert set(locked) == {'id', 'locked', 'role', 'revision'}, locked
print(datetime.now(timezone.utc).isoformat())
print('PASS actual HTTP owner/viewer/editor/stranger: read, write, sharing, protection, locked minimal metadata.')
print('No tokens or private content logged. Local fixture only; no public deployment claim.')
