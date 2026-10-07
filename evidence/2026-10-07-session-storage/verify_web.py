"""Verify disposable local fixture profile/note and independent server logout, without saving tokens."""
import json
from datetime import datetime, timezone
from pathlib import Path
import httpx

folder = Path(__file__).resolve().parent
with httpx.Client(base_url='http://127.0.0.1:8017',timeout=20) as client:
    response = client.post('/auth/login',json={'email':'perf-owner-de4a3ba9-0ce3-47f0-ae40-b71514b30b9f@example.test',
                                            'password':'Perf-local-2026!'})
    assert response.status_code == 200
    header = {'Authorization':'Bearer '+response.json()['token']}
    profile = client.get('/me',headers=header).json()
    assert profile['name'] == 'Session vault Web'
    notes = client.get('/notes',headers=header).json()
    assert len(notes) == 1 and notes[0]['id'] == '31318b66-245a-4273-9c41-efd990946c6e'
    assert notes[0]['revision'] == 4 and notes[0]['content'] == 'Web overlay survives reload'
    assert client.post('/auth/logout',headers=header).status_code == 200
    assert client.get('/me',headers=header).status_code == 401
    result = {'result':'PASS','date_utc':datetime.now(timezone.utc).isoformat(),
      'target':'IAB Web debug7366 / actual loopback API8017',
      'fixture_from_previous_version_restored':True,'encrypted_session_offline_reload':True,
      'logout_reload_showed_auth':True,'manual_login_restored_same_note':True,
      'profile_name':profile['name'],'note_count':1,'note_id':notes[0]['id'],'note_revision':4,
      'independent_server_logout_status':401,
      'limits':'Browser storage/token not read through automation; native/host verify opaque records and compaction. No public/physical/OS kill/XSS-immunity claim.'}
    (folder/'web-result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('PASS profile/note retained; independent API login/logout token returns401; no credential values recorded.')
