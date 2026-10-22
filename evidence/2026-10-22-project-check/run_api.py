"""Run existing HTTP ACL QA against an isolated, provider-free local server."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import httpx

root = Path(__file__).resolve().parents[2]
output = Path(__file__).resolve().parent
environment = os.environ.copy()
environment.pop('MAIL_OUTBOX_KEY_FILE', None)
with tempfile.TemporaryDirectory(prefix='project-check-', dir=root / 'tmp') as folder:
    database = str(Path(folder) / 'qa.sqlite3')
    code = ('import uvicorn; from backend.app import create_app; '
            'from backend.tests.mail_support import RecordingDelivery; '
            f'app=create_app({database!r},email_delivery=RecordingDelivery(),'
            'start_email_worker=False); app.state.ai_provider=None; '
            'uvicorn.run(app,host="127.0.0.1",port=8077,log_level="warning")')
    with (output / 'api-server.txt').open('w') as log:
        server = subprocess.Popen([sys.executable, '-c', code], cwd=root,
                                  env=environment, stdout=log, stderr=log)
        try:
            for _ in range(60):
                if server.poll() is not None:
                    raise RuntimeError('QA server exited')
                try:
                    if httpx.get('http://127.0.0.1:8077/health').status_code == 200:
                        break
                except httpx.TransportError:
                    time.sleep(0.5)
            else:
                raise RuntimeError('QA server did not become ready')
            subprocess.run([sys.executable, 'scripts/qa_protected_notes.py',
                            '--url', 'http://127.0.0.1:8077', '--output',
                            str(output / 'http-roles.json')], cwd=root, check=True)
        finally:
            server.terminate()
            server.wait(timeout=15)
