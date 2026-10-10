"""Isolated loopback UI QA; provider is an explicit test double, never Gemini."""
import os
from pathlib import Path
import sys

ROOT = Path(r'D:\flutter cuoi ki')
sys.path.insert(0, str(ROOT))
os.environ['WEB_ORIGINS'] = 'http://127.0.0.1:7360'
os.environ['GEMINI_API_KEY'] = ''
os.environ['GEMINI_API_KEY_FILE'] = ''
os.environ['SMTP_HOST'] = ''

import uvicorn
from backend.app import create_app
from scripts.ai_fixture import FixtureProvider

if __name__ == '__main__':
    folder = Path(__file__).parent / 'theme-2026-10-09'
    folder.mkdir(exist_ok=True)
    app = create_app(folder / 'qa.sqlite3', ai_provider=FixtureProvider(), start_email_worker=False)
    print('LOCAL theme QA 8022, explicit fixture-not-an-llm, email worker disabled.', flush=True)
    uvicorn.run(app, host='127.0.0.1', port=8022, access_log=False)
