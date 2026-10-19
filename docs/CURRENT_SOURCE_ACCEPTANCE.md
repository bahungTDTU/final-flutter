# Nghiệm thu source sau PR #7 — 12/10/2026

## Bổ sung19/10/2026

[NATIVE_OS_ACCEPTANCE](NATIVE_OS_ACCEPTANCE.md) có probe OS force-stop/relaunch core
với QA entrypoint riêng; không thay main UI/IME. session_storage_test nay đi thêm actual
Home settings/password dialog và manual login mới, hai token cũ401 và draft giữ nguyên.
Command/evidence ở ../evidence/2026-10-19-account-password/INDEX.md. Browser runtime
lượt này lỗi kernel; Web compile không thay Web UI acceptance.


Base `46df286` chứa baseline PR #5, Trung tâm bảo mật PR #6 và Deskbook PR #7.
Ba required checks của từng PR đã PASS trên đúng head trước merge; snapshot tại
`evidence/2026-10-12-current-source-acceptance/github.json`. Không dùng CI của các
head đó thay CI cho thay đổi tiếp theo. Backlog chuẩn vẫn là LOCAL_BASELINE_AND_ROADMAP.md.

## Chạy native trên máy hiện tại

Backend phải dùng SQLite QA mới trong `tmp/`, không dùng dữ liệu cá nhân. Khởi động
uvicorn factory với `NOTETOGETHER_DB` trỏ database đó và port riêng (lượt này 8042).
Không đưa database, token, password tài khoản thật hoặc mail key vào evidence.
Emulator dùng `http://10.0.2.2:8042`; thiết bị thật cần đường kết nối phù hợp riêng.

```powershell
$env:FLUTTER_BIN = 'F:\bin\flutter.bat'
# Chỉ dùng F: sau khi xác minh ánh xạ đúng SDK 3.47.1 riêng; không ghi đè ổ đang dùng.
& scripts/qa_native.ps1 -Device emulator-5554 -ApiUrl http://10.0.2.2:8042 `
  -JvmSocketDirectory C:\Temp\notetogether-jvm -SoftwareRendering
```

`qa_native.ps1` chạy note_flow, sharing và realtime qua Flutter drive tuần tự, dừng khi có FAIL,
lưu lệnh/commit/tracked changes/exit code theo từng run. Log mặc định ở `output/`
ignored; chỉ copy log đã kiểm tra sang evidence. Không clear data/uninstall, không
tự start/stop backend/emulator, không cấu hình SMTP/Gemini hoặc gửi dịch vụ thật.
SoftwareRendering dùng flags của drive, không truyền flags đó cho flutter test.
VM-service capability trong stdout được che khỏi log xuất bản.
Nếu chạy trên install cá nhân, dùng emulator QA riêng: integration đăng nhập/đăng
xuất và tạo tài khoản/note disposable, có thể thay session trong app cài trên target.

Windows packaged app có thể khiến JVM lỗi `Unable to establish loopback connection`
ở `UnixDomainSockets.connect0`, trước build app. Chỉ khi gặp lỗi này, truyền thư mục
socket tuyệt đối không khoảng trắng bằng `-JvmSocketDirectory`. Script thêm
`-Djdk.net.unixdomain.tmpdir=...` vào JAVA_TOOL_OPTIONS của process con rồi phục hồi
giá trị ban đầu. Không đổi global Java/Flutter config, firewall hoặc bảo mật OS.
IPv4Stack và java.io.tmpdir riêng đã không sửa lỗi trên máy này; giữ log FAIL.
Nguồn workaround: [OpenJDK nio-dev](https://mail.openjdk.org/pipermail/nio-dev/2023-March/013297.html).

## Phạm vi và các gate còn riêng

| Gate | Tự động hiện có | Nghiệm thu thực cần bổ sung |
|---|---|---|
| N01 | note_flow nhập qua TextInputClient, editor autosave → GET backend | Gõ Telex/VNI qua IME Android thật, selection/paste/undo/redo/format, theme/resize |
| N02 | note_flow dùng Sembast/platform key, đóng/mở DB và socket offline/reconnect | Web reload; Android force-stop/relaunch process, giữ UUID và Delta/format trước reconnect |
| N03 | sharing/realtime dùng socket thật, các role và frozen base409/recovery | Hai cửa sổ UI độc lập cùng thao tác, dirty draft + revoke/downgrade |
| N04 | protected_editing PASS: vault/offline DB reopen/SSE/revalidation/delete | TTL thật, background/relock/đổi password và visual/cache privacy trên artifact mới |
| N05 | avatar_labels/attachments/session_storage integration riêng | DocumentsUI picker protected TXT, cancel/error, AND filter/rename, đổi password/old token401 |

TextInputClient injection không phải IME. Reopen DB trong cùng process không phải OS
relaunch. Peer API/controller không phải hai giao diện người dùng độc lập. Compile,
widget tests, fixture hoặc Chrome phone viewport không đóng các gate native này.
Kết quả thực và blocker được ghi tại evidence INDEX, không suy PASS từ bảng này.

## Chuẩn bị provider (chặng 3)

Người dùng xác nhận trong lượt này: chưa cấu hình SMTP/Gemini, tiếp tục phần local.

- P01: hiện backend QA `/health` báo `email_delivery=not_configured`. Cần nhóm chọn
  SMTP Internet, sender được phép và inbox QA nhận thư. Cấu hình SMTP_* trong process
  backend theo .env.example; code không tự load .env. Giữ MAIL_OUTBOX_KEY_FILE bền,
  không commit. Chỉ nghiệm thu sau inbox receipt → verify/reset trên Web/Android,
  resend/cooldown/expiry/reuse/error và old session401. SMTP accepted chưa là receipt.
- P02: hiện `/health` báo `ai=not_configured`. Key lịch sử đã bị lộ phải được thay;
  không tự tái sử dụng. Nhóm nhập key mới bằng scripts/configure_ai.ps1 (prompt che
  ký tự, file ignored), không dán vào chat. Sau khi xác nhận project/budget phù hợp,
  restart backend và chạy scripts/qa_ai.py --url <QA API> --live --output <ignored JSON>.
  Script dùng dữ liệu demo và gọi Google thật; phải tách kết quả HTTP khỏi UI hai target.
  Nghiệm thu Summary/regenerate/no overwrite, Q&A đa nguồn/citations/no-info,
  ACL/locked/revoke và prompt injection; không coi provider fixture là Gemini.

Thiếu cấu hình provider không chặn native/core QA. Không tự deploy, mua dịch vụ,
bật billing, ký bằng debug key để gọi release, hoặc tạo video/timestamp/teamwork giả.

Protected driver dùng test_driver/integration_test.dart ở lượt PASS native-protected-focus.txt.
Các lượt FAIL trước đó giữ nguyên kết quả; helper nay chờ focus chuyển khỏi password
trước khi mở TextInputClient Quill. Assert nội dung offline và envelope dirty được
kiểm tra trước DB close, rồi GET backend sau reopen; không bỏ assertion để đạt PASS.
