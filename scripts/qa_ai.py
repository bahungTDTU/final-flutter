"""Actual HTTP ACL/UI fixtures; --live requires real Gemini, never treats a double as LLM."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import sys
import traceback
from uuid import uuid4

import httpx


def run(base, live):
    results = []
    prefix = str(uuid4())
    with httpx.Client(base_url=base, timeout=60) as client:
        def call(method, path, token=None, body=None, expected=200):
            response = client.request(method, path, headers={'Authorization': 'Bearer ' + token} if token else {}, json=body)
            assert response.status_code == expected, f'{method} {path}: expected {expected}, actual {response.status_code}, error={response.json().get("detail", "unknown")}'
            return response.json() if response.content else None

        def register(role):
            return call('POST', '/auth/register', body={'email': f'ai-{role}-{prefix}@example.test',
                'name': f'AI QA {role}', 'password': 'QaAi-local-2026!', 'confirmation': 'QaAi-local-2026!'}, expected=201)
        users = {role: register(role) for role in ('owner', 'viewer', 'editor', 'stranger')}
        tokens = {role: u['token'] for role, u in users.items()}
        status = call('GET', '/ai/status', tokens['owner'])
        assert status['enabled']
        assert status['provider'] == ('gemini' if live else 'test-double'), status

        def create(title, content):
            key = str(uuid4())
            call('POST', '/sync', tokens['owner'], {'op_id': str(uuid4()), 'note_id': key, 'base_revision': 0,
                'kind': 'upsert', 'title': title, 'content': content})
            return key
        first = create('Dự án Orion — lịch nộp', 'Dự án Orion nộp báo cáo ngày 20 tháng 11 năm 2026. Hùng chuẩn bị giao diện Flutter.')
        second = create('Dự án Orion — ngân sách', 'Ngân sách dự án Orion là 300.000 đồng. Long phụ trách backend và triển khai.')
        protected = create('Dự án Orion — bảo vệ', 'Dự án Orion có mã nhắc việc nội bộ ORION_LOCKED_CANARY.')
        for note in (first, second):
            for role in ('viewer', 'editor'):
                call('POST', f'/notes/{note}/shares', tokens['owner'], {'email': users[role]['user']['email'], 'role': role})
        call('POST', f'/notes/{protected}/protection', tokens['owner'], {'password': 'note-password-123', 'confirmation': 'note-password-123'})
        call('POST', f'/notes/{first}/ai/summary', expected=401)
        call('POST', f'/notes/{first}/ai/summary', tokens['stranger'], expected=404)
        call('POST', f'/notes/{protected}/ai/summary', tokens['owner'], expected=423)
        call('POST', '/sync', tokens['viewer'], {'op_id': str(uuid4()), 'note_id': first, 'base_revision': 1,
             'kind': 'upsert', 'title': 'Illegal', 'content': 'Viewer blocked'}, expected=403)
        results.append('PASS actual HTTP anonymous/stranger/viewer-write/owner-locked ACL')
        before = call('GET', f'/notes/{first}', tokens['owner'])
        summaries = []
        for role in ('owner', 'viewer', 'editor'):
            summaries.append(call('POST', f'/notes/{first}/ai/summary', tokens[role]))
        assert call('GET', f'/notes/{first}', tokens['owner']) == before
        results.append('PASS owner/viewer/editor summary read access and original unchanged')
        result = call('POST', '/ai/questions', tokens['viewer'], {'question': 'Dự án Orion nộp báo cáo khi nào và có ngân sách bao nhiêu?'})
        assert result['sufficient'] and {s['id'] for s in result['sources']} == {first, second}
        assert 'ORION_LOCKED_CANARY' not in json.dumps(result)
        for source in result['sources']:
            assert call('GET', f'/notes/{source["id"]}', tokens['viewer'])['id'] == source['id']
        no_data = call('POST', '/ai/questions', tokens['viewer'], {'question': 'Quỹ đạo sao Hải Vương có chu kỳ bao lâu?'})
        assert not no_data['sufficient'] and not no_data['sources']
        results.append('PASS multi-note sources/open citations/no-data/locked exclusion')
        call('DELETE', f'/notes/{first}/shares/{users["viewer"]["user"]["id"]}', tokens['owner'])
        call('POST', '/ai/validate', tokens['viewer'], {'sources': [{'id': first, 'revision': 1}]}, expected=404)
        call('POST', f'/notes/{first}/ai/summary', tokens['viewer'], expected=404)
        results.append('PASS revoke invalidates validation and later summary')
        # Store only disposable QA sessions for UI automation, never LLM key; tmp is ignored.
        session_file = Path('tmp/ai-qa-session.json')
        session_file.parent.mkdir(exist_ok=True)
        session_file.write_text(json.dumps({'users': users, 'notes': [first, second, protected]}, ensure_ascii=False), encoding='utf-8')
        evidence = {'date_utc': datetime.now(timezone.utc).isoformat(), 'base_url': base, 'status': status,
                    'live_llm': live, 'results': results, 'summary': summaries[0]['summary'], 'answer': result,
                    'note_ids': [first, second, protected]}
        return evidence


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--url', default='http://127.0.0.1:8012')
    parser.add_argument('--live', action='store_true')
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    try:
        result = run(args.url, args.live)
        Path(args.output).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
        for line in result['results']:
            print(line)
        print('LIVE GEMINI PASS' if args.live else 'TEST DOUBLE ONLY; real HTTP/ACL PASS, Gemini NOT RUN')
    except Exception as error:
        # Avoid dumping provider/http headers, credentials, session dicts or stack frames.
        frame = traceback.extract_tb(error.__traceback__)[-1]
        print(f'FAIL AI QA: {type(error).__name__} at {Path(frame.filename).name}:{frame.lineno}; no secrets logged.')
        sys.exit(1)
