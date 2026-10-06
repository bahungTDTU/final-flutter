"""Real HTTP + TLS sink acceptance. Local disposable data, not Internet delivery."""
from datetime import datetime, timezone
import json
from pathlib import Path
import time
from uuid import uuid4
import httpx


def main():
    prefix = str(uuid4())
    password = 'Email-queue-QA-2026!'
    with httpx.Client(base_url='http://127.0.0.1:8011', timeout=8) as api:
        def call(method, path, user=None, body=None, status=200):
            response = api.request(method, path, headers={'Authorization': 'Bearer ' + user['token']} if user else {}, json=body)
            assert response.status_code == status, (path, response.status_code)
            return response.json()
        def code(email, kind):
            for _ in range(100):
                reply = httpx.get('http://127.0.0.1:8026/code', params={'email': email, 'kind': kind},
                                  headers={'X-Email-Fixture': 'local-test-only'})
                if reply.status_code == 200:
                    return reply.json()['code']
                time.sleep(.2)
            raise AssertionError('TLS sink acceptance timed out')
        users = {role: call('POST', '/auth/register', body={
            'email': f'mail-{role}-{prefix}@example.test', 'name': 'Mail QA ' + role,
            'password': password, 'confirmation': password}, status=201) for role in ('owner', 'viewer', 'editor', 'stranger')}
        owner = users['owner']
        assert owner['email_delivery'] == 'queued' and owner['user']['verified'] is False
        email = owner['user']['email']
        received = code(email, 'verify')
        assert call('GET', '/auth/email-status', owner)['email_delivery'] == 'smtp_accepted'
        assert received not in json.dumps(call('GET', '/auth/email-status', owner))
        call('GET', '/auth/email-status', status=401)
        note = str(uuid4())
        def op(base, text):
            return {'note_id': note, 'op_id': str(uuid4()), 'base_revision': base, 'kind': 'upsert',
                    'title': 'Email queue role QA', 'content': text}
        call('POST', '/sync', owner, op(0, 'Unverified notes remain usable'))
        for role in ('viewer', 'editor'):
            call('POST', f'/notes/{note}/shares', owner, {'email': users[role]['user']['email'], 'role': role})
        call('POST', '/sync', users['viewer'], op(1, 'Forbidden'), status=403)
        call('GET', f'/notes/{note}', users['stranger'], status=404)
        call('POST', '/sync', users['editor'], op(1, 'Editor can still edit'))
        call('POST', '/auth/verify', body={'token': received})
        call('POST', '/auth/verify', body={'token': received}, status=400)
        assert call('GET', '/auth/email-status', owner)['email_delivery'] == 'already_verified'
        known = call('POST', '/auth/forgot', body={'email': email})
        unknown = call('POST', '/auth/forgot', body={'email': 'absent-' + prefix + '@example.test'})
        assert known == unknown
        reset = code(email, 'reset')
        call('POST', '/auth/reset/check', body={'token': reset})
        result = call('POST', '/auth/reset', body={'token': reset, 'password': password + 'next', 'confirmation': password + 'next'})
        assert result == {'ok': True, 'login_required': True}
        call('GET', '/me', owner, status=401)
        call('POST', '/auth/login', body={'email': email, 'password': password + 'next'})
        output = {'date_utc': datetime.now(timezone.utc).isoformat(), 'api': 'http://127.0.0.1:8011',
                  'transport': 'actual SMTP STARTTLS loopback sink, no external delivery',
                  'results': ['PASS queued registration + private status + actual TLS receipt',
                              'PASS unverified notes + owner/viewer/editor/stranger ACL',
                              'PASS verify one-time + public reset no-enumeration + session revoke/manual login']}
        Path('evidence/2026-10-06-email-queue/http.json').write_text(json.dumps(output, indent=2), encoding='utf-8')
        for line in output['results']:
            print(line)


if __name__ == '__main__':
    main()
