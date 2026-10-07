from pathlib import Path
import sys, os
import uvicorn

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from backend.app import create_app
from backend.email_delivery import DisabledDelivery

class NeverCalled:
    mode = 'qa-disabled'
    model = 'not-an-llm'
    def generate(self, *_):
        raise AssertionError('No AI calls in protection/status QA')

os.environ['WEB_ORIGINS'] = 'http://127.0.0.1:7365,http://localhost:7365'
app = create_app(ROOT / 'tmp/priorities/qa.sqlite3', email_delivery=DisabledDelivery(),
                 ai_provider=NeverCalled(), start_email_worker=False)
uvicorn.run(app, host='127.0.0.1', port=8016, access_log=False, log_level='warning')
