# Protection/status —07/10/2026 Asia/Saigon

Base f8ff8fa427b3d490255c0522699f1a9650a3cb73 + working changes, chưa commit/push.
F1/F2 audit fixes + user's explicit public-pin/shared policy; preserve prior UI work.

| Command / target | Result | Files |
|---|---|---|
| scripts/check.ps1 |Format80 files0changes/analyze clean;173 Flutter/93 backend PASS;1 upstream warning |check.txt |
| flutter test test/locked_status_test.dart |6 PASS after fixture/locator repairs |flutter-status.txt |
| pytest password_limits/listing/security/protected_editing |27 PASS/1 warning |backend-targeted.txt |
| python scripts/qa_protection_status.py --output evidence/2026-10-07-protection-status/http.json |Actual HTTP4roles/mixed attempts429/public flags/pin/revoke PASS |http.json;http.txt |
| Flutter run -d web-server --web-port7365 --web-hostname127.0.0.1 --dart-define=API_URL=http://127.0.0.1:8016 |IAB actual grid/list1280×900/mobile390×844/reload/SSE clear/restore PASS |web-ui.json;5web JPG;web-clear-api.json;web-restore-api.json |
| Flutter drive locked_status integration / emulator-5554 API36 |1new scenario+teardown PASS7s |android.txt;native/4PNG |
| flutter pub get; flutter analyze / final81 source files |Dependencies/registrant normal; analyze clean |pub-get.txt;analyze-final.txt |

Native exact command: `flutter drive --driver=test_driver/ui_cohesion.dart
--target=integration_test/locked_status_test.dart -d emulator-5554
--dart-define=API_URL=http://127.0.0.1:8016 --enable-software-rendering --no-enable-impeller`.
UI_SCREENSHOT_DIR=evidence/2026-10-07-protection-status/native,
ANDROID_AVD_HOME=D:/Android/avd; taskflow_api36 preinstalled, adb reverse8016.
Unique QA Sembast file + disposable account; successful workflow closes/deletes own DB.
Reopen uses real device key/account AES-GCM, then real unreachable socket65530; not mocked
connectivity, not OS relaunch or network toggle. No manual GeneratedPluginRegistrant edit.

Loopback backend: tmp/priorities/server.py, isolated tmp/priorities/qa.sqlite3, email disabled,
AI stub that rejects inference, worker disabled. CORS limited to local Web7365. HTTP helper
creates disposable accounts/notes; no bearer credentials in evidence. Browser fixture login
file stays ignored tmp and is removed after QA. Public status fields contain no note title,
body/labels/share identities/times/counts. Pin timestamps are intentionally public per user.

## Failure history

- flutter-targeted-first.txt: new390px/200% test checked a lazy card before scrolling;
  existing protected/cohesion tests passed. Added scroll, kept assertions.
- flutter-status-first.txt: after unsharing it matched global people icon from navigation;
  scoped assertion to actual card, kept privacy/semantics/flag checks. Final6 PASS.
- check-first.txt: unused import and audit-snapshot print lint; removed import, explicit
  analyzer source scope excludes frozen evidence/generated tmp, keeps actual test dirs.
- android-first.txt: ordinary fixture accidentally used same body as protected fixture,
  making global privacy assertion fail. Changed ordinary fixture to Visible ordinary body.
- android-second.txt: after screenshot/card scroll, header had been Sliver-unloaded;
  test now scrolls to actual list control. Final native scenario passes without skipped checks.
- Initial Web login hit missing7365 QA CORS origin; configured loopback origin/restarted
  helper and actual login/flags/refresh passed. No production CORS policy broadened.

Host formatting/analyze and historical hashes/logs are separate from functional tests.
No release/signing/public hosting, Internet SMTP/real Gemini, physical/FPS/NVDA/TalkBack/video.
Full rationale: [PROTECTION_STATUS_FIXES.md](../../docs/PROTECTION_STATUS_FIXES.md).
