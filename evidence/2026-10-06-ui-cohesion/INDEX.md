# UI cohesion/responsive/performance —06/10/2026

Base `aded41ec0ccdbfb46cae579b64ef3eab004f68bf` + working changes chưa commit.
Nguồn yêu cầu PDF tr.5–6 + prompt/AGENTS và yêu cầu người dùng hiện tại. No release/push/deploy.

| Command / target | Result | Log/artifact |
|---|---|---|
| `scripts/check.ps1` / host |format78 files unchanged, analyze clean,161 Flutter/88 backend PASS;1 upstream deprecation warning|check.txt|
| `flutter test test/ui_cohesion_test.dart --reporter expanded`|6 new regressions PASS; invalidation/lock/Unicode/debounce/short landscape/keyboard|cohesion-tests.txt; full check authoritative|
| `flutter test ... --plain-name 'Controlled NotoSans shaping and cached-query benchmark'` / host NotoSans engine|11-iteration medians, input100000→481, paragraph4279→165µs/query348926→388µs/repeat10µs|benchmark-isolated.txt; benchmark.json|
| `.venv/Scripts/python.exe scripts/qa_writing_studio.py --output evidence/2026-10-06-ui-cohesion/http.json` / API8012|Actual owner/editor/viewer/stranger, stale/revoke/lock/minimal fields PASS|http.txt; http.json|
| `flutter drive --driver=test_driver/ui_cohesion.dart --target=integration_test/ui_cohesion_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8012 --enable-software-rendering --no-enable-impeller` / API36 debug|3 reused real workflows + teardown PASS47s; no3-new-test claim|android-final.txt;8 native PNG|
| `flutter run -d web-server --web-hostname=127.0.0.1 --web-port=7363 --dart-define=API_URL=http://127.0.0.1:8012` / IAB|Gallery responsive/preview, editor theme+sync, AI input across breakpoint, protected unlock/relock, tail search/remote lock cached Home PASS|web.json; after-*.png|
| `flutter pub get` then `flutter analyze`|Normal dependency/registrant restored; analyze clean; no Java handedit|pub-get.txt; analyze-final.txt|
| `collect_manifest.py` then `--verify`|Source/evidence/base SHA256 + README/Readme equality; no QA rerun/build claim|source-manifest.json; manifest-verify.txt|

Backend uses ignored `tmp/ui-cohesion.sqlite3`, loopback8012, Web origin7363; SMTP/AI not configured.
Disposable test users/text only, actual HTTP; no Internet service call. Token/password fixture files
only in ignored tmp, excluded from source/evidence manifest and removed after QA. Generated long
note is100000 characters; no user note changed. Source changes do not touch API/schema/store sync.

Before-gallery-mobile.png and before-layout.json captured actual old footer before gallery edits.
After images use current source. Viewport switches require a fresh settled snapshot: early Home
capture was clipped618px and was replaced after DOM1280×900 verification. Tablet screenshots are
768×988 despite requested768×1024; do not silently claim PNG1024. Widget tests cover exactsizes/200%.

First native attempt found a stale02/10 test looking for a direct theme icon; actual compact menu
has existed since Studio06/10. Updated test navigates menu and keeps all assertions; final rerun is
authoritative. First check found one brace lint; fixed before final gate. A legacy HTTP script initially
wrote its fixed historical JSON path; restored byte-for-byte from the original log and verified against
the historical manifest, then added explicit output argument. No historical evidence timestamp changed.

Limits: benchmark is controlled host test-engine measurement, keyword near beginning, not FPS/
every workload/profile/physical performance. Software emulator IME/jank logs retained. Screen reader,
browser history, production/default renderer, physical, OS kill, public HTTPS/release/Gemini/video NOT RUN.
Provider was not called; AI screenshots prove layout/input preservation only.
