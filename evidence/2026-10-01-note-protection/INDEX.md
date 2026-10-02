# Note protection evidence — 01/10/2026

Commit: chưa có; git log xác nhận unborn master. Windows11/Flutter3.47.1/Dart3.13.1/
Python3.12; localhost FastAPI/SQLite8000, release static7357; emulator-5554 API36.

| Lệnh / target | Kết quả chốt | Artifact |
|---|---|---|
| scripts/check.ps1 / Windows local | Format/analyze sạch;67 Flutter/15 backend PASS;1 TestClient deprecation warning | checks.txt |
| flutter test integration_test/note_protection_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000 (adb reverse/backend running) |1 integration PASS, native dialogs + platform key store/Sembast + API; lifecycle notification mô phỏng | android-protection.txt |
| scripts/build.ps1 -Target web / release | PASS; workeraf10e1047aa661e6,41 static resources | web-build.txt |
| scripts/build.ps1 -Target apk / release | PASS;52.3MB; local HTTP/debug signing, chưa production release acceptance | apk-build.txt |
| Playwright CLI session vault / Chrome localhost:7357 | Enable menu/password2x → neutral cards → wrong/retry/read → relock → change → unlock new → disable → reload | web-reader.png,web-locked-home.yml,web-changed-gate.yml,web-mobile-gate.png |
| python scripts/verify_note_protection.py changed | New independent session: metadata neutral/rev3; old403/new200/relock423; original423; exact fixture preserved/count2 | web-changed.json |
| python scripts/verify_note_protection.py final | After UI disable: rev4, content200 without grant, original423, exact content/count2 | web-final.json |

Backend API tests cover owner/viewer/editor/stranger, own-session relock isolation and idempotency;
negative 401/403/404/423 cases intentional. Browser console403 entries came from deliberate wrong
password; not unexpected JS crash. Unit requests are doubles; backend TestClient uses real SQLite.
Native debug integration uses real HTTP/backend and platform local plugins. Older encrypted recovery/
baseline native integrations were not rerun this increment; unit crypto/recovery tests ran in check.

Harness troubleshooting: Flutter Web fill could leave confirmation empty; click-focus + separate
keyboard commands/observed values used before submit. Native tester focusedEditable retained a
closed connection after busy-disabled field; reset test binding connection, assert typed value,
hide native keyboard, await real response before checking. Final PASS logs do not imply first run passed.

Tab-select experiment kept document.visibilityState=visible on both automated tabs and did not hide
reader; it did not generate a browser hidden lifecycle event. Real browser background/OS recents,
full screen-reader, physical device, force-kill/relaunch, offline note-password unlock and protected
editing remain unverified/unavailable as applicable. Reader visual is desktop dark; mobile screenshot
is password gate390x844 after reload. No end-to-end encryption/production/signing/public deployment claim.

Fixture credentials are disposable local test inputs. Evidence snapshots exclude token/device keys;
scripts print assertions/IDs/statuses only. No commit/push/deploy/video/submission occurred.
