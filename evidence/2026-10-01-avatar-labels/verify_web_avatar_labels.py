"""Assertions for the disposable account operated through Chrome, not synthetic UI claims.

Run stages baseline, reconnect, peer, final in order after the corresponding UI actions.
Credentials below belong only to this local QA fixture. Tokens are never printed/saved.
"""
from datetime import datetime, timezone
from io import BytesIO
import json
from pathlib import Path
import sqlite3
import sys
from uuid import uuid4

import httpx
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
EMAIL = 'web-avatar-20261001-1404@example.test'
TITLE = 'Web label durable fixture'
CONTENT = 'Content remains unchanged across label rename and deletion.'
stage = sys.argv[1]
with httpx.Client(base_url='http://127.0.0.1:8000', timeout=15) as client:
    login = client.post('/auth/login', json={'email': EMAIL, 'password': 'web-avatar-password-123'})
    login.raise_for_status()
    client.headers['Authorization'] = 'Bearer ' + login.json()['token']
    notes = client.get('/notes').json()
    assert len(notes) == 1 and notes[0]['title'] == TITLE and notes[0]['content'] == CONTENT
    note = notes[0]
    catalogue = client.get('/labels').json()
    profile = client.get('/me').json()
    result = {'stage': stage, 'utc': datetime.now(timezone.utc).isoformat(),
              'target': 'Chrome release + second API session + SQLite', 'commit': None,
              'note_id': note['id'], 'note_revision': note['revision'], 'note_count': len(notes)}
    if stage == 'baseline':
        assert len(catalogue) == 1 and catalogue[0]['name'] == 'Học tập Web'
        assert note['labels'] == [catalogue[0]['id']]
        assert profile['has_avatar'] and profile['avatar_revision'] == 1
        response = client.get('/me/avatar?revision=1')
        assert response.status_code == 200 and response.headers['cache-control'] == 'private, no-store'
        with Image.open(BytesIO(response.content)) as image:
            assert image.format == 'PNG' and image.size == (96, 96) and not image.info
        assert httpx.get('http://127.0.0.1:8000/me/avatar?revision=1').status_code == 401
        result.update(label_id=catalogue[0]['id'], avatar_revision=1, canonical_metadata={},
                      avatar_anonymous=401, label_name=catalogue[0]['name'])
    else:
        baseline = json.loads((HERE / 'web-baseline.json').read_text(encoding='utf-8'))
        assert note['id'] == baseline['note_id'] and note['revision'] == baseline['note_revision']
        label = next(row for row in catalogue if row['id'] == baseline['label_id'])
        result.update(label_id=label['id'], label_revision=label['revision'], label_name=label['name'])
        if stage == 'reconnect':
            assert label['name'] == 'Nhãn offline Web' and label['revision'] == 2 and not label['deleted']
            assert note['label_names'] == {label['id']: label['name']}
        elif stage == 'peer':
            response = client.post('/labels/sync', json={
                'op_id': str(uuid4()), 'label_id': label['id'], 'base_revision': label['revision'],
                'kind': 'upsert', 'name': 'Nhãn từ phiên khác',
            })
            assert response.status_code == 200 and response.json()['revision'] == 3
            result.update(label_revision=3, label_name=response.json()['name'])
        elif stage == 'final':
            assert label['deleted'] and label['revision'] == 4
            assert note['labels'] == [] and note['label_names'] == {} and not note['deleted']
            assert not profile['has_avatar'] and profile['avatar_revision'] == 2
            assert client.get('/me/avatar?revision=2').status_code == 404
            result.update(avatar_revision=2, avatar_after_remove=404, label_deleted=True,
                          note_content_preserved=True, note_revision_preserved=True)
        else:
            raise ValueError(stage)
    with sqlite3.connect(ROOT / 'backend' / 'state' / 'app.sqlite3') as conn:
        db_note = conn.execute('SELECT revision,title,content,deleted FROM notes WHERE id=?', (note['id'],)).fetchone()
        assert db_note == (note['revision'], TITLE, CONTENT, 0)
        assert conn.execute('PRAGMA user_version').fetchone()[0] == 2
        if stage == 'final':
            assert conn.execute('SELECT data FROM avatars WHERE user_id=?', (profile['id'],)).fetchone()[0] is None
    result['result'] = 'PASS'
    (HERE / f'web-{stage}.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=True))
