"""Reproduce isolated loopback QA with a fresh --db file; never a production DB."""
import argparse
import os
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
os.environ['GEMINI_API_KEY'] = ''
os.environ['GEMINI_API_KEY_FILE'] = ''
os.environ['WEB_ORIGINS'] = 'http://127.0.0.1:7380'

from backend.app import create_app
from backend.email_delivery import DisabledDelivery
import uvicorn

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--db', required=True, help='A new SQLite file under tmp for synthetic fixtures')
    args = parser.parse_args()
    database = Path(args.db).resolve()
    task_root = Path(__file__).resolve().parents[2] / 'tmp'
    if not database.is_relative_to(task_root.resolve()) or database.exists():
        parser.error('Use a fresh database path under the workspace tmp folder')
    database.parent.mkdir(parents=True, exist_ok=True)
    app = create_app(database, email_delivery=DisabledDelivery(), start_email_worker=False)
    uvicorn.run(app, host='127.0.0.1', port=8062, access_log=False)
