"""Capture current source/artifacts; verify old QA payloads without rewriting them."""
from datetime import datetime
import hashlib
import json
from pathlib import Path
import re
import subprocess

import httpx

root = Path(__file__).resolve().parents[2]
out = Path(__file__).resolve().parent


def sha(data):
    return hashlib.sha256(data).hexdigest()


def write(name, data):
    (out / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n',
                            encoding='utf-8')


def git(*args):
    return subprocess.run(['git', *args], cwd=root, capture_output=True,
                          text=True, check=True).stdout.strip()


captured = datetime.now().astimezone().isoformat()
base = git('rev-parse', 'HEAD')
branch = git('branch', '--show-current')
paths = [
    '.gitattributes', 'lib/ui/note_inspector.dart', 'lib/ui/note_protection.dart',
    'lib/ui/editor.dart', 'lib/ui/document_workspace.dart', 'test/inspector_ui_test.dart',
    'test/bug_audit_regression_test.dart', 'backend/attachments.py',
    'backend/tests/test_attachment_ranges.py', 'scripts/prepare_web_offline.py',
    'pubspec.yaml', 'pubspec.lock', 'README.md', 'Readme.txt', 'STATUS.md',
    'docs/REQUIREMENTS_MATRIX.md', 'docs/UI_UX_DESIGN.md', 'docs/UI_UX_QA.md',
    'docs/UI_INSPECTOR_REFINEMENT.md',
    'design-system/notetogether-deskbook/pages/note-inspector.md',
]
old_source = json.loads((root / 'evidence/2026-10-12-bug-audit/source_manifest.json')
                        .read_text(encoding='utf-8-sig'))
unchanged = {}
for path in ['backend/attachments.py', 'backend/tests/test_attachment_ranges.py',
             'test/bug_audit_regression_test.dart', 'pubspec.yaml', 'pubspec.lock']:
    actual = sha((root / path).read_bytes().replace(b'\r\n', b'\n'))
    unchanged[path] = actual == old_source['files'][path]['lf_sha256']
assert all(unchanged.values()), unchanged
write('source_manifest.json', {
    'capturedAt': captured, 'base': base, 'branch': branch, 'workingChanges': True,
    'unchangedFromBugAudit': unchanged,
    'stateDataDependenciesAndroidDiff': git('diff', '--name-only', '--', 'lib/state',
                                          'lib/data', 'pubspec.yaml', 'pubspec.lock',
                                          'backend/requirements.txt', 'android').splitlines(),
    'files': {path: {'sha256': sha((root / path).read_bytes()),
                     'lf_sha256': sha((root / path).read_bytes().replace(b'\r\n', b'\n'))}
              for path in paths},
})
assert (root / 'README.md').read_bytes() == (root / 'Readme.txt').read_bytes()

history = []
for folder in ['2026-10-12-ui-system-refresh', '2026-10-12-atelier-ui',
               '2026-10-12-deskbook-layout', '2026-10-12-bug-audit']:
    directory = root / 'evidence' / folder
    previous = json.loads((directory / 'SHA256SUMS.json').read_text(encoding='utf-8-sig'))
    failures = [name for name, expected in previous.items()
                if not (directory / name).is_file()
                or sha((directory / name).read_bytes()) != expected]
    history.append({'folder': folder, 'filesChecked': len(previous), 'failures': failures})
assert all(not row['failures'] for row in history), history
write('historical-integrity.json', {'capturedAt': captured, 'result': 'PASS',
                                   'scope': 'old evidence payload bytes only; source snapshots remain historical',
                                   'snapshots': history})

artifacts = [
    'build/web/main.dart.js', 'build/web/flutter_bootstrap.js', 'build/web/offline_worker.js',
    'build/app/outputs/flutter-apk/app-debug.apk',
    'tmp/inspector-web-2026-10-13/main.dart.js',
    'tmp/inspector-web-2026-10-13/offline_worker.js',
]
cache = {}
for directory in ['build/web', 'tmp/inspector-web-2026-10-13']:
    worker = (root / directory / 'offline_worker.js').read_text(encoding='utf-8')
    cache[directory] = re.search(r'notetogether-static-[0-9a-f]+', worker).group()
write('artifacts.json', {
    'capturedAt': captured, 'defaultWebAPI': 'http://127.0.0.1:8000',
    'qaWebAPI': 'http://127.0.0.1:8058', 'androidRuntime': 'NOT RUN', 'cacheNames': cache,
    'files': {path: {'bytes': (root / path).stat().st_size,
                     'sha256': sha((root / path).read_bytes())} for path in artifacts},
})

with httpx.Client(timeout=15) as client:
    health = client.get('http://127.0.0.1:8000/health')
    served = client.get('http://127.0.0.1:7357/main.dart.js')
    worker = client.get('http://127.0.0.1:7357/offline_worker.js')
assert health.status_code == served.status_code == worker.status_code == 200
assert sha(served.content) == sha((root / 'build/web/main.dart.js').read_bytes())
assert sha(worker.content) == sha((root / 'build/web/offline_worker.js').read_bytes())
write('local-running.json', {'capturedAt': captured, 'result': 'PASS', 'backendHealth': 200,
                           'web': 'http://127.0.0.1:7357', 'servedAssetsMatchBuild': True,
                           'cacheName': cache['build/web'], 'containsUserData': False})

subprocess.run(['git', 'diff', '--check'], cwd=root, check=True, capture_output=True)
payloads = {path.relative_to(out).as_posix(): sha(path.read_bytes())
            for path in sorted(out.rglob('*')) if path.is_file() and path.name != 'SHA256SUMS.json'
            and '__pycache__' not in path.parts}
write('SHA256SUMS.json', payloads)
print(json.dumps({'result': 'PASS', 'sourceFiles': len(paths),
                  'evidenceFiles': len(payloads), 'historicalSnapshots': len(history),
                  'defaultCache': cache['build/web'], 'userAppRetained': True}))
