# OTP 6 chữ số — 18/11/2026

Kiểm tra thay đổi local trên base `f880c06`. Backend thử nghiệm dùng SQLite
mới, API 8011, SMTP STARTTLS local 8025 và code reader fixture 8026.
Chrome phục vụ bundle release local trên cổng 7391.

| Lệnh hoặc luồng | Kết quả |
|---|---|
| `python -m pytest backend/tests -q` | PASS 166. Gồm giới hạn 5 lần sai qua restart, scope email/mục đích, gửi lại, backup cũ, ACL và SMTP TLS. |
| `flutter analyze --no-pub`, `flutter test --no-pub` | PASS, không issue và 333 tests. Widget reset gửi đúng email và mã bắt đầu bằng 0. |
| `flutter build web --release --no-web-resources-cdn --dart-define=API_URL=http://127.0.0.1:8011 --output tmp/otp-20261118/web` | PASS. Offline manifest được tạo cho 41 tài nguyên. |
| `scripts/email_fixture.py --allow-code-endpoint` và `scripts/qa_email_queue.py`, bản sao QA dùng DB/output riêng | PASS thực qua HTTP và SMTP TLS local. Verify dùng một lần, reset trả về đăng nhập thủ công và thu hồi phiên cũ. |
| Chrome Playwright trên bundle mới | Nhập OTP qua bàn phím, xác minh thành công. Reset nhận mã bắt đầu bằng 0, chuyển sang form mật khẩu, HTTP 200 và trở về màn hình đăng nhập. Lần đầu dùng thao tác fill trực tiếp của Playwright thì form báo thiếu dữ liệu. Đã chạy lại bằng bàn phím. |

Chưa gửi OTP mới qua Gmail thật và chưa chạy APK Android cho thay đổi này.
Kết quả Gmail `smtp_accepted` trước đó thuộc luồng mã dài.

## Cấu hình SMTP từ .env

Trên cùng base `f880c06` với thay đổi local, `scripts/start_backend.ps1
-Port <cổng QA> -EnvFile <file QA>` chạy PowerShell và Uvicorn thật. File
Gmail QA chứa hai biến, có BOM UTF-8 và App Password giả có khoảng trắng.
`GET /health` báo `email_delivery: smtp`. Ca Gmail chỉ kiểm tra khởi động.
Ca với MailSink localhost đọc các biến từ file riêng, xác thực sau
STARTTLS, gửi OTP 6 số từ HTTP đăng ký và xác minh thành công. Biến
`SMTP_FROM` ở process ghi đè giá trị trong file.

`python -m pytest backend/tests/test_email.py backend/tests/test_email_queue.py backend/tests/test_backup.py -q`
PASS 26. Không dùng credential thật hoặc gửi thư ra ngoài trong lượt này.

## Gmail thật ngày 19/11/2026

Source local trên base `f880c06`, gồm thay đổi OTP và nạp dotenv chưa push.
`scripts/start_backend.ps1` khởi động tại `127.0.0.1:8000` và nạp
`.env`. `GET /health` trả HTTP 200, `email_delivery=smtp`,
`ai=not_configured`.

`POST /auth/register` trả HTTP 201 cho alias QA của hộp gửi Gmail. SQLite
xác nhận bản ghi xác minh dùng định dạng OTP mới. `GET /auth/email-status`
chuyển từ `queued` sang `smtp_accepted`. Gmail đã chấp nhận thư xác minh.
Phiên QA đã đăng xuất. Chưa xác nhận vị trí thư trong inbox và chưa thử
reset qua Gmail thật trong lượt này.

PR #19 trên GitHub có ba CI PASS tại commit `f880c06` và còn mở. CI đó
chưa bao gồm phần OTP và dotenv local.

## Quên mật khẩu qua Gmail ngày 19/11/2026

Người dùng xác nhận đã nhận thư xác minh chứa OTP 6 chữ số ở ca trước.
PR #19 đã merge vào `master` tại `71fcd31`. Nhánh `codex/email-otp-dotenv`
dùng source cùng tree với `f880c06` trước khi áp dụng các thay đổi OTP.

Ca reset dùng FastAPI TestClient và SQLite tạm. Đăng ký tài khoản QA với
SMTP tắt, rồi mở lại cùng SQLite với transport Gmail thật lấy cấu hình từ
`.env`. Bộ kiểm thử chỉ cho gửi thư reset tới alias của hộp Gmail đã cấu
hình. Sau khi Gmail nhận SMTP DATA, mã QA được giữ trong bộ nhớ để kiểm tra
API. Ca này không cần đọc hộp thư hoặc ghi mã, mật khẩu và địa chỉ vào log
đưa lên Git.

| Kiểm tra | Kết quả |
|---|---|
| `POST /auth/forgot` | HTTP 200, phản hồi generic `requested`. |
| Gmail SMTP gửi OTP reset 6 chữ số | PASS `smtp_accepted`. |
| `POST /auth/reset/check`, `POST /auth/reset` | PASS, mã hợp lệ và thay mật khẩu, yêu cầu đăng nhập lại. |
| Dùng lại OTP, phiên cũ, mật khẩu cũ | Bị từ chối với HTTP 400, 401, 401. |
| Đăng nhập bằng mật khẩu mới | HTTP 200. Phiên QA sau đó đã đăng xuất. |

Kết quả trên xác minh transport Gmail và toàn bộ API reset. Vị trí thư reset
trong Gmail và UI Android sau thay đổi cần được xác nhận riêng.

Kiểm tra trước khi push trên nhánh mới:

- `scripts/check.ps1` PASS format 138 file, analyze, 333 Flutter tests và 167
  backend tests. Backend còn một cảnh báo deprecation của Starlette TestClient.
- `scripts/qa_protected_notes.py` qua backend HTTP QA ở cổng 8077 PASS bốn
  vai trò, lock/grant, chỉnh sửa theo revision, quyền tệp và thu hồi grant.
- `git diff --cached --check` và quét dữ liệu cấu hình riêng PASS. Chỉ mẫu
  `.env.example` với trường credential trống được stage.
