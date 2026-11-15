# NoteTogether

Ứng dụng ghi chú Flutter cho Web và Android, dùng FastAPI/SQLite và Sembast.
Có đăng nhập, rich text, tự lưu/bản nháp offline, nhãn, tệp đính kèm riêng tư,
khóa ghi chú, chia sẻ theo quyền, realtime và tích hợp AI Summary/Q&A.

## Trạng thái hiện hành — 15/11/2026

Đã đồng bộ source GitHub `master` tại `9d00fcf` (PR #17). Đang hoàn thiện local;
**chưa sẵn sàng nộp/public release**. Chức năng có code không đồng nghĩa đã
nghiệm thu provider thật, bản Android ký phát hành và Web HTTPS.

- [Kết quả kiểm tra máy hiện tại](docs/LOCAL_READINESS_2026-11-15.md).
- [Các việc còn thiếu](docs/REMAINING_GATES.md), [ma trận 32 tiêu chí](docs/REQUIREMENTS_MATRIX.md).
- [Checklist bộ nộp](docs/SUBMISSION_CHECKLIST.md), [quy trình branch/PR](docs/BRANCH_WORKFLOW.md).
- [Lịch sử triển khai và lệnh trên máy cũ](README_HISTORY.md); các kết quả trong đó chỉ áp dụng cho lần chạy được ghi.

## Chạy nhanh trên Windows

Chạy lệnh từ thư mục repository. Cần Python **3.12** và Flutter có Dart **>=3.13.1 <4.0.0**.
CI dùng Flutter 3.47.1; lượt local 15/11 chuẩn bị SDK riêng 3.47.9.
Flutter 3.47.0/Dart 3.13.0 không đáp ứng `pubspec.yaml`.

```powershell
# Nếu Flutter phù hợp chưa nằm trên PATH, đặt đường dẫn SDK riêng trong mỗi terminal:
# $env:FLUTTER_BIN = 'C:\path\to\flutter\bin\flutter.bat'
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/setup.ps1
# Có thể truyền: -Python 'C:\path\to\Python312\python.exe'
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1
```

Mở hai terminal tại repository, cùng cấu hình `FLUTTER_BIN` nếu cần:

```powershell
# Terminal 1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start_backend.ps1
# Terminal 2
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start_web.ps1
```

Mở Web tại `http://127.0.0.1:7357`, API health tại `http://127.0.0.1:8000/health`.
Sau sửa source, chạy `scripts/build.ps1 -Target web` rồi reload; server không tự rebuild.
Script setup từ chối `.venv` khác Python 3.12; môi trường kiểm tra tương thích 3.13
ở lượt 15/11 không thay baseline CI. Dùng checkout riêng với Python 3.12 để tái lập baseline.

`.env.example` là mẫu tham khảo, ứng dụng **không tự nạp `.env`**.
Cấu hình provider qua environment/private key file theo hướng dẫn bên dưới.
Không cần email/LLM thật để chạy các test fixture; các test đó không chứng minh dịch vụ thật hoạt động.

## Hoàn thiện bản nộp

1. Cấu hình SMTP/inbox và LLM thật, chạy nghiệm thu email và AI trên hai nền tảng.
2. Chuẩn bị backend/Web HTTPS và keystore của nhóm; build, cài và nghiệm thu cùng source.
3. Chạy các luồng còn thiếu trên artifact cuối: IME, offline/relaunch, khóa/background,
   tệp bảo vệ, nhãn và hai client đổi quyền khi đang sửa.
4. Bổ sung Rubric gốc, video hai thành viên, Insights thật và tài khoản chấm;
   đóng gói source có `.git`, release, tài liệu, rồi giải nén kiểm tra.

Xem [release/backup](docs/RELEASE_AND_BACKUP.md), [nghiệm thu native](docs/NATIVE_OS_ACCEPTANCE.md),
[AI](docs/AI_FEATURES.md), [email](docs/EMAIL_DELIVERY.md) và [kế hoạch C0–C5](docs/COMPLETION_PLAN_2026-10-19.md).
Không dùng các bước local thay nghiệm thu release hoặc tự đánh dấu đủ 32 tiêu chí.

## Setup trên Windows

AI: xem [docs/AI_FEATURES.md](docs/AI_FEATURES.md). Dùng Gemini key của project Free tier,
chỉ cấu hình ở backend, không đặt trong Flutter hoặc Git. Key cũ đã xuất hiện trong output
công cụ ở lượt05/10 và chưa được lưu/sử dụng; cần thay trước khi cấu hình.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/configure_ai.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start_backend.ps1
```

Nhập key vào prompt che ký tự. File local `backend/state/gemini-api-key.txt` bị Git bỏ qua;
không đưa vào gói nộp. `.env.example` có `GEMINI_API_KEY`/`GEMINI_API_KEY_FILE`/`GEMINI_MODEL`.
`start_backend.ps1` tự chọn file local; backend deployment cần service env/secret store riêng.
Free tier có thể dùng dữ liệu gửi lên để cải thiện sản phẩm; AI UI có thông báo trước khi gửi.

Nghiệm thu local có provider double tường minh, không gọi Google:

```powershell
# Terminal fixture; chỉ loopback và ghi nhãn không phải LLM.
& .\.venv\Scripts\python.exe scripts/ai_fixture.py --allow-test-provider
& .\.venv\Scripts\python.exe scripts/qa_ai.py --url http://127.0.0.1:8012 --output output/ai-http-fixture.json
# Android debug/emulator cần adb reverse8012, giống hướng dẫn integration bên dưới.
& 'D:\Android\sdk\platform-tools\adb.exe' reverse tcp:8012 tcp:8012
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' drive --driver=test_driver/ai.dart --target=integration_test/ai_flow_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8012 --enable-software-rendering --no-enable-impeller
# Chỉ khi đã thay/config key: actual Gemini QA với disposable notes.
& .\.venv\Scripts\python.exe scripts/qa_ai.py --url http://127.0.0.1:8000 --live --output output/ai-live.json
```

`--live` từ chối provider fixture; không được gọi fixture PASS là Gemini đã nghiệm thu.
Hai AI routes chỉ đọc bản server; summary không overwrite/autosave vào note, pending draft
bị chặn. Q&A retrieval lọc quyền/unlock trước prompt, recheck mọi nguồn sau inference;
result ở RAM, citation mở note thật với recheck. Hạn mức/giới hạn ở AI_FEATURES.md.

Flutter3.47.1/Dart3.13.1 là phiên bản CI đã chốt; SDK Dart phải thỏa ^3.13.1.
Flutter3.47.0/Dart3.13.0 không đủ. Đặt Flutter phù hợp trên PATH hoặc FLUTTER_BIN
(đường dẫn flutter.bat); có thể dùng SDK riêng để không đổi SDK của dự án khác.
Python 3.12 cần sẵn, cùng phiên bản minor với CI. Khi tạo .venv, setup ưu tiên
-Python, rồi PYTHON_BIN, rồi py -3.12, cuối cùng python trên PATH. Script kiểm tra
đúng Python 3.12 trước cài dependencies; không tự tải runtime hoặc xóa .venv cũ.
Máy dùng runtime ngoài PATH truyền -Python với đường dẫn thật, không dùng WindowsApps stub.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
# Máy khác:
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1 -Python C:\Python312\python.exe
powershell -ExecutionPolicy Bypass -File scripts/check.ps1
```

Chạy backend và Web ở hai terminal:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/start_backend.ps1
powershell -ExecutionPolicy Bypass -File scripts/start_web.ps1
```

Nếu7357 đã có server khác, dùng scripts/start_web.ps1 -Port 7358, không dừng server đó.
Khi dùng port khác, đặt WEB_ORIGINS gồm origin mới trước khi khởi động backend (ví dụ
http://127.0.0.1:7358,http://localhost:7358); không dùng wildcard.

Backend http://127.0.0.1:8000, /health, /docs. Web port7357 mặc định; start_web phục vụ release local,
tự build nếu chưa có worker. Sau sửa source chạy scripts/build.ps1 -Target web rồi reload.
Backend đọc NOTETOGETHER_DB và WEB_ORIGINS từ process environment. .env.example là template;
code không tự load .env. CORS cần origin chính xác. API_URL chỉ là public URL, không secret.
Tạo tài khoản test email/display name/password≥10 ký tự hai lần, tự login và giữ banner unverified.
Không có grading account/public credentials preloaded; production email/AI không được giả success.
