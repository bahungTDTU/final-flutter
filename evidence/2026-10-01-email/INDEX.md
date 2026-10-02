# SMTP/TLS và email code UI — 01/10/2026

Workspace D:\flutter cuoi ki. Windows11, Flutter3.47.1/Dart3.13.1, Python3.12,
Chrome154; Android emulator-5554/API36. Commit: chưa có (Git unborn master, không remote).
Không push/deploy/video/timestamp video. Log times là lần chạy local, không contribution cá nhân.

| Ngày | Command/scenario | Target | Kết quả thực |
|---|---|---|---|
| 2026-10-01 | `& scripts/check.ps1` | Flutter unit/widget; SQLite/TestClient; SMTP socket TLS | Format/analyze sạch;71 Flutter/22 backend PASS,1 Starlette warning; checks.txt |
| 2026-10-01 | `.venv/Scripts/python.exe scripts/email_fixture.py --allow-code-endpoint` | API8011, TLS SMTP8025, loopback QA reader8026 | Thư thực qua SMTP socket vào local sink; không email ngoài/forward |
| 2026-10-01 | `adb reverse tcp:8011 tcp:8011`; `adb reverse tcp:8026 tcp:8026` | emulator-5554 | Applied cho HTTP fixture access |
| 2026-10-01 | `flutter test integration_test/email_flow_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8011` | Android debug/API36 | 1 PASS,20s test; platform encrypted store/keys, note preserved, verify/reset/manual login/old session401; android-email.txt |
| 2026-10-01 | `& scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8011` | Web release fixture | PASS39.9s; worker77a417f4ff54f1a9/41 resources; web-fixture-build.txt |
| 2026-10-01 | Playwright CLI `-s=email`, headed Chrome, localhost7357,390x844 | Actual Web release/API8011 | Register/autologin → verify/banner gone → logout → forgot → received-code check → password2x → login screen → manual login/home PASS |
| 2026-10-01 | `.venv/Scripts/python.exe evidence/2026-10-01-email/verify_web_email.py` | Same disposable account + actual API/SQLite | PASS old-password401/new200/verified=true, both code reuse400/DBdigest-only+used; web-api-confirmation.json |
| 2026-10-01 | `& scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8000` | Normal Web release restored | PASS37.4s; workere0024e394d2344b9/41 resources; web-build.txt |
| 2026-10-01 | `& scripts/build.ps1 -Target apk -ApiUrl http://127.0.0.1:8000` | Release APK | PASS52.3MB,37.8s; debug signing, không install/core release QA đợt này; apk-build.txt |
| 2026-10-01 | `& scripts/start_backend.ps1`; `GET /health` | Normal backend8000 | Restart code mới; email_delivery=not_configured, không gửi thư; runtime.json |

## Web procedure và ảnh

CLI dùng `npx --yes --package @playwright/cli playwright-cli -s=email`:
open/snapshot/click/type/run-code/screenshot. Session Chrome riêng, accessibility bật cho Flutter;
mỗi click lấy reference từ snapshot mới. Disposable account web-mail-20261001-1243@example.test.
Fixture passwords có trong verifier chỉ cho QA, không credentials thật. Code lấy từ thư đã nhận bằng
`GET http://127.0.0.1:8026/code?email=...&kind=verify|reset`, header X-Email-Fixture=local-test-only;
gõ vào UI, nhấn Xác nhận/Kiểm tra mã. Không lấy token từ SQLite, không bypass activation/reset API.

Form password chỉ xuất hiện sau code-check200; code read-only. Reset quay về màn hình login,
không auto-login; đăng nhập bằng password mới qua UI rồi Home không banner. Snapshots tạm sau
check có mã được redact trước đọc; file evidence cuối không chứa code/session/password.
Settings semantic overlay intercept click Đăng xuất, dùng force click đúng control rồi xác nhận
auth screen; không tuyên bố initial automatic click pass hoặc full keyboard/screen-reader QA.

- web-verified-home.png: Home sau verify, không banner.
- web-reset-manual-login.png: màn hình login sau reset.
- web-final-home.yml: actual snapshot sau manual login/new password.
- web-api-confirmation.json: timestamp UTC thực + HTTP status/DB assertions, không secrets.

## Phạm vi

Backend tests có owner/viewer/editor/stranger negative cases; frozen editor base revision,
immutable preferences và encrypted recovery regressions vẫn qua toàn bộ Flutter suite.
SMTP transport tests có STARTTLS/implicitSSL/AUTH-sau-TLS/UTF8, không hỗ trợTLS/untrustedCA/
recipient refusal fail closed; token30min/reuse/kind/reset-check/cooldown/known-unknown/status tests.
RecordingDelivery được inject explicit cho failure scenario; production không chọn mock/mailbox.

SMTP sink dùng certificate local sinh tại tmp/email-fixture ignored; CA trusted chỉ fixture. QA reader
chỉ disposable example.test, explicit flag, loopback/no-store, không có trong production backend.
Internet SMTP credentials/auth, inbox receipt/Gmail/Outlook/SPF/DKIM chưa chạy; SMTP accepted
không đồng nghĩa inbox delivery. Chưa durable email outbox/worker retry hoặc timing-abuse guarantee.
Android functional test debug/emulator; physical/release core/OS kill chưa chạy. Web local HTTP
không public HTTPS. Widget390x844/scale2 không thay native/browser font200% hay screen reader.
Không tăng trạng thái full tiêu chí2/4/32. Cấu hình/tái lập: docs/EMAIL_DELIVERY.md.

Sau QA đã tắt fixture8011/8025/8026, gỡ adb reverse8011/8026 và đóng Chrome session email.
runtime.json xác nhận HTTP fixture8011/8026 không còn chạy; backend8000 giữ hoạt động.
README.md/Readme.txt đã đối chiếu byte-identical. Build Web cuối API8000, không giữ fixture target.
