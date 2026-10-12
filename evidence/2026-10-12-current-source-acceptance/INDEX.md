# Current source acceptance — 12/10/2026

Source base: `46df286302cc88e07c98ba1b14160cc64491e2df`, branch
`codex/current-source-acceptance`. App/backend business code matches that base;
working changes are test harnesses, QA scripts and documentation. `source-manifest.json`
records SHA256 of the code/scripts exercised; containing Git commit records final docs.
Author/committer: Nguyễn Bảo Long <523k0014@student.tdtu.edu.vn>; AI-assisted implementation/QA.

## Environment and commands

Windows, Flutter 3.47.1/Dart 3.13.1, Python 3.12 venv, JVM actually Java17,
Android16/API36 `taskflow_api36`, emulator-5554, software rendering/headless.
Flutter SDK mapped to F: after verifying the drive was unused. Disposable SQLite in
ignored `tmp/current-source-acceptance`, API127.0.0.1:8042 (Android10.0.2.2:8042),
Web release127.0.0.1:7364. No personal DB, SMTP/Gemini or external provider calls.

- Native: `scripts/qa_native.ps1 -Device emulator-5554 -ApiUrl http://10.0.2.2:8042 -JvmSocketDirectory C:\Temp\notetogether-jvm -SoftwareRendering -EvidenceDirectory evidence/2026-10-12-current-source-acceptance`.
- Protected: `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/protected_editing_test.dart -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:8042 --enable-software-rendering --no-enable-impeller`, same process-only JAVA_TOOL_OPTIONS socket setting.
- HTTP: `.venv/Scripts/python.exe scripts/qa_protected_notes.py --url http://127.0.0.1:8042 --output evidence/2026-10-12-current-source-acceptance/http-acl.json`.
- Web: release build with `--dart-define=API_URL=http://127.0.0.1:8042`, then `scripts/prepare_web_offline.py`;39 static resources. Actual IAB UI registration/edit/reload/offline/reconnect, not fixture.
- Analyze: `flutter analyze integration_test/protected_editing_test.dart integration_test/sharing_test.dart test_driver/editor_input.dart`; format these3 files:0 changed.

## Results

| Scope | Result / evidence |
|---|---|
| GitHub upstream | PR5 baseline, PR6 security center, PR7 Deskbook merged; all3 checks success on each exact head in github.json |
| Native note_flow | PASS; registration/autosave/GET, Sembast+device key, offline socket and DB reopen; 20261012-202119-067 results JSON (all3 exit0) |
| Native sharing/realtime | PASS after phone menu locator; role downgrade/revoke/recovery/frozen409; 20261012-202119-067 results JSON (all3 exit0) |
| Native protected | PASS native-protected-focus.txt; SSE, frozen base, autosave, offline draft assertion+dirty encrypted envelope before DB close, reopen→backendGET same content, revalidation, confirmed delete |
| HTTP4roles | PASS http-acl.json/txt; protected ACL/mutations/replay/409/private files/revoke/password/delete |
| Web build | PASS web-build.txt |
| Web actual UI | PASS screenshots/AX snapshots and web-roundtrip.json; Vietnamese bold, undo/redo, autosave→reload, backend unavailable edit→reload→reconnect; UUID82332578-469f-4527-a6a9-e39637a55d1d kept, rich Delta bold retained, revision5 |
| Analyze/script validation | PASS analyze-final.txt, script-validation.txt; PowerShell parser, URL guard and environment restore, duplicate HTTP output rejected, Python compile |

## Failed attempts retained

Native Gradle UnixDomainSockets loopback failed; IPv4Stack/java.io.tmpdir/Java17
alone did not resolve it. Process-only `jdk.net.unixdomain.tmpdir` did. Windowed emulator
disconnected mid note_flow; foreground headless software emulator was stable. First script
attempt incorrectly passed software-rendering flags to flutter test (exit64); changed to drive.
First sharing run assumed desktop tooltip; fixed actual phone menu navigation.

Protected runs before focus fix are FAIL, not discarded: first backend was stopped for
Web offline QA while the test compiled (QA scheduling mistake); retry used find.text on
Quill; next assumed save status existed in reading mode. Subsequent assertions exposed
input still targeting the preceding password client. Waiting for focus before opening
Quill TextInputClient fixed it; final PASS keeps stronger draft/envelope/backend assertions.
No production behavior was changed to satisfy the test. Earlier FAIL screenshots are
not used as final protected visual acceptance.

New publishable logs redact only temporary VM-service capability URLs as [REDACTED];
private original copies retained under ignored tmp. Historical evidence folders unchanged.
Synthetic local emails/note text/UUIDs are test data; no auth tokens or DB/key files published.

## Remaining gates

Stage2 remains open: real native IME/Telex/VNI/selection/paste/format, OS force-stop/relaunch,
two independent UI peers for dirty draft/revoke, protected TTL/background/picker cancel/error,
remaining avatar/labels/session acceptance. Injected TextInputClient != real IME;
same-process DB reopen != OS relaunch; API/controller peer != two UI users.
User confirmed no SMTP/Gemini configuration: stage3 blocked pending real setup/receipt/provider.
HTTPS/release signing/submission/video/team evidence remain later stages. CI of prior PRs
is upstream history; new branch requires its own CI and another human approval before merge.
