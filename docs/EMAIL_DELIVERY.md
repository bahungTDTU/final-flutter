# SMTP và xác minh/khôi phục bằng mã email

Đề gốc tr.2–3 cho phép link hoặc mã tương đương/OTP. NoteTogether dùng mã43 ký tự URL-safe,
copy nguyên mã từ email vào app Web/Android. Mã được dẫn xuất HMAC-SHA256 từ nonce ngẫu nhiên
32 byte + account/kind và khóa server32 byte, không tự viết thuật toán crypto. Không cần deep
link để dùng luồng này. Mã một lần, hết hạn sau30 phút từ lúc tạo; email_tokens lưu SHA-256
digest, email_jobs chỉ giữ nonce/metadata để retry. Không lưu mã thô trong SQLite hoặc log.

Đăng ký tự đăng nhập; chưa verified vẫn dùng chức năng ghi chú. Home **Xác minh** → nhập mã
→ **Xác nhận** → Back; banner biến mất sau cập nhật profile. **Gửi lại mã xác minh** cần session
của đúng tài khoản. Gửi lại thay mã cũ và có cooldown60s (kể cả lần gửi khi đăng ký).
Đã verified không gửi lại. Lỗi gửi không xóa tài khoản, không ép logout và không fake verified.

**Quên mật khẩu** ở màn hình đăng nhập → nhập email → mã khôi phục → **Kiểm tra mã**. Password
fields chỉ hiện sau API kiểm tra mã; kiểm tra chưa tiêu thụ mã. Nhập mật khẩu mới hai lần
(10–128 ký tự) → xác nhận. Backend kiểm tra lại TTL/kind/used và tiêu thụ mã trong transaction,
đổi Argon2id hash, hủy mọi session/grant cũ. App về login để đăng nhập thủ công, không auto-login.
Mã invalid/expired/reused giữ input và báo lỗi; có thể chọn **Nhập mã khác**.

Đợt06/10: đăng ký/resend trả `queued` ngay sau transaction, không chờ SMTP. **Kiểm tra trạng
thái gửi** truy vấn GET /auth/email-status bằng session của đúng account, không trả mã/nonce/
recipient hoặc trạng thái của người khác. UI phân biệt queued/retrying/smtp_accepted/failed/
expired/not_configured. Public reset có **Email nhận mã khôi phục → Yêu cầu gửi lại mã**;
luôn phản hồi generic/cooldown như nhau cho known/unknown email, không có public delivery-status.
Chưa verified vẫn dùng ghi chú; lỗi email không phải verified success hoặc inbox receipt.

## Hàng đợi bền và vòng đời

email_jobs được tạo cùng transaction với account/token/session hoặc resend/reset request.
Worker chạy trong FastAPI lifespan, SMTP ở ngoài DB transaction/request auth. Lease120s,
claim transaction serial cho nhiều worker; restart retry job chưa xong sau lease, không reset
lease của worker khác. Backoff15/60/180/600/900s, tối đa6 claim attempts (kể cả crashed claim).
Mã giữ nguyên qua retry. Key/storage lỗi giữ payload và không gửi mã không xác thực; không
tăng attempt SMTP khi key chưa sẵn sàng. Expired/used/replaced tokens hủy pending job; worker
kiểm tra lại ngay trước gửi. SMTP đã in-flight có thể đến muộn, nhưng mã cũ không dùng được.

`smtp_accepted` chỉ nói SMTP nhận DATA. Timeout sau DATA/process crash có thể khiến cùng mã
gửi hơn1lần; đây là at-least-once, không exactly-once/inbox delivery. Success/failed/cancelled
xóa nonce khỏi record sống, terminal jobs giữ tối đa24h qua cleanup worker. Không hứa secure
erase SQLite pages/backups. Profile/session/vault của Flutter không đổi theo đợt này.

Khóa HMAC riêng nằm ở `NOTETOGETHER_DB + .mail-key`, hoặc `MAIL_OUTBOX_KEY_FILE` được cấu hình.
Auto-create bằng exclusive write/fsync khi gửi đã configured lần đầu; đọc lại32 byte trước
enqueue. Mất/hỏng khóa khi DB đã có jobs không tự tạo khóa thay thế: resend/register trả503,
pending jobs vẫn giữ, public forgot vẫn generic để không lộ account. Phục hồi đúng khóa từ
backup server. Disabled SMTP không tạo jobs/key. Key không derive từ mật khẩu user/note.
Giữ khóa cùng server state trong backup có kiểm soát; không đưa vào Git/ZIP/Web root. *.mail-key
đã Git ignored; custom filename khác phải nằm trong thư mục ignored. POSIX mode600; Windows
dùng ACL của thư mục triển khai, không claim os.open mode bảo đảm ACL Windows hoặc key escrow.
Không cung cấp UI tự rotate/delete key ở đợt này. Key là bí mật server, không phải device vault key.

## Cấu hình hộp thư ngoài

Backend đọc process environment; không tự load .env. .env.example chỉ là template, không chứa
secret thật. Không dán password vào chat/repo. Chỉ cấu hình credentials của nhóm sau khi có
dịch vụ. Đợt này không thêm credential ngoại vi hoặc gửi thư ngoài.

| Biến | Ý nghĩa |
|---|---|
| SMTP_HOST |Host provider; trống = disabled, không giữ mailbox mã thô |
| SMTP_PORT |587 cho STARTTLS hoặc465 cho implicit TLS theo provider |
| SMTP_SECURITY |starttls hoặc ssl; không chấp nhận plaintext/none |
| SMTP_FROM |Địa chỉ sender ASCII được provider cho phép |
| SMTP_USERNAME/SMTP_PASSWORD |Cả hai có hoặc cùng trống cho TLS relay; chỉ auth sau TLS |
| SMTP_TIMEOUT |Socket timeout mỗi bước,1–6 giây, mặc định3; không phải tổng deadline |
| SMTP_CA_FILE |Optional trusted CA riêng; mặc định system roots; luôn verify certificate/hostname |
| MAIL_OUTBOX_KEY_FILE |Optional đường dẫn khóa HMAC32 byte; mặc định bên cạnh DB, đuôi .mail-key |

PowerShell, thay placeholder bằng dịch vụ thật của nhóm và restart backend:

```powershell
$env:SMTP_HOST = 'SMTP_HOST_CUA_NHOM'
$env:SMTP_PORT = '587'
$env:SMTP_SECURITY = 'starttls'
$env:SMTP_FROM = 'SENDER_EMAIL_CUA_NHOM'
$smtpCredential = Get-Credential -Message 'Thông tin SMTP của nhóm'
$env:SMTP_USERNAME = $smtpCredential.UserName
$env:SMTP_PASSWORD = $smtpCredential.GetNetworkCredential().Password
try { & scripts/start_backend.ps1 }
finally { $env:SMTP_PASSWORD = $null; $smtpCredential = $null }
```

Khi SMTP_HOST có giá trị, backend fail startup nếu port/security/sender/timeout/cặp credentials
không hợp lệ. Lỗi CA/kết nối báo delivery_failed lúc gửi; không fallback plaintext/bypass CA.
/health email_delivery=smtp chỉ nói đã cấu hình, không chứng minh inbox delivery.
Đăng ký/resend trả queued sau persist, not_configured khi disabled. Authenticated status trả
smtp_accepted chỉ sau SMTP nhận DATA, retrying khi chưa gửi được, failed sau giới hạn retry.
smtp_accepted không bảo đảm email tới inbox; cần kiểm tra spam/provider.
Forgot trả cùng requested/cooldown cho known/unknown email, kể cả lỗi gửi, để không lộ account
existence qua response. Không bảo đảm chống timing/abuse protection hoàn chỉnh.

Gửi lại tạo mã mới và vô hiệu mã cũ trước gửi; SMTP lỗi/timeout có thể xảy ra sau server nhận thư.
Chờ cooldown60s khi muốn mã mới; không sửa timestamp DB production để bỏ cooldown. Worker tự
retry mã hiện tại qua durable outbox. SMTP per-step timeout không phải tổng deadline; worker
graceful shutdown đợi tối đa25s, lease phục hồi phần in-flight sau restart.

## QA local tái lập

Fixture không phải provider: chỉ nhận loopback, dùng certificate OpenSSL local/trusted CA riêng,
không forward thư. Main không có mailbox/raw-token HTTP endpoint/log. Test doubles chỉ được inject
tường minh từ backend/tests, không chọn bằng environment production.

```powershell
# Terminal1: API8011 / TLS SMTP sink8025 / fixture code reader8026.
& .\.venv\Scripts\python.exe scripts/email_fixture.py --allow-code-endpoint
# Terminal2: Android debug integration, emulator đã online.
& 'D:\Android\sdk\platform-tools\adb.exe' reverse tcp:8011 tcp:8011
& 'D:\Android\sdk\platform-tools\adb.exe' reverse tcp:8026 tcp:8026
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' test integration_test/email_flow_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8011
# Web QA với fixture rồi serve bằng start_web.ps1.
& scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8011
# Sau QA, build lại normal target.
& scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8000
```

Code reader chỉ đọc disposable @example.test với X-Email-Fixture=local-test-only; chỉ tồn tại trong
script QA, explicit flag, loopback, no-store/no logs. Không deploy/đưa endpoint vào production.
Certificate/private key/database ở tmp/ ignored; không nộp. OpenSSL cần có trên PATH hoặc Git for
Windows như máy hiện tại; production backend không cần OpenSSL CLI.

Xem evidence/2026-10-01-email, STATUS/matrix cho kết quả thật. Internet SMTP auth/deliverability/
SPF/DKIM, Gmail/Outlook receipt, public HTTPS/native release/physical-device/video chưa xác minh.
Không đánh dấu tiêu chí2/4 full chỉ vì fixture PASS. Backend không thêm dependency runtime.
Đợt outbox06/10: evidence/2026-10-06-email-queue/INDEX.md;146 Flutter/88 backend, real HTTP
roles/TLS receipt và API36 debug lifecycle verify/reset/status; Web debug status/verify/reset
resend/cooldown. Release được người dùng yêu cầu để cuối; không build/deploy release đợt này.
Nguồn: [smtplib](https://docs.python.org/3.12/library/smtplib.html),
[SSL default context](https://docs.python.org/3.12/library/ssl.html#ssl.create_default_context),
[HMAC](https://docs.python.org/3.12/library/hmac.html),
[FastAPI lifespan](https://fastapi.tiangolo.com/advanced/events/).
