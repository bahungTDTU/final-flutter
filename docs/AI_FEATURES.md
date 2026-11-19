# AI Summary và Q&A — triển khai 05/10/2026

Nguồn yêu cầu: 503107-FinalProject-V1.pdf tr.5/13, tiêu chí 27 và 28.
Một Flutter Web/Android core; FastAPI gọi Gemini bằng HTTP từ server.
Mốc audit trước đó vẫn là snapshot trước khi triển khai AI, không sửa lịch sử evidence.

## Cấu hình Gemini free tier

Backend mặc định dùng `gemini-3.1-flash-lite`, hỗ trợ JSON có cấu trúc và có Free
Tier theo tài liệu Google ngày 19/11/2026. Dùng key mới của project Free Tier
để nghiệm thu. Hạn mức phụ thuộc project và model.
[Model Gemini](https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-lite),
[bảng giá và Free Tier](https://ai.google.dev/gemini-api/docs/pricing),
[tạo API key](https://aistudio.google.com/api-keys).

Free tier có thể dùng nội dung gửi lên để cải thiện sản phẩm. UI thông báo điều đó
trước thao tác AI. Chỉ dùng dữ liệu demo phù hợp khi nghiệm thu; không coi đây là
bảo đảm riêng tư của dịch vụ LLM hoặc khả năng thu hồi dữ liệu đã gửi hợp lệ.

Điền key vào `GEMINI_API_KEY` trong file `.env` ở gốc dự án. Dùng chính file
đang cấu hình SMTP. Với bản clone mới, sao chép `.env.example` thành `.env` trước.

```dotenv
GEMINI_API_KEY=
```

Khởi động lại backend để nạp giá trị mới:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start_backend.ps1
```

`start_backend.ps1` nạp `.env` qua Uvicorn. Biến môi trường đã đặt trước khi
khởi động có ưu tiên. Có thể đặt `GEMINI_MODEL` nếu project cần model khác.
Đặt `GEMINI_IPV6=1` khi máy chủ đã xác minh truy cập trực tiếp được API
Gemini qua IPv6. Tùy chọn mặc định là `0`.
Biến `GEMINI_API_KEY_FILE` là phương án cho tệp secret và được dùng khi
`GEMINI_API_KEY` trống. Nếu tệp secret bị thiếu, backend ghi cảnh báo và vẫn chạy.
Production có thể đặt key qua môi trường dịch vụ hoặc secret store.

Không dùng key trong Flutter `--dart-define`, URL/query string, browser worker, Git,
request bodies trả cho client, log hoặc screenshots. Key outbound nằm trong header
`x-goog-api-key`, chỉ gửi đến endpoint Google cố định qua HTTPS/verify certificate.
Chưa có key → 503 `AI_NOT_CONFIGURED`, không có câu trả lời giả.

`GET /health` báo `ai: configured` khi backend đã nạp cấu hình. Sau khi có key
Free Tier, chạy lệnh sau để kiểm tra bằng dữ liệu mẫu và SQLite tạm, với SMTP tắt:

```powershell
& .\.venv\Scripts\python.exe scripts/qa_ai.py --live --output output/ai-live.json
```

Để chạy giao diện với Gemini thật, mở backend QA ở terminal riêng. Server chỉ
nghe loopback, dùng SQLite tạm và tắt SMTP.

```powershell
$env:WEB_ORIGINS = 'http://127.0.0.1:17357'
& .\.venv\Scripts\python.exe scripts/qa_ai.py --live --serve 18245
```

Mở Web release local với cùng API. Đăng nhập bằng tài khoản QA và dùng ghi chú mẫu.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start_web.ps1 -Port 17357 -ApiUrl http://127.0.0.1:18245
```

Trên Android emulator, chuyển tiếp cổng rồi chạy integration test. Thay
`emulator-5580` bằng thiết bị QA đang chạy.

```powershell
adb -s emulator-5580 reverse tcp:18245 tcp:18245
flutter drive --driver=test_driver/ai.dart --target=integration_test/ai_flow_test.dart -d emulator-5580 --dart-define=API_URL=http://127.0.0.1:18245 --dart-define=AI_QA_LIVE=true --enable-software-rendering --no-enable-impeller
```

## Giao diện và hành vi

- Editor note đã đồng bộ → **Tóm tắt bằng AI** → **Tạo tóm tắt**/**Tạo lại**.
  Note có draft/outbox chưa đồng bộ bị chặn để không tóm tắt phiên bản server cũ.
  Không có thao tác tự ghi đè note, không đổi editor ID/base revision/caret/outbox.
- Home → **Hỏi ghi chú** → nhập câu hỏi → **Hỏi AI**. Trả lời có nút mở từng note nguồn;
  API kiểm tra lại quyền/revision trước khi điều hướng đúng Editor/ProtectedNoteScreen.
- Protected reader sau unlock → **Tóm tắt AI** hoặc **Hỏi AI**. Gate theo reader/session;
  TTL/lock/revoke/background/logout che result và metadata. Mở citation protected note
  dẫn thẳng đến password gate của note đó, không bypass unlock.
- Loading, cancel, quota/busy/timeout/not-configured/permission/source-change errors được
  hiển thị. Cancel che output và abort client request; không hứa server/Google đã hủy
  inference đang chạy hoặc hoàn lại quota.
- Khi Gemini trả HTTP 503, app báo dịch vụ AI đang bận và cho phép người dùng
  thử lại. Backend ghi mã lỗi để chẩn đoán và giữ nội dung yêu cầu ngoài log.
- Kết quả ở RAM của màn hình, không lưu vào local vault, DB, notes, history hay outbox.
  Không có multi-turn chat history. Đóng route/chuyển nền/xóa kết quả sẽ bỏ response.
  AI output render bằng text, không HTML/Markdown tools hoặc URL lấy từ LLM.

## API và authorization

| API | Hành vi |
|---|---|
| `GET /ai/status` | Authenticated; enabled/provider/model, không key |
| `POST /notes/{id}/ai/summary` | Read ACL; protected note cần live grant của session; generate mỗi lần, không lưu summary |
| `POST /ai/questions` | `{question}`; extra fields bị từ chối; server tự chọn notes có quyền/unlocked, không nhận owner/permission/content từ client |
| `POST /ai/validate` | `{sources:[{id,revision}]}`; recheck ACL/grant/revision cho response đang hiển thị, không trả nội dung |

Q&A đọc rows hiện tại theo owner/share và live grant **trước retrieval/context**.
Không có index/cache chứa nguồn đã bị revoke/lock. Retrieval BM25 theo title và content,
normalize dấu tiếng Việt, chunks 1800 ký tự/overlap; ưu tiên đa dạng note, tối đa 6 notes,
2 chunks/note. LLM tổng hợp bằng dữ liệu nguồn, không chỉ trả kết quả keyword search.
BM25 không phải semantic embeddings; truy vấn dùng từ đồng nghĩa không xuất hiện trong
notes có thể không tìm được nguồn. Không có dữ liệu liên quan hoặc LLM nói thiếu căn cứ
→ thông báo insufficient information, không dùng kiến thức chung thay nguồn.

Prompt system tách riêng; question/notes là JSON data không tin cậy, không có secret,
tools, web search hoặc execution. Mỗi nguồn dùng alias `S1`…`S6`; server chỉ chấp nhận
citations trong nguồn đã gửi và tự ánh xạ note ID/title/revision. Citation bịa/JSON lỗi,
output quá dài hoặc finishReason không STOP bị từ chối. Schema/citation checks không
chứng minh mọi câu trả lời đúng hoặc chống tuyệt đối prompt injection; phải đánh giá
chất lượng trên LLM thật và người dùng kiểm tra source.

Trước outbound và **sau inference**, backend kiểm tra lại **mọi context source**, kể cả
nguồn không được LLM cite: session, quyền, grant TTL/version, note revision/deleted.
Thay đổi bất kỳ nguồn nào → bỏ toàn bộ answer/summary, 409 `AI_SOURCES_CHANGED`.
Không giữ transaction/SQLite lock khi gọi LLM. Nguồn đã gửi khi còn quyền không thể
được thu hồi vật lý từ Google khi quyền đổi sau đó.

Client so account/token, epoch, note revisions và protected gate; late response sau
logout/route disposal bị bỏ. Result đang hiển thị được kiểm tra server mỗi 10s và khi
có realtime signal; khi disconnect/source changed thì che. Đây là bounded revalidation,
không phải thu hồi tức thì dữ liệu trên máy mất mạng hay chống screenshot.

## Giới hạn và budget

- Summary nhận đầy đủ title/content tối đa 24.000 ký tự; dài hơn trả 413, không âm thầm
  tóm tắt prefix rồi coi là toàn bộ note.
- Q&A tối đa 1000 authorized/unlocked notes, tổng 2 triệu ký tự; vượt trả 413.
  Không parse attachments/media/OCR; yêu cầu hiện tại dùng title/content note.
- Google timeout 45s; client AI 55s; output JSON ≤64 KiB, text ≤8000 ký tự.
  API thường giữ timeout cũ. Không auto retry inference hoặc chuyển model/provider trả phí.
- SQLite durable counters: 6 requests/phút/account, 40/ngày/account, 200/ngày/application.
  Count cả provider errors để hạn chế retry storm. Tối đa 2 inference cùng lúc/process.
  Đây là app budgets, không phải quota/billing guarantee của Google. Project Free tier
  cần được giữ đúng tier; trả 429 rõ ràng khi quota thật thấp hơn.

## Kiểm thử và nghiệm thu

`backend/tests/test_ai.py`: explicit RecordingProvider/httpx MockTransport để test
ACL/filtering/lock/revoke/delete/change/TTL/logout trong inference, uncited context,
JSON/citation validation, no-mutation/regenerate, rate limits và sanitized errors.
Đây là **test doubles**, không phải bằng chứng Gemini thật đã trả lời.

`test/ai_test.dart`: RAM-only/no overwrite, pending draft, source revoke, late account
response, citation permission, protected TTL/background, Q&A navigation và Summary UI
320×568/chữ 200%. HTTP doubles, không thay Web/native acceptance.

Ngày 19/11/2026, Tóm tắt AI và Hỏi ghi chú qua FastAPI đều PASS với Gemini
`gemini-3.1-flash-lite` thật. Summary giữ đúng hạn nộp và ghi chú gốc. Q&A
trả đúng hạn nộp, ngân sách và hai nguồn mở được. Lượt chạy dùng ghi chú mẫu,
SQLite tạm và tắt SMTP. [Bằng chứng Gemini thật](../evidence/2026-11-19-ai-dotenv/INDEX.md#gemini-thật).

Chrome Web release local và Android emulator API 36 cũng PASS với Gemini thật
ngày 19/11. Cả hai chạy Summary, Tạo lại, kiểm tra ghi chú gốc giữ nguyên, Q&A
đa nguồn và mở đúng ghi chú nguồn. Nghiệm thu public HTTPS, Android release và
video vẫn còn. [Bằng chứng Web và Android](../evidence/2026-11-19-ai-dotenv/INDEX.md#web-và-android-với-gemini-thật).

Nguồn kỹ thuật chính thức đã đọc:
[Gemini pricing](https://ai.google.dev/gemini-api/docs/pricing),
[API key](https://ai.google.dev/gemini-api/docs/api-key),
[GenerateContent REST](https://ai.google.dev/api/generate-content),
[Structured outputs](https://ai.google.dev/gemini-api/docs/structured-output).
