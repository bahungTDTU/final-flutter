"""Collect or verify final source/evidence checksums; never rerun or fabricate acceptance."""
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
parser.add_argument('--verify',action='store_true')
args = parser.parse_args()

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

if args.verify:
    value = json.loads(MANIFEST.read_text(encoding='utf-8'))
    for category in ('source_sha256','evidence_sha256'):
        for name, expected in value[category].items():
            assert digest(ROOT/name) == expected, name
    assert (ROOT/'README.md').read_bytes() == (ROOT/'Readme.txt').read_bytes()
    print('PASS final session source/evidence integrity and README identity; no QA rerun/public release claim.')
else:
    check = (FOLDER/'check-final.txt').read_text(encoding='utf-8-sig')
    assert '+188: All tests passed!' in check and '94 passed' in check and 'No issues found!' in check
    assert '85 files (0 changed)' in (FOLDER/'format-analyze-final.txt').read_text(encoding='utf-8-sig')
    assert 'No issues found!' in (FOLDER/'format-analyze-final.txt').read_text(encoding='utf-8-sig')
    assert 'All tests passed.' in (FOLDER/'native.txt').read_text(encoding='utf-8-sig')
    assert '+8: All tests passed!' in (FOLDER/'session-targeted.txt').read_text(encoding='utf-8-sig')
    for name in ('http.json','web-result.json'):
        assert json.loads((FOLDER/name).read_text(encoding='utf-8'))['result'] == 'PASS'
    observed = json.loads((FOLDER/'web-observations.json').read_text(encoding='utf-8'))
    assert observed['profile_offline_reload']['observed_button_name'] == 'Ảnh đại diện mặc định S Session vault Web Hồ sơ và tùy chỉnh'
    assert observed['profile_offline_reload']['backend_running'] is False
    assert (ROOT/'README.md').read_bytes() == (ROOT/'Readme.txt').read_bytes()
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
    evidence = [p for p in FOLDER.rglob('*') if p.is_file() and p not in (MANIFEST,FOLDER/'integrity.txt')
                and '__pycache__' not in p.parts]
    images = {}
    for p in evidence:
        if p.suffix in ('.jpg','.png'):
            with Image.open(p) as image:
                images[p.relative_to(ROOT).as_posix()] = {'width':image.width,'height':image.height,'format':image.format}
    assert len(images) == 7
    value = {'collected_at_utc':datetime.now(timezone.utc).isoformat(),'local_date':'2026-10-07 Asia/Saigon',
        'base_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'working_changes':True,'readme_byte_identity':True,
        'targets':'host188 Flutter/94 backend; actual HTTP8017; IAB Web debug7366; Android API36 software1 workflow+teardown',
        'application_bearer_or_device_key_values_in_evidence':False,
        'not_claimed':['XSS immunity','secure erase','physical device','OS kill','quota eviction','multi-tab','public release','real Gemini','Internet SMTP'],
        'source_sha256':{p.relative_to(ROOT).as_posix():digest(p) for p in sorted(sources)},
        'evidence_sha256':{p.relative_to(ROOT).as_posix():digest(p) for p in sorted(evidence)},'images':images}
    MANIFEST.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'Collected {len(sources)} inputs/{len(evidence)} evidence files/{len(images)} images; actual checks only.')
