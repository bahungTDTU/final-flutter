"""Assert the disposable Web account after UI verification/reset via TLS SMTP fixture.

Fixture only: never prints OTP/session values, never sends external email.
Run after the browser sequence documented in INDEX.md, while email_fixture.py runs.
"""
import hashlib
import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[2]
EMAIL = 'web-mail-20261001-1243@example.test'


def call(path, body=None, headers=None, port=8011):
    request = Request(f'http://127.0.0.1:{port}{path}',
                      data=None if body is None else json.dumps(body).encode(),
                      headers={'Content-Type': 'application/json', **(headers or {})})
    try:
        with urlopen(request, timeout=10) as response:
            return response.status, json.load(response)
    except HTTPError as error:
        return error.code, json.load(error)


def main():
    assert call('/health')[1]['email_delivery'] == 'smtp'
    old_status, _ = call('/auth/login', {'email': EMAIL, 'password': 'web-account-password-123'})
    assert old_status == 401
    new_status, login = call('/auth/login', {'email': EMAIL, 'password': 'web-next-password-123'})
    assert new_status == 200
    headers = {'Authorization': 'Bearer ' + login['token']}
    profile_status, profile = call('/me', headers=headers)
    assert profile_status == 200 and profile['verified'] is True
    codes = {}
    for kind in ('verify', 'reset'):
        status, data = call('/code?' + urlencode({'email': EMAIL, 'kind': kind}),
                            port=8026, headers={'X-Email-Fixture': 'local-test-only'})
        assert status == 200
        codes[kind] = data['code']
    verify_status, _ = call('/auth/verify', {'token': codes['verify']})
    check_status, _ = call('/auth/reset/check', {'token': codes['reset']})
    reset_status, _ = call('/auth/reset', {'token': codes['reset'],
                                        'password': 'other-password-123', 'confirmation': 'other-password-123'})
    assert (verify_status, check_status, reset_status) == (400, 400, 400)
    with sqlite3.connect(ROOT / 'tmp/email-fixture/fixture.sqlite3') as connection:
        for code in codes.values():
            row = connection.execute('SELECT used FROM email_tokens WHERE digest=?',
                                     (hashlib.sha256(code.encode()).hexdigest(),)).fetchone()
            assert row == (1,)
            assert code not in str(connection.execute('SELECT * FROM email_tokens').fetchall())
    result = {'date_utc': datetime.now(timezone.utc).isoformat(), 'target': 'local API8011 / SMTP TLS fixture',
              'commit': None, 'account': EMAIL, 'old_password_login': old_status,
              'new_password_login': new_status, 'profile_verified': profile['verified'],
              'verify_reuse': verify_status, 'reset_check_reuse': check_status,
              'reset_reuse': reset_status, 'sqlite_used_and_digest_only': True}
    (Path(__file__).parent / 'web-api-confirmation.json').write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print('PASS: verified account, old password rejected, new password accepted, both codes consumed/digest-only.')


if __name__ == '__main__':
    main()
