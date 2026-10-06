"""Bind implemented source and local QA evidence; no release artifact claim."""
from datetime import datetime, timezone
from hashlib import sha256
import json
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def digest(path):
    return sha256(path.read_bytes()).hexdigest()


if '--verify' in sys.argv:
    saved = json.loads((HERE / 'source-manifest.json').read_text(encoding='utf-8'))
    for section, base in [('files', ROOT), ('evidence', HERE)]:
        for name, expected in saved[section].items():
            assert digest(base / name) == expected, (section, name)
    assert (ROOT / 'README.md').read_bytes() == (ROOT / 'Readme.txt').read_bytes()
    assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip() == saved['base_commit']
    print(f'PASS integrity: {len(saved["files"])} inputs/{len(saved["evidence"])} evidence; no QA rerun or release build claim.')
    raise SystemExit(0)

files = set()
for folder, pattern in [('lib', '*.dart'), ('backend', '*.py'), ('test', '*.dart'), ('integration_test', '*.dart'),
                        ('test_driver', '*.dart'), ('scripts', '*.py'), ('scripts', '*.ps1'), ('docs', '*.md')]:
    files.update(ROOT.joinpath(folder).rglob(pattern))
files.update(ROOT / name for name in ['README.md', 'Readme.txt', 'STATUS.md', 'AGENTS.md', '.gitignore', '.env.example',
                                    'pubspec.yaml', 'pubspec.lock', 'backend/schema.sql', 'backend/requirements.txt'])
excluded = {'source-manifest.json', 'manifest-verify.txt', 'manifest-summary.txt', 'fixture-local.txt', 'web-debug.txt'}
saved = {'collected_at_utc': datetime.now(timezone.utc).isoformat(),
         'base_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
         'working_changes': True,
         'files': {p.relative_to(ROOT).as_posix(): digest(p) for p in sorted(files)},
         'evidence': {p.relative_to(HERE).as_posix(): digest(p) for p in sorted(HERE.rglob('*')) if p.is_file() and p.name not in excluded},
         'scope': {'flutter': '146 full + final7 email regressions PASS/analyze clean', 'backend': '88 PASS',
                   'native': 'API36 debug Skia software actual HTTP/platform keys/Sembast/STARTTLS fixture PASS',
                   'web': 'IAB debug local status/verify/reset-resend/cooldown PASS',
                   'external_email': 'NOT RUN; loopback TLS receipt only', 'release': 'deferred per user, no release build/deploy'}}
assert (ROOT / 'README.md').read_bytes() == (ROOT / 'Readme.txt').read_bytes()
(HERE / 'source-manifest.json').write_text(json.dumps(saved, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'base': saved['base_commit'], 'inputs': len(files), 'evidence': len(saved['evidence']), 'release_built': False}))
