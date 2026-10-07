import argparse
import gc
import json
import sqlite3
import sys
import tempfile
import time
import tracemalloc
from contextlib import closing
from datetime import datetime, timezone
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT))
from fastapi.testclient import TestClient
from backend.app import create_app, digest
from backend.email_delivery import DisabledDelivery

class NoAi:
    mode='probe-disabled'
    model='not-used'
    def generate(self,*_): raise AssertionError('No external calls')

parser=argparse.ArgumentParser()
parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args()
with tempfile.TemporaryDirectory(prefix='notetogether-attachment-probe-') as folder:
    app=create_app(Path(folder)/'probe.sqlite3',email_delivery=DisabledDelivery(),ai_provider=NoAi(),start_email_worker=False)
    with closing(sqlite3.connect(app.state.database)) as conn:
        conn.execute('INSERT INTO users(id,email,name,password) VALUES (?,?,?,?)',('owner','owner@example.test','Fixture','unused'))
        conn.execute('INSERT INTO sessions VALUES (?,?,?)',(digest('probe-session'),'owner',time.time()+600))
        conn.execute('INSERT INTO notes(id,owner_id,title,content,revision,updated_at) VALUES (?,?,?,?,1,?)',
          ('note','owner','Fixture','Fixture','2026-10-07'))
        for i in range(10):
            conn.execute('INSERT INTO attachments VALUES (?,?,?,?,?,?,?,?,?,?,0)',
              (str(i),'note','owner',f'file-{i}.txt','file','text/plain',5*1024*1024,'2026-10-07','fixture',b'x'*(5*1024*1024)))
        conn.commit()
    runs=[]
    with TestClient(app) as client:
        for index in range(8):
            gc.collect();tracemalloc.start();start=time.perf_counter()
            response=client.get('/notes/note/attachments',headers={'Authorization':'Bearer probe-session'})
            elapsed=(time.perf_counter()-start)*1000
            peak=tracemalloc.get_traced_memory()[1];tracemalloc.stop()
            assert response.status_code==200 and len(response.json())==10
            assert all(set(n)=={'id','name','kind','media_type','size','created_at'} for n in response.json())
            if index: runs.append({'elapsed_ms':elapsed,'python_peak_allocated_bytes':peak})
    output={'measured_at_utc':datetime.now(timezone.utc).isoformat(),
      'target':'local ASGI TestClient / real temporary SQLite / warm request / tracemalloc',
      'attachments':10,'blob_bytes_each':5*1024*1024,'warmup_excluded':1,'runs':runs,
      'network_or_rss_or_native_latency_measured':False}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(output,indent=2)+'\n')
    print('PASS attachment metadata probe; measurements saved without BLOBs/credentials')
