import json
from pathlib import Path
from uuid import uuid4
from datetime import datetime,timezone
import httpx
fixture=json.loads(Path('tmp/desk-navigation-2026-10-14/browser-login.json').read_text(encoding='utf-8'))
with httpx.Client(base_url='http://127.0.0.1:8060',timeout=20) as client:
    response=client.post('/auth/login',json={'email':fixture['email'],'password':fixture['password']});response.raise_for_status()
    owner=response.json()
    client.headers['Authorization']='Bearer '+owner['token']
    note=next(n for n in client.get('/notes').json() if n['id']==fixture['note'])
    response=client.post('/sync',json={'op_id':str(uuid4()),'note_id':note['id'],'base_revision':note['revision'],'kind':'upsert','title':'Ý tưởng cho NoteTogether','content':'Một không gian gọn gàng để ghi lại ý tưởng và làm việc cùng nhóm.'});response.raise_for_status()
    response=client.post('/auth/register',json={'email':f'nav-collaborator-{uuid4()}@example.test','name':'QA cộng tác','password':fixture['password'],'confirmation':fixture['password']});response.raise_for_status()
    collaborator=response.json();client.headers['Authorization']='Bearer '+collaborator['token']
    shared=str(uuid4())
    response=client.post('/sync',json={'op_id':str(uuid4()),'note_id':shared,'base_revision':0,'kind':'upsert','title':'Kế hoạch chung của nhóm','content':'Ghi chú tổng hợp để kiểm tra thanh điều hướng và thư viện cộng tác.'});response.raise_for_status()
    response=client.post('/notes/'+shared+'/shares',json={'email':fixture['email'],'role':'editor'});response.raise_for_status()
    result={'date_utc':datetime.now(timezone.utc).isoformat(),'target':'http://127.0.0.1:8060','owned_notes':1,'received_notes':1,'result':'PASS synthetic fixture only'}
    Path('evidence/2026-10-14-desk-navigation/fixture.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result))
