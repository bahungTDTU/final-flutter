import json
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4
import httpx
root=Path('evidence/2026-10-14-dashboard-polish')
email=json.loads((root/'seed.json').read_text(encoding='utf-8'))['email']
with httpx.Client(base_url='http://127.0.0.1:8059',timeout=20) as client:
    r=client.post('/auth/login',json={'email':email,'password':'Performance-fixture-2026!'})
    r.raise_for_status()
    client.headers['Authorization']='Bearer '+r.json()['token']
    notes=client.get('/notes').json()
    titles=['Ý tưởng cho NoteTogether','Kế hoạch học tập trong tuần','Bản nháp cộng tác từ xa']
    bodies=['Mục tiêu: xây dựng một thư viện ghi chú dễ đọc, có nhịp điệu và tập trung.\nTách rõ tiêu đề, nội dung và công cụ để thao tác thoải mái.', 'Ôn tập Flutter và chuẩn bị bài trình bày.\nHoàn thành các phần quan trọng trước, dành thời gian cho phản hồi của nhóm.', 'Nội dung mẫu để xác nhận cập nhật và khóa ghi chú từ xa.']
    for index,n in enumerate(notes[:3]):
        r=client.post('/sync',json={'op_id':str(uuid4()),'note_id':n['id'],'kind':'upsert','base_revision':n['revision'],'title':titles[index],'content':bodies[index],'labels':n['labels'],'labels_format':'ids','pinned_at':datetime.now(timezone.utc).isoformat() if index<2 else None})
        r.raise_for_status()
    client.patch('/me',json={'name':'QA thư viện'}).raise_for_status()
    (Path('tmp/dashboard-2026-10-14')/'remote-note.json').write_text(json.dumps({'email':email,'note':notes[2]['id']}),encoding='utf-8')
print('Dashboard fixture: 500 notes, 2 pinned, 1 remote-update target; synthetic account only.')
