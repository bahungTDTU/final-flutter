"""Capture this audit without regenerating historical evidence or staging Git."""
import argparse
from datetime import datetime
from hashlib import sha256
import json
from pathlib import Path
import subprocess

here = Path(__file__).resolve().parent
root = here.parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('mode', choices=['qa', 'final'])
args = parser.parse_args()


def write(name, value):
    (here / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def git(*arguments):
    return subprocess.check_output(['git', *arguments], cwd=root, text=True).strip()


def artifacts():
    paths = ['build/web/main.dart.js', 'build/web/flutter_bootstrap.js',
             'build/web/offline_worker.js', 'build/app/outputs/flutter-apk/app-debug.apk']
    return {name: {'bytes': (root / name).stat().st_size,
                   'sha256': sha256((root / name).read_bytes()).hexdigest()} for name in paths}


timestamp = datetime.now().astimezone().isoformat()
if args.mode == 'qa':
    cache_log = (here / 'browser-cache-final.txt').read_text(encoding='utf-8-sig')
    cache = next(json.loads(line) for line in cache_log.splitlines() if line.startswith('{"result"'))
    files = artifacts()
    for name, expected in cache['hashes'].items():
        assert files['build/web/' + name]['sha256'] == expected, name
    write('qa-artifacts.json', {'capturedAt': timestamp, 'webAPI': 'http://127.0.0.1:8058',
                              'cache': cache, 'files': files, 'android': 'debug compile only'})
    print(json.dumps({'qaArtifactAndCacheHashes': 'PASS', 'worker': cache['worker']}))
    raise SystemExit(0)

old = {}
for name in ['2026-10-12-ui-system-refresh', '2026-10-12-atelier-ui', '2026-10-12-deskbook-layout']:
    directory = root / 'evidence' / name
    checksums = json.loads((directory / 'SHA256SUMS.json').read_text(encoding='utf-8'))
    for relative, expected in checksums.items():
        assert sha256((directory / relative).read_bytes()).hexdigest() == expected, (name, relative)
    old[name] = {'files': len(checksums), 'result': 'PASS'}
write('historical-integrity.json', old)
unchanged = git('diff', '--name-only', '--', 'lib/state', 'lib/data', 'pubspec.yaml',
                'pubspec.lock', 'android').splitlines()
assert not unchanged, unchanged
assert (root / 'README.md').read_bytes() == (root / 'Readme.txt').read_bytes()
paths = ['lib/ui/document_workspace.dart', 'backend/attachments.py',
         'test/bug_audit_regression_test.dart', 'backend/tests/test_attachment_ranges.py',
         'README.md', 'Readme.txt', 'STATUS.md', 'docs/REQUIREMENTS_MATRIX.md',
         'docs/UI_UX_QA.md', 'docs/BUG_AUDIT_2026-10-12.md', '.gitattributes',
         'pubspec.yaml', 'pubspec.lock']
sources = {name: {'sha256': sha256((root / name).read_bytes()).hexdigest(),
                  'lf_sha256': sha256((root / name).read_bytes().replace(b'\r\n', b'\n')).hexdigest()} for name in paths}
write('source_manifest.json', {'capturedAt': timestamp, 'base': git('rev-parse', 'HEAD'),
                              'branch': git('branch', '--show-current'), 'workingChanges': True,
                              'stateDataDependenciesAndroidDiff': unchanged, 'files': sources})
write('artifacts.json', {'capturedAt': timestamp, 'defaultWebAPI': 'http://127.0.0.1:8000',
                         'androidRuntime': 'NOT RUN', 'files': artifacts()})
images = sorted((here / 'screenshots').glob('*.png'))
gallery = ['# Ảnh QA bug audit —12/10/2026', '',
           'Chrome thật với dữ liệu tổng hợp. Ảnh phone là Web viewport; không phải native runtime.',
           '', '[Phạm vi](INDEX.md)', '']
for image in images:
    gallery += [f'## {image.stem}', '', f'![{image.stem}](screenshots/{image.name})', '']
(here / 'GALLERY.md').write_text('\n'.join(gallery), encoding='utf-8')
excluded = {'SHA256SUMS.json', 'backend-local.txt', 'web-local.txt', 'backend-error.txt',
            'web-error.txt', 'verify-result.txt'}
checksums = {path.relative_to(here).as_posix(): sha256(path.read_bytes()).hexdigest()
             for path in sorted(here.rglob('*')) if path.is_file() and path.name not in excluded
             and '__pycache__' not in path.parts}
write('SHA256SUMS.json', checksums)
print(json.dumps({'sources': len(sources), 'evidenceFiles': len(checksums), 'screenshots': len(images),
                  'historicalEvidence': old, 'unchangedStateDataDependenciesAndroid': True}))
