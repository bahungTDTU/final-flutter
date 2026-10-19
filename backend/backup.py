"""Consistent SQLite + mail-key backups. Restore only into a new directory.

Backups contain private server data and must stay outside Git/public artifacts.
Attachments and avatars are SQLite BLOBs, so no separate uploads tree is needed.
"""
import argparse
from contextlib import closing
from datetime import datetime, timezone
import hashlib
import hmac
import json
import os
from pathlib import Path
import shutil
import sqlite3

from backend.email_queue import derive_mail_code


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def read_database(path):
    return sqlite3.connect(path.resolve().as_uri() + '?mode=ro', uri=True, timeout=15)


def validate_database(path):
    with closing(read_database(path)) as conn:
        if conn.execute('PRAGMA integrity_check').fetchall() != [('ok',)]:
            raise ValueError('SQLite integrity check failed')
        if conn.execute('PRAGMA foreign_key_check').fetchone() is not None:
            raise ValueError('SQLite foreign key check failed')
        # Reject unrelated/empty SQLite files before treating them as a backup.
        for table in ('users', 'notes', 'attachments', 'email_jobs'):
            conn.execute(f'SELECT 1 FROM {table} LIMIT 1')
        return conn.execute('SELECT 1 FROM email_jobs LIMIT 1').fetchone() is not None


def validate_mail_key(database, key):
    if len(key) != 32:
        raise ValueError('Mail key must contain exactly32 bytes')
    with closing(read_database(database)) as conn:
        for user_id, kind, nonce, expected in conn.execute(
                'SELECT user_id,kind,nonce,token_digest FROM email_jobs WHERE nonce IS NOT NULL'):
            code = derive_mail_code(key, user_id, kind, bytes(nonce))
            if not hmac.compare_digest(hashlib.sha256(code.encode()).hexdigest(), expected):
                raise ValueError('Mail key does not match queued mail in the snapshot')


def write_private(path, value):
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'wb') as stream:
        stream.write(value)
        stream.flush()
        os.fsync(stream.fileno())


def copy_private(source, destination):
    fd = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'wb') as target, source.open('rb') as stream:
        shutil.copyfileobj(stream, target)
        target.flush()
        os.fsync(target.fileno())


def backup(database, destination, mail_key=None):
    database, destination = Path(database), Path(destination)
    if not database.is_file():
        raise ValueError('Source database does not exist')
    key = Path(mail_key) if mail_key is not None else Path(str(database) + '.mail-key')
    # mkdir is exclusive; an incomplete previous run is never overwritten.
    destination.mkdir(mode=0o700)
    copy = destination / 'app.sqlite3'
    write_private(copy, b'')
    with closing(read_database(database)) as source, closing(sqlite3.connect(copy)) as target:
        source.backup(target)
    needs_key = validate_database(copy)
    files = {'app.sqlite3': digest(copy)}
    if key.is_file():
        value = key.read_bytes()
        validate_mail_key(copy, value)
        write_private(destination / 'app.sqlite3.mail-key', value)
        files['app.sqlite3.mail-key'] = digest(destination / 'app.sqlite3.mail-key')
    elif needs_key:
        raise ValueError('Mail jobs exist but their private key is unavailable')
    manifest = {'version': 1, 'created_utc': datetime.now(timezone.utc).isoformat(), 'sha256': files}
    write_private(destination / 'manifest.json', json.dumps(manifest, indent=2).encode())
    return manifest


def restore(source, destination):
    source, destination = Path(source), Path(destination)
    manifest = json.loads((source / 'manifest.json').read_text(encoding='utf-8'))
    if not isinstance(manifest, dict):
        raise ValueError('Unsupported backup manifest')
    files = manifest.get('sha256', {})
    if (manifest.get('version') != 1 or not isinstance(files, dict) or set(files) not in (
            {'app.sqlite3'}, {'app.sqlite3', 'app.sqlite3.mail-key'})):
        raise ValueError('Unsupported backup manifest')
    for name, expected in files.items():
        path = source / name
        if path.is_symlink() or not path.is_file() or digest(path) != expected:
            raise ValueError('Backup file hash mismatch or unsafe file')
    needs_key = validate_database(source / 'app.sqlite3')
    if needs_key and 'app.sqlite3.mail-key' not in files:
        raise ValueError('Backup is missing the mail key')
    if 'app.sqlite3.mail-key' in files:
        validate_mail_key(source / 'app.sqlite3', (source / 'app.sqlite3.mail-key').read_bytes())
    destination.mkdir(mode=0o700)
    for name in files:
        copy_private(source / name, destination / name)
    # Recheck the bytes actually restored, not just the source manifest.
    for name, expected in files.items():
        if digest(destination / name) != expected:
            raise ValueError('Restored file hash mismatch')
    validate_database(destination / 'app.sqlite3')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    create = commands.add_parser('backup')
    create.add_argument('--database', required=True)
    create.add_argument('--mail-key')
    create.add_argument('--destination', required=True)
    recover = commands.add_parser('restore')
    recover.add_argument('--backup', required=True)
    recover.add_argument('--destination', required=True)
    args = parser.parse_args()
    try:
        if args.command == 'backup':
            backup(args.database, args.destination, args.mail_key)
        else:
            restore(args.backup, args.destination)
    except (ValueError, OSError, sqlite3.Error) as error:
        # Do not echo paths, SQL data, key bytes or configuration credentials.
        parser.exit(2, f'{args.command} failed ({type(error).__name__}); existing state was not overwritten.\n')
    print(f'PASS {args.command}: integrity/foreign keys/file hashes; private output is not publishable')


if __name__ == '__main__':
    main()
