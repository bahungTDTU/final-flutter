"""Create isolated local QA accounts and notes, never production sample data."""
import json
from urllib.request import Request, urlopen
from uuid import uuid4
from urllib.error import HTTPError

BASE = 'http://127.0.0.1:8000'
PASSWORD = 'UiEvidence-2026!'
EMAIL = 'ui-upgrade-owner@example.test'


def call(path, body, token=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    with urlopen(Request(BASE + path, json.dumps(body).encode(), headers)) as res:
        return json.load(res)


try:
    auth = call('/auth/register', dict(email=EMAIL, name='Không gian học tập',
                                     password=PASSWORD, confirmation=PASSWORD))
except HTTPError as err:
    if err.code != 409:
        raise
    auth = call('/auth/login', dict(email=EMAIL, password=PASSWORD))
token = auth['token']
notes = [
    ('Kế hoạch đồ án cuối kỳ', 'Chốt luồng ghi chú, rà lại quyền chia sẻ và chuẩn bị buổi demo.\nMỗi thay đổi cần có bằng chứng kiểm thử.', ['Đồ án', 'Nhóm'], True),
    ('Những ý tưởng đáng giữ', 'Một nơi để ghi nhanh ý tưởng trong ngày.\nĐọc lại, sắp xếp và cùng nhau phát triển.', ['Cá nhân'], False),
    ('Flutter: ghi chú buổi học', 'Widget tạo giao diện. Controller quản lý trạng thái.\nTách rõ giao diện, dữ liệu và kiểm thử.', ['Học tập'], False),
    ('Checklist buổi họp nhóm', '• Rà lại tiến độ\n• Thử Web và Android\n• Ghi lại các việc còn cần xác minh', ['Nhóm'], False),
    ('Tài liệu cần bảo vệ', 'Nội dung này phải được che trước khi mở khóa.', [], False),
]
ids = []
for title, content, labels, pinned in notes:
    nid = str(uuid4())
    ids.append(nid)
    op = dict(op_id=str(uuid4()), note_id=nid, base_revision=0, kind='upsert',
              title=title, content=content, labels=labels)
    if pinned:
        op['pinned_at'] = '2026-10-02T11:00:00Z'  # Explicit QA fixture, not evidence timestamp.
    result = call('/sync', op, token)
    assert result['id'] == nid, result
call('/notes/' + ids[-1] + '/protection',
     dict(password=PASSWORD, confirmation=PASSWORD), token)
print('Created local UI fixture: 5 notes, 4 labels, 1 locked note. No tokens logged.')
