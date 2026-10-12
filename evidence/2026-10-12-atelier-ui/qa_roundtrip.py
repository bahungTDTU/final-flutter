"""Verify only synthetic QA data; keep session tokens out of evidence."""
import json
import httpx

with httpx.Client(base_url='http://127.0.0.1:8058', timeout=15) as client:
    auth = client.post('/auth/login', json={'email': 'ui-refresh-owner@example.test',
                                           'password': 'safe-password-123'})
    auth.raise_for_status()
    headers = {'Authorization': 'Bearer ' + auth.json()['token']}
    response = client.get('/notes', headers=headers)
    response.raise_for_status()
    notes = response.json()
    edited = next(note for note in notes if note.get('title') == 'Thiết kế NoteTogether · UI mới')
    content = edited['content']
    document_format = 'NTDOC1 Delta' if content.startswith('NTDOC1:') else 'legacy Markdown'
    text = ''.join(operation['insert'] for operation in json.loads(content[7:])) \
        if content.startswith('NTDOC1:') else content
    assert 'Phân tách ý tưởng, nội dung và công việc để dễ theo dõi.' in text
    assert edited['pinned_at'] and edited['shared_count'] == 2
    locked = next(note for note in notes if note.get('locked'))
    assert set(locked) == {'id', 'locked', 'revision', 'role', 'pinned_at', 'shared'}
    print(json.dumps({'result': 'PASS', 'exactEditedTitleOnServer': True,
                      'storedContentFormat': document_format, 'originalContentRetained': True,
                      'pinAndShareRetained': True,
                      'lockedPublicProjection': sorted(locked), 'tokensRecorded': False}))
