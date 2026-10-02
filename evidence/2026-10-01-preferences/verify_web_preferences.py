import json
import sqlite3
from pathlib import Path

with sqlite3.connect('backend/state/app.sqlite3') as db:
    row = db.execute(
        'SELECT id, preferences FROM users WHERE email=?',
        ('web-check-20261001@example.com',),
    ).fetchone()
    assert row is not None
    preferences = json.loads(row[1])
    assert preferences == {'grid': False, 'dark': True, 'font_size': 18.0}, preferences
    operations = db.execute(
        'SELECT COUNT(*) FROM preference_operations WHERE user_id=?', (row[0],)
    ).fetchone()[0]
    assert operations >= 3
result = {
    'observed_on': '2026-10-01',
    'target': 'Chrome / localhost Web release + real FastAPI SQLite',
    'commit': None,
    'preferences': preferences,
    'accepted_preference_operations': operations,
    'result': 'PASS',
}
Path('evidence/2026-10-01-preferences/web-server-confirmation.json').write_text(
    json.dumps(result, indent=2), encoding='utf-8'
)
print('Web preferences SQLite assertions: PASS')
