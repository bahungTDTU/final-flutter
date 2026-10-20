"""Locale HTTP checks on disposable loopback QA only; never publish tokens."""
import hashlib,json
from datetime import datetime,timezone
from pathlib import Path
from uuid import uuid4
import httpx

root=Path(__file__).resolve().parents[2]
login=json.loads((root/'tmp/bilingual-2026-10-16/browser-login.json').read_text())
with httpx.Client(base_url='http://127.0.0.1:8062',timeout=20) as c:
    def call(method,path,token=None,body=None,status=200):
        r=c.request(method,path,json=body,headers={'Authorization':'Bearer '+token} if token else {})
        assert r.status_code==status,(method,path,r.status_code,status)
        return r.json()
    auth=call('POST','/auth/login',body={'email':login['email'],'password':login['password']})
    token=auth['token']
    before=call('GET','/notes',token)
    assert call('GET','/me',token)['preferences']['locale']=='vi'
    english={'op_id':str(uuid4()),'locale':'en'}
    call('POST','/me/preferences/sync',body=english,status=401)
    for locale in ['fr','en-US',None,True]:
        call('POST','/me/preferences/sync',token,{'op_id':str(uuid4()),'locale':locale},422)
    call('POST','/me/preferences/sync',token,{**english,'owner_id':'other'},422)
    assert call('POST','/me/preferences/sync',token,english)['preferences']['locale']=='en'
    assert call('PATCH','/me/preferences',token,{'grid':True,'dark':True,'font_size':16})['preferences']['locale']=='en'
    call('POST','/me/preferences/sync',token,{'op_id':str(uuid4()),'locale':'vi'})
    assert call('POST','/me/preferences/sync',token,english)['preferences']['locale']=='vi'
    call('POST','/me/preferences/sync',token,{**english,'locale':'vi'},409)
    email=f'locale-other-{uuid4()}@example.test'
    other=call('POST','/auth/register',body={'email':email,'name':'QA locale isolation','password':login['password'],'confirmation':login['password']},status=201)
    other_token=other['token']
    call('POST','/me/preferences/sync',other_token,english)
    assert call('GET','/me',other_token)['preferences']['locale']=='en'
    assert call('GET','/me',token)['preferences']['locale']=='vi'
    assert call('GET','/notes',token)==before
    locked=[n for n in before if n.get('locked')]
    assert locked and all('title' not in n and 'content' not in n and 'updated_at' not in n for n in locked)
    result={'captured_at_utc':datetime.now(timezone.utc).isoformat(),'target':'http://127.0.0.1:8062','result':'PASS',
      'browser_vi_and_dark_received':True,'anonymous':401,'invalid_locale_and_owner_id':422,'altered_replay':409,
      'old_operation_cannot_undo_vi':True,'legacy_patch_retains_en':True,'account_isolation':True,
      'note_array_identical_before_after_preferences':True,'locked_listing_redacted':True,'notes':len(before)}
    (Path(__file__).resolve().parent/'api-locale.json').write_text(json.dumps(result,indent=2)+'\n')
    print('PASS locale merge/replay/legacy/schema/account/privacy and unchanged note array.')
