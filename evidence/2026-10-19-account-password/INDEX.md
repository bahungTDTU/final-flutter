# Account password UI native acceptance —19/10/2026

Base a351e08 + session_storage_test.dart extension (hashes attached).
No production app/controller/API changes. Android16/API36 emulator-5554 debug,
software rendering, local real API8062/SQLite QA with providers disabled.

PASS actual production Home settings→password dialog current/new/confirmation→submit.
App returns auth route; both current token and peer token GET /me return401. Old password
login401. Actual auth form manual login using changed password restores same account,
encrypted session and invalid draft. Registration/server tests use disposable account.
Input injected by Flutter driver, not real IME. Existing native legacy migration,
offline session reopen/logout/manual-login assertions also pass in the same integration.

Command: JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:\Temp\notetogether-jvm;
flutter drive --no-pub --driver=test_driver/integration_test.dart
--target=integration_test/session_storage_test.dart -d emulator-5554
--dart-define=API_URL=http://10.0.2.2:8062 --enable-software-rendering --no-enable-impeller.
Debug build49.2s PASS; integration23s PASS. Excerpt preserves result lines; full log
ignored at output/native-password-oct19.txt (temporary VM capability redacted during capture).
Flutter full279 tests PASS earlier this turn; final116files format0 changes PASS; final analyze PASS15.3s.

Web release compile115.2s PASS, static offline manifest40resources generated. This is
compile only: Web UI not run this turn. mcp__cua_repl getState failed twice including
reset; node_repl Computer Use @oai/sky initialization also failed with exact error:
“failed to write kernel assets: The system cannot find the path specified. (os error 3)”.
No UI actions could be taken and no browser acceptance claimed. Tooling failure is
separate from app behavior; no inferred Web failure/PASS. Browser gate remains open.

Other external gates unchanged: Docker Linux engine pipe absent, ignored signing
config absent, SMTP/Gemini not configured per user, official Rubric/video absent.
No release/deploy/merge/submission. N05 account-password native UI supplemented;
Web password UI, picker/labels and C1/C2 full final-artifact gates stay open.
