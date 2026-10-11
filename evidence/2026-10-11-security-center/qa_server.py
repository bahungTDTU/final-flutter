"""Reusable loopback QA wrapper; use a fresh QA directory/database for each seed."""
import os
from pathlib import Path

os.environ['GEMINI_API_KEY'] = ''
os.environ['GEMINI_API_KEY_FILE'] = ''
os.environ['WEB_ORIGINS'] = 'http://127.0.0.1:7372'

from backend.app import create_app
from backend.email_delivery import DisabledDelivery

# Reproduction helper defaults to ignored tmp/, never evidence or backend/state.
directory = Path(os.environ.get('NOTETOGETHER_SECURITY_QA_DIR', 'tmp/security-center-qa'))
app = create_app(directory / 'qa.sqlite3', email_delivery=DisabledDelivery(), start_email_worker=False)
