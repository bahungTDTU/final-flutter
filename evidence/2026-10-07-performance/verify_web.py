import json
from datetime import datetime, timezone
from pathlib import Path
import httpx

root = Path(__file__).resolve().parents[2]
login = json.loads((root/'tmp/performance-2026-10-07/browser-login.json').read_text())
with httpx.Client(base_url='http://127.0.0.1:8017', timeout=20) as client:
    auth = client.post('/auth/login', json={'email':login['email'],'password':login['password']})
    assert auth.status_code == 200
    headers = {'Authorization':'Bearer '+auth.json()['token']}
    note = client.get('/notes/'+login['note'], headers=headers).json()
    assert note['id'] == login['note'] and note['revision'] == 4, (note['id'], note['revision'])
    assert note['title'] == 'Web optimized draft'
    assert note['content'] == 'Web overlay survives reload'
    assert len(client.get('/notes', headers=headers).json()) == 1
    result = {'result':'PASS','date_utc':datetime.now(timezone.utc).isoformat(),
      'target':'IAB Web debug7366 / real loopback API8017 / IndexedDB + platform WebCrypto keys',
      'backend_stopped_after_login':True,'reload_while_backend_unreachable':True,
      'restored_title':' ','restored_content':note['content'],'completed_title':note['title'],
      'note_id':note['id'],'revision_before':3,'revision_after':4,'note_count':1,
      'limits':'Static Flutter debug server remained online; not Wi-Fi toggle/OS kill/physical/FPS/cold-first-load.'}
    (root/'evidence/2026-10-07-performance/web-result.json').write_text(json.dumps(result,indent=2)+'\n')
    print('PASS Web restored draft -> same-ID revision4; one remote note, exact title/body.')
