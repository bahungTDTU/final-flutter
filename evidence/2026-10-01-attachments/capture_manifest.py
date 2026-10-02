"""Capture final local evidence integrity; does not rerun tests or invent commits."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent

def sha(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()

browser = next(json.loads(line) for line in (HERE / 'web-final-source.txt').read_text(encoding='utf-8-sig').splitlines() if line.startswith('{'))
assert browser['sha256'] == sha(ROOT / 'build/web/main.dart.js')
worker = (ROOT / 'build/web/offline_worker.js').read_text(encoding='utf-8')
assert len(browser['caches']) == 1 and f"const CACHE_NAME = '{browser['caches'][0]}';" in worker
assert (ROOT / 'README.md').read_bytes() == (ROOT / 'Readme.txt').read_bytes()
fixture = (HERE / 'attachment-fixture.txt').read_bytes()
assert (HERE / 'browser-saved.txt').read_bytes() == fixture
assert (HERE / 'native-saved-final.txt').read_bytes() == fixture
commit = subprocess.run(['git', 'rev-parse', '--verify', 'HEAD'], cwd=ROOT, capture_output=True, text=True)
sources = [
    ROOT / path for path in [
        'backend/attachments.py', 'backend/app.py', 'backend/schema.sql',
        'backend/tests/test_attachments.py', 'backend/requirements.txt',
        'lib/data/api.dart', 'lib/ui/attachments.dart', 'lib/ui/editor.dart',
        'lib/ui/note_protection.dart', 'lib/state/attachment_session.dart',
        'android/app/src/main/kotlin/vn/edu/notetogether/note_together/MainActivity.kt',
        'test/attachments_test.dart', 'integration_test/attachments_test.dart',
        'pubspec.yaml', 'pubspec.lock', 'README.md', 'Readme.txt', 'STATUS.md',
        'build/web/main.dart.js', 'build/web/offline_worker.js',
        'build/app/outputs/flutter-apk/app-release.apk',
    ]
]
sources += list((ROOT / 'lib/data').glob('attachment*.dart'))
sources += list((ROOT / 'docs').glob('*.md'))
sources += [p for p in HERE.iterdir() if p.is_file() and p.name != 'manifest.json']
rows = [dict(path=p.relative_to(ROOT).as_posix(), bytes=p.stat().st_size, sha256=sha(p)) for p in sorted(set(sources))]
manifest = dict(
    captured_utc=datetime.now(timezone.utc).isoformat(),
    commit=commit.stdout.strip() if commit.returncode == 0 else None,
    scope='Local integrity snapshot, not a test rerun or production acceptance',
    flutter_tests=88, backend_tests=40, native_debug_integration=1,
    web_source=browser, text_export_sha256=hashlib.sha256(fixture).hexdigest(),
    checks='checks.txt + final-format.txt + final-analyze.txt', files=rows,
)
(HERE / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'PASS integrity: {len(rows)} files; Web source/hash, README parity, Web/native exports match; commit={manifest["commit"]}')
