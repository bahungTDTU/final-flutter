import sqlite3
from uuid import uuid4

import pytest
from backend.tests.test_security import env, headers, operation, make_note


def protected(client, owner):
    key = make_note(client, owner)
    assert client.post(f'/notes/{key}/protection', headers=headers(owner), json={
        'password':'protected-password-123','confirmation':'protected-password-123'}).status_code == 200
    return key


def unlock(client, user, key):
    assert client.post(f'/notes/{key}/unlock', headers=headers(user), json={'password':'protected-password-123'}).status_code == 200


@pytest.mark.parametrize('role,edit_status,delete_status', [('owner',200,200),('viewer',403,403),('editor',200,403),('stranger',404,404)])
def test_protected_mutations_require_both_grant_and_current_role(env, role, edit_status, delete_status):
    client, app, users = env
    owner, viewer, editor = users
    if role=='stranger':
        actor = client.post('/auth/register', json={'email':f'stranger-{uuid4()}@example.test','name':'Stranger',
            'password':'stranger-password-123','confirmation':'stranger-password-123'}).json()
    else:
        actor = {'owner':owner,'viewer':viewer,'editor':editor}[role]
    key=protected(client,owner)
    for recipient, assigned in ((viewer,'viewer'),(editor,'editor')):
        unlock(client,owner,key)
        assert client.post(f'/notes/{key}/shares',headers=headers(owner),json={'email':recipient['user']['email'],'role':assigned}).status_code==200
    if role in ('owner','editor'):
        client.post(f'/notes/{key}/lock',headers=headers(actor))
        assert client.post('/sync',headers=headers(actor),json=operation(key,2,content='Before unlock')).status_code==423
    if role!='stranger': unlock(client,actor,key)
    before=client.get('/notes',headers=headers(owner)).json()[0]
    assert set(before)=={'id','locked','revision','role','pinned_at','shared'}
    assert before['shared'] is True and before['pinned_at'] is None
    result=client.post('/sync',headers=headers(actor),json=operation(key,2,content='Protected edit',pinned_at='2026-10-05',labels=[]))
    assert result.status_code==edit_status
    revision=3 if edit_status==200 else 2
    if edit_status==200:
        content=client.get(f'/notes/{key}',headers=headers(actor)).json()
        assert content['content']=='Protected edit' and content['locked'] is True and content['protection_version']==1
        assert content['pinned_at']==('2026-10-05' if role=='owner' else None)
    result=client.post('/sync',headers=headers(actor),json=operation(key,revision,kind='delete'))
    assert result.status_code==delete_status
    if delete_status==200:
        assert client.get(f'/notes/{key}',headers=headers(owner)).status_code==404


def test_protected_conflict_idempotency_and_untrusted_flags_do_not_change_protection(env):
    client,app,users=env
    owner=users[0]; key=protected(client,owner); unlock(client,owner,key)
    with sqlite3.connect(app.state.database) as conn:
        before=conn.execute('SELECT password,protection_version,owner_id FROM notes WHERE id=?',(key,)).fetchone()
    op=operation(key,2,content='Frozen protected edit',owner_id=users[1]['user']['id'],locked=False,password=None,role='owner')
    assert client.post('/sync',headers=headers(owner),json=op).json()['revision']==3
    assert client.post('/sync',headers=headers(owner),json=op).json()['revision']==3
    assert client.post('/sync',headers=headers(owner),json=operation(key,2,content='Stale overwrite')).status_code==409
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT password,protection_version,owner_id FROM notes WHERE id=?',(key,)).fetchone()==before
    client.post(f'/notes/{key}/lock',headers=headers(owner))
    assert client.post('/sync',headers=headers(owner),json=op).status_code==423


def test_protected_attachments_edit_read_roles_grant_expiry_and_private_headers(env):
    client,app,users=env
    owner,viewer,editor=users; key=protected(client,owner); unlock(client,owner,key)
    for recipient,role in ((viewer,'viewer'),(editor,'editor')):
        client.post(f'/notes/{key}/shares',headers=headers(owner),json={'email':recipient['user']['email'],'role':role})
        unlock(client,recipient,key)
    file=str(uuid4()); route=f'/notes/{key}/attachments/{file}?name=fixture.txt&kind=file'
    assert client.post(route,headers={**headers(viewer),'Content-Type':'text/plain'},content=b'Protected attachment').status_code==403
    assert client.post(route,headers={**headers(editor),'Content-Type':'text/plain'},content=b'Protected attachment').status_code==200
    result=client.get(f'/notes/{key}/attachments/{file}',headers=headers(viewer))
    assert result.content==b'Protected attachment' and result.headers['cache-control']=='private, no-store'
    with sqlite3.connect(app.state.database) as conn:
        conn.execute('UPDATE grants SET expires=0')
    assert client.get(f'/notes/{key}/attachments/{file}',headers=headers(viewer)).status_code==423
    assert client.delete(f'/notes/{key}/attachments/{file}',headers=headers(editor)).status_code==423
    unlock(client,editor,key)
    assert client.delete(f'/notes/{key}/attachments/{file}',headers=headers(editor)).status_code==200
