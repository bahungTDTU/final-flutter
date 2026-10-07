"""Real loopback API ACL/attachment QA; disposable browser fixture, not provider acceptance."""
import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse
from uuid import uuid4
import httpx

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--url',default='http://127.0.0.1:8017')
parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args()
assert urlparse(args.url).hostname in ('127.0.0.1','localhost')
PASSWORD='Perf-local-2026!'
with httpx.Client(base_url=args.url,timeout=20) as client:
    def call(method,path,user=None,body=None,status=200,content=None,extra=None):
        response=client.request(method,path,json=body,content=content,
            headers={**({'Authorization':'Bearer '+user['token']} if user else {}),**(extra or {})})
        assert response.status_code==status,(method,path,response.status_code,status)
        return response
    users={role:call('POST','/auth/register',body={'email':f'perf-{role}-{uuid4()}@example.test',
        'name':f'QA {role}','password':PASSWORD,'confirmation':PASSWORD},status=201).json()
        for role in ('owner','editor','viewer','stranger')}
    owner=users['owner'];note=str(uuid4())
    call('POST','/sync',owner,{'op_id':str(uuid4()),'note_id':note,'base_revision':0,
        'kind':'upsert','title':'Browser performance note','content':'Original server content'})
    for role in ('editor','viewer'):
        call('POST',f'/notes/{note}/shares',owner,{'email':users[role]['user']['email'],'role':role})
    attachment=str(uuid4());body=b'Private perf file\n'*32768
    url=f'/notes/{note}/attachments/{attachment}?name=fixture.txt&kind=file'
    first=call('POST',url,owner,content=body,extra={'Content-Type':'text/plain'}).json()
    assert call('POST',url,owner,content=body,extra={'Content-Type':'text/plain'}).json()==first
    listing=f'/notes/{note}/attachments'
    for role in ('owner','editor','viewer'):
        assert call('GET',listing,users[role]).json()==[first]
    call('GET',listing,users['stranger'],status=404);call('GET',listing,status=401)
    call('POST',listing+'/'+str(uuid4())+'?name=viewer.txt&kind=file',users['viewer'],
         content=b'denied',extra={'Content-Type':'text/plain'},status=403)
    second=call('POST',listing+'/'+str(uuid4())+'?name=editor.txt&kind=file',users['editor'],
         content=b'editor data',extra={'Content-Type':'text/plain'}).json()
    binary=call('GET',listing+'/'+attachment,users['viewer'])
    assert hashlib.sha256(binary.content).digest()==hashlib.sha256(body).digest()
    assert binary.headers['cache-control']=='private, no-store'
    call('POST',f'/notes/{note}/protection',owner,{'password':'Perf-note-2026!','confirmation':'Perf-note-2026!'})
    for role in ('owner','editor','viewer'):call('GET',listing,users[role],status=423)
    for role in ('owner','editor'):
        call('POST',f'/notes/{note}/unlock',users[role],{'password':'Perf-note-2026!'})
    call('DELETE',listing+'/'+second['id'],users['editor'])
    call('DELETE',f'/notes/{note}/shares/{users["editor"]["user"]["id"]}',owner)
    call('GET',listing,users['editor'],status=404)
    call('POST',f'/notes/{note}/protection',owner,{'current_password':'Perf-note-2026!'})
    result={'date_utc':datetime.now(timezone.utc).isoformat(),'target':args.url,'result':'PASS',
        'roles':{'owner':'upload/replay/list/grant/private download','editor':'upload/delete/revoke404',
                 'viewer':'read hash200/write403/locked423','stranger':'list404/anonymous401'},
        'attachment_fields':sorted(first),'download_sha256':hashlib.sha256(body).hexdigest(),
        'browser_note':note,'browser_base_revision':3,'real_mail_llm_or_release':False}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,indent=2)+'\n')
    folder=Path('tmp/performance-2026-10-07');folder.mkdir(parents=True,exist_ok=True)
    (folder/'browser-login.json').write_text(json.dumps({'email':owner['user']['email'],'password':PASSWORD,'note':note}))
    print(json.dumps(result))
