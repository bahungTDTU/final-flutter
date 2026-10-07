"""Capture audit provenance without inspecting secrets or production databases."""
import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parents[2]
folder = Path(__file__).resolve().parent
def git(*args):
    return subprocess.check_output(['git', *args], cwd=root, text=True).strip()

report = root / 'docs/PROJECT_AUDIT_2026-10-07.md'
criteria = list(map(int, re.findall(r'^\| (\d+) \|', report.read_text(encoding='utf-8'), re.M)))
assert criteria == list(range(1, 33))
assert (root / 'README.md').read_bytes() == (root / 'Readme.txt').read_bytes()
for helper in ('probe.py', 'write_amplification_test.dart'):
    assert (folder / helper).read_bytes() == (root / 'tmp/audit-2026-10-07' / helper).read_bytes()
paths = [report, *sorted(p for p in folder.iterdir() if p.is_file() and p.name != 'audit-summary.json')]
result = {
    'collected_at_utc': datetime.now(timezone.utc).isoformat(),
    'local_date': '2026-10-07 Asia/Saigon',
    'head': git('rev-parse', 'HEAD'),
    'remote_master': git('-c', 'http.sslBackend=openssl', 'ls-remote', 'origin', 'refs/heads/master').split()[0],
    'existing_ui_working_changes_preserved': True,
    'criteria_rows': len(criteria),
    'readme_byte_identity': True,
    'helper_copies_byte_identity': True,
    'full_suite_rerun': False,
    'browser_native_rerun': False,
    'real_gemini_or_internet_smtp': False,
    'application_source_changes_by_audit': False,
    'files_sha256': {p.relative_to(root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},
}
assert result['head'] == result['remote_master']
(folder / 'audit-summary.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('PASS: 32 criteria, README identity, probe copies, local/remote HEAD and audit checksums.')
