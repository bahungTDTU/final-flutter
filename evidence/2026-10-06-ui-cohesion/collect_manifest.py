"""Bind this working source/evidence snapshot; never imply a release or QA rerun."""
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

base = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
assert (ROOT / 'README.md').read_bytes() == (ROOT / 'Readme.txt').read_bytes()
if '--verify' in sys.argv:
    saved = json.loads((HERE / 'source-manifest.json').read_text(encoding='utf-8'))
    assert subprocess.run(['git', 'merge-base', '--is-ancestor', saved['base_commit'], base],
                          cwd=ROOT, check=False).returncode == 0
    for key, root in [('files', ROOT), ('evidence', HERE)]:
        for name, expected in saved[key].items():
            assert digest(root / name) == expected, (key, name)
    print(f'PASS integrity: {len(saved["files"])} inputs/{len(saved["evidence"])} evidence; snapshot only, no QA rerun/release claim.')
    raise SystemExit(0)

files = set()
for folder, pattern in [('lib', '*.dart'), ('test', '*.dart'), ('integration_test', '*.dart'),
                        ('test_driver', '*.dart'), ('backend', '*.py'), ('scripts', '*.py'),
                        ('scripts', '*.ps1'), ('docs', '*.md')]:
    files.update((ROOT / folder).rglob(pattern))
files.update((ROOT / 'assets/fonts').rglob('*'))
files = {p for p in files if p.is_file()}
files.update(ROOT / name for name in ['README.md', 'Readme.txt', 'STATUS.md', 'AGENTS.md',
    'pubspec.yaml', 'pubspec.lock', 'backend/schema.sql', 'backend/requirements.txt', '.gitignore', '.env.example'])
exclude = {'source-manifest.json', 'manifest-verify.txt', 'manifest-summary.txt', 'web-debug.txt', 'web-final.txt'}
saved = {'collected_at_utc': datetime.now(timezone.utc).isoformat(), 'base_commit': base,
    'working_changes': True,
    'files': {p.relative_to(ROOT).as_posix(): digest(p) for p in sorted(files)},
    'evidence': {p.relative_to(HERE).as_posix(): digest(p) for p in sorted(HERE.rglob('*'))
                 if p.is_file() and p.name not in exclude},
    'scope': {'flutter': '161 full PASS;6 new regressions;format78/analyze clean',
              'backend': '88 PASS;one upstream deprecation warning',
              'web': 'IAB local debug responsive/gallery/editor/theme/AI input/protected unlock/tail search/remote lock cached Home PASS',
              'native': 'API36 debug Skia software3 reused workflows + teardown PASS47s;actual API/keys/encrypted Sembast/offline/SSE',
              'benchmark': 'isolated host NotoSans test engine11 medians;paragraph4279->165us,prefix query348926->388us,cached10us;not FPS',
              'release': 'deferred;not built/pushed/deployed',
              'external_ai_email_physical_screen_reader_fps': 'NOT RUN in this increment'}}
(HERE / 'source-manifest.json').write_text(json.dumps(saved, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'base': base, 'inputs': len(files), 'evidence': len(saved['evidence']), 'release_built': False}))
