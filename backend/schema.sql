PRAGMA foreign_keys=ON;
CREATE TABLE IF NOT EXISTS users (
 id TEXT PRIMARY KEY, email TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
 password TEXT NOT NULL, verified INTEGER NOT NULL DEFAULT 0,
 preferences TEXT NOT NULL DEFAULT '{}'
);
CREATE TABLE IF NOT EXISTS sessions (
 digest TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id), expires REAL NOT NULL
);
CREATE TABLE IF NOT EXISTS email_tokens (
 digest TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id),
 kind TEXT NOT NULL, expires REAL NOT NULL, used INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS notes (
 id TEXT PRIMARY KEY, owner_id TEXT NOT NULL REFERENCES users(id),
 title TEXT NOT NULL, content TEXT NOT NULL, revision INTEGER NOT NULL,
 updated_at TEXT NOT NULL, pinned_at TEXT, labels TEXT NOT NULL DEFAULT '[]',
 password TEXT, protection_version INTEGER NOT NULL DEFAULT 0, deleted INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS shares (
 note_id TEXT NOT NULL REFERENCES notes(id), user_id TEXT NOT NULL REFERENCES users(id),
 role TEXT NOT NULL CHECK(role IN ('viewer','editor')), shared_at TEXT NOT NULL,
 PRIMARY KEY(note_id,user_id)
);
CREATE TABLE IF NOT EXISTS grants (
 session_digest TEXT NOT NULL REFERENCES sessions(digest) ON DELETE CASCADE,
 note_id TEXT NOT NULL REFERENCES notes(id), version INTEGER NOT NULL, expires REAL NOT NULL,
 PRIMARY KEY(session_digest,note_id)
);
CREATE TABLE IF NOT EXISTS operations (
 user_id TEXT NOT NULL REFERENCES users(id), op_id TEXT NOT NULL,
 fingerprint TEXT NOT NULL, result TEXT NOT NULL, PRIMARY KEY(user_id,op_id)
);
CREATE TABLE IF NOT EXISTS attempts (
 scope TEXT PRIMARY KEY, failures INTEGER NOT NULL, blocked_until REAL NOT NULL
);
CREATE INDEX IF NOT EXISTS notes_owner ON notes(owner_id,deleted);
CREATE TABLE IF NOT EXISTS preference_operations (
 user_id TEXT NOT NULL REFERENCES users(id), op_id TEXT NOT NULL,
 fingerprint TEXT NOT NULL, PRIMARY KEY(user_id,op_id)
);
CREATE INDEX IF NOT EXISTS shares_user ON shares(user_id);
CREATE TABLE IF NOT EXISTS attachments (
 id TEXT PRIMARY KEY, note_id TEXT NOT NULL REFERENCES notes(id),
 created_by TEXT NOT NULL REFERENCES users(id), name TEXT NOT NULL, kind TEXT NOT NULL,
 media_type TEXT NOT NULL, size INTEGER NOT NULL, created_at TEXT NOT NULL,
 fingerprint TEXT NOT NULL, data BLOB, deleted INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS attachments_note ON attachments(note_id,deleted);
CREATE TABLE IF NOT EXISTS share_versions (
 note_id TEXT PRIMARY KEY REFERENCES notes(id) ON DELETE CASCADE, revision INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS share_operations (
 user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE, op_id TEXT NOT NULL, fingerprint TEXT NOT NULL,
 PRIMARY KEY(user_id,op_id)
);
