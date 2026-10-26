"""Check tenant isolation and SQLite work, not flaky wall-clock thresholds."""
import sqlite3
from pathlib import Path

from backend.catalogue import migrate
from backend.note_listing import list_visible_notes


def listing_fixture():
    conn = sqlite3.connect(':memory:')
    conn.row_factory = sqlite3.Row
    conn.executescript(Path('backend/schema.sql').read_text())
    migrate(conn)
    for user in ('owner', 'peer', 'unrelated'):
        conn.execute('INSERT INTO users(id,email,name,password) VALUES (?,?,?,?)',
                     (user, user + '@example.test', user, 'fixture'))
    for index in range(50):
        owner = 'owner' if index < 25 else 'peer'
        conn.execute('INSERT INTO notes(id,owner_id,title,content,revision,updated_at) VALUES (?,?,?,?,1,?)',
                     (f'n{index:02}', owner, 'Title', 'Body', '2026-10-23'))
        if index >= 25:
            conn.execute('INSERT INTO shares VALUES (?,?,?,?)',
                         (f'n{index:02}', 'owner', 'viewer', '2026-10-23'))
    conn.execute("UPDATE notes SET password='locked' WHERE id='n26'")
    conn.execute("UPDATE notes SET deleted=1 WHERE id='n27'")
    conn.execute("INSERT INTO labels VALUES ('label','peer','Visible','visible',1,0)")
    conn.execute('UPDATE notes SET labels=? WHERE owner_id=?', ('["label"]', 'peer'))
    return conn


def add_unrelated(conn, count):
    conn.executemany('INSERT INTO notes(id,owner_id,title,content,revision,updated_at) VALUES (?,?,?,?,1,?)',
                     ((f'other{i}', 'unrelated', 'Private', 'Must not be returned', '2026-10-23')
                      for i in range(count)))


def measured_listing(conn, user='owner'):
    ticks = 0

    def progress():
        nonlocal ticks
        ticks += 1
        return 0

    conn.set_progress_handler(progress, 100)
    try:
        result = list_visible_notes(conn, user)
    finally:
        conn.set_progress_handler(None, 0)
    return result, ticks


def test_listing_work_does_not_scale_with_unrelated_accounts():
    conn = listing_fixture()
    try:
        before, small = measured_listing(conn)
        add_unrelated(conn, 20000)
        after, large = measured_listing(conn)
        assert after == before
        assert len(after) == 49
        assert large <= small + 100, (small, large)
        locked = next(n for n in after if n['id'] == 'n26')
        assert set(locked) == {'id', 'locked', 'revision', 'role', 'pinned_at', 'shared'}
        shared = next(n for n in after if n['id'] == 'n25')
        assert shared['role'] == 'viewer' and shared['labels'] == ['label']
        conn.execute("DELETE FROM shares WHERE note_id='n25' AND user_id='owner'")
        assert 'n25' not in {n['id'] for n in list_visible_notes(conn, 'owner')}
        conn.execute("INSERT INTO users(id,email,name,password) VALUES ('empty','empty@example.test','Empty','fixture')")
        empty, work = measured_listing(conn, 'empty')
        assert empty == [] and work < 100
    finally:
        conn.close()
