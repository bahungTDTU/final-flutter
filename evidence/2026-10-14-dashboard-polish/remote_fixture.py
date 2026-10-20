import argparse,json
from pathlib import Path
from uuid import uuid4
from datetime import datetime, timezone
import httpx
parser=argparse.ArgumentParser();parser.add_argument('action',choices=['update','lock','reset']);args=parser.parse_args()
fixture=json.loads(Path('tmp/dashboard-2026-10-14/remote-note.json').read_text(encoding='utf-8'))
with httpx.Client(base_url='http://127.0.0.1:8059',timeout=20) as client:
    response=client.post('/auth/login',json={'email':fixture['email'],'password':'Performance-fixture-2026!'});response.raise_for_status()
    client.headers['Authorization']='Bearer '+response.json()['token']
    if args.action=='update':
        notes=client.get('/notes').json();n=next(x for x in notes if x['id']==fixture['note'])
        response=client.post('/sync',json={'op_id':str(uuid4()),'note_id':n['id'],'kind':'upsert','base_revision':n['revision'],'title':n['title'],'content':'Preview đã nhận cập nhật mới — QA_REMOTE_CONTENT_FINAL_20261014.','labels':n['labels'],'labels_format':'ids'})
    elif args.action=='lock':
        response=client.post('/notes/'+fixture['note']+'/protection',json={'password':'Perf-note-2026!','confirmation':'Perf-note-2026!'})
    else:
        response=client.post('/notes/'+fixture['note']+'/protection',json={'current_password':'Perf-note-2026!'})
    response.raise_for_status()
    result={'date_utc':datetime.now(timezone.utc).isoformat(),'action':args.action,'status':response.status_code,'note':fixture['note'],'target':'http://127.0.0.1:8059'}
    Path('evidence/2026-10-14-dashboard-polish/remote-'+args.action+'.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result))
