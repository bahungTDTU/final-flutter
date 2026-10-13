# Inspector UI acceptance — 13/10/2026

Target: Flutter Web/Android NoteTogether. Branch`codex/bug-audit-fixes`, base master
`46df286302cc88e07c98ba1b14160cc64491e2df`; working changes, chưa commit/push.
[Báo cáo](../../docs/UI_INSPECTOR_REFINEMENT.md), [ảnh](GALLERY.md).

| Command / target | Log | Result |
| --- | --- | --- |
| `scripts/check.ps1` / intermediate UI | check-accepted.txt | PASS278Flutter/119backend |
| `dart format --output=none --set-exit-if-changed lib test integration_test` / final | format-accepted.txt | PASS115files/0changes |
| `flutter analyze` / final | analyze-accepted.txt | PASS |
| `flutter test` / final | flutter-accepted.txt | PASS279 |
| Targeted inspector/protected tests / final | inspector-accepted.txt | PASS16 |
| `flutter build web --release --no-web-resources-cdn --output tmp/inspector-web-2026-10-13 --dart-define=API_URL=http://127.0.0.1:8058` +offline helper`--build-dir` | build-web-qa-final.txt | PASS |
| `scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8000` +defaultoffline helper | build-web-user-accepted.txt | PASS |
| `flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8000` | build-apk-debug.txt | PASS compile |
| DirectHTTP roles / synthetic isolated server8058 | api-fixtures.json | PASS |
| Edit+pin actual browser then directAPI | api-autosave.json | PASS exact title/content/pin/share |
| CUA IAB UI /1280×1000 light+dark,375×812 dark,844×390 dark | browser-results.json +screenshots | PASS |

`check.txt` preserves the first lint failure (missing braces in the new test); fixed before
acceptance. `build-web-qa.txt` and`inspector-tests.txt` are intermediate, not final badges.
The first user build was interrupted at Flutter's SDK-cache lock loop in the restricted
shell (`build-web-user.txt` is empty); the accepted build ran with SDK write permission.
Backend119PASScame before the final metadata-only badge change; backend source unchanged.

Regressions assert geometry/target spacing/disabled semantics and document controller/
selection preservation plus private purge. They do not duplicate UI implementation or
claim actual screen-reader/native behavior. Viewer actualWeb hides owner-only controls.
LLM/email providers disabled on QA; no provider success claimed.

`source_manifest.json`: final edited source/doc hashes and Git state;`artifacts.json`:
Web/APK sizes+hashes;`historical-integrity.json`: old snapshot payloads byte-preserved;
`SHA256SUMS.json`: this evidence payload. Older source manifests remain historical after
the UI source changes. User backend8000/web7357 are retained; only isolated QA8058/7376
are stopped after verification (service-cleanup.json).

NOT RUN: native runtime/IME/FPS/real screen reader/CI/release/submission.
