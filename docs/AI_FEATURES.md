# AI Summary và Q&A — triển khai 05/10/2026

Nguồn yêu cầu: 503107-FinalProject-V1.pdf tr.5/13, tiêu chí 27 và 28.
Một Flutter Web/Android core; FastAPI gọi Gemini bằng HTTP từ server.
Mốc audit trước đó vẫn là snapshot trước khi triển khai AI, không sửa lịch sử evidence.

## Cấu hình Gemini free tier

Đối chiếu tài liệu Google ngày 05/10/2026: `gemini-2.5-flash-lite` có standard free tier.
Hạn mức thực tế phụ thuộc project/model/Google; không hard-code một quota Google được
cho là luôn còn. Dùng key của project Free tier trong [Google AI Studio](https://aistudio.google.com/api-keys).
Không cần đổi sang Paid tier hoặc bật billing cho nghiệm thu này.

Free tier có thể dùng nội dung gửi lên để cải thiện sản phẩm. UI thông báo điều đó
trước thao tác AI. Chỉ dùng dữ liệu demo phù hợp khi nghiệm thu; không coi đây là
bảo đảm riêng tư của dịch vụ LLM hoặc khả năng thu hồi dữ liệu đã gửi hợp lệ.

Key chỉ ở backend. Trên máy local, nhập bằng prompt che ký tự:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/configure_ai.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start_backend.ps1
```

Script ghi `backend/state/gemini-api-key.txt` (Git ignored). `start_backend.ps1` tự
chọn file này khi chưa đặt `GEMINI_API_KEY`/`GEMINI_API_KEY_FILE` trong process environment.
File là secret local plaintext để development, không được copy vào source/release/ZIP
hoặc public server static root. Production đặt secret qua service environment/secret store.

Backend có thể cấu hình trực tiếp các biến process:

- `GEMINI_API_KEY` hoặc `GEMINI_API_KEY_FILE`: key hoặc đường dẫn file secret.
- `GEMINI_MODEL`: mặc định `gemini-2.5-flash-lite`; không tự fallback sang model khác.
- `.env.example` là template, backend không tự load `.env`.

Không dùng key trong Flutter `--dart-define`, URL/query string, browser worker, Git,
request bodies trả cho client, log hoặc screenshots. Key outbound nằm trong header
`x-goog-api-key`, chỉ gửi đến endpoint Google cố định qua HTTPS/verify certificate.
Chưa có key → 503 `AI_NOT_CONFIGURED`, không có câu trả lời giả.

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

Lệnh thật và kết quả của lượt này ở [AI evidence](../evidence/2026-10-05-ai/INDEX.md).
Real Gemini/provider, actual browser bundle và Android native acceptance chỉ được ghi
PASS sau khi chạy đúng target. Public HTTPS và video không được suy từ tests/build.

Lượt này: Web actual local và native debug API36 qua provider fixture đã chạy PASS;
Gemini thật **chưa chạy** theo lựa chọn người dùng. Key đã có trên AI Studio dùng format
mới, đã xuất hiện trong tool output do bộ che format cũ; key đó không được lưu hoặc
gọi API. Người dùng cần thay/config key mới trước live QA. Không lưu screenshot key
hoặc giá trị key trong evidence/source; report này không lặp lại secret.

Nguồn kỹ thuật chính thức đã đọc:
[Gemini pricing](https://ai.google.dev/gemini-api/docs/pricing),
[API key](https://ai.google.dev/gemini-api/docs/api-key),
[GenerateContent REST](https://ai.google.dev/api/generate-content),
[Structured outputs](https://ai.google.dev/gemini-api/docs/structured-output).
