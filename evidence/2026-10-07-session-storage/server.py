import os
import sys
from pathlib import Path
import uvicorn

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT))
from backend.app import create_app
from backend.email_delivery import DisabledDelivery
class NoAi:
    mode='qa-disabled'
    model='not-used'
    def generate(self,*_): raise AssertionError('No inference in performance QA')
os.environ['WEB_ORIGINS']='http://127.0.0.1:7366,http://localhost:7366'
app=create_app(ROOT/'tmp/performance-2026-10-07/qa.sqlite3',email_delivery=DisabledDelivery(),
               ai_provider=NoAi(),start_email_worker=False)
uvicorn.run(app,host='127.0.0.1',port=8017,access_log=False,log_level='warning')
