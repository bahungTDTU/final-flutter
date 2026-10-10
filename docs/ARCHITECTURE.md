# Kiến trúc NoteTogether

Planner10/10: NotePlan ID/stage/priority/calendar-date trong workspace encrypted, không note
snapshot/server endpoint. save/move/remove dùng _editWorkspace durable serialization; move
merge trường deadline/priority mới nhất, không tạo sync op. PlannerSliver derive workspaceNotes,
lazy per-column/mobile rows, route-owned query state không giữ note snapshots. Calendar/form/
picker revalidate controller. Entrance-only220ms/press180ms/progress220ms không giữ child exit;
reduced motion durations0, midnight timer/resume riêng cho calendar. WORKSPACE_PLANNER_AND_MOTION.md.

Workspace tập trung10/10 thêm FocusData/session/deadline/history trong account
workspace blob. _editWorkspace đọc durable root/serialize write, giữ drafts/vault và
chỉ publish account đang active. Deadline-based timer không persist mỗi tick; panel
có ticker riêng, completion theo ID/deadline idempotent, không backend endpoint mới.
Form save await durable transaction, failure giữ controllers/input. WORKSPACE_FOCUS_AND_UX.md.
Web worker upgrade lấy static bytes với cache:reload, tôn trọng reload/no-store khi fetch;
fingerprint bao gồm worker template, bootstrap updateViaCache:none. Allowlist vẫn chỉ
40 tài nguyên build, không API/session/private files. SHA256 cache cuối khớp release QA.

Ngày đối chiếu: 10/10/2026, source base `a5e5ec6` + ordering và workspace cá nhân.
Đây là kiến trúc đã triển khai local; nghiệm thu provider thật, native editor mới và release
còn các gate riêng trong STATUS.md và REQUIREMENTS_MATRIX.md.

## Luồng đã triển khai

`ui → AppController (ChangeNotifier) → Api / LocalStore → FastAPI / Sembast`.
Một Flutter project, core Dart chung, conditional export ở thao tác mở database và attachment platform:
Web dùng IndexedDB qua sembast_web; Android dùng file trong application support qua path_provider.
Không dùng shared_preferences cho note quan trọng vì package không bảo đảm độ bền dữ liệu.

Controller quản lý session, notes, drafts, preferences, labels, immutable outbox, conflict và recovery.
EncryptedAccountStore mã hóa snapshot key `account:<user UUID>` chứa cả notes/outbox/drafts/recovery
trong một transaction, device key riêng. Từ07/10, nhập ordinary drafts dùng projection mã hóa
`drafts:account:<UUID>` với AAD riêng; read gộp, full publish ghi root + xóa projection nguyên tử.
Không đổi password vault/immutable outbox. Xem PERFORMANCE_DRAFTS_AND_ATTACHMENTS.md và
ENCRYPTED_RECOVERY.md cho capability/fallback/migration/key lifecycle.
`session` riêng giữ token/profile trong AES-GCM envelope với device key/AAD riêng, migrate và
compact legacy trước controller mở Home. Logout tombstone không revive session khi compact
bị ngắt; account/drafts giữ riêng. Web provider chưa chống XSS/full-profile reader; xem
SESSION_STORAGE.md cho scope/giới hạn. List/cache note khóa chỉ giữ sáu trường công khai;
server vẫn lưu nội dung để phục vụ reader có quyền và grant, không phải mã hóa đầu-cuối.
Recovery giữ local edit trước khóa trong envelope, không tải source content hoặc tạo unlock grant.

FastAPI dùng SQLite, foreign keys và transaction `BEGIN IMMEDIATE` bao quanh quyền + mutation.
Phù hợp spike và quy mô nhóm nhỏ, chưa được load-test và không thiết kế multi-instance.
Auth dùng opaque bearer token: server chỉ giữ SHA-256 token ngẫu nhiên; password dùng Argon2id.
Client không thể gán owner/verified/role/protection thông qua sync payload.

## Schema và ranh giới transaction

Source schema: `backend/schema.sql` + `backend/catalogue.py`, schema2 migration0/1→2 atomic.
Uvicorn dùng `backend.app:create_app --factory`; import module tests không mở DB default.

| Entity | Khóa / quan hệ / invariant |
|---|---|
| users | UUID PK; email lowercase UNIQUE; password hash; preferences JSON |
| sessions | token digest PK; FK user; TTL 24h; grants cascade khi session bị xóa |
| email_tokens | digest PK; kind verify/reset; TTL 30 phút; one-time; resend vô hiệu token cũ |
| email_jobs | token digest/nonce; transactional outbox; lease/retry/TTL; không lưu mã email thô |
| notes | UUID PK; FK owner; revision; timestamps UTC; soft-delete; Argon2 note password/version |
| shares | note + user composite PK; viewer/editor; shared_at được giữ khi đổi role |
| share_versions | note PK; revision riêng cho catalogue quyền, không dùng content revision |
| share_operations | owner+op_id PK; immutable fingerprint; replay chỉ trả current catalogue |
| grants | session + note PK; protection version; TTL 5 phút |
| operations | user + operation ID UNIQUE; fingerprint payload; result chỉ metadata |
| preference_operations | user+op_id PK; fingerprint; không stale replay preferences |
| labels | ID PK; owner FK; name/name_key; revision; deleted; active name casefold UNIQUE/account |
| label_operations | user+op_id PK; immutable fingerprint; replay trả current row, không reapply |
| avatars | user PK/FK; revision; canonical PNG BLOB hoặc NULL khi dùng mặc định |
| attachments | UUID PK; note/creator FK; canonical BLOB; immutable fingerprint; deleted tombstone |
| attempts | scope login/email hoặc unlock/user/note; 5 lỗi → cooldown 60s |
| ai_budgets | scope/bucket; giới hạn request AI trước gọi provider |

Realtime tracking được cài bằng `backend/realtime.py`: counters tăng cùng transaction với
mutation, SSE không mang nội dung/ID note; client refetch qua API có ACL.

Indexes: notes(owner,deleted), shares(user). Sync transaction kiểm tra ACL/unlock →
idempotency fingerprint → revision → mutate → journal result. Delete tạo tombstone,
xóa shares/grants và null attachment BLOB cùng transaction. Attachment mutations không tăng note revision.

Note associations lưu ID nhãn trong JSON; serializer lấy name/loại tombstones từ catalogue server.
Rename/delete label tăng label revision, không rewrite content/revision note. CAS/idempotent label
outbox lưu trong encrypted account snapshot; avatar bytes cache cùng envelope. Avatar APIs chỉ
session own-user, raw upload decode/canonicalize trước CAS; không có public image URL.
Migration v1 giữ old note operation payload/fingerprint; chi tiết AVATAR_AND_LABELS.md.

## Editor và projection nội dung

`DocumentWorkspace` dùng Flutter Quill: PC ribbon/trang viết/inspector, phone toolbar dưới.
`note_document.dart` lưu Delta qua envelope `NTDOC1:` trong content string hiện có; backend kiểm tra
schema, giới hạn và chỉ cho định dạng được hỗ trợ. Markdown cũ được đọc qua adapter, mở note
không tự ghi migration. Plain-text projection dùng cho cards/search/AI/studio, không tìm trong
tên trường định dạng. Editor giữ ID/base revision lúc mở qua theme/resize/remote refresh.
Xem ADAPTIVE_DOCUMENT_EDITOR.md; không có bảng hay export DOCX/PDF.

`GET /notes` được sắp `updated_at DESC, id ASC` tại server trước projection. Note khóa vẫn
chỉ có `id/locked/revision/role/pinned_at/shared`, kể cả khi có grant. Client nhóm ghim theo
public pin time và giữ thứ tự array cho phần chưa ghim có ngày bị ẩn; array được lưu nguyên
trong encrypted account snapshot. Không thêm ngày hoặc sort metadata vào cache note khóa.
Local ordinary edits được đưa lên đầu khi pending; ACK/refetch trả thứ tự server.
Xem NOTE_LIST_ORDERING.md cho offline/cache cũ và race tests.

## Chức năng đã triển khai, nghiệm thu và giới hạn

- Email: SMTP/TLS transport, transactional outbox, worker lease/retry/restart, resend/status/
  verify/reset đã có và được kiểm tra local TLS. SMTP ngoài và inbox thật chưa nghiệm thu.
  Không có mailbox raw token trong app. Xem EMAIL_DELIVERY.md.
- AI: Gemini REST adapter, Summary/regenerate và Q&A BM25/citations đã có. ACL/grant được
  kiểm tra trước context và sau inference; kết quả RAM-only, không ghi đè note. Tests và QA
  fixture đã chạy, chưa gọi Gemini thật với key mới. Thiếu config báo disabled, không giả
  câu trả lời. Xem AI_FEATURES.md.
- Protected notes: đọc/sửa/autosave/xóa theo role, password-encrypted cache/draft, offline
  unlock, immutable protected operation, recovery và SSE revalidation đã có; local Web và
  Android debug có evidence05/10. Đây không phải key backup hoặc quyền offline vô thời hạn.
  Xem NOTE_PROTECTION.md.
- Private attachments: API/ACL/grant, upload/preview/download/Range/delete đã có, online-only.
  Retry giữ RAM; durable/offline media outbox chưa triển khai. Xem PRIVATE_ATTACHMENTS.md.
- Cải tiến tùy chọn chưa triển khai: key backup/transfer, bảng/export DOCX/PDF và OT/CRDT;
  không đưa chúng thành yêu cầu độc lập của đề. Public HTTPS và signing production chưa có.
  Native runtime/IME/FPS của editor Quill mới, physical device/screen reader,
  clean-machine release và submission/video/teamwork chưa đủ evidence. Release để cuối theo
  yêu cầu người dùng; không biến build hoặc local fixture thành production acceptance.

## Nguồn kỹ thuật

- https://pub.dev/packages/sembast và https://pub.dev/packages/sembast_web
- https://pub.dev/packages/shared_preferences (cảnh báo critical data)
- https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/ (tham khảo cơ chế security; dự án dùng opaque session)
- https://argon2-cffi.readthedocs.io/en/stable/api.html

Packages được resolve bằng tool thật và giữ pubspec.lock/requirements.txt. Không tái sử dụng code app khác.

Preferences: xem PREFERENCES_SYNC.md cho durable field-patch queue và last-server-accepted rule.

ProtectedReader giữ nội dung giải mã riêng cho route, TTL/epoch guard/SSE/polling quyền;
password vault riêng giữ encrypted cache/draft/outbox/recovery, không ghi plaintext protected
content vào ordinary account snapshot. Owner/editor sửa qua DocumentWorkspace, viewer đọc.
AppController serialize note grant mutations qua nhiều reader routes; xem NOTE_PROTECTION.md.

AttachmentSession là ChangeNotifier riêng theo route/account/token, RAM-only, poll15s/epoch guards;
metadata/binary không đi vào encrypted account snapshot hoặc note outbox. Private API kiểm tra
read/edit/grant trước stream và trước upload commit; Range cho native player, Web dùng authorized
bytes→Blob URL, Android export ACTION_CREATE_DOCUMENT. Attachments table là additive extension
schema2, giữ nguyên v1 migration/journal. Chi tiết và limits: PRIVATE_ATTACHMENTS.md.

ShareSession quản lý owner recipients qua atomic batch/CAS/idempotent API, route RAM-only.
AppController nhận server role/owner/time/count; lost edit/revoke chuyển latest draft vào recovery
mã hóa, giữ frozen editor base. Catalogue người nhận không ghi vault; note khóa chỉ giữ public
pin/shared flags trong list/cache, không danh tính/thời điểm/số người nhận chia sẻ.
Xem SHARING_AND_PERMISSIONS.md cho mốc sharing; SSE mới xem REALTIME_COLLABORATION.md.

RealtimeFeed riêng một authenticated GET /events per account foreground. Backend SQLite triggers
tăng counter trong transaction; server kiểm tra session/version250ms và stream thông báo không
content/ID/metadata. Controller coalesce100ms, giữ tín hiệu giữa sync, route sessions refresh;
15s HTTP sync vẫn fallback. Editor sạch nhận remote text/selection, base không tự đổi, explicit
CTA mở phiên mới. Dirty/outbox giữ nguyên để CAS409/recovery khi quyền mất. Không OT/CRDT.


WorkspaceData/WorkspaceView là immutable domain values cho favorites/recent/view/template.
Trường workspace nằm trong encrypted account vault; serialize độc lập và merge durable
field tại commit để không mất tổ chức cá nhân khi ordinary snapshot/draft/vault cùng ghi.
WorkspaceTaskCache có giới hạn200sources/100tasks, route-local purge theo quyền/content.
Task mutation kiểm tra rendered revision/source/draft/pending/conflict rồi dùng save với
frozen base; import tạo UUID/base0/immutable ops và publish local batch trước network,
commit guards ngăn send batch chưa bền. Server vẫn giữ ACL/CAS. Portable schema chỉ có
content/title, strict limits/reject extra fields; SAF/Blob dùng adapter attachment hiện có.
Không endpoint mới, không multi-device workspace sync. Chi tiết PRODUCTIVITY_WORKSPACE.md.
