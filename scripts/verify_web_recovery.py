"""Local disposable-account evidence. No credentials/tokens/content in output."""
import json
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / 'evidence' / '2026-10-01-encrypted-recovery'


def call(path, method='GET', body=None, token=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request('http://127.0.0.1:8000' + path,
        data=None if body is None else json.dumps(body).encode(), headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=10) as response:
        return json.load(response)


def main():
    mode = sys.argv[1]
    account = call('/auth/login', 'POST', {
        'email': 'web-vault-20261001@example.com', 'password': 'local-vault-password-123'})
    token = account['token']
    notes = call('/notes', token=token)
    if mode == 'lock':
        assert len(notes) == 1
        original = notes[0]['id']
        call('/notes/' + original + '/protection', 'POST',
             {'password': 'local-note-protection-123', 'confirmation': 'local-note-protection-123'}, token)
        result = {'original_id': original, 'second_session_lock': True}
    elif mode == 'verify':
        original = json.loads((EVIDENCE / 'web-lock.json').read_text())['original_id']
        assert len(notes) == 2
        copies = [n for n in notes if n['id'] != original]
        assert len(copies) == 1
        copy = call('/notes/' + copies[0]['id'], token=token)
        assert copy['title'] == 'Recovered browser copy'
        assert copy['content'] == 'Unfinished browser edit preserved after remote lock'
        result = {'original_id': original, 'copy_id': copy['id'], 'different_id': True,
                  'exact_content': True, 'server_note_count': 2}
    else:
        raise ValueError('Use lock or verify')
    try:
        call('/notes/' + original, token=token)
        raise AssertionError('Locked source was readable')
    except urllib.error.HTTPError as error:
        assert error.code == 423
        result['source_read_status'] = 423
    result['time_utc'] = datetime.now(timezone.utc).isoformat()
    (EVIDENCE / f'web-{mode}.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
