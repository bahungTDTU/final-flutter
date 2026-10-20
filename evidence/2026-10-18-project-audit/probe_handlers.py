"""Socket-free checks of actual synchronous route handlers and SQLite.

Not HTTP/ASGI, browser, native, middleware, or external-provider acceptance.
Uses a fresh disposable DB, never the user's application data.
"""
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
os.environ['GEMINI_API_KEY'] = ''
os.environ['GEMINI_API_KEY_FILE'] = ''
from fastapi import HTTPException
from pydantic import ValidationError
from starlette.requests import Request
from backend.app import create_app, Registration, Operation, Share, Protection, Unlock, digest
from backend.email_delivery import DisabledDelivery

database = ROOT / 'tmp' / f'audit-handlers-{uuid4()}.sqlite'
app = create_app(database, email_delivery=DisabledDelivery(), start_email_worker=False)
routes = {(r.path, m): r.endpoint for r in app.routes if hasattr(r, 'methods') for m in r.methods}
def route(method, path, **kwargs):
    return routes[path, method](**kwargs)
def status(expected, method, path, **kwargs):
    try:
        route(method, path, **kwargs)
    except HTTPException as error:
        assert error.status_code == expected, (path, error.status_code, expected)
    else:
        raise AssertionError((path, 'expected rejection', expected))

users = {}
for role in ('owner', 'viewer', 'editor', 'stranger'):
    user = route('POST', '/auth/register', body=Registration(
        email=f'{role}@example.test', name=role, password='Audit-local-2026!', confirmation='Audit-local-2026!'),
        request=Request({'type': 'http', 'headers': []}))
    users[role] = (user['user']['id'], digest(user['token']))
note_id = str(uuid4())
def operation(**changes):
    return Operation(**dict(dict(op_id=str(uuid4()), note_id=note_id, base_revision=0,
        kind='upsert', title='private title', content='private body'), **changes))
created = route('POST', '/sync', body=operation(), identity=users['owner'])
assert created['revision'] == 1
for role in ('viewer', 'editor'):
    route('POST', '/notes/{note_id}/shares', note_id=note_id,
          body=Share(email=f'{role}@example.test', role=role), identity=users['owner'])
status(403, 'POST', '/sync', body=operation(base_revision=1), identity=users['viewer'])
status(404, 'GET', '/notes/{note_id}', note_id=note_id, identity=users['stranger'])
edited = route('POST', '/sync', body=operation(base_revision=1, content='editor update'), identity=users['editor'])
assert edited['revision'] == 2
route('POST', '/notes/{note_id}/protection', note_id=note_id,
      body=Protection(password='Audit-note-2026!', confirmation='Audit-note-2026!'), identity=users['owner'])
for role in ('owner', 'viewer', 'editor'):
    status(423, 'GET', '/notes/{note_id}', note_id=note_id, identity=users[role])
    listing = route('GET', '/notes', identity=users[role])
    assert set(listing[0]) == {'id', 'locked', 'revision', 'role', 'pinned_at', 'shared'}
route('POST', '/notes/{note_id}/unlock', note_id=note_id, body=Unlock(password='Audit-note-2026!'), identity=users['owner'])
assert route('GET', '/notes/{note_id}', note_id=note_id, identity=users['owner'])['content'] == 'editor update'
route('DELETE', '/notes/{note_id}/shares/{user_id}', note_id=note_id, user_id=users['editor'][0], identity=users['owner'])
status(404, 'GET', '/notes/{note_id}', note_id=note_id, identity=users['editor'])

invalid = {}
for name, changes in {
    '50_family_emoji_title': {'title': '👨‍👩‍👧‍👦' * 50},
    'conflict_copy_of_valid_200_char_title': {'title': 'a' * 200 + ' (bản phục hồi)'},
    '31_labels': {'labels': [str(uuid4()) for _ in range(31)]},
    '100001_plain_content': {'content': 'x' * 100001},
}.items():
    try:
        operation(**changes)
    except ValidationError as error:
        invalid[name] = [{'field': list(e['loc']), 'type': e['type']} for e in error.errors()]
    else:
        raise AssertionError(name)
result = {'date_utc': datetime.now(timezone.utc).isoformat(),
          'scope': 'synchronous route functions + actual SQLite; no HTTP/middleware',
          'acl_result': 'PASS owner/viewer/editor/stranger, locked projection, unlock, revoke',
          'validation_rejections': invalid,
          'network_and_providers_used': False}
print(json.dumps(result, indent=2))
