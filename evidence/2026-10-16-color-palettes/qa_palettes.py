"""Palette acceptance on disposable loopback QA, with no provider or private tokens output."""
import json,hashlib
from pathlib import Path
from uuid import uuid4
from datetime import datetime,timezone
import httpx
root=Path(__file__).resolve().parents[2]
login=json.loads((root/'tmp/palettes-2026-10-16/browser-login.json').read_text())
with httpx.Client(base_url='http://127.0.0.1:8063',timeout=20) as c:
 def call(method,path,token=None,body=None,status=200):
  r=c.request(method,path,json=body,headers={'Authorization':'Bearer '+token} if token else {})
  assert r.status_code==status,(method,path,r.status_code,status)
  return r.json()
 auth=call('POST','/auth/login',body={'email':login['email'],'password':login['password']});token=auth['token']
 current=call('GET','/me',token)['preferences']
 assert current['palette']=='amber' and current['dark'] is True and current['locale']=='en'
 before=call('GET','/notes',token)
 old={'op_id':str(uuid4()),'palette':'ocean'}
 call('POST','/me/preferences/sync',body=old,status=401)
 for value in ('random','Ocean',None,True,1):call('POST','/me/preferences/sync',token,{'op_id':str(uuid4()),'palette':value},422)
 call('POST','/me/preferences/sync',token,{**old,'owner_id':'stranger'},422)
 for palette in ('atelier','ocean','iris','rose','amber','forest'):
  assert call('POST','/me/preferences/sync',token,{'op_id':str(uuid4()),'palette':palette})['preferences']['palette']==palette
 call('POST','/me/preferences/sync',token,old)
 call('POST','/me/preferences/sync',token,{'op_id':str(uuid4()),'palette':'forest'})
 assert call('POST','/me/preferences/sync',token,old)['preferences']['palette']=='forest'
 call('POST','/me/preferences/sync',token,{**old,'palette':'iris'},409)
 legacy=call('PATCH','/me/preferences',token,{'grid':True,'dark':True,'font_size':16})['preferences']
 assert legacy['palette']=='forest' and legacy['locale']=='en'
 other=call('POST','/auth/register',body={'email':f'palette-other-{uuid4()}@example.test','name':'QA other','password':login['password'],'confirmation':login['password']},status=201)
 call('POST','/me/preferences/sync',other['token'],old)
 assert call('GET','/me',other['token'])['preferences']['palette']=='ocean'
 assert call('GET','/me',token)['preferences']['palette']=='forest'
 call('POST','/me/preferences/sync',token,{'op_id':str(uuid4()),**current})
 after=call('GET','/notes',token)
 assert before==after
 locked=[n for n in after if n.get('locked')]
 assert locked and all('title' not in n and 'content' not in n and 'updated_at' not in n for n in locked)
 note=next(n for n in after if n.get('title')=='Kế hoạch học tập')
 body=call('GET','/notes/'+note['id'],token)['content']
 assert 'Bản nháp giữ nguyên khi đổi bảng màu.' in body
 result={'captured_at_utc':datetime.now(timezone.utc).isoformat(),'target':'http://127.0.0.1:8063','result':'PASS',
  'browser_palette_and_dark_and_language_ack':current,'all_six_ids':True,'anonymous':401,'bad_id_and_owner_id':422,'changed_replay':409,
  'old_replay_cannot_undo_newer_palette':True,'legacy_patch_retains_palette_and_language':True,'account_isolation':True,
  'note_array_identical_before_after_preferences':True,'locked_listing_redacted':True,'notes':len(after),'edited_note_revision':note['revision'],
  'edited_body_sha256':hashlib.sha256(body.encode()).hexdigest()}
 (Path(__file__).resolve().parent/'api-palettes.json').write_text(json.dumps(result,indent=2)+'\n')
 print('PASS palette IDs/schema/merge/replay/legacy/account/privacy; browser Amber+dark+English acknowledged, notes unchanged.')
