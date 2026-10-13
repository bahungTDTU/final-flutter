"""Read-only verification of recorded evidence and the current exact source."""
from hashlib import sha256
import json
from pathlib import Path

here = Path(__file__).resolve().parent
root = here.parents[1]
counts = {}
for directory in [here, *(root / 'evidence' / name for name in [
        '2026-10-12-ui-system-refresh', '2026-10-12-atelier-ui', '2026-10-12-deskbook-layout'])]:
    checksums = json.loads((directory / 'SHA256SUMS.json').read_text(encoding='utf-8'))
    for name, expected in checksums.items():
        assert sha256((directory / name).read_bytes()).hexdigest() == expected, (directory.name, name)
    counts[directory.name] = len(checksums)
sources = json.loads((here / 'source_manifest.json').read_text(encoding='utf-8'))['files']
for name, expected in sources.items():
    data = (root / name).read_bytes()
    assert sha256(data).hexdigest() == expected['sha256'], name
    assert sha256(data.replace(b'\r\n', b'\n')).hexdigest() == expected['lf_sha256'], name
artifacts = json.loads((here / 'artifacts.json').read_text(encoding='utf-8'))['files']
for name, expected in artifacts.items():
    assert sha256((root / name).read_bytes()).hexdigest() == expected['sha256'], name
assert (root / 'README.md').read_bytes() == (root / 'Readme.txt').read_bytes()
print(json.dumps({'result': 'PASS', 'evidenceFiles': counts, 'sourceFiles': len(sources),
                  'artifactFiles': len(artifacts), 'readmeMirrored': True}))
