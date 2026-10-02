"""Read/grant assertions for the disposable browser fixture; no secrets in output."""
import json
import sys
import urllib.error
from datetime import datetime, timezone
from pathlib import Path

from verify_web_recovery import call, ROOT


def status(path, token, method='GET', body=None):
    try:
        call(path, method, body, token)
        return 200
    except urllib.error.HTTPError as error:
        return error.code


def main():
    mode = sys.argv[1]
    if mode not in ['changed', 'final']:
        raise ValueError('Use changed or final after the corresponding browser UI operation')
    session = call('/auth/login', 'POST', {
        'email': 'web-vault-20261001@example.com', 'password': 'local-vault-password-123'})
    token = session['token']
    original = json.loads((ROOT / 'evidence/2026-10-01-encrypted-recovery/web-lock.json').read_text())['original_id']
    notes = call('/notes', token=token)
    assert len(notes) == 2
    copy = next(n for n in notes if n['id'] != original)
    url = '/notes/' + copy['id']
    result = {'mode': mode, 'time_utc': datetime.now(timezone.utc).isoformat(),
              'target': 'Chrome local release localhost:7357 / FastAPI localhost:8000',
              'commit': None, 'original_id': original, 'copy_id': copy['id'], 'note_count': 2}
    assert status('/notes/' + original, token) == 423
    result['original_still_locked'] = True
    if mode == 'changed':
        assert set(copy) == {'id', 'locked', 'revision', 'role'}
        assert copy['revision'] == 3 and copy['role'] == 'owner'
        assert status(url, token) == 423
        assert status(url + '/unlock', token, 'POST', {'password': 'web-note-password-123'}) == 403
        call(url + '/unlock', 'POST', {'password': 'web-next-password-123'}, token)
        content = call(url, token=token)
        call(url + '/lock', 'POST', token=token)
        assert status(url, token) == 423
        result.update({'redacted_metadata': True, 'old_password_status': 403,
                       'new_password_read_status': 200, 'own_relock_read_status': 423})
    else:
        assert copy['locked'] is False and copy['revision'] == 4
        content = call(url, token=token)
        result.update({'disable_read_without_grant': True, 'revision': copy['revision']})
    assert content['title'] == 'Recovered browser copy'
    assert content['content'] == 'Unfinished browser edit preserved after remote lock'
    result['exact_content_preserved'] = True
    call('/auth/logout', 'POST', token=token)
    (ROOT / f'evidence/2026-10-01-note-protection/web-{mode}.json').write_text(
        json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
