import json
import statistics
from pathlib import Path

folder=Path('evidence/2026-10-07-performance')
result={}
for topic in ('write','attachments'):
    data={phase:json.loads((folder/f'{topic}-{phase}.json').read_text()) for phase in ('before','after')}
    assert data['before']['target']==data['after']['target']
    keys=('encoded_write_bytes','elapsed_ms','full_account_writes') if topic=='write' else ('elapsed_ms','python_peak_allocated_bytes')
    result[topic]={phase:{key:round(statistics.median(r[key] for r in item['runs']),3) for key in keys}
                   for phase,item in data.items()}
    metric='encoded_write_bytes' if topic=='write' else 'python_peak_allocated_bytes'
    result[topic]['reduction_percent']=round((1-result[topic]['after'][metric]/result[topic]['before'][metric])*100,3)
result['limits']='Warm local host probes only; no FPS, UI frame, network, physical-device latency or RSS claim.'
(folder/'comparison.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
