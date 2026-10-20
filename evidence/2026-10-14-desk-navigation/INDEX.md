# Desktop navigation acceptance —14/10/2026

Uncommitted local source on `codex/dashboard-motion-performance`, base
`4a196ef33019b38c6c2812fcbd48f05bf0d7d134`. Includes the previously accepted dashboard
changes; this turn refines the pictured masthead navigation. No push/PR/merge/deploy.
Actual UTC timestamps are recorded in JSON; client date14/10/2026.

| Gate | Result | Evidence |
|---|---|---|
| Keyboard/semantics/large text/contrast and existing layout regressions | PASS6 | targeted-tests.txt |
| Format119/analyze/Flutter290/backend143 | PASS | check.txt |
| Loopback API owner/editor/viewer/stranger | PASS | api.json, api.txt |
| Real Web three destinations, themes, keyboard, resize and query | PASS scoped | browser.json, keyboard-browser.txt, resize-browser.txt, screenshots |
| QA Web/API8060/offline resources | PASS | build-web-qa.txt |
| Local Web/API8000/offline resources | PASS | build-web-local.txt |
| APK debug/emulator API10.0.2.2:8000 | PASS compile | build-android-debug.txt |
| Android runtime/IME/FPS/screen reader/provider/CI/release | NOT RUN | no inferred completion |

Synthetic API fixture: one owned/shared-out note, one shared-in note from a QA collaborator.
DB is under tmp/desk-navigation-2026-10-14; providers disabled. No production state,
private tokens, cookies or real user content in evidence. Source/backend/schema/permissions
are unchanged apart from the stated UI. Browser control used cua_repl only.

Images: full desktop-light/shared-light/ai-light/shared-dark;1280×1000. The navigation-only
light/dark images are native screenshot crops of the observed group DOM bounds. Also
desktop-1180-dark, phone-dark, rail-dark and desktop-return-dark show responsive states.
No image editing or simulated screenshot. Keyboard-browser records the shared heading
after Shift+Tab/Enter; resize-browser includes the retained search value and destination.

Reproduce format/analyze/tests via scripts/check.ps1; targeted tests:
`flutter test test/desk_navigation_test.dart test/deskbook_layout_test.dart --reporter expanded`.
Build QA: `flutter build web --release --no-web-resources-cdn --output tmp/desk-navigation-web-2026-10-14 --dart-define=API_URL=http://127.0.0.1:8060`,
then `scripts/prepare_web_offline.py --build-dir tmp/desk-navigation-web-2026-10-14`.
qa_server.py requires a fresh --db path under tmp, origin7378 and port8060. qa_api.py/
prepare_fixture.py create synthetic users/notes through the real API. For another run,
copy helpers into a new evidence directory and adjust paths together; do not overwrite
this snapshot. The QA tab and servers8060/7378 were closed after acceptance.

Initial probes under ignored tmp diagnosed separate semantics nodes and test-harness
cleanup/header-name mismatches. Use accepted logs above. A transient long-input browser
transport timeout was resolved using documented paste input; it is not an app bug claim.

SHA256SUMS/source_manifest/artifacts confirm byte integrity, not a fresh test execution
or FPS measurement. Previous dashboard and publication evidence payloads stay unchanged.
[Implementation](../../docs/UI_DESK_NAVIGATION.md).
