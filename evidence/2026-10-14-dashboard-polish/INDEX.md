# Dashboard acceptance —14/10/2026

Source: local branch `codex/dashboard-motion-performance`, base
`4a196ef33019b38c6c2812fcbd48f05bf0d7d134`. Changes are uncommitted/unpushed;
source hashes identify the tested files. Timestamps are actual UTC; the client day is14/10.
No CI, provider, release or native-runtime completion is inferred from this record.

## Accepted results

| Gate | Result | Evidence |
|---|---|---|
| Three original bugs on isolated base source | FAIL confirmed | flutter-baseline-final.txt |
| Eight regressions on corrected source, including Tab/Enter both themes | PASS | flutter-focus-final.txt, check-with-focus-final.txt |
| Format118/analyze/287 Flutter/143 backend | PASS | check-with-focus-final.txt |
| Real loopback owner/editor/viewer/stranger API | PASS | api.json, api-final.txt |
| Seed500notes/30labels on separate backend | PASS | seed.json, seed-final.txt |
| Real Chromium IAB responsive/themes/search/menu/realtime/relock | PASS | browser-final.json, final screenshots, browser-final-before/after-lock.txt |
| QA Web release/API8059/offline static resources | PASS | build-web-with-focus-final.txt |
| Local Web release/API8000/offline static resources | PASS | build-local-web-with-focus-final.txt |
| Android debug compile/API10.0.2.2:8000 | PASS | build-android-debug-with-focus-final.txt |
| Android device/FPS/profile/IME/screen reader | NOT RUN | android-devices.txt has no devices; browser-final.json fps=false |

Same20 connection pulses: one-note header replacements20→0, preview projections20→0.
500 rich-note widget workload:6 visible initial previews; extra projections120→0.
One harness sample688695→77334µs is CPU wall time, not frame time or FPS.
Before: workload-500-before.txt; after: flutter-expanded-final.txt.

Screenshots are synthetic data only. Title/body remote sentinel is visible before lock,
absent after lock, with a visible locked card. No token/cookie/private user content is recorded.
The API helper's synthetic fixture passwords are test constants; LLM/mail are disabled.
Browser controls used cua_repl; no DOM mutation or network call through page evaluation.
The QA tab and servers8059/7377 were closed after acceptance. Existing services were not stopped.

## Reproduction

```powershell
scripts/check.ps1
flutter test test/dashboard_polish_regression_test.dart --reporter expanded
flutter build web --release --no-web-resources-cdn --output tmp/dashboard-web-2026-10-14 --dart-define=API_URL=http://127.0.0.1:8059
.venv/Scripts/python.exe scripts/prepare_web_offline.py --build-dir tmp/dashboard-web-2026-10-14
scripts/build.ps1 -Target web
flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8000
```

Start qa_server.py with `--db` pointing to a fresh file under tmp, then seed_performance.py
and prepare_dashboard.py. The helper deliberately rejects an existing DB. All helper
URLs are loopback8059; QA Web uses7377. Copy helpers to a new dated evidence directory
and adjust fixture paths together for another run; do not overwrite this snapshot.
For the baseline, archive Git base4a196ef into a separate tmp checkout, copy the regression
test there, enforce pubspec.lock and run only the three named probes/the500-note probe.
Do not replace production source with baseline files or use backend/state for fixtures.

The browser.json and screenshots without final- prefix are the first UI snapshot;
browser-final.json records the last source, with reload after worker installation.
Tab/Enter focus-ring acceptance is from widget tests; full browser focus order is not asserted.
The other flutter-before/targeted/baseline-accepted/expanded logs are intermediate probe
calibrations (edge hit point, viewport/scroll and debounce timing). check.txt is the
initial lint failure; check-final.txt is the286-test snapshot before the final focus ring.
check-with-focus-final is the final287-test gate. api.txt/seed.txt are sandbox-connectivity
failures before the host QA server was started. These are not accepted product regressions
or final gates; preserve them as diagnostic history, use the named final files above.

Manifest SHA-256 confirms bytes only, not a rerun of tests. Prior evidence snapshots
remain unchanged. [Implementation and limits](../../docs/DASHBOARD_MOTION_AND_PERFORMANCE.md).
