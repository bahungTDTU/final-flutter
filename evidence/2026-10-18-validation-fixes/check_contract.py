"""Compare actual Dart validation results with actual backend model validation."""
import json
import sys
from pathlib import Path
from uuid import uuid4
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from backend.app import Operation
from pydantic import ValidationError

cases = json.loads(Path('tmp/validation-fixes-contract.json').read_text(encoding='utf-8-sig'))
results = []
for case in cases:
    try:
        Operation(op_id=str(uuid4()), note_id=str(uuid4()), base_revision=0, kind='upsert',
                  title=case['title'], content=case['content'])
        accepted = True
    except ValidationError:
        accepted = False
    assert accepted == case['valid'], case['name']
    results.append({'case': case['name'], 'dart_accepts': case['valid'], 'server_accepts': accepted})
print(json.dumps({'result': 'PASS', 'cases': results, 'scope': 'Dart domain + Pydantic; no HTTP or Flutter runtime'}, indent=2))
