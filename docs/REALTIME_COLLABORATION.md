# Cộng tác realtime — tiêu chí26

Triển khai local 02/10/2026 trên một Flutter Web/Android project. Nguồn yêu cầu:
503107-FinalProject-V1.pdf tr.4/tr.13 và PROMPT_CHO_AGENT.md. Cơ chế SSE authenticated
đưa thông báo thay đổi đến app; các thao tác ghi vẫn dùng HTTP outbox/revision CAS hiện có.
Không có OT/CRDT, presence/cursor, merge từng ký tự hay production deployment.

## Luồng dữ liệu và quyền

1. App đang foreground và đã login mở một `GET /events`, Bearer trong Authorization header.
   Không đưa token vào URL, worker cache, log hoặc snapshot realtime.
2. SQLite triggers tăng `realtime_versions` cho owner/người đang được chia sẻ, trong cùng
   transaction với notes/shares/attachments/labels/profile/avatar/preferences. Rollback không
   phát thay đổi; replay immutable op không ghi lại note/counter. Người bị revoke vẫn nhận
   invalidation cuối để tải lại quyền; edits sau revoke không gửi thông báo cho họ.
3. Mỗi stream kiểm tra session và counter bằng read transaction ngắn mỗi250ms trên worker
   thread; đây là polling SQLite phía server, không phải DB pub/sub. Không giữ DB connection
   qua thời gian chờ mạng. App nhận push trên HTTP response lâu dài, không đợi polling15s.
4. `ready` và `changed` chỉ chứa `{"version":3}` với version integer≥0. Không note ID,
   title/content/role/email/attachment/label, kể cả ghi chú đã khóa. Heartbeat comment mỗi10s.
   `expired` chứa `{}` rồi đóng stream khi logout/reset/password-change/session expiry.
5. App coalesce100ms rồi synchronize bằng các API đã kiểm tra ACL/grant. Event đến giữa
   synchronize giữ dirty flag và chạy lượt tiếp theo; không bỏ update vì `_syncing`.
   ShareSession/AttachmentSession cùng nhận tín hiệu để refresh catalogue/private metadata.
   GET/POST luôn kiểm tra quyền server, bất kể trạng thái UI hay stream.

Counter bền trong SQLite, không lưu event lịch sử/payload nhạy cảm. Reconnect luôn có ready
và full authorized refresh, kể cả counter trùng/lùi sau restore. Trigger startup idempotent,
không đổi schema2/immutable journals/last-server-accepted policy riêng của preferences.

## Editor và chống mất dữ liệu

- Editor sạch nhận nội dung mới ngay trong màn hình đang mở, giữ/clamp selection. **Base revision
  của phiên đang mở không tự nâng theo server.** Trường tạm chỉ đọc và nút “Chỉnh sửa phiên bản
  mới” tạo phiên editor mới rõ ràng trên revision đã hiển thị; không phải refresh để xem update.
- Editor đang gõ/có draft/pending/conflict giữ nội dung local. Ghi từ base cũ nhận409 qua
  cơ chế CAS/conflict UI hiện có; không silent last-write-wins cho notes.
- Viewer chỉ đọc nội dung server. Downgrade/revoke/remote lock chuyển latest draft/upsert vào
  encrypted recovery, xóa source queue trong snapshot. Revoked/locked UI che nội dung; bản
  phục hồi là dữ liệu local đã có hợp lệ, tạo UUID mới khi người dùng chọn.
- ProtectedReader vẫn giữ grant/TTL/RAM-only; controller refresh lock/role/revision che route
  không còn hợp lệ. Realtime không cấp grant hay gửi protected content. Actual protected-reader
  realtime flows chưa nghiệm thu đợt này; protected edit/offline unlock vẫn chưa triển khai.

## Kết nối, lifecycle và vận hành

Production main.dart bật RealtimeFeed; constructor controller cho phép không có feed trong
host fixtures. Browser dùng streaming Fetch qua http1.6; Android dùng IOClient. Parser nhận
UTF-8/chunks/CRLF, kiểm tra frame≤4096 characters và strict payload. Token/status/callback
theo epoch/account/generation; callback cũ không vượt sang tài khoản mới.

Header timeout10s, idle timeout25s, reconnect1/2/4/8/16/30s (không jitter). Ready kích hoạt
catchup. Background dừng feed, resumed nối lại; logout/dispose hủy request/timer. Response
subscription được cancel xong trước client.close để tránh socket cancellation error trên Android.
HTTP sync15s hiện có vẫn là fallback; chỉ báo “Trực tiếp” nghĩa là stream đã nhận frame,
không thay trạng thái pending/offline/conflict và không bảo đảm mọi API vừa thành công.

`/events` trả private/no-store, text/event-stream, X-Accel-Buffering:no/nosniff; Origin header
phải thuộc WEB_ORIGINS, native không Origin vẫn cần Bearer. Connection cap3/session,8/account
**mỗi process**; dependency finally trả slot khi disconnect/error. CORS allowlist giữ nguyên.
Không coi cap này là distributed quota/production abuse protection. Counter read mỗi stream
250ms cần load test trước scale lớn; proxy phải tắt buffering, giữ idle timeout>heartbeat và
HTTPS. Không thể thu hồi ngay dữ liệu đã tải trên thiết bị mất mạng hoặc bản đã export.

## Bằng chứng

Xem [INDEX](../evidence/2026-10-02-realtime/INDEX.md) cho exact commands/date/target/source
hash và failure→repair. Host106 Flutter/53 backend PASS;5 bài SSE socket localhost thật bao
gồm owner/editor/viewer/stranger, auth/origin/connection caps, rollback/replay/reconnect,
lock/session revoke. Android API36 debug real SSE/API/platform key/encrypted Sembast reopen
PASS; Chrome local release QA có phạm vi ghi riêng trong index. Không suy ra physical-device,
OS kill/Wi-Fi toggle, public HTTPS, release functional, video hay đủ32 tiêu chí.

Nguồn kỹ thuật chính thức đối chiếu 02/10/2026:
[FastAPI StreamingResponse](https://fastapi.tiangolo.com/advanced/custom-response/#streamingresponse),
[MDN SSE](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events).
Streaming Fetch/abort được kiểm tra thêm trên source http1.6.0 đã resolve trong Pub cache;
không thêm dependency hay chép module app ngoài.
