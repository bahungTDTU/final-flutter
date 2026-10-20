"""Record exact audit source hashes and local Git metadata, without secrets."""
import hashlib
import json
import subprocess
from collections import Counter
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

root = Path(__file__).resolve().parents[2]
out = Path(__file__).resolve().parent
def git(*args):
    return subprocess.check_output(['git', *args], cwd=root).decode('utf-8').strip()
files = []
for folder in ('lib', 'backend', 'test', 'integration_test', 'test_driver', 'scripts', '.github/workflows'):
    for p in (root / folder).rglob('*'):
        if p.is_file() and p.suffix in ('.dart', '.py', '.sql', '.ps1', '.yaml', '.yml') and '__pycache__' not in p.parts:
            files.append(p)
files += [root / p for p in ('pubspec.yaml', 'pubspec.lock', 'backend/requirements.txt',
    'compose.yaml', 'android/app/build.gradle.kts', 'android/app/src/main/AndroidManifest.xml')]
counts = Counter()
for line in git('log', '--all', '--no-merges', '--format=%ad|%an', '--date=short').splitlines():
    day, author = line.split('|', 1)
    value = date.fromisoformat(day)
    counts[(str(value - timedelta(days=value.weekday())), author)] += 1
metadata = {
    'date_utc': datetime.now(timezone.utc).isoformat(),
    'branch': git('branch', '--show-current'), 'head': git('rev-parse', 'HEAD'),
    'dirty': True, 'target': 'Windows local audit; not browser/native acceptance',
    'pdf_sha256': hashlib.sha256(Path('C:/Users/LENOVO/Downloads/503107-FinalProject-V1.pdf').read_bytes()).hexdigest(),
    'source_sha256': {str(p.relative_to(root)).replace('\\', '/'): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(set(files))},
    'local_nonmerge_commit_counts_not_contribution_verification': [
        {'week_monday': week, 'author': author, 'count': count}
        for (week, author), count in sorted(counts.items())],
}
(out / 'source_manifest.json').write_text(json.dumps(metadata, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
(out / 'git-status.txt').write_text(git('status', '--short') + '\n', encoding='utf-8')
print(json.dumps({'source_files': len(set(files)), 'pdf_sha256': metadata['pdf_sha256'],
                  'local_week_counts': metadata['local_nonmerge_commit_counts_not_contribution_verification']}, ensure_ascii=False))
