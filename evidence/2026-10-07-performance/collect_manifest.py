"""Hash final source and dated evidence; does not repeat QA or fabricate release acceptance."""
import argparse
import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FOLDER = Path(__file__).resolve().parent
MANIFEST = FOLDER/'source-manifest.json'
parser = argparse.ArgumentParser()
parser.add_argument('--verify', action='store_true')
args = parser.parse_args()

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

if args.verify:
    value = json.loads(MANIFEST.read_text())
    for category in ('source_sha256','evidence_sha256'):
        for name, expected in value[category].items():
            assert digest(ROOT/name) == expected, name
    assert (ROOT/'README.md').read_bytes() == (ROOT/'Readme.txt').read_bytes()
    print('PASS final source/evidence integrity and README identity; no QA rerun/release claim.')
else:
    assert (ROOT/'README.md').read_bytes() == (ROOT/'Readme.txt').read_bytes()
    check = (FOLDER/'check-complete.txt').read_text(encoding='utf-8-sig')
    assert '+180: All tests passed!' in check and '94 passed' in check and 'No issues found!' in check
    final = (FOLDER/'format-analyze-final.txt').read_text(encoding='utf-8-sig')
    assert 'No issues found!' in final and '83 files (0 changed)' in final
    assert '+7: All tests passed!' in (FOLDER/'flutter-final-projection.txt').read_text(encoding='utf-8-sig')
    assert 'All tests passed.' in (FOLDER/'native.txt').read_text(encoding='utf-8-sig')
    for name in ('http.json','web-result.json'):
        assert json.loads((FOLDER/name).read_text())['result'] == 'PASS'
    sources = {ROOT/name for name in ('AGENTS.md','README.md','Readme.txt','STATUS.md',
        'analysis_options.yaml','pubspec.yaml','pubspec.lock','.gitignore','.gitattributes',
        'android/app/build.gradle.kts','android/app/src/main/AndroidManifest.xml')}
    for folder in ('lib','test','integration_test','test_driver','backend','scripts','docs','web'):
        for p in (ROOT/folder).rglob('*'):
            if not p.is_file() or p.suffix not in ('.dart','.py','.md','.txt','.sql','.ps1','.yaml','.js','.html','.json'):
                continue
            if '__pycache__' in p.parts or p.relative_to(ROOT).parts[:2] == ('backend','state'):
                continue
            sources.add(p)
    assert ROOT/'lib/state/app_controller.dart' in sources
    evidence = [p for p in FOLDER.rglob('*') if p.is_file() and p not in (MANIFEST,FOLDER/'integrity.txt')
                and '__pycache__' not in p.parts]
    images = {}
    for p in evidence:
        if p.suffix in ('.jpg','.png'):
            with Image.open(p) as image:
                images[p.relative_to(ROOT).as_posix()] = {'width':image.width,'height':image.height,'format':image.format}
    assert len(images) == 5
    value = {'collected_at_utc':datetime.now(timezone.utc).isoformat(),'local_date':'2026-10-07 Asia/Saigon',
        'base_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'working_changes':True,'readme_byte_identity':True,
        'targets':'host180 Flutter/94 backend; HTTP8017; IAB Web debug7366; Android API36 software renderer1 workflow+teardown',
        'not_claimed':['FPS','disk IO','RSS','physical device','OS kill','Wi-Fi toggle','real Gemini','Internet SMTP','public release'],
        'source_sha256':{p.relative_to(ROOT).as_posix():digest(p) for p in sorted(sources)},
        'evidence_sha256':{p.relative_to(ROOT).as_posix():digest(p) for p in sorted(evidence)},'images':images}
    MANIFEST.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'Collected {len(sources)} inputs/{len(evidence)} evidence files/{len(images)} images; actual checks only.')
