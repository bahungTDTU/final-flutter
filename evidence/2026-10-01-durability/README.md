# Durability evidence — 01/10/2026

Workspace D:/flutter cuoi ki. Local Git chưa commit; không có commit ID.

- Command: powershell -ExecutionPolicy Bypass -File scripts/check.ps1.
  Target: Windows host Flutter tests + FastAPI TestClient/temporary SQLite.
  Result: format23 files unchanged; analyze no issues;45 Flutter tests PASS;14 backend tests PASS.
  Một Starlette/httpx deprecation warning. Log checks.txt.
- Command: flutter test integration_test/note_flow_test.dart -d emulator-5554
  --dart-define=API_URL=http://127.0.0.1:8000, sau adb reverse tcp:8000 tcp:8000.
  Target: Android debug emulator + real local backend.
  Result:1 integration PASS. Log android-integration.txt.
- Test source: test/sync_durability_test.dart,8 tests mới. Sembast file close/reopen thật trên
  Windows; blocked writes/disk failure và HTTP loss/ack races được điều khiển bằng doubles.
  Đây không phải force-kill/native two-device/browser conflict nghiệm thu.
- Web build command: powershell -ExecutionPolicy Bypass -File scripts/build.ps1 -Target web.
  Result PASS, worker notetogether-static-321ef473f248fcdf,41 resources; log web-build.txt.
  Build không chứng minh browser behavior; chưa browser regression lượt này.

Không encrypted vault/key rotation, production release, deploy, video hoặc fake timestamp.
