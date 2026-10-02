import json
import sqlite3
import sys
from pathlib import Path

stage = sys.argv[1]
with sqlite3.connect('backend/state/app.sqlite3') as db:
    user_id, prefs = db.execute('SELECT id,preferences FROM users WHERE email=?',
                               ('web-check-20261001@example.com',)).fetchone()
    rows = db.execute('SELECT id,content,pinned_at FROM notes WHERE owner_id=? AND title=? AND deleted=0',
                      (user_id, 'Kiểm tra ID ổn định')).fetchall()
    assert len(rows) == 1
    row = rows[0]
    count = db.execute('SELECT COUNT(*) FROM notes WHERE owner_id=? AND deleted=0', (user_id,)).fetchone()[0]
    result = dict(stage=stage, note_id=row[0], content=row[1], pinned=bool(row[2]),
                  account_note_count=count, preferences=json.loads(prefs), commit=None)
if stage == 'after':
    before = json.loads(Path('evidence/2026-10-01-ui/web-state-before.json').read_text(encoding='utf-8'))
    assert row[0] == before['note_id']
    assert count == before['account_note_count'] == 3
    assert row[1] == 'Kiểm chứng UI mới: ghi chú được giữ trên thiết bị khi mất mạng và đồng bộ khi có kết nối.'
    assert row[2] is not None
Path(f'evidence/2026-10-01-ui/web-state-{stage}.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
print('Real SQLite state assertions: PASS')
