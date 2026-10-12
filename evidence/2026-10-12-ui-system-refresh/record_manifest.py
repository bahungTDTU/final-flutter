"""Record current source/artifacts/evidence, without adding anything to Git."""
from datetime import datetime
from hashlib import sha256
import json
from pathlib import Path
import re
import subprocess

directory = Path(__file__).resolve().parent
root = directory.parents[1]

def write(name, value):
    (directory / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def git(*arguments):
    return subprocess.check_output(['git', *arguments], cwd=root, text=True).strip()

source_paths = ['lib/ui/' + name + '.dart' for name in [
    'ai', 'app', 'dashboard', 'design_system', 'document_workspace', 'focus_panel',
    'home', 'planner', 'prism', 'security_center', 'workspace']]
source_paths += ['test/ui_system_refresh_test.dart', 'pubspec.yaml', 'pubspec.lock']
sources = {}
for relative in source_paths:
    data = (root / relative).read_bytes()
    sources[relative] = {'sha256': sha256(data).hexdigest(),
                         'lf_sha256': sha256(data.replace(b'\r\n', b'\n')).hexdigest()}
unchanged_paths = git('diff', '--name-only', '--', 'lib/state', 'lib/data', 'backend',
                      'pubspec.yaml', 'pubspec.lock').splitlines()
assert not unchanged_paths, unchanged_paths
write('source_manifest.json', {'capturedAt': datetime.now().astimezone().isoformat(),
    'base': git('rev-parse', 'HEAD'), 'branch': git('branch', '--show-current'),
    'workingChanges': True, 'businessAndDependencyDiff': unchanged_paths, 'files': sources})

artifacts = {}
for relative in ['build/web/main.dart.js', 'build/web/flutter_bootstrap.js',
                 'build/web/offline_worker.js', 'build/app/outputs/flutter-apk/app-debug.apk']:
    path = root / relative
    data = path.read_bytes()
    artifacts[relative] = {'bytes': len(data), 'sha256': sha256(data).hexdigest()}
cache_log = (directory / 'browser-cache-final.txt').read_text(encoding='utf-8-sig')
cache_result = next(json.loads(line) for line in cache_log.splitlines() if line.startswith('{"cache"'))
worker = (root / 'build/web/offline_worker.js').read_text(encoding='utf-8')
write('artifacts.json', {'capturedAt': datetime.now().astimezone().isoformat(),
    'chromeQA_API': 'http://127.0.0.1:8058', 'chromeQA': cache_result,
    'defaultWebAPI': 'http://127.0.0.1:8000',
    'defaultWorker': re.search(r'notetogether-static-[0-9a-f]+', worker).group(),
    'androidTarget': 'debug compile only, runtime NOT RUN', 'files': artifacts})

pictures = sorted((directory / 'screenshots').glob('*.png'))
gallery = ['# UI NoteTogether —12/10/2026', '',
    f'{len(pictures)} ảnh Chrome trực tiếp, dữ liệu tổng hợp trên server/DB riêng. '
    'Đây là bố cục Web theo kích thước viewport; ảnh điện thoại không phải Android runtime.', '',
    '[Phạm vi nghiệm thu và giới hạn](INDEX.md)', '',
    '## Một số màn hình chính', '']
for name in ['home-desktop-light', 'home-phone-dark', 'editor-desktop-light', 'editor-phone-dark']:
    gallery += [f'![{name}](screenshots/{name}.png)', '']
gallery += ['## Toàn bộ ảnh', '']
gallery += [f'- [{path.stem}](screenshots/{path.name})' for path in pictures]
(directory / 'GALLERY.md').write_text('\n'.join(gallery) + '\n', encoding='utf-8')

evidence = {}
for path in sorted(directory.rglob('*')):
    if path.is_file() and path.name != 'SHA256SUMS.json':
        evidence[path.relative_to(directory).as_posix()] = sha256(path.read_bytes()).hexdigest()
write('SHA256SUMS.json', evidence)
print(json.dumps({'sourceFiles': len(sources), 'businessAndDependencyDiff': unchanged_paths,
                  'screenshots': len(pictures), 'evidenceFiles': len(evidence),
                  'defaultWorker': re.search(r'notetogether-static-[0-9a-f]+', worker).group()}))
