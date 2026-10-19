# Native core OS process relaunch —19/10/2026

Base d929a63 + QA helper sources SHA256 in result.json. App production code unchanged.
Android16/API36 taskflow_api36 emulator-5554, debug QA entrypoint, software renderer;
local Uvicorn API8062 with disposable tmp/os-relaunch-20261019/qa.sqlite3.
SMTP/Gemini explicitly disabled. No personal app database opened.

PASS: exact same installed APK force-stopped with am force-stop; pidof empty before
launch; PID4558→4729. Native secure-storage keys and encrypted Sembast reopened.
Rich Vietnamese/bold Delta, invalid italic draft and complete immutable operation
fingerprint survived. Reconnect to real HTTP backend returned exactly one original
UUID with exact rich content, pending empty and invalid draft retained. No synthetic
content/token plaintext found in Sembast file. APK SHA256 and helper hashes in result.

Commands: flutter build apk --debug --target test_driver/os_relaunch_app.dart
--dart-define=API_URL=http://10.0.2.2:8062 --dart-define=QA_RUN_ID=oct19-os-a;
python scripts/qa_os_relaunch.py --adb C:/Android/sdk/platform-tools/adb.exe
--device emulator-5554 --apk build/app/outputs/flutter-apk/app-debug.apk
--run-id oct19-os-a --output output/os-relaunch/oct19-os-a.json.
Build incremental24.5s PASS; initial build137.2s PASS. Both use private JVM socket
directory workaround in JAVA_TOOL_OPTIONS, no system config changed.

Flutter full tests279 PASS58s; analyze PASS; Dart format/Python compile/diff check PASS.
No backend changes, no new backend suite claim (previous148 PASS remains historical).

Scope limits: controller-written data in dedicated QA entrypoint; no real IME/editor
UI, Wi-Fi toggle, production main-entrypoint/signed artifact or physical-device claim.
Socket65530 refusal represents backend unreachable, not a network-adapter toggle.
OS kill happens after awaited local commit; uncommitted keystrokes are not guaranteed.
N02 core supplemented; C1/N01 and full final-artifact N02 remain open.
See docs/NATIVE_OS_ACCEPTANCE.md for replay and manual cases.
