"""Actual HTTP protected-note ACL/mutation/attachment probe; disposable local users."""
from datetime import datetime, timezone
import json
from pathlib import Path
from uuid import uuid4
import httpx

password='ProtectedQA-local-2026!'
note_password='protected-password-123'
with httpx.Client(base_url='http://127.0.0.1:8000',timeout=15) as api:
    def call(method,path,user=None,body=None,status=200,**kwargs):
        headers={'Authorization':'Bearer '+user['token']} if user else {}
        response=api.request(method,path,headers=headers,json=body,**kwargs)
        assert response.status_code==status, f'{method} {path} returned {response.status_code}, expected {status}'
        return response.json() if response.content and 'application/json' in response.headers.get('content-type','') else response
    users={role:call('POST','/auth/register',body={'email':f'protected-{role}-{uuid4()}@example.test',
        'name':f'Protected QA {role}','password':password,'confirmation':password},status=201) for role in ('owner','viewer','editor','stranger')}
    owner=users['owner']; key=str(uuid4())
    def op(revision,content='Protected original',kind='upsert'):
        return {'op_id':str(uuid4()),'note_id':key,'base_revision':revision,'kind':kind,'title':'Protected QA note',
                'content':content,'pinned_at':'2026-10-05','labels':[],'labels_format':'ids'}
    call('POST','/sync',owner,op(0))
    for role in ('viewer','editor'):
        call('POST',f'/notes/{key}/shares',owner,{'email':users[role]['user']['email'],'role':role})
    call('POST',f'/notes/{key}/protection',owner,{'password':note_password,'confirmation':note_password})
    for role in ('owner','viewer','editor'):
        call('GET',f'/notes/{key}',users[role],status=423)
    call('GET',f'/notes/{key}',users['stranger'],status=404)
    for role in ('owner','viewer','editor'):
        call('POST',f'/notes/{key}/unlock',users[role],{'password':note_password})
    detail=call('GET',f'/notes/{key}',owner)
    assert detail['protection_version']==1 and detail['pinned_at'] and detail['shared_count']==2
    listed=call('GET','/notes',owner)[0]
    assert set(listed)=={'id','locked','revision','role','pinned_at','shared'}
    call('POST','/sync',users['viewer'],op(2,'Illegal viewer'),status=403)
    edit=op(2,'Edited by authorized editor')
    call('POST','/sync',users['editor'],edit)
    assert call('POST','/sync',users['editor'],edit)['revision']==3
    call('POST','/sync',owner,op(2,'Stale owner'),status=409)
    assert call('GET',f'/notes/{key}',owner)['content']=='Edited by authorized editor'
    call('POST','/sync',users['editor'],op(3,kind='delete'),status=403)
    file=str(uuid4())
    route=f'/notes/{key}/attachments/{file}?name=protected.txt&kind=file'
    r=api.post(route,headers={'Authorization':'Bearer '+users['editor']['token'],'Content-Type':'text/plain'},content=b'Protected fixture attachment')
    assert r.status_code==200
    binary=api.get(f'/notes/{key}/attachments/{file}',headers={'Authorization':'Bearer '+users['viewer']['token']})
    assert binary.content==b'Protected fixture attachment'
    assert binary.headers['cache-control']=='private, no-store'
    call('DELETE',f'/notes/{key}/attachments/{file}',users['viewer'],status=403)
    call('DELETE',f'/notes/{key}/attachments/{file}',users['editor'])
    call('DELETE',f'/notes/{key}/shares/{users["editor"]["user"]["id"]}',owner)
    call('POST','/sync',users['editor'],op(3,'After revoke'),status=404)
    call('POST',f'/notes/{key}/protection',owner,{'current_password':note_password,'password':'new-protected-password-123','confirmation':'new-protected-password-123'})
    call('GET',f'/notes/{key}',owner,status=423)
    call('POST',f'/notes/{key}/unlock',owner,{'password':'new-protected-password-123'})
    call('POST','/sync',owner,op(4,kind='delete'))
    call('GET',f'/notes/{key}',owner,status=404)
    # A separate intact note for actual browser UI; no session/token copied to evidence.
    ui_id=str(uuid4())
    ui=op(0,'Protected UI initial content'); ui['op_id']=str(uuid4()); ui['note_id']=ui_id
    call('POST','/sync',owner,ui)
    for role in ('viewer','editor'):
        call('POST',f'/notes/{ui_id}/shares',owner,{'email':users[role]['user']['email'],'role':role})
    call('POST',f'/notes/{ui_id}/protection',owner,{'password':note_password,'confirmation':note_password})
    Path('tmp/protected-qa-session.json').write_text(json.dumps({'users':users,'note':ui_id},ensure_ascii=False),encoding='utf-8')
    output={'date_utc':datetime.now(timezone.utc).isoformat(),'url':'http://127.0.0.1:8000','note_id':key,'ui_note_id':ui_id,
            'results':['PASS actual HTTP owner/viewer/editor/stranger locked + grant + minimal list',
                       'PASS protected edit/replay/frozen revision409/viewer and editor-delete denied',
                       'PASS private attachment upload/read/delete role rules',
                       'PASS revoke/password change invalidates grant/owner confirmed delete']}
    Path('evidence/2026-10-05-protected-notes/http-api.json').write_text(json.dumps(output,indent=2),encoding='utf-8')
    for line in output['results']: print(line)
