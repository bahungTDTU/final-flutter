# Tiêu chí 8 – Preferences: bằng chứng ngày 01/10/2026

Target: Windows 11, Flutter 3.47.1/Dart 3.13.1, Python 3.12, Chrome 154,
Android API 36 emulator `taskflow_api36` / `emulator-5554`. Backend thật local
FastAPI/SQLite tại `http://127.0.0.1:8000`; Web release tại localhost:7357.
Commit: chưa có commit; không gán tác giả Git hay contribution cá nhân.

| Lệnh / kiểm tra | Kết quả thực tế | File |
|---|---|---|
| `scripts/check.ps1` | Format/analyze sạch, 12 Flutter tests (6 unit + 6 widget), 14 backend tests PASS; 1 Starlette deprecation warning | checks.txt |
| `flutter test integration_test/note_flow_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000` (Flutter executable qua toolchain) | 1 integration PASS: real HTTP, native Sembast reopen, offline note + preferences, reconnect, second-session preference update | android-integration.txt |
| `scripts/build.ps1 -Target web` (build + static worker) | PASS, static manifest 39 resources | web-build.txt |
| `flutter build apk --release --dart-define=API_URL=http://127.0.0.1:8000` | PASS, APK 50.6 MB; chưa kiểm tra functionality của release này | apk-build.txt |
| Playwright CLI session `preferences`, Chrome Web release | PASS offline edit → offline reload → reconnect; server values xác nhận bằng SQLite | web-*.png, web-server-confirmation.json |
| `.venv/Scripts/python.exe evidence/2026-10-01-preferences/verify_web_preferences.py` | SQLite assert grid=false, dark=true, font_size=18, ≥3 accepted operations PASS | web-server-confirmation.json |

Browser sequence thực chạy bằng `npx --yes --package @playwright/cli playwright-cli -s=preferences`:
login tài khoản kiểm thử, `network-state-set offline`, chuyển grid→list, bật dark,
slider từ16→18 bằng keyboard. UI hiện 3 pending operations (ảnh web-offline-settings).
`reload` trong offline vẫn mở app/cache; kích hoạt Flutter accessibility và mở settings:
dark checked, font18, list view và pending3 còn nguyên (ảnh web-offline-reload).
`network-state-set online`, bấm Đồng bộ tùy chỉnh: pending biến mất, theme/font/view giữ nguyên
(ảnh web-synced-settings); truy vấn SQLite xác nhận dữ liệu server.

Một số click qua Flutter semantics bị overlay chặn; dùng Playwright `click({force:true})`
cho switch và sync, keyboard cho slider. Đây là giới hạn automation đã quan sát;
chưa nghiệm thu screen reader hoặc keyboard navigation toàn ứng dụng.
Console offline có `ERR_INTERNET_DISCONNECTED` ở GET /me như dự kiến; không gọi đây là lỗi production đã khắc phục.

Unit/controller dùng HTTP và memory doubles; backend dùng SQLite/TestClient.
Android integration dùng socket port65530 không lắng nghe để gây lỗi HTTP thật,
DB close/reopen cùng process, không OS force-kill/relaunch hoặc Wi-Fi toggle/physical device.
Không SMTP thật, public HTTPS, release signing, video, submission hoặc kết luận đạt đủ32 tiêu chí.
