"""Read-only hashing of current workspace inputs; writes this evidence manifest only."""
import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git(*args):
    result = subprocess.run(['git', *args], cwd=ROOT, capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None


if '--verify' in sys.argv:
    saved = json.loads((HERE / 'source-manifest.json').read_text(encoding='utf-8'))
    for section, base in [('files', ROOT), ('builds', ROOT), ('evidence', HERE)]:
        for name, expected in saved[section].items():
            assert sha(base / name) == expected, f'Hash mismatch: {section}/{name}'
    assert (ROOT / 'README.md').read_bytes() == (ROOT / 'Readme.txt').read_bytes()
    assert subprocess.run(['git', 'merge-base', '--is-ancestor', saved['base_commit'], 'HEAD'], cwd=ROOT).returncode == 0
    print(f'PASS integrity: {len(saved["files"])} source/docs inputs, '
          f'{len(saved["evidence"])} evidence files, {len(saved["builds"])} build artifacts; '
          'does not rerun tests or browser/native QA.')
    raise SystemExit(0)


code = sorted([*ROOT.joinpath('lib').rglob('*.dart'), *ROOT.joinpath('backend').glob('*.py'), ROOT / 'backend/schema.sql'])
fingerprint = hashlib.sha256()
for path in code:
    fingerprint.update(path.relative_to(ROOT).as_posix().encode('utf-8'))
    fingerprint.update(path.read_bytes())
paths = set(code)
for folder, extension in [('test', '*.dart'), ('integration_test', '*.dart'), ('test_driver', '*.dart'), ('backend/tests', '*.py'), ('docs', '*.md'), ('scripts', '*.ps1'), ('scripts', '*.py'), ('web', '*.js')]:
    paths.update(ROOT.joinpath(folder).rglob(extension))
for folder in ('web', 'assets'):
    paths.update(p for p in ROOT.joinpath(folder).rglob('*') if p.is_file())
paths.update(ROOT / p for p in ['README.md', 'Readme.txt', 'STATUS.md', 'AGENTS.md', '.gitignore', 'evidence/2026-10-01-ui/contrast_audit_legacy.py', 'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'backend/requirements.txt', 'android/app/src/main/AndroidManifest.xml', 'android/app/src/debug/AndroidManifest.xml', 'android/app/build.gradle.kts', 'android/settings.gradle.kts'])
evidence = {p.relative_to(HERE).as_posix(): sha(p) for p in sorted(HERE.rglob('*')) if p.is_file()
            and p.name not in {'source-manifest.json', 'manifest-summary.txt', 'manifest-verify.txt', 'backend-local.txt', 'web-local.txt'}}
result = {
    'collected_at_utc': datetime.now(timezone.utc).isoformat(),
    'workspace': str(ROOT), 'base_commit': git('rev-parse', '--verify', 'HEAD'),
    'branch': git('branch', '--show-current'), 'remotes': (git('remote', '-v') or '').splitlines(),
    'code_fingerprint_sha256': fingerprint.hexdigest(),
    'files': {p.relative_to(ROOT).as_posix(): sha(p) for p in sorted(paths)},
    'builds': {p: sha(ROOT / p) for p in ['build/web/main.dart.js', 'build/web/offline_worker.js', 'build/app/outputs/flutter-apk/app-release.apk']},
    'evidence': evidence,
    'readme_equal': (ROOT / 'README.md').read_bytes() == (ROOT / 'Readme.txt').read_bytes(),
    'scope': {'flutter': 123, 'backend': 56, 'android': 'API36 debug real backend core/autosave/offline/encrypted DB reopen PASS under Skia software; no physical/release-functional/FPS claim', 'web': 'Chrome final local release real UI/auth/home/editor theme-resize/offline edit-reload-reconnect + actual API same note ID/count/content revision1-to-2 PASS', 'release': 'Web40 static resources/APK55.8MB build PASS, debug signing/local HTTP; not public HTTPS or release-functional acceptance', 'measurement': 'ASGI/SQLite local count10/1000, 7 measured requests+warmup; owner5803/viewer7753 SELECTs to4; timings not production/device FPS', 'cleanup': '309 obsolete/duplicate generated files, 5229325 bytes; historical/unique evidence kept', 'integrity': 'raw local byte hashes; HEAD must descend base_commit, tested working changes represented by input hashes; does not rerun QA', 'excluded_live_logs': ['backend-local.txt', 'web-local.txt']},
}
assert result['readme_equal']
(HERE / 'source-manifest.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'collected_at_utc': result['collected_at_utc'], 'base_commit': result['base_commit'], 'branch': result['branch'], 'remote_count': len(result['remotes']), 'code_fingerprint_sha256': result['code_fingerprint_sha256'], 'file_count': len(paths), 'evidence_count': len(evidence), 'readme_equal': result['readme_equal'], 'builds': result['builds']}, ensure_ascii=False))
