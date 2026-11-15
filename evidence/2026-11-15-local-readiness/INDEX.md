# Local readiness — 15/11/2026 (Asia/Saigon)

Source: `9d00fcf` / `origin/master`; working branch `codex/local-readiness-update`.
Application/test/config source unchanged. Documentation changes described in
[report](../../docs/LOCAL_READINESS_2026-11-15.md). No publication or deployment.

## Commands and results

- `git fetch origin`; checkout tracking master; create working branch: PASS.
- Flutter SDK3.47.9/Dart3.13.7 installed separately from existing3.47.0.
- `python -m venv .venv`; `.venv/Scripts/python.exe -m pip install -r backend/requirements.txt`:
  Python3.13.7 compatibility environment; NOT baseline Python3.12.
- `dart format --output=none --set-exit-if-changed lib test integration_test test_driver`:
  PASS138 files, zero edits; `format.txt`.
- `flutter pub get --enforce-lockfile`: PASS, `pub-get.txt` / `pub-get-clean.txt`.
- `flutter analyze --no-pub`: original Unicode path FAIL LSP parsing (`analyze.txt`);
  junction run stopped without conclusion (`analyze-short-path.txt`);
  ASCII checkout at same source PASS (`analyze-clean.txt`).
- `flutter test --no-pub --reporter expanded`: original SDK path FAIL native hook
  quoting (`flutter-tests.txt`); ASCII junction PASS333 (`flutter-tests-short-path.txt`);
  ASCII clean checkout PASS333 (`flutter-tests-clean.txt`).
- `.venv/Scripts/python.exe -m pytest backend/tests -q`: PASS163, one Starlette warning,
  Python3.13.7, `backend-tests.txt`.
- `git diff --check`, README/Readme byte comparison and relative links: checked after docs update.

SDK junction: `C:/Temp/notetogether-20261115/flutter`.
Project junction: `C:/Temp/notetogether-20261115/project`.
QA clone: `C:/Temp/notetogether-20261115/checkout`, shared local Git objects, source9d00fcf.
Clone tests validate unchanged app source, not uncommitted documentation.

Python3.12 installer was rejected by automatic approval review without a detailed
reason. Existing Python3.13 was used only for explicitly labeled compatibility QA.
No source guard or CI version was relaxed.

NOT RUN: UI/browser/native acceptance, release signing, provider receipt/LLM,
public HTTPS, submission packaging, live hosted CI/review checks.

## Web build

`scripts/build.ps1 -Target web` with the ASCII SDK/project junctions: PASS.
API `http://127.0.0.1:8000`, 41 static resources, worker `notetogether-static-7860965acf2abbb5`.
Log: `web-build.txt`. Build is local, not a public deployment or browser acceptance.

- `main.dart.js` SHA256: `272b591ee6bb18bcf8512b8b3cadc4b0df0d1e5dc739f925f68d6bc0d92c72ba`
- `offline_worker.js` SHA256: `626f5bc7b1c01159cb8c789d57547eced61dae3f03c7b22227212fe3dad0e936`
