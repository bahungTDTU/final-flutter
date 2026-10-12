"""Verify this snapshot plus the unchanged preceding UI snapshot."""
from hashlib import sha256
import json
from pathlib import Path
here=Path(__file__).resolve().parent
root=here.parents[1]
for directory in [here,root/'evidence/2026-10-12-ui-system-refresh',root/'evidence/2026-10-12-atelier-ui']:
    manifest=json.loads((directory/'SHA256SUMS.json').read_text(encoding='utf-8'))
    for relative,expected in manifest.items():
        assert sha256((directory/relative).read_bytes()).hexdigest()==expected,relative
    print(directory.name, len(manifest), 'evidence hashes PASS')
source=json.loads((here/'source_manifest.json').read_text(encoding='utf-8'))
for relative,expected in source['files'].items():
    data=(root/relative).read_bytes()
    assert sha256(data).hexdigest()==expected['sha256'],relative
    assert sha256(data.replace(b'\r\n',b'\n')).hexdigest()==expected['lf_sha256'],relative
assert (root/'README.md').read_bytes()==(root/'Readme.txt').read_bytes()
artifacts=json.loads((here/'artifacts.json').read_text(encoding='utf-8'))
for relative,expected in artifacts['files'].items():
    assert sha256((root/relative).read_bytes()).hexdigest()==expected['sha256'],relative
print(len(source['files']), 'source hashes and default build/APK hashes PASS; README mirrored')
