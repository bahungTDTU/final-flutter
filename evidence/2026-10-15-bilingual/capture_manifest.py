"""Seal this acceptance record; hashes prove bytes, never fresh execution or FPS."""
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parents[2]
folder = Path(__file__).resolve().parent


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(name, data):
    (folder / name).write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    preserved = {}
    for previous in ('2026-10-13-inspector-ui', '2026-10-13-master-integration',
                     '2026-10-14-publish-resume', '2026-10-14-dashboard-polish',
                     '2026-10-14-desk-navigation', '2026-10-14-rubric-ux-audit'):
        previous_folder = root / 'evidence' / previous
        manifest = json.loads((previous_folder / 'SHA256SUMS.json').read_text(encoding='utf-8'))
        mismatches = [name for name, expected in manifest.items()
                      if not (previous_folder / name).is_file()
                      or digest(previous_folder / name) != expected]
        assert not mismatches, (previous, mismatches)
        preserved[previous] = {'payloads': len(manifest), 'result': 'PASS integrity only'}
    save('prior-evidence-integrity.json', preserved)
    sources = set()
    for source_dir in ('lib', 'test', 'integration_test', 'test_driver'):
        sources.update((root / source_dir).rglob('*.dart'))
    sources.update((root / 'backend').glob('*.py'))
    sources.update((root / 'backend' / 'tests').rglob('*.py'))
    for name in ('pubspec.yaml', 'pubspec.lock', 'backend/requirements.txt',
                 'scripts/check.ps1', 'scripts/build.ps1', 'scripts/toolchain.ps1',
                 'scripts/prepare_web_offline.py', 'README.md', 'Readme.txt', 'STATUS.md',
                 'docs/REQUIREMENTS_MATRIX.md', 'docs/UI_UX_DESIGN.md', 'docs/UI_UX_QA.md',
                 'docs/DASHBOARD_MOTION_AND_PERFORMANCE.md', 'docs/UI_DESK_NAVIGATION.md',
                 'docs/RUBRIC_AND_UX_AUDIT_2026-10-14.md', 'docs/BILINGUAL_UI.md', 'docs/PREFERENCES_SYNC.md',
                 'docs/ARCHITECTURE.md', 'docs/LOCAL_BASELINE_AND_ROADMAP.md',
                 'design-system/notetogether-deskbook/pages/label-manager.md',
                 'design-system/notetogether-deskbook/pages/dashboard-motion.md', 'design-system/notetogether-deskbook/pages/desk-navigation.md', '.gitattributes'):
        sources.add(root / name)
    save('source_manifest.json', {
        'client_date': '2026-10-16', 'started_client_date': '2026-10-15', 'captured_at_utc': datetime.now(timezone.utc).isoformat(),
        'base': '4a196ef33019b38c6c2812fcbd48f05bf0d7d134',
        'branch': 'codex/dashboard-motion-performance', 'new_commit': None,
        'acceptance': {'format': 'PASS125files0changes', 'analyze': 'PASS',
                       'flutter_tests': 302, 'backend_tests': 145,
                       'web_browser': 'PASS scoped browser.json', 'api': 'PASS scoped api-roles.json and api-locale.json',
                       'web_release': 'PASS', 'android_debug_compile': 'PASS',
                       'fps': 'NOT RUN', 'android_runtime': 'NOT RUN', 'ci': 'NOT RUN',
                       'frontend_log': 'frontend-verified.txt', 'backend_log': 'check-final.txt',
                       'backend_changed_after_145_pass': False},
        'sha256': {p.relative_to(root).as_posix(): digest(p) for p in sorted(sources)},
    })
    artifacts = ('build/web/main.dart.js', 'build/web/offline_worker.js',
                 'tmp/bilingual-web-2026-10-16/main.dart.js',
                 'tmp/bilingual-web-2026-10-16/offline_worker.js',
                 'build/app/outputs/flutter-apk/app-debug.apk')
    save('artifacts.json', {name: {'bytes': (root / name).stat().st_size,
                                 'sha256': digest(root / name)} for name in artifacts})
    save('SHA256SUMS.json', {
        p.relative_to(folder).as_posix(): digest(p) for p in sorted(folder.rglob('*'))
        if p.is_file() and p.name != 'SHA256SUMS.json' and '__pycache__' not in p.parts
    })
    print(f'PASS integrity: {len(sources)} source/docs inputs, {len(artifacts)} builds; '
          f'previous snapshots {sum(v["payloads"] for v in preserved.values())} payloads unchanged')
