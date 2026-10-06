"""Bind current source/docs, local QA evidence and final build bytes; not a QA rerun."""
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
    for section, base in [('files', ROOT), ('builds', ROOT), ('evidence', HERE)]:
        for filename, expected in saved[section].items():
            assert digest(base / filename) == expected, f'Hash mismatch: {section}/{filename}'
    assert (ROOT / 'README.md').read_bytes() == (ROOT / 'Readme.txt').read_bytes()
    assert subprocess.run(['git','merge-base','--is-ancestor',saved['base_commit'],'HEAD'],cwd=ROOT).returncode == 0
    print(f'PASS integrity: {len(saved["files"])} inputs, {len(saved["evidence"])} evidence files, {len(saved["builds"])} builds; does not rerun tests/QA.')
    raise SystemExit(0)

files = set()
for folder, pattern in [('lib','*.dart'),('backend','*.py'),('test','*.dart'),('integration_test','*.dart'),
                        ('test_driver','*.dart'),('docs','*.md'),('scripts','*.ps1'),('scripts','*.py')]:
    files.update(ROOT.joinpath(folder).rglob(pattern))
for folder in ('assets','web'):
    files.update(p for p in ROOT.joinpath(folder).rglob('*') if p.is_file())
files.update(ROOT / filename for filename in ['README.md','Readme.txt','STATUS.md','AGENTS.md','.env.example','.gitignore',
             'pubspec.yaml','pubspec.lock','analysis_options.yaml','backend/requirements.txt','backend/schema.sql',
             'android/app/src/main/AndroidManifest.xml','android/app/src/debug/AndroidManifest.xml','android/app/build.gradle.kts'])
evidence = {p.relative_to(HERE).as_posix(): digest(p) for p in sorted(HERE.rglob('*'))
            if p.is_file() and p.name not in {'source-manifest.json','manifest-summary.txt','manifest-verify.txt','backend-local.txt','web-local.txt'}}
build_names = ['build/web/main.dart.js','build/web/offline_worker.js','build/app/outputs/flutter-apk/app-release.apk']
saved = {'collected_at_utc':datetime.now(timezone.utc).isoformat(),
         'base_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
         'working_changes':True,
         'files':{p.relative_to(ROOT).as_posix():digest(p) for p in sorted(files)},
         'builds':{filename:digest(ROOT / filename) for filename in build_names},'evidence':evidence,
         'scope':{'host':'143 Flutter/79 backend PASS; analyze clean; 12 new protection host regressions',
                  'web':'IAB local real HTTP protected read/edit/SSE/picker-upload/offline reload/server unlock/same-ID sync; final-build smoke separately',
                  'native':'API36 debug Skia software real HTTP/SSE/platform keys/Sembast offline reopen/revalidate/sync/confirmed delete PASS',
                  'llm':'Gemini NOT RUN; no key saved/used; needs key replacement/configuration',
                  'release':'Web/APK build; default API8000/debug signing, not public or release-functional acceptance'}}
assert (ROOT / 'README.md').read_bytes() == (ROOT / 'Readme.txt').read_bytes()
(HERE / 'source-manifest.json').write_text(json.dumps(saved,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'collected_at_utc':saved['collected_at_utc'],'base_commit':saved['base_commit'],
                  'inputs':len(files),'evidence':len(evidence),'builds':saved['builds'],'live_gemini':False},ensure_ascii=False))
