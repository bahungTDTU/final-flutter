"""Bind the source and real evidence; this does not rerun QA or build a release."""
from datetime import datetime, timezone
from hashlib import sha256
from pathlib import Path
import json
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def digest(path):
    return sha256(path.read_bytes()).hexdigest()


base = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
assert (ROOT / 'README.md').read_bytes() == (ROOT / 'Readme.txt').read_bytes()
if '--verify' in sys.argv:
    saved = json.loads((HERE / 'source-manifest.json').read_text(encoding='utf-8'))
    assert subprocess.run(['git', 'merge-base', '--is-ancestor', saved['base_commit'], base], cwd=ROOT).returncode == 0
    for key, folder in [('files', ROOT), ('evidence', HERE)]:
        for name, expected in saved[key].items():
            assert digest(folder / name) == expected, (key, name)
    print('PASS source/evidence integrity; no QA rerun or release claim.')
    raise SystemExit(0)

files = set()
for folder, pattern in [('lib', '*.dart'), ('test', '*.dart'), ('integration_test', '*.dart'),
                        ('test_driver', '*.dart'), ('backend', '*.py'), ('scripts', '*.py'), ('scripts', '*.ps1')]:
    files.update(p.relative_to(ROOT).as_posix() for p in (ROOT / folder).rglob(pattern) if '__pycache__' not in p.parts)
files.update(p.relative_to(ROOT).as_posix() for p in (ROOT / 'docs').rglob('*.md'))
files.update(['pubspec.yaml', 'pubspec.lock', 'backend/requirements.txt', 'README.md', 'Readme.txt', 'STATUS.md', 'AGENTS.md'])
saved = {
    'date_utc': datetime.now(timezone.utc).isoformat(), 'local_period': '2026-10-06 / 2026-10-07 Asia/Saigon',
    'base_commit': base, 'working_changes': True,
    'files': {name: digest(ROOT / name) for name in sorted(files)},
    'evidence': {p.relative_to(HERE).as_posix(): digest(p) for p in sorted(HERE.rglob('*'))
                 if p.is_file() and p.name not in ['source-manifest.json', 'manifest-verify.txt', 'manifest-summary.txt']},
    'quality': {
        'host': '167 Flutter / 88 backend, format/analyze PASS06/10;6 stronger geometry regressions PASS07/10',
        'web': 'IAB debug; real input/API ack, theme/mobile resize/text/range, protected API ack/relock/expiry',
        'native': 'API36 debug Skia software;3 reused workflows plus teardown PASS46s;8 new PNG',
        'http': 'actual loopback owner/editor/viewer/stranger ACL/stale/revoke/lock PASS',
        'release_physical_screen_reader_fps_external_ai_email': 'NOT RUN',
    },
}
(HERE / 'source-manifest.json').write_text(json.dumps(saved, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'base': base, 'inputs': len(files), 'evidence': len(saved['evidence']), 'release_built': False}))
