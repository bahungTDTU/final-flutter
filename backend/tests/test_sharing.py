import sqlite3
from uuid import uuid4

from fastapi.testclient import TestClient
import pytest

from backend.app import create_app
from backend.tests.test_security import env, headers, operation, make_note


def mutation(base, action='add', **fields):
    return dict(op_id=str(uuid4()), base_revision=base, action=action, **fields)


def test_batch_owner_catalogue_recipient_metadata_and_roles(env):
    client, _, users = env
    owner, viewer, editor = users
    note = make_note(client, owner)
    url = f'/notes/{note}/shares'
    payload = mutation(0, recipients=[{'email':viewer['user']['email'], 'role':'viewer'}, {'email':editor['user']['email'],'role':'editor'}])
    response = client.post(url+'/sync', headers=headers(owner), json=payload)
    assert response.status_code == 200 and response.headers['cache-control']=='private, no-store'
    rows = response.json()['recipients']
    assert len(rows)==2 and rows[0]['shared_at']==rows[1]['shared_at']
    assert client.get(url, headers=headers(owner)).json()==response.json()
    assert client.get(url).status_code==401
    for user in (viewer, editor):
        assert client.get(url, headers=headers(user)).status_code==403
        assert client.post(url+'/sync', headers=headers(user), json=mutation(1,'revoke',user_id=viewer['user']['id'])).status_code==403
        result=client.get(f'/notes/{note}', headers=headers(user)).json()
        assert result['shared_by']['email']==owner['user']['email'] and result['shared_at']==rows[0]['shared_at']
        assert 'shared_count' not in result
    assert client.post('/sync',headers=headers(viewer),json=operation(note,1)).status_code==403
    assert client.post('/sync',headers=headers(editor),json=operation(note,1,content='Editor content')).status_code==200
    result=client.get(f'/notes/{note}',headers=headers(owner)).json()
    assert result['shared_count']==2 and result['revision']==2
    assert client.post('/sync',headers=headers(editor),json=operation(note,2,kind='delete')).status_code==403


@pytest.mark.parametrize('emails,status', [
    (['recipient@example.com','absent@example.com'],404),
    (['recipient@example.com','RECIPIENT@example.com'],422),
    (['owner@example.com'],422),
    (['bad-email'],422),
], ids=['atomic-absent','duplicate-casefold','self','invalid'])
def test_batch_validation_never_partially_grants(env, emails, status):
    client, app, users=env
    note=make_note(client,users[0])
    response=client.post(f'/notes/{note}/shares/sync',headers=headers(users[0]),json=mutation(0,recipients=[{'email':e,'role':'viewer'} for e in emails]))
    assert response.status_code==status
    with sqlite3.connect(app.state.database) as conn:
        assert conn.execute('SELECT COUNT(*) FROM shares').fetchone()[0]==0
        assert conn.execute('SELECT COUNT(*) FROM share_operations').fetchone()[0]==0


def test_cas_replay_cannot_restore_revoked_permissions_and_restart(env):
    client, app, users=env
    owner, recipient, stranger=users
    note=make_note(client,owner)
    url=f'/notes/{note}/shares'
    add=mutation(0,recipients=[{'email':recipient['user']['email'],'role':'viewer'}])
    assert client.get(url,headers=headers(stranger)).status_code==404
    first=client.post(url+'/sync',headers=headers(owner),json=add).json()
    shared_at=first['recipients'][0]['shared_at']
    change=mutation(1,'role',user_id=recipient['user']['id'],role='editor')
    assert client.post(url+'/sync',headers=headers(owner),json=change).json()['revision']==2
    assert client.post(url+'/sync',headers=headers(owner),json=mutation(1,'role',user_id=recipient['user']['id'],role='viewer')).status_code==409
    revoke=mutation(2,'revoke',user_id=recipient['user']['id'])
    assert client.post(url+'/sync',headers=headers(owner),json=revoke).json()['recipients']==[]
    with TestClient(create_app(app.state.database)) as restarted:
        replay=restarted.post(url+'/sync',headers=headers(owner),json=add)
        assert replay.status_code==200 and replay.json()=={'revision':3,'recipients':[]}
        assert restarted.get(f'/notes/{note}',headers=headers(recipient)).status_code==404
        altered={**add,'recipients':[{'email':stranger['user']['email'],'role':'viewer'}]}
        assert restarted.post(url+'/sync',headers=headers(owner),json=altered).status_code==409
        assert restarted.get(f'/notes/{note}',headers=headers(owner)).json()['revision']==1
    assert shared_at


def test_locked_catalogue_grants_metadata_and_legacy_invalidates_cas(env):
    client, _, users=env
    owner, recipient, _=users
    note=make_note(client,owner)
    url=f'/notes/{note}'
    client.post(url+'/shares',headers=headers(owner),json={'email':recipient['user']['email'],'role':'editor'})
    initial=client.get(url+'/shares',headers=headers(owner)).json()
    client.post(url+'/protection',headers=headers(owner),json={'password':'note-password-123','confirmation':'note-password-123'})
    assert client.get(url+'/shares',headers=headers(owner)).status_code==423
    assert client.get('/notes',headers=headers(recipient)).json()==[{'id':note,'locked':True,'revision':2,'role':'editor'}]
    client.post(url+'/unlock',headers=headers(owner),json={'password':'note-password-123'})
    client.post(url+'/unlock',headers=headers(recipient),json={'password':'note-password-123'})
    stale=mutation(initial['revision'],'role',user_id=recipient['user']['id'],role='viewer')
    client.post(url+'/shares',headers=headers(owner),json={'email':recipient['user']['email'],'role':'viewer'})
    assert client.get(url,headers=headers(recipient)).status_code==423
    assert client.post(url+'/shares/sync',headers=headers(owner),json=stale).status_code==409
    client.post(url+'/lock',headers=headers(owner))
    assert client.post(url+'/shares/sync',headers=headers(owner),json=stale).status_code==423


def test_share_payload_cannot_assign_owner_and_add_existing_needs_role_action(env):
    client, _, users=env
    owner, other, _=users
    note=make_note(client,owner)
    url=f'/notes/{note}/shares/sync'
    add=mutation(0,recipients=[{'email':other['user']['email'],'role':'viewer'}])
    assert client.post(url,headers=headers(owner),json={**add,'owner_id':other['user']['id']}).status_code==422
    assert client.post(url,headers=headers(owner),json=add).status_code==200
    assert client.post(url,headers=headers(owner),json=mutation(1,recipients=add['recipients'])).status_code==409
    assert client.get(f'/notes/{note}',headers=headers(owner)).json()['owner_id']==owner['user']['id']
