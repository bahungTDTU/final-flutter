import sqlite3
from uuid import uuid4

from backend.tests.test_security import env, headers, make_note
from backend.tests.test_attachments import upload


def test_metadata_listing_and_idempotent_upload_never_materialize_binary_column(env, monkeypatch):
    client, _, users = env
    owner, viewer, stranger = users
    note = make_note(client, owner)
    attachment, accepted = upload(client, owner, note, data=b'x' * (1024 * 1024))
    assert accepted.status_code == 200
    assert client.post(f'/notes/{note}/shares', headers=headers(owner), json={
        'email': viewer['user']['email'], 'role': 'viewer'}).status_code == 200
    loaded = []
    original = sqlite3.connect

    class ObservedConnection(sqlite3.Connection):
        def execute(self, sql, parameters=()):
            cursor = super().execute(sql, parameters)
            if sql.lstrip().upper().startswith('SELECT') and 'FROM attachments' in sql:
                def row_factory(current, values):
                    loaded.append(sum(len(value) for value in values if isinstance(value, bytes)))
                    return sqlite3.Row(current, values)
                cursor.row_factory = row_factory
            return cursor

    monkeypatch.setattr(sqlite3, 'connect', lambda *args, **kwargs: original(*args, factory=ObservedConnection, **kwargs))
    base = f'/notes/{note}/attachments'
    for user in (owner, viewer):
        response = client.get(base, headers=headers(user))
        assert response.status_code == 200 and response.json() == [accepted.json()]
    replay = upload(client, owner, note, id=attachment, data=b'x' * (1024 * 1024))[1]
    assert replay.status_code == 200 and replay.json() == accepted.json()
    assert loaded and sum(loaded) == 0
    assert client.get(base, headers=headers(stranger)).status_code == 404
    assert client.get(base).status_code == 401
    downloaded = client.get(base + '/' + attachment, headers=headers(viewer))
    assert downloaded.content == b'x' * (1024 * 1024)
    assert sum(loaded) == 1024 * 1024  # Actual file download is the binary boundary.
