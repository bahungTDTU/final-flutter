"""Hash final source/evidence; verification does not rerun QA."""
import argparse
import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FOLDER = Path(__file__).resolve().parent
MANIFEST = FOLDER / 'source-manifest.json'
parser = argparse.ArgumentParser()
parser.add_argument('--verify', action='store_true')
args = parser.parse_args()
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

if args.verify:
    value = json.loads(MANIFEST.read_text())
    for category in ('source_sha256', 'evidence_sha256'):
        for name, expected in value[category].items():
            assert digest(ROOT / name) == expected, name
    print('PASS source/evidence integrity; no QA rerun/public release claim.')
else:
    assert (ROOT / 'README.md').read_bytes() == (ROOT / 'Readme.txt').read_bytes()
    check = (FOLDER / 'check.txt').read_text(encoding='utf-8-sig')
    assert '+173: All tests passed!' in check and '93 passed' in check
    assert 'No issues found!' in (FOLDER / 'analyze-final.txt').read_text(encoding='utf-8-sig')
    assert 'All tests passed.' in (FOLDER / 'android.txt').read_text(encoding='utf-8-sig')
    assert json.loads((FOLDER / 'http.json').read_text())['result'] == 'PASS'
    sources = {ROOT / name for name in ('AGENTS.md', 'README.md', 'Readme.txt', 'STATUS.md',
        'analysis_options.yaml', 'pubspec.yaml', 'pubspec.lock', '.gitignore',
        'android/app/build.gradle.kts', 'android/app/src/main/AndroidManifest.xml')}
    for folder in ('lib', 'test', 'integration_test', 'test_driver', 'backend', 'scripts', 'docs', 'web'):
        sources.update(p for p in (ROOT / folder).rglob('*') if p.is_file()
                       and p.suffix in ('.dart','.py','.md','.txt','.sql','.ps1','.yaml','.js','.html','.json')
                       and 'state' not in p.relative_to(ROOT).parts and '__pycache__' not in p.parts)
    evidence = [p for p in FOLDER.rglob('*') if p.is_file() and p != MANIFEST and '__pycache__' not in p.parts]
    images = {}
    for item in evidence:
        if item.suffix in ('.jpg','.png'):
            with Image.open(item) as image:
                images[item.relative_to(ROOT).as_posix()] = {'width':image.width,'height':image.height,'format':image.format}
    assert len(images) == 9
    value = {
        'collected_at_utc': datetime.now(timezone.utc).isoformat(),
        'local_date': '2026-10-07 Asia/Saigon',
        'base_commit': subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT, text=True).strip(),
        'working_changes': True, 'readme_byte_identity': True,
        'targets': 'host173 Flutter/93 backend; HTTP8016; IAB Web debug7365; API36 debug software renderer1 workflow+teardown',
        'user_policy': 'public pinned_at/shared boolean; private content/labels/identities/share times/counts redacted',
        'release_real_llm_internet_mail_physical': False,
        'source_sha256': {p.relative_to(ROOT).as_posix():digest(p) for p in sorted(sources)},
        'evidence_sha256': {p.relative_to(ROOT).as_posix():digest(p) for p in sorted(evidence)},
        'images': images,
    }
    MANIFEST.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Collected {len(sources)} inputs/{len(evidence)} evidence files/{len(images)} images; actual checks only.')
