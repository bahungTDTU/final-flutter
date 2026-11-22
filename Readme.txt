# NoteTogether

Ứng dụng ghi chú Flutter cho Web và Android, dùng FastAPI/SQLite và Sembast.
Có đăng nhập, xác minh email và đặt lại mật khẩu bằng OTP 6 số, rich text,
tự lưu/bản nháp offline, nhãn, tệp đính kèm riêng tư,
khóa ghi chú, chia sẻ theo quyền, realtime và tích hợp AI Summary/Q&A.

## Trạng thái hiện hành — 21/11/2026

Web HTTPS trên Azure phục vụ master `26e4660` tại lần kiểm tra ngày 21/11.
Bản sửa trên nhánh bổ sung tìm kiếm tiếng Việt với dấu tổ hợp, cho phép mở
Web trong khi chuẩn bị cache offline và hỗ trợ xoay màn hình khi cài PWA.
Xem kết quả kiểm tra trong STATUS.md. Android ký phát hành và bộ nộp vẫn còn mở.

- [Giao diện thích ứng, chuyển trang và kiểm thử luồng 21/11](docs/UI_UX_QA.md).
- [Nghiệm thu Web và Android 18/11](docs/RUNTIME_ACCEPTANCE_2026-11-18.md).
- [Nghiệm thu OTP và Gmail](evidence/2026-11-18-email-otp/INDEX.md).
- [Kết quả kiểm tra môi trường 15/11](docs/LOCAL_READINESS_2026-11-15.md).
- [Các việc còn thiếu](docs/REMAINING_GATES.md), [ma trận 32 tiêu chí](docs/REQUIREMENTS_MATRIX.md).
- [Deploy Web trên Azure](docs/AZURE_WEB_DEPLOYMENT.md), [checklist bộ nộp](docs/SUBMISSION_CHECKLIST.md), [quy trình branch/PR](docs/BRANCH_WORKFLOW.md).
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
Sau khi sửa source, chạy lại `scripts/start_web.ps1 -Rebuild` để build trước khi phục vụ.
Nếu cổng mặc định bận, có thể dùng `scripts/start_backend.ps1 -Port 8090` và
`scripts/start_web.ps1 -Port 7390 -ApiUrl http://127.0.0.1:8090`.
Đặt `WEB_ORIGINS=http://127.0.0.1:7390` trong terminal backend trước khi chạy.
Chỉ định `-ApiUrl` sẽ build lại bundle vì URL được gắn ở lúc biên dịch.
Script setup từ chối `.venv` khác Python 3.12; môi trường kiểm tra tương thích 3.13
ở lượt 15/11 không thay baseline CI. Dùng checkout riêng với Python 3.12 để tái lập baseline.

`scripts/start_backend.ps1` tự đọc `.env` ở thư mục gốc. Với Gmail, điền
`SMTP_USERNAME` và `SMTP_PASSWORD` (Google App Password) rồi khởi động lại.
`.env.example` là mẫu các biến. Biến đã đặt trong terminal được ưu tiên.
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

Để bật AI, điền `GEMINI_API_KEY` trong file `.env` ở gốc dự án, cùng file dùng
cho SMTP. Nếu chưa có file, sao chép `.env.example` thành `.env`. Dùng key của
project Free Tier trong Google AI Studio. Backend mặc định dùng `gemini-3.1-flash-lite`.
[Hướng dẫn cấu hình AI](docs/AI_FEATURES.md).

```dotenv
GEMINI_API_KEY=
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start_backend.ps1
```

Khởi động lại backend sau khi cập nhật key. Git bỏ qua file `.env`. Khi deploy,
đặt key trong biến môi trường hoặc secret store của backend. AI UI thông báo
trước khi gửi ghi chú vì Google có thể dùng dữ liệu Free Tier để cải thiện sản phẩm.

Nghiệm thu local có provider double tường minh, không gọi Google:

```powershell
# Terminal fixture; chỉ loopback và ghi nhãn không phải LLM.
& .\.venv\Scripts\python.exe scripts/ai_fixture.py --allow-test-provider
& .\.venv\Scripts\python.exe scripts/qa_ai.py --url http://127.0.0.1:8012 --output output/ai-http-fixture.json
# Android debug/emulator cần adb reverse8012, giống hướng dẫn integration bên dưới.
& 'D:\Android\sdk\platform-tools\adb.exe' reverse tcp:8012 tcp:8012
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' drive --driver=test_driver/ai.dart --target=integration_test/ai_flow_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8012 --enable-software-rendering --no-enable-impeller
# Sau khi cấu hình key Free Tier: Gemini thật với SQLite tạm và SMTP tắt.
& .\.venv\Scripts\python.exe scripts/qa_ai.py --live --output output/ai-live.json
```

`--live` dùng API FastAPI qua ASGI, gửi ghi chú mẫu đến Gemini và lưu kết quả QA.
Dùng `--live --serve 18245` để chạy Web và Android với SQLite tạm, SMTP tắt.
[Các lệnh kiểm tra Web và Android](docs/AI_FEATURES.md#cấu-hình-gemini-free-tier).
Hai AI routes chỉ đọc bản server; summary không overwrite/autosave vào note, pending draft
bị chặn. Q&A retrieval lọc quyền/unlock trước prompt, recheck mọi nguồn sau inference;
result ở RAM, citation mở note thật với recheck. Câu hỏi tổng quan dùng tối đa sáu ghi chú gần nhất. Xem phạm vi trong AI_FEATURES.md.

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
Backend đọc NOTETOGETHER_DB và WEB_ORIGINS từ process environment. Launcher PowerShell
nạp `.env` qua Uvicorn. Khi tự gọi Uvicorn, truyền `--env-file .env` nếu cần.
CORS cần origin chính xác. API_URL chỉ là public URL, không secret.
Tạo tài khoản test email/display name/password≥10 ký tự hai lần, tự login và giữ banner unverified.
Không có grading account/public credentials preloaded; production email/AI không được giả success.

Ngày 22/11/2026, mục **Giao diện → Bảng màu giao diện** có 10 bảng phối sáng/tối, gồm bốn lựa chọn mới Rạn san hô, Hạ chí, Cực quang và Đầm phá. Chi tiết trong docs/COLOR_PALETTES.md.
