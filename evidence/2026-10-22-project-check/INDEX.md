# Project check — 22/10/2026

Base `ad21cf8889dd40fc615eebdbe0904fac8dc7123f`, local uncommitted changes.
Target: Windows host, Flutter Web release local, Android debug compile,
FastAPI/SQLite isolated loopback8077. No provider calls or deployment.

- `status-before.txt`: pre-existing changes preserved.
- `assignment.txt`: extraction from original 19-page assignment, pypdf.
- `unicode-before.txt`: 2 regression failures before production fix.
- `checks-host.txt`: `scripts/check.ps1`, format/analyze/331 Flutter/152 backend PASS.
- `flutter-final.txt`: `flutter test --no-pub`, 331 PASS after fix.
- `format-final.txt`: `dart format --output=none --set-exit-if-changed lib test integration_test test_driver`, 137 files, 0 changes.
- `backend-host.txt`: `python -m pytest backend/tests -q`, 152 PASS.
- `backend.txt`: original sandbox setup failures, NOT a passing run.
- `build-web.txt`: `flutter build web --release --no-pub --no-web-resources-cdn --dart-define=API_URL=http://127.0.0.1:8000`; `python scripts/prepare_web_offline.py`, PASS40 assets.
- `build-apk.txt`: `flutter build apk --debug --no-pub --dart-define=API_URL=http://10.0.2.2:8000`, PASS.
- `run_api.py`, `http.txt`, `http-roles.json`: actual HTTP4roles via `scripts/qa_protected_notes.py`; temporary backend stopped and its temporary database removed.
- `cleanup.ps1`, `cleanup.json`: reviewed generated outputs removed, 339 files/281327252 bytes.
- `cleanup_test_cache.ps1`, `cleanup-test-cache.json`: old test caches, 723 files/78810798 bytes/259 links; 2 inaccessible directories retained.

Backend tests use fixtures; SMTP/Gemini Internet not verified. No fresh browser UI,
Android runtime, accessibility, FPS, signed release, public HTTPS, CI or submission
acceptance. Prior evidence and user modifications preserved.

Auto-review blocked deletion of the two inaccessible cache directories because their
contents and recoverability could not be verified. Read-only elevated inspection also
returned Access denied; no ACL/ownership changes attempted.
