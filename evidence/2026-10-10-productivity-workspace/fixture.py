import json
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from uuid import uuid4

ROOT = Path(__file__).parent
BASE = 'http://127.0.0.1:8033'
def call(method, path, body=None, token=None):
    headers = {'Content-Type': 'application/json'}
    if token: headers['Authorization'] = 'Bearer ' + token
    req = Request(BASE + path, data=json.dumps(body).encode() if body is not None else None, headers=headers, method=method)
    try:
        with urlopen(req, timeout=10) as res: return res.status, json.loads(res.read())
    except HTTPError as e: return e.code, json.loads(e.read())

users = {}
for name in ['owner', 'viewer', 'editor', 'stranger']:
    email = f'workspace-{name}@example.test'
    status, data = call('POST', '/auth/register', {'email': email, 'name': 'Workspace ' + name, 'password': 'workspace-password-123', 'confirmation': 'workspace-password-123'})
    if status != 201:
        status, data = call('POST', '/auth/login', {'email': email, 'password': 'workspace-password-123'})
    assert status in [200, 201], (name, status)
    users[name] = data

def op(title, content, note_id=None, revision=0):
    return {'op_id': str(uuid4()), 'note_id': note_id or str(uuid4()), 'kind': 'upsert', 'base_revision': revision, 'title': title, 'content': content, 'pinned_at': None, 'labels': [], 'labels_format': 'ids'}
owner = users['owner']['token']
status, existing = call('GET', '/notes', token=owner)
for item in existing:
    revision = item['revision']
    if item['locked']:
        status, response = call('POST', f'/notes/{item["id"]}/protection', {'current_password': 'workspace-note-123', 'password': None}, owner)
        assert status == 200
        revision = response['revision']
    status, _ = call('POST', '/sync', {'op_id': str(uuid4()), 'note_id': item['id'], 'kind': 'delete', 'base_revision': revision}, owner)
    assert status == 200
notes = {}
for key, title, content in [
    ('plan', 'Kế hoạch sáng tạo', '# Kế hoạch\n\n- [ ] Thiết kế không gian làm việc\n- [ ] Kiểm tra trải nghiệm trên điện thoại\n- [x] Giữ bản nháp an toàn'),
    ('idea', 'Vườn ý tưởng', '## Ý tưởng\nTập hợp những thử nghiệm nhỏ cho NoteTogether.'),
    ('private', 'Thông tin cần bảo vệ', 'Nội dung riêng tư phải biến mất ngay khi khóa.'),
    ('acl', 'ACL checklist', '- [ ] Review')]:
    operation = op(title, content); status, _ = call('POST', '/sync', operation, owner); assert status == 200
    notes[key] = operation['note_id']
for role in ['viewer', 'editor']:
    status, _ = call('POST', f'/notes/{notes["acl"]}/shares', {'email': users[role]['user']['email'], 'role': role}, owner); assert status == 200
report = {'target': BASE, 'provider': 'disabled', 'roles': {}}
for role in ['owner', 'viewer', 'editor', 'stranger']:
    token = users[role]['token']
    status, _ = call('GET', f'/notes/{notes["acl"]}', token=token)
    edit_status, _ = call('POST', '/sync', op('ACL checklist', '- [x] Review', notes['acl'], 1 if role != 'owner' else 2), token)
    report['roles'][role] = {'read': status, 'task_edit': edit_status}
    assert status == (404 if role == 'stranger' else 200)
    assert edit_status == {'owner': 409, 'viewer': 403, 'editor': 200, 'stranger': 404}[role], (role, edit_status)
# The owner also updates against the current accepted revision.
status, _ = call('POST', '/sync', op('ACL checklist', '- [ ] Review', notes['acl'], 2), owner); assert status == 200
report['owner_current_revision_edit'] = status
status, _ = call('POST', f'/notes/{notes["acl"]}/protection', {'password': 'workspace-note-123', 'confirmation': 'workspace-note-123'}, owner); assert status == 200
status, redacted = call('GET', '/notes', token=users['editor']['token']); assert status == 200
assert set(redacted[0]) == {'id', 'locked', 'revision', 'role', 'pinned_at', 'shared'}
report['locked_fields'] = sorted(redacted[0])
status, _ = call('POST', '/sync', op('ACL checklist', '- [x] Review', notes['acl'], 4), users['editor']['token']); assert status == 423
report['locked_task_edit'] = status
status, _ = call('POST', f'/notes/{notes["acl"]}/unlock', {'password': 'workspace-note-123'}, owner); assert status == 200
status, _ = call('DELETE', f'/notes/{notes["acl"]}/shares/{users["editor"]["user"]["id"]}', token=owner); assert status == 200
status, revoked = call('GET', '/notes', token=users['editor']['token']); assert revoked == []
report['revoked_listing_empty'] = True
(ROOT/'fixture.json').write_text(json.dumps({'email': users['owner']['user']['email'], 'notes': notes}, ensure_ascii=False, indent=2), encoding='utf-8')
(ROOT/'http-roles.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
