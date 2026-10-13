"""Only modifies synthetic QA actors on the isolated loopback service."""
import argparse
import json
from uuid import uuid4

import httpx

parser = argparse.ArgumentParser()
parser.add_argument('mode', choices=['dark', 'light', 'share', 'verify'])
args = parser.parse_args()
with httpx.Client(base_url='http://127.0.0.1:8058', timeout=15) as client:
    credentials = client.post('/auth/login', json={
        'email': 'ui-refresh-owner@example.test', 'password': 'safe-password-123'})
    assert credentials.status_code == 200
    headers = {'Authorization': 'Bearer ' + credentials.json()['token']}
    if args.mode in ('dark', 'light'):
        response = client.post('/me/preferences/sync', headers=headers,
                               json={'op_id': str(uuid4()), 'dark': args.mode == 'dark'})
        assert response.status_code == 200
    else:
        note = next(row for row in client.get('/notes', headers=headers).json() if row['locked'])
        assert set(note) == {'id', 'locked', 'revision', 'role', 'pinned_at', 'shared'}
        path = f'/notes/{note["id"]}'
        assert client.post(path + '/unlock', headers=headers, json={'password': 'note-password-123'}).status_code == 200
        if args.mode == 'share':
            for role in ['viewer', 'editor']:
                result = client.post(path + '/shares', headers=headers,
                                     json={'email': f'ui-refresh-{role}@example.test', 'role': role})
                assert result.status_code == 200
        else:
            actual = client.get(path, headers=headers).json()
            assert actual['title'] == 'Bản ghi riêng tư · QA giao diện'
            assert 'Phân tách ý tưởng' in actual['content']
            assert actual['pinned_at'] is not None
            assert actual['shared_count'] == 2
        assert client.post(path + '/lock', headers=headers).status_code == 200
    print(json.dumps({'mode': args.mode, 'result': 'PASS', 'tokensRecorded': False}))
