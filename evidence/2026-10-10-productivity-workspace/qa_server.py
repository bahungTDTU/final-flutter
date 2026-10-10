import os
from pathlib import Path
os.environ['GEMINI_API_KEY'] = ''
os.environ['GEMINI_API_KEY_FILE'] = ''
os.environ['WEB_ORIGINS'] = 'http://127.0.0.1:7363'
from backend.app import create_app
from backend.email_delivery import DisabledDelivery
app = create_app(Path(__file__).parent / 'qa.sqlite3', email_delivery=DisabledDelivery(), start_email_worker=False)
