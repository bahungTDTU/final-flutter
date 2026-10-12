"""Synthetic server-backed UI fixtures; auth tokens remain in RAM only."""
import json
from uuid import uuid4
import httpx

PASSWORD = 'safe-password-123'
with httpx.Client(base_url='http://127.0.0.1:8058', timeout=15) as client:
    def request(method, path, actor=None, body=None, expected=200):
        headers = {'Authorization': 'Bearer ' + actor['token']} if actor else {}
        response = client.request(method, path, json=body, headers=headers)
        assert response.status_code == expected, (method, path, response.status_code)
        return response.json()

    actors = {}
    for role in ('owner', 'viewer', 'editor', 'stranger'):
        actors[role] = request('POST', '/auth/register', body={
            'email': f'ui-refresh-{role}@example.test', 'name': 'UI QA ' + role,
            'password': PASSWORD, 'confirmation': PASSWORD,
        }, expected=201)
    owner = actors['owner']
    labels = []
    for name in ['Học tập', 'Dự án', 'Ý tưởng', 'Cá nhân']:
        label = str(uuid4())
        request('POST', '/labels/sync', owner, {'op_id': str(uuid4()), 'label_id': label,
                                               'base_revision': 0, 'kind': 'upsert', 'name': name})
        labels.append(label)
    titles = ['Thiết kế NoteTogether', 'Kế hoạch học tập trong tuần', 'Ý tưởng cho buổi thuyết trình',
              'Flutter và kiến trúc ứng dụng', 'Những điều muốn đọc', 'Hành trình học tập',
              'Lịch họp nhóm', 'Một ngày thật hiệu quả', 'Bản ghi riêng tư']
    ids = []
    for index, title in enumerate(titles):
        note = str(uuid4())
        request('POST', '/sync', owner, {'op_id': str(uuid4()), 'note_id': note,
                'kind': 'upsert', 'base_revision': 0, 'title': title,
                'content': '## Mục tiêu\nPhân tách ý tưởng, nội dung và công việc để dễ theo dõi.\n\n- [ ] Ghi lại điều quan trọng\n- [ ] Kiểm tra và hoàn thiện\n\nDữ liệu thử nghiệm cho nghiệm thu UI.',
                'labels': [labels[index % len(labels)]], 'labels_format': 'ids',
                'pinned_at': '2026-10-12T00:00:00Z' if index < 2 else None})
        ids.append(note)
    for role in ('viewer', 'editor'):
        request('POST', f'/notes/{ids[0]}/shares', owner,
                {'email': actors[role]['user']['email'], 'role': role})
    request('POST', '/sync', actors['viewer'], {'op_id': str(uuid4()), 'note_id': ids[0],
            'kind': 'upsert', 'base_revision': 1, 'title': 'Denied', 'content': 'Denied'}, 403)
    request('GET', f'/notes/{ids[0]}', actors['stranger'], expected=404)
    request('GET', f'/notes/{ids[0]}', actors['editor'])
    request('POST', f'/notes/{ids[-1]}/protection', owner,
            {'password': 'note-password-123', 'confirmation': 'note-password-123'})
    locked = next(note for note in request('GET', '/notes', owner) if note['id'] == ids[-1])
    assert set(locked) == {'id', 'locked', 'revision', 'role', 'pinned_at', 'shared'}
    request('GET', f'/notes/{ids[-1]}', owner, expected=423)
    print(json.dumps({'fixture': 'synthetic, isolated loopback server', 'notes': len(ids),
                      'labels': len(labels), 'roles': ['owner', 'viewer', 'editor', 'stranger'],
                      'viewerWrite': 403, 'strangerRead': 404, 'lockedRead': 423,
                      'lockedProjectionFields': sorted(locked), 'tokensRecorded': False}, ensure_ascii=False))
