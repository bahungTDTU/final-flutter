"""Stage assertions for actual Chrome fixture; tokens never printed or persisted."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import sqlite3
import sys
import httpx

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
stage = sys.argv[1]
with httpx.Client(base_url='http://127.0.0.1:8000', timeout=20) as client:
    login = client.post('/auth/login', json={'email': 'web-avatar-20261001-1404@example.test', 'password': 'web-avatar-password-123'})
    login.raise_for_status()
    client.headers['Authorization'] = 'Bearer ' + login.json()['token']
    notes = client.get('/notes').json()
    assert len(notes) == 1
    note = notes[0]
    note_id = note['id']
    base = f'/notes/{note_id}/attachments'
    result = {'stage': stage, 'utc': datetime.now(timezone.utc).isoformat(), 'commit': None, 'note_id': note_id}
    if stage in ('baseline', 'deleted'):
        files = client.get(base).json()
        assert note['content'] == 'Content remains unchanged across label rename and deletion.' and note['revision'] == 2
        assert len(files) == (3 if stage == 'baseline' else 2)
        result.update(note_revision=2, note_content_preserved=True, attachment_count=len(files))
        for row in files:
            response = client.get(base + '/' + row['id'])
            assert response.status_code == 200 and response.headers['cache-control'] == 'private, no-store'
            assert response.headers['content-disposition'].startswith('attachment;')
            assert httpx.get(client.base_url.join(base + '/' + row['id'])).status_code == 401
            if row['kind'] in ('file', 'video'):
                assert response.content == (HERE / row['name']).read_bytes()
        if stage == 'baseline':
            result['files'] = files
        else:
            original = json.loads((HERE / 'web-baseline.json').read_text(encoding='utf-8'))
            old = next(row for row in original['files'] if row['kind'] == 'file')
            assert client.get(base + '/' + old['id']).status_code == 404
            with sqlite3.connect(ROOT / 'backend/state/app.sqlite3') as conn:
                assert conn.execute('SELECT data FROM attachments WHERE id=?', (old['id'],)).fetchone()[0] is None
            downloaded = ROOT / 'output/playwright/attachment-web.txt'
            assert downloaded.read_bytes() == (HERE / 'attachment-fixture.txt').read_bytes()
            result['download_sha256'] = hashlib.sha256(downloaded.read_bytes()).hexdigest()
    elif stage in ('lock', 'confirm-lock'):
        response = client.post(f'/notes/{note_id}/protection', json={'password': 'attachment-lock-password', 'confirmation': 'attachment-lock-password'})
        assert response.status_code == 200
        assert client.get(base).status_code == 423
        original = json.loads((HERE / 'web-baseline.json').read_text(encoding='utf-8'))
        assert all(client.get(base + '/' + row['id']).status_code == 423 for row in original['files'])
        result.update(note_revision=response.json()['revision'], attachments_list=423, attachments_direct=423)
    elif stage in ('restore', 'confirm-restore'):
        # If a verification-only failure occurred after the mutation, don't mutate twice.
        response = (client.post(f'/notes/{note_id}/protection', json={'current_password': 'attachment-lock-password', 'password': None})
                    if note.get('locked') else client.get(f'/notes/{note_id}'))
        assert response.status_code == 200
        assert client.get(base).status_code == 200
        assert client.get(f'/notes/{note_id}').json()['content'] == 'Content remains unchanged across label rename and deletion.'
        result.update(note_revision=response.json()['revision'], attachments_restored=200)
    elif stage == 'peer-delete':
        assert note['revision'] == 4 and note['content'] == 'Content remains unchanged across label rename and deletion.'
        files = client.get(base).json()
        image = next(row for row in files if row['kind'] == 'image')
        assert client.delete(base + '/' + image['id']).status_code == 200
        assert client.get(base + '/' + image['id']).status_code == 404
        assert len(client.get(base).json()) == 1
        with sqlite3.connect(ROOT / 'backend/state/app.sqlite3') as conn:
            assert conn.execute('SELECT data FROM attachments WHERE id=?', (image['id'],)).fetchone()[0] is None
        after = client.get(f'/notes/{note_id}').json()
        assert after['revision'] == 4 and after['content'] == note['content']
        result.update(note_revision=4, note_content_preserved=True, deleted_image=image['id'], attachment_count=1)
    else:
        raise ValueError(stage)
    result['result'] = 'PASS'
    (HERE / f'web-{stage}.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=True))
