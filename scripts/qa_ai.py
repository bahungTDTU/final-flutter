"""Verify AI API permissions with the HTTP fixture or real Gemini on disposable data."""
import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import sys
from tempfile import TemporaryDirectory
import traceback
from uuid import uuid4

import httpx

ROOT = Path(__file__).resolve().parents[1]


@contextmanager
def isolated_ai_app():
    sys.path.insert(0, str(ROOT))
    from dotenv import dotenv_values

    from backend.ai import provider_from_environment
    from backend.app import create_app
    from backend.email_delivery import DisabledDelivery

    settings = {key: value for key, value in dotenv_values(ROOT / '.env').items()
                if key.startswith('GEMINI_') and value is not None}
    settings.update({key: value for key, value in os.environ.items() if key.startswith('GEMINI_')})
    provider = provider_from_environment(settings)
    if provider is None:
        raise SystemExit('Gemini is not configured. Set GEMINI_API_KEY in the backend .env first.')
    with TemporaryDirectory(prefix='notetogether-ai-qa-') as directory:
        yield create_app(Path(directory) / 'qa.sqlite3', ai_provider=provider,
                         email_delivery=DisabledDelivery(), start_email_worker=False)


@contextmanager
def qa_client(url):
    if url:
        with httpx.Client(base_url=url, timeout=60) as client:
            yield client
        return

    from fastapi.testclient import TestClient

    with isolated_ai_app() as app, TestClient(app) as client:
        yield client


def run(base, live, *, session_file=Path('tmp/ai-qa-session.json')):
    results = []
    prefix = str(uuid4())
    with qa_client(base) as client:
        def call(method, path, token=None, body=None, expected=200):
            response = client.request(method, path, headers={'Authorization': 'Bearer ' + token} if token else {}, json=body)
            assert response.status_code == expected, f'{method} {path}: expected {expected}, actual {response.status_code}, error={response.json().get("detail", "unknown")}'
            return response.json() if response.content else None

        health = call('GET', '/health')
        if health['email_delivery'] != 'not_configured':
            raise SystemExit('AI QA needs a disposable backend with SMTP disabled. No QA accounts were created.')
        if health['ai'] != 'configured':
            raise SystemExit('AI is not configured on the QA backend. No QA accounts were created.')

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
        results.append('PASS API anonymous/stranger/viewer-write/owner-locked ACL')
        before = call('GET', f'/notes/{first}', tokens['owner'])
        summaries = []
        for role in ('owner', 'viewer', 'editor'):
            summaries.append(call('POST', f'/notes/{first}/ai/summary', tokens[role]))
        deadline = r'\b20(?:\s+tháng\s+|[./-])0?11\b'
        assert all(re.search(deadline, summary['summary'].casefold()) for summary in summaries)
        assert call('GET', f'/notes/{first}', tokens['owner']) == before
        results.append('PASS owner/viewer/editor summary retains deadline and original note')
        result = call('POST', '/ai/questions', tokens['viewer'], {'question': 'Dự án Orion nộp báo cáo khi nào và có ngân sách bao nhiêu?'})
        assert result['sufficient'] and {s['id'] for s in result['sources']} == {first, second}
        assert re.search(deadline, result['answer'].casefold())
        assert re.search(r'\b300(?:[.,\s])?000\b', result['answer'])
        assert 'ORION_LOCKED_CANARY' not in json.dumps(result)
        for source in result['sources']:
            assert call('GET', f'/notes/{source["id"]}', tokens['viewer'])['id'] == source['id']
        no_data = call('POST', '/ai/questions', tokens['viewer'], {'question': 'Quỹ đạo sao Hải Vương có chu kỳ bao lâu?'})
        assert not no_data['sufficient'] and not no_data['sources']
        results.append('PASS answer retains deadline and budget with two openable sources/no-data/locked exclusion')
        call('DELETE', f'/notes/{first}/shares/{users["viewer"]["user"]["id"]}', tokens['owner'])
        call('POST', '/ai/validate', tokens['viewer'], {'sources': [{'id': first, 'revision': 1}]}, expected=404)
        call('POST', f'/notes/{first}/ai/summary', tokens['viewer'], expected=404)
        results.append('PASS revoke invalidates validation and later summary')
        # Store only disposable QA sessions for UI automation, never LLM key; tmp is ignored.
        if not live and session_file is not None:
            session_file.parent.mkdir(parents=True, exist_ok=True)
            session_file.write_text(json.dumps({'users': users, 'notes': [first, second, protected]}, ensure_ascii=False), encoding='utf-8')
        evidence = {'date_utc': datetime.now(timezone.utc).isoformat(), 'base_url': base,
                    'transport': 'HTTP' if base else 'in-process ASGI', 'status': status,
                    'live_llm': live, 'results': results, 'summary': summaries[0]['summary'], 'answer': result,
                    'note_ids': [first, second, protected]}
        return evidence


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--url', help='Use an existing disposable QA backend with SMTP disabled.')
    parser.add_argument('--live', action='store_true',
                        help='Call Gemini with demo notes. Without --url, use .env and a temporary database.')
    parser.add_argument('--serve', type=int, metavar='PORT',
                        help='Serve the temporary Gemini backend on loopback for Web/Android QA.')
    parser.add_argument('--output')
    args = parser.parse_args()
    if args.serve is not None:
        if not args.live or args.url or args.output:
            parser.error('--serve requires --live and cannot be used with --url or --output')
        if not 1024 <= args.serve <= 65535:
            parser.error('--serve requires a port from 1024 to 65535')
        import uvicorn

        with isolated_ai_app() as app:
            uvicorn.run(app, host='127.0.0.1', port=args.serve, access_log=False)
        sys.exit(0)
    if not args.output:
        parser.error('--output is required when running API checks')
    try:
        url = args.url or (None if args.live else 'http://127.0.0.1:8012')
        result = run(url, args.live)
        output = Path(args.output)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
        for line in result['results']:
            print(line)
        print('LIVE GEMINI PASS' if args.live else 'TEST DOUBLE ONLY; real HTTP/ACL PASS, Gemini NOT RUN')
    except Exception as error:
        # Avoid dumping provider/http headers, credentials, session dicts or stack frames.
        frame = traceback.extract_tb(error.__traceback__)[-1]
        print(f'FAIL AI QA: {type(error).__name__} at {Path(frame.filename).name}:{frame.lineno}; no secrets logged.')
        sys.exit(1)
