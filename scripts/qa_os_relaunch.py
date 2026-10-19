"""Force-stop/relaunch the QA-only APK on a disposable Android emulator.

Build test_driver/os_relaunch_app.dart with the same QA_RUN_ID first. This does
not test IME/editor UI, toggle Wi-Fi, clear app data or touch a physical device.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import time

PACKAGE = 'vn.edu.notetogether.note_together'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', required=True)
    parser.add_argument('--device', required=True)
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--run-id', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if not re.fullmatch(r'emulator-[0-9]+', args.device):
        parser.error('Use a disposable emulator; physical devices are not supported')
    if not re.fullmatch(r'[a-zA-Z0-9-]{1,64}', args.run_id):
        parser.error('Invalid QA run ID')
    if not args.apk.is_file() or args.output.exists():
        parser.error('APK must exist and output must be a new file')

    def adb(*command, check=True):
        result = subprocess.run(
            [args.adb, '-s', args.device, *command], capture_output=True,
            text=True, encoding='utf-8', errors='replace', timeout=30)
        if check and result.returncode:
            raise RuntimeError('ADB command failed: ' + command[0])
        return result

    def read():
        result = adb('shell', 'run-as', PACKAGE, 'cat',
                     f'files/qa-os-{args.run_id}.json', check=False)
        if result.returncode:
            return None
        try:
            return json.loads(result.stdout)
        except ValueError:
            return None

    def wait(stage):
        deadline = time.monotonic() + 150
        while time.monotonic() < deadline:
            result = read()
            if result and result.get('stage') == 'fail':
                raise RuntimeError('Native probe failed; inspect QA assertion log privately')
            if result and result.get('stage') == stage:
                return result
            time.sleep(1)
        raise RuntimeError('Timed out waiting for native stage: ' + stage)

    def launch():
        adb('shell', 'am', 'start', '-n', PACKAGE + '/.MainActivity',
            '--ez', 'enable-software-rendering', 'true',
            '--ez', 'enable-impeller', 'false')

    # Install -r preserves the existing app sandbox; dedicated QA DB uses run ID.
    # Reject a stale run instead of accepting an old PASS or overwriting its marker.
    adb('install', '-r', str(args.apk.resolve()))
    if read() is not None:
        raise RuntimeError('Run ID already exists; choose a new run ID and rebuild')
    launch()
    before = wait('ready_for_force_stop')
    observed = adb('shell', 'pidof', PACKAGE).stdout.strip().split()
    if str(before['pid']) not in observed:
        raise RuntimeError('Ready marker does not match live OS process')
    adb('shell', 'am', 'force-stop', PACKAGE)
    if adb('shell', 'pidof', PACKAGE, check=False).stdout.strip():
        raise RuntimeError('OS process still running after force-stop')
    launch()
    result = wait('pass')
    if result['pid_before'] == result['pid_after']:
        raise RuntimeError('Expected a new native OS process')
    with args.apk.open('rb') as artifact:
        apk_hash = hashlib.file_digest(artifact, 'sha256').hexdigest()
    result.update({
        'run_id': args.run_id,
        'device': args.device,
        'apk_sha256': apk_hash,
        'source': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
        'os_force_stop_verified': True,
        'offline_scope': 'real refused socket, not Wi-Fi toggle',
    })
    result['qa_source_sha256'] = {}
    for name in ('test_driver/os_relaunch_app.dart', 'scripts/qa_os_relaunch.py'):
        with Path(name).open('rb') as source:
            result['qa_source_sha256'][name] = hashlib.file_digest(source, 'sha256').hexdigest()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open('x', encoding='utf-8') as output:
        json.dump(result, output, indent=2)
    print('PASS native core: OS process death, encrypted reopen, exact Delta/UUID and sync')


if __name__ == '__main__':
    main()
