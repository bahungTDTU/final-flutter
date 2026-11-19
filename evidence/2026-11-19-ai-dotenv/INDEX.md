# Kiểm tra cấu hình Gemini từ .env — 19/11/2026

Base `fd87ce9`. Các kiểm tra chạy trên thay đổi local.

| Lệnh hoặc mục tiêu | Kết quả |
|---|---|
| `git check-ignore -- .env` | PASS. Git bỏ qua tệp cấu hình local. Thêm trường `GEMINI_API_KEY` và đối chiếu toàn bộ byte đã có, gồm cấu hình SMTP. |
| `scripts/start_backend.ps1 -Port <QA_PORT> -EnvFile <TEMP_ENV>` | PASS ở hai tiến trình loopback với SQLite tạm, SMTP tắt. Với key rỗng, `/health` báo `not_configured`. Với key mẫu, `/health` và `/ai/status` sau đăng nhập xác nhận đã nạp cấu hình và model `gemini-3.1-flash-lite`. Status chỉ trả thông tin trạng thái và model. |
| `scripts/qa_ai.py` qua HTTP loopback, `FixtureProvider` | PASS. Owner/viewer/editor đọc được summary có hạn nộp. Q&A giữ hạn nộp và số tiền, mở được hai nguồn. Người ngoài, note khóa và nguồn bị thu hồi đều được kiểm tra. |
| QA với SQLite tạm, `DisabledDelivery` và `httpx.MockTransport` | PASS. Nhánh QA cô lập nạp key mẫu từ `.env` và thực hiện ba summary, một Q&A qua transport mô phỏng. Khi thiếu key hoặc chọn backend bật SMTP, preflight dừng trước khi tạo tài khoản QA. |
| `python -m pytest -q --tb=short backend/tests` | PASS, 169 test. Lượt trong sandbox gặp lỗi OpenSSL khi tạo chứng chỉ SMTP fixture. Chạy lại cùng suite ngoài sandbox toàn bộ PASS. |
| `flutter test test/ai_test.dart --reporter expanded` | PASS, 8 test. |
| `docker compose config --quiet` | PASS, phân tích cấu hình Compose. |

## Gemini thật

Ngày 19/11/2026 lúc 19:48 (UTC+7), trên cùng base và thay đổi local, người dùng
đã cấu hình key Gemini Free Tier trong `.env`. Hai kiểm tra dưới đây chạy độc lập.

| Mục tiêu | Kết quả |
|---|---|
| Khởi động lại bằng `scripts/start_backend.ps1`, kiểm tra `GET http://127.0.0.1:8000/health` | PASS. Tiến trình mới báo `status: ok`, `ai: configured`, `email_delivery: smtp`. |
| `& ./.venv/Scripts/python.exe scripts/qa_ai.py --live --output output/ai-live-2026-11-19.json` | PASS. FastAPI xử lý yêu cầu qua ASGI, backend gọi `gemini-3.1-flash-lite` thật. QA dùng ghi chú mẫu, SQLite tạm và tắt SMTP. |

- **Tóm tắt AI** PASS với chủ sở hữu, người xem và người chỉnh sửa. Cả ba bản
  giữ hạn nộp 20/11/2026. Ghi chú gốc giữ nguyên.
- **Hỏi ghi chú** PASS. Câu trả lời nêu hạn 20/11/2026 và ngân sách 300.000 đồng,
  dẫn đúng hai ghi chú lịch nộp và ngân sách. API mở được cả hai nguồn.
- Ca thiếu dữ liệu, ghi chú khóa, người ngoài và quyền đã bị thu hồi đều qua kiểm tra.

Báo cáo JSON ở `output/ai-live-2026-11-19.json` trên máy local và được Git bỏ qua.

## Web và Android với Gemini thật

Ngày 19/11/2026, khoảng 20:08 (UTC+7), kiểm thử giao diện với
`gemini-3.1-flash-lite`. Cả hai target dùng backend QA loopback cổng 18245
qua `scripts/qa_ai.py --live --serve 18245`, với SQLite tạm và SMTP tắt.

| Target | Kết quả |
|---|---|
| Chrome 157, Web release local trên cổng 17357 | PASS. Tóm tắt và Tạo lại giữ đúng hạn 20/11/2026. Đối chiếu API trước/sau xác nhận ghi chú gốc giữ nguyên. Q&A tổng hợp hạn nộp và ngân sách 300.000 đồng, hiện hai nút nguồn. Bấm lịch nộp gọi đúng ID qua API rồi mở editor. [Kết quả Web](web-result.json) |
| Android debug, emulator-5580, API 36 | PASS. Tóm tắt qua menu **Công cụ ghi chú**, Tạo lại và so sánh ghi chú gốc. Q&A hiển thị cả ngày và ngân sách, có hai nguồn, bấm nguồn mở editor đúng tiêu đề và nội dung. Flutter drive thoát mã 0. |
| `scripts/qa_ai.py --url http://127.0.0.1:18245 --live --output output/ai-live-http-2026-11-19.json` | PASS qua HTTP loopback với Gemini thật. Kiểm tra Summary của chủ sở hữu/người xem/người chỉnh sửa, chặn người ngoài, ghi chú khóa và quyền bị thu hồi, Q&A đa nguồn và ca thiếu dữ liệu. |

Web dùng `flutter build web --release --no-web-resources-cdn --dart-define=API_URL=http://127.0.0.1:18245` và tạo offline shell 41 tài nguyên. Android chạy
`flutter drive --no-pub --driver=test_driver/ai.dart --target=integration_test/ai_flow_test.dart -d emulator-5580 --dart-define=API_URL=http://127.0.0.1:18245 --dart-define=AI_QA_LIVE=true --enable-software-rendering --no-enable-impeller`.
[Lệnh khởi động server QA](../../docs/AI_FEATURES.md#cấu-hình-gemini-free-tier).

Lượt Android đầu dùng vị trí nút của màn hình rộng. Bài test đã được sửa để mở
menu trên màn hình nhỏ. Chụp ảnh native là tùy chọn vì plugin screenshot của
toolchain QA này không khả dụng. Lượt Chrome đầu nhận HTTP 503 từ Gemini qua
FastAPI. Backend giờ trả `AI_BUSY` cho trường hợp này và UI hướng dẫn thử lại.
Ca 503 có backend regression test. Lượt Chrome cuối chạy trọn luồng mà không
gặp 503.

Format Dart, Flutter analyze, 333 Flutter tests và 170 backend tests đều PASS.
HTTPS công khai, Android release ký và thiết bị vật lý chưa chạy trong lượt này.
