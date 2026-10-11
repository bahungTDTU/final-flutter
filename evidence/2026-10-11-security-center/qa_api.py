"""Local HTTP fixtures only. Tokens remain in RAM; never dump responses from auth."""
import json
import sys
from uuid import uuid4

import httpx

ROOT = 'http://127.0.0.1:8055'
PASSWORD = 'safe-password-123'  # Synthetic QA accounts only.


def request(client, method, path, actor=None, body=None, expected=200, headers=None):
    values = dict(headers or {})
    if actor:
        values['Authorization'] = 'Bearer ' + actor['token']
    r = client.request(method, path, headers=values, json=body)
    assert r.status_code == expected, (method, path, r.status_code)
    assert r.headers['Cache-Control'] == 'private, no-store'
    return r.json()


def login(client, name='owner', ua='Mozilla/5.0 Linux Firefox/130.0'):
    return request(client, 'POST', '/auth/login', body={
        'email': 'security-' + name + '@example.test', 'password': PASSWORD,
    }, headers={'User-Agent': ua})


def main():
    with httpx.Client(base_url=ROOT, timeout=10) as client:
        if sys.argv[1] == 'seed':
            users = {}
            for name in ['owner', 'viewer', 'editor', 'stranger']:
                users[name] = request(client, 'POST', '/auth/register', expected=201, body={
                    'email': 'security-' + name + '@example.test', 'name': 'Security QA ' + name,
                    'password': PASSWORD, 'confirmation': PASSWORD,
                })
            owner = users['owner']
            note = str(uuid4())
            def edit(actor, revision=0, expected=200):
                return request(client, 'POST', '/sync', actor, {
                    'op_id': str(uuid4()), 'note_id': note, 'kind': 'upsert', 'base_revision': revision,
                    'title': 'Bản ghi kiểm tra bảo mật', 'content': 'Nội dung thử nghiệm quyền và phiên.',
                }, expected)
            edit(owner)
            for role in ['viewer', 'editor']:
                request(client, 'POST', f'/notes/{note}/shares', owner,
                        {'email': users[role]['user']['email'], 'role': role})
            edit(users['viewer'], 1, 403)
            edit(users['editor'], 1)
            request(client, 'GET', f'/notes/{note}', users['stranger'], expected=404)
            request(client, 'POST', f'/notes/{note}/protection', owner,
                    {'password': 'note-password-123', 'confirmation': 'note-password-123'})
            for name in ['owner', 'viewer', 'editor']:
                rows = request(client, 'GET', '/notes', users[name])
                assert set(rows[0]) == {'id', 'locked', 'revision', 'role', 'pinned_at', 'shared'}
                assert rows[0]['locked'] and rows[0]['shared']
                request(client, 'GET', f'/notes/{note}', users[name], expected=423)
                request(client, 'POST', f'/notes/{note}/unlock', users[name], {'password': 'note-password-123'})
                request(client, 'GET', f'/notes/{note}', users[name])
            owner_handle = request(client, 'GET', '/me/sessions', owner)['sessions'][0]['id']
            assert request(client, 'POST', '/me/sessions/revoke', users['stranger'], {
                'scope': 'one', 'session_id': owner_handle, 'password': PASSWORD,
            }) == {'ok': True, 'revoked': 0}
            request(client, 'GET', '/me', owner)
            # Exercise actual HTTP revocation, grant removal, retry and unchanged other account.
            second = login(client)
            request(client, 'POST', f'/notes/{note}/unlock', second, {'password': 'note-password-123'})
            handle = request(client, 'GET', '/me/sessions', second)['sessions'][0]['id']
            request(client, 'POST', '/me/sessions/revoke', owner,
                    {'scope': 'one', 'session_id': handle, 'password': 'wrong'}, 403)
            assert request(client, 'POST', '/me/sessions/revoke', owner,
                           {'scope': 'one', 'session_id': handle, 'password': PASSWORD})['revoked'] == 1
            request(client, 'GET', '/me', second, expected=401)
            request(client, 'GET', f'/notes/{note}', second, expected=401)
            assert request(client, 'POST', '/me/sessions/revoke', owner,
                           {'scope': 'one', 'session_id': handle, 'password': PASSWORD})['revoked'] == 0
            for name in ['viewer', 'editor', 'stranger']:
                request(client, 'GET', '/me', users[name])
            login(client)  # Browser will have two other sessions available for UI actions.
            print(json.dumps({'result': 'PASS', 'roles': ['owner', 'viewer', 'editor', 'stranger'],
                              'checks': ['owner-only session handles', 'foreign target no-op', 'wrong password 403',
                                         'remote token/grant 401', 'idempotent retry', 'six-field locked projection',
                                         'editor allowed/viewer denied/stranger hidden', 'API no-store headers']}, indent=2))
        elif sys.argv[1] == 'validation':
            marker = 'private-validation-marker'
            r = client.post('/auth/login', json={'email': 'fixture@example.test', 'password': marker * 8})
            assert r.status_code == 422 and marker not in r.text
            assert all(set(e) == {'loc', 'msg', 'type'} for e in r.json()['detail'])
            assert r.headers['cache-control'] == 'private, no-store'
            print(json.dumps({'result': 'PASS', 'status': 422, 'no_secret_input': True,
                              'diagnostic_keys': ['loc', 'msg', 'type']}))
        elif sys.argv[1] == 'revoke-browser':
            actor = login(client, ua='Mozilla/5.0 Android Chrome/130.0')
            before = request(client, 'GET', '/me/sessions', actor)
            result = request(client, 'POST', '/me/sessions/revoke', actor,
                             {'scope': 'others', 'password': PASSWORD})
            after = request(client, 'GET', '/me/sessions', actor)
            assert after['total'] == 1 and after['sessions'][0]['is_current']
            print(json.dumps({'result': 'PASS', 'before': before['total'],
                              'revoked': result['revoked'], 'after': after['total']}))
        else:
            raise ValueError('Unknown QA action')


if __name__ == '__main__':
    main()
