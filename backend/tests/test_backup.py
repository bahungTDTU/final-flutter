from contextlib import closing
import hashlib
import json
import sqlite3
import subprocess
import sys

from fastapi.testclient import TestClient
import pytest

from backend.app import create_app
from backend.backup import backup, restore
from backend.tests.mail_support import RecordingDelivery
from backend.tests.test_security import headers, make_note
from backend.tests.test_attachments import upload


def test_wal_backup_restores_acl_blobs_and_queued_mail_without_touching_source(tmp_path, monkeypatch):
    monkeypatch.delenv('MAIL_OUTBOX_KEY_FILE', raising=False)
    database = tmp_path / 'source.sqlite3'
    app = create_app(database, email_delivery=RecordingDelivery(), start_email_worker=False)
    with closing(sqlite3.connect(database)) as wal, TestClient(app) as client:
        wal.execute('PRAGMA journal_mode=WAL')
        users = []
        for name in ('owner', 'viewer', 'stranger'):
            response = client.post('/auth/register', json={'email': name + '@example.test',
                'name': name, 'password': 'Backup-test-2026!', 'confirmation': 'Backup-test-2026!'})
            assert response.status_code == 201
            users.append(response.json())
        owner, viewer, stranger = users
        note = make_note(client, owner)
        attachment, response = upload(client, owner, note, data=b'Backup private Vietnamese: ghi chu')
        assert response.status_code == 200
        assert client.post(f'/notes/{note}/shares', headers=headers(owner),
                           json={'email': viewer['user']['email'], 'role': 'viewer'}).status_code == 200
        # A live uncommitted transaction must not leak into the consistent snapshot.
        wal.execute('BEGIN IMMEDIATE')
        wal.execute("UPDATE notes SET title='uncommitted' WHERE id=?", (note,))
        manifest = backup(database, tmp_path / 'backup')
        wal.rollback()
        restore(tmp_path / 'backup', tmp_path / 'restored')
        assert database.is_file()
        restored = create_app(tmp_path / 'restored/app.sqlite3', email_delivery=RecordingDelivery(),
                              start_email_worker=False)
        with TestClient(restored) as recovered:
            assert recovered.get(f'/notes/{note}', headers=headers(owner)).json()['title'] == 'Private title'
            url = f'/notes/{note}/attachments/{attachment}'
            binary = recovered.get(url, headers=headers(viewer))
            assert hashlib.sha256(binary.content).digest() == hashlib.sha256(b'Backup private Vietnamese: ghi chu').digest()
            assert recovered.get(url, headers=headers(stranger)).status_code == 404
            assert recovered.delete(url, headers=headers(viewer)).status_code == 403
            assert recovered.get('/me', headers=headers(owner)).status_code == 200
            # Recover the exact pending PRF code using the copied key (test transport only).
            assert restored.state.email_queue.run_once()
            message = restored.state.email_delivery.messages[0]
            assert recovered.post('/auth/verify', json={'token': message['token']}).status_code == 200
        assert set(manifest['sha256']) == {'app.sqlite3', 'app.sqlite3.mail-key'}


def test_no_overwrite_missing_key_and_tamper_detection(tmp_path, monkeypatch):
    monkeypatch.delenv('MAIL_OUTBOX_KEY_FILE', raising=False)
    database = tmp_path / 'source.sqlite3'
    app = create_app(database, email_delivery=RecordingDelivery(), start_email_worker=False)
    with TestClient(app) as client:
        client.post('/auth/register', json={'email': 'backup@example.test', 'name': 'Backup',
                    'password': 'Backup-test-2026!', 'confirmation': 'Backup-test-2026!'})
    destination = tmp_path / 'backup'
    backup(database, destination)
    before = (destination / 'app.sqlite3').read_bytes()
    with pytest.raises(FileExistsError):
        backup(database, destination)
    assert (destination / 'app.sqlite3').read_bytes() == before
    with pytest.raises(FileExistsError):
        restore(destination, tmp_path)
    with pytest.raises(ValueError, match='private key'):
        backup(database, tmp_path / 'missing-key', tmp_path / 'absent-key')
    assert not (tmp_path / 'missing-key/manifest.json').exists()
    (destination / 'app.sqlite3').write_bytes(before + b'tamper')
    with pytest.raises(ValueError, match='hash mismatch'):
        restore(destination, tmp_path / 'tampered-restore')
    assert not (tmp_path / 'tampered-restore').exists()
    manifest = json.loads((destination / 'manifest.json').read_text())
    manifest['sha256']['../outside'] = 'bad'
    (destination / 'manifest.json').write_text(json.dumps(manifest))
    with pytest.raises(ValueError, match='manifest'):
        restore(destination, tmp_path / 'path-traversal')


def test_wrong_32_byte_key_cannot_publish_backup_or_restore_pending_mail(tmp_path, monkeypatch):
    monkeypatch.delenv('MAIL_OUTBOX_KEY_FILE', raising=False)
    database = tmp_path / 'source.sqlite3'
    app = create_app(database, email_delivery=RecordingDelivery(), start_email_worker=False)
    with TestClient(app) as client:
        assert client.post('/auth/register', json={'email': 'queued@example.test', 'name': 'Queued',
            'password': 'Backup-test-2026!', 'confirmation': 'Backup-test-2026!'}).status_code == 201
    original_key = app.state.email_queue.key_path.read_bytes()
    wrong_key = bytes([original_key[0] ^ 1]) + original_key[1:]
    key_path = tmp_path / 'other.mail-key'
    key_path.write_bytes(wrong_key)
    with pytest.raises(ValueError, match='does not match'):
        backup(database, tmp_path / 'bad-backup', key_path)
    assert not (tmp_path / 'bad-backup/manifest.json').exists()
    assert app.state.email_queue.key_path.read_bytes() == original_key

    valid = tmp_path / 'valid-backup'
    backup(database, valid)
    # Hashes alone cannot detect pairing a valid DB with another server's key.
    (valid / 'app.sqlite3.mail-key').write_bytes(wrong_key)
    manifest = json.loads((valid / 'manifest.json').read_text())
    manifest['sha256']['app.sqlite3.mail-key'] = hashlib.sha256(wrong_key).hexdigest()
    (valid / 'manifest.json').write_text(json.dumps(manifest))
    with pytest.raises(ValueError, match='does not match'):
        restore(valid, tmp_path / 'bad-restore')
    assert not (tmp_path / 'bad-restore').exists()


@pytest.mark.parametrize('manifest', [[], None, {'version': 1, 'sha256': None},
                                     {'version': 1, 'sha256': ['app.sqlite3']}])
def test_malformed_manifest_is_rejected_before_creating_restore_target(tmp_path, manifest):
    source = tmp_path / 'backup'
    source.mkdir()
    (source / 'manifest.json').write_text(json.dumps(manifest))
    with pytest.raises(ValueError, match='manifest'):
        restore(source, tmp_path / 'restored')
    assert not (tmp_path / 'restored').exists()
    result = subprocess.run([sys.executable, '-m', 'backend.backup', 'restore',
        '--backup', str(source), '--destination', str(tmp_path / 'cli-restored')],
        capture_output=True, text=True)
    assert result.returncode == 2
    assert 'Traceback' not in result.stderr and str(source) not in result.stderr
    assert not (tmp_path / 'cli-restored').exists()
