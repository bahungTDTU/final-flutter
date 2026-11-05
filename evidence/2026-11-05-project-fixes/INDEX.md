# Project verification and fixes — 2026-11-05 (Asia/Saigon)

Base: `7a8e84c08f0d3f5d5c0b3f6eba4beb258aa09cda`, after verified local backup
and `git pull --ff-only origin master`. Branch: `codex/release-readiness-validation`.
Changed-source SHA256 manifest accompanies this evidence; publication commit contains it.
Local toolchain: Flutter3.47.9/Dart3.13.7/Python3.12.14; CI pins Flutter3.47.1 separately.

| Command | Result | Log |
|---|---|---|
| `flutter test test/rich_attribute_contract_test.dart` BEFORE FIX | FAIL1/PASS1: client accepts null attributes | flutter-before.txt |
| `.venv/Scripts/python.exe -m pytest backend/tests/test_note_document.py -q` BEFORE FIX | FAIL2/PASS19: seven-digit foreground/background accepted by API | backend-before.txt |
| `flutter pub add cupertino_icons:1.0.8` | PASS, only this package added to lockfile | pub.txt |
| `flutter test test/rich_attribute_contract_test.dart test/workspace_test.dart` | PASS21 (intermediate targeted run) | flutter-targeted.txt |
| `.venv/Scripts/python.exe -m pytest backend/tests/test_note_document.py -q` | PASS21 (before adding 3 valid/legacy cases) | backend-targeted.txt |
| `scripts/check.ps1` final source | PASS format138files0changes/analyze/333Flutter/163backend | checks.txt |
| `.venv/Scripts/python.exe evidence/2026-11-05-project-fixes/run_api.py` | PASS actual HTTP owner/viewer/editor/stranger, lock/grant/edit/replay409/private files/revoke/password/delete | http-run.txt, http-roles.json |
| `scripts/build.ps1 -Target web` | PASS, 41 static resources; Cupertino font bundled1472bytes, missing-font warning gone | web-build.txt |

Backend retains one Starlette/httpx TestClient deprecation warning. No broad dependency
upgrade. Read-only performance result in sibling acceptance folder remains applicable
to unchanged listing code; no new production speedup claim.

HTTP runner uses isolated temporary SQLite and provider fixture with AI disabled.
Server/database cleaned by runner; ignored private QA session JSON was deleted afterward.
No secrets or personal data intentionally included. Raw failures preserved.

NOT RUN: browser/native runtime on final source, signed release, publicHTTPS,
SMTP inbox/LLM providers, final Rubric/video/Insights/ZIP, external approval/merge.
Build/unit/widget/API passes do not close these acceptance gates.

`flutter build apk --debug --dart-define=API_URL=http://127.0.0.1:8000`: PASS (apk-build.txt), compile only, not signed-release/runtime acceptance. Android emits an SDK XML v3/v4 tooling warning; build exits0.
