"""Read-only project audit: disposable ASGI/SQLite fixtures, no external services."""
import json
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from fastapi.testclient import TestClient
from backend.app import create_app
from backend.email_delivery import DisabledDelivery


class NoInference:
    mode = 'audit-disabled'
    model = 'not-used'

    def generate(self, *_):
        raise AssertionError('Audit must not call LLM')


with tempfile.TemporaryDirectory(prefix='notetogether-audit-') as folder:
    app = create_app(Path(folder) / 'audit.sqlite3', email_delivery=DisabledDelivery(),
                     ai_provider=NoInference(), start_email_worker=False)
    with TestClient(app) as client:
        def register(name):
            response = client.post('/auth/register', json={
                'email': name + '@example.test', 'name': name,
                'password': 'audit-account-password', 'confirmation': 'audit-account-password'})
            assert response.status_code == 201
            return {'Authorization': 'Bearer ' + response.json()['token']}

        owner, viewer, stranger = [register(n) for n in ('owner', 'viewer', 'stranger')]
        note_id = str(uuid4())
        assert client.post('/sync', headers=owner, json={
            'op_id': str(uuid4()), 'note_id': note_id, 'base_revision': 0,
            'kind': 'upsert', 'title': 'Audit fixture', 'content': 'Disposable audit content',
            'pinned_at': '2026-10-07T00:00:00+00:00'}).status_code == 200
        assert client.post(f'/notes/{note_id}/shares', headers=owner,
                           json={'email': 'viewer@example.test', 'role': 'viewer'}).status_code == 200
        before = client.get('/notes', headers=owner).json()[0]
        assert client.post(f'/notes/{note_id}/protection', headers=owner, json={
            'password': 'audit-note-password', 'confirmation': 'audit-note-password'}).status_code == 200
        locked = client.get('/notes', headers=owner).json()[0]
        denied_roles = {
            role: client.post(f'/notes/{note_id}/protection', headers=headers,
                              json={'current_password': 'wrong-password'}).status_code
            for role, headers in [('viewer', viewer), ('stranger', stranger)]}
        attempts = [client.post(f'/notes/{note_id}/unlock', headers=owner,
                               json={'password': 'wrong-password'}).status_code for _ in range(6)]
        bypass = [client.post(f'/notes/{note_id}/protection', headers=owner,
                             json={'current_password': 'wrong-password'}).status_code for _ in range(6)]
        disable = client.post(f'/notes/{note_id}/protection', headers=owner,
                              json={'current_password': 'audit-note-password'}).status_code
        assert attempts == [403] * 5 + [429]
        assert bypass == [403] * 6 and disable == 200
        assert denied_roles == {'viewer': 403, 'stranger': 404}
        result = {
            'measured_at_utc': datetime.now(timezone.utc).isoformat(),
            'target': 'FastAPI TestClient / disposable SQLite / real Argon2; no network/mail/LLM',
            'base_commit': 'f8ff8fa427b3d490255c0522699f1a9650a3cb73 + existing UI working changes',
            'locked_metadata': {'before_has_pin': before['pinned_at'] is not None,
                                'before_shared_count': before['shared_count'],
                                'after_fields': sorted(locked),
                                'pin_shared_removed': 'pinned_at' not in locked and 'shared_count' not in locked},
            'protection_rate_limit': {'unlock_wrong_statuses': attempts,
                                      'protection_wrong_statuses_during_block': bypass,
                                      'correct_protection_during_block': disable,
                                      'other_roles': denied_roles},
        }
        destination = ROOT / 'evidence/2026-10-07-project-audit/probe.json'
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print(json.dumps(result, ensure_ascii=False, indent=2))
