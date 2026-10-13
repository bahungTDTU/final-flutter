from backend.tests.test_attachments import upload
from backend.tests.test_security import env, headers, make_note


def test_attachment_range_large_offsets_are_bounded_without_server_errors(env):
    client, _, users = env
    owner, viewer, stranger = users
    note = make_note(client, owner)
    attachment, accepted = upload(client, owner, note, data=b'private file')
    assert accepted.status_code == 200
    url = f'/notes/{note}/attachments/{attachment}'
    client.post(f'/notes/{note}/shares', headers=headers(owner),
                json={'email': viewer['user']['email'], 'role': 'viewer'})
    huge = '9' * 5000  # Exceeds Python's integer conversion limit.
    cases = [
        ('bytes=2-' + huge, 206, b'ivate file', 'bytes 2-11/12'),
        ('bytes=-' + huge, 206, b'private file', 'bytes 0-11/12'),
        ('bytes=' + huge + '-', 416, None, 'bytes */12'),
        ('bytes=' + '0' * 5000 + '2-5', 206, b'ivat', 'bytes 2-5/12'),
    ]
    for value, status, content, content_range in cases:
        response = client.get(url, headers={**headers(viewer), 'Range': value})
        assert response.status_code == status
        assert response.headers['content-range'] == content_range
        assert response.headers['cache-control'] == 'private, no-store'
        if content is not None:
            assert response.content == content
    assert client.get(url, headers={**headers(stranger), 'Range': 'bytes=2-' + huge}).status_code == 404
