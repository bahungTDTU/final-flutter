# Kiến trúc NoteTogether

Ngày đối chiếu: 01/10/2026. Đây là nền tảng local M0 và một phần M1/M2, chưa phải sản phẩm hoàn tất.

## Luồng đã triển khai

`ui → AppController (ChangeNotifier) → Api / LocalStore → FastAPI / Sembast`.
Một Flutter project, core Dart chung, conditional export ở thao tác mở database và attachment platform:
Web dùng IndexedDB qua sembast_web; Android dùng file trong application support qua path_provider.
Không dùng shared_preferences cho note quan trọng vì package không bảo đảm độ bền dữ liệu.

Controller quản lý session, notes, drafts, preferences, labels, immutable outbox, conflict và recovery.
EncryptedAccountStore mã hóa snapshot key `account:<user UUID>` chứa cả notes/outbox/drafts/recovery
trong một transaction, device key riêng. Xem ENCRYPTED_RECOVERY.md cho migration/key lifecycle.
`session` riêng giữ token và profile để khôi phục offline. Hiện session store chưa được mã hóa;
đây là giới hạn bản local, cần hardening trước public release. Server note khóa chỉ giữ metadata;
recovery giữ local edit trước khóa trong envelope, không tải source content hoặc tạo unlock grant.

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

Indexes: notes(owner,deleted), shares(user). Sync transaction kiểm tra ACL/unlock →
idempotency fingerprint → revision → mutate → journal result. Delete tạo tombstone,
xóa shares/grants và null attachment BLOB cùng transaction. Attachment mutations không tăng note revision.

Note associations lưu ID nhãn trong JSON; serializer lấy name/loại tombstones từ catalogue server.
Rename/delete label tăng label revision, không rewrite content/revision note. CAS/idempotent label
outbox lưu trong encrypted account snapshot; avatar bytes cache cùng envelope. Avatar APIs chỉ
session own-user, raw upload decode/canonicalize trước CAS; không có public image URL.
Migration v1 giữ old note operation payload/fingerprint; chi tiết AVATAR_AND_LABELS.md.

## Các phần chưa triển khai

Internet SMTP delivery/outbox, durable/offline media upload, offline protected-note unlock,
protected editing, protected-reader realtime acceptance, LLM/retrieval, hosting HTTPS, production signing.
Không có mock AI hoặc câu trả lời giả. SMTP/TLS transport đã có, disabled nếu chưa config.
Main không giữ mailbox raw token. Test double/sink/code reader chỉ ở test/QA script, không phải
provider production. EMAIL_DELIVERY.md mô tả code UI và giới hạn mail outbox.

## Nguồn kỹ thuật

- https://pub.dev/packages/sembast và https://pub.dev/packages/sembast_web
- https://pub.dev/packages/shared_preferences (cảnh báo critical data)
- https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/ (tham khảo cơ chế security; dự án dùng opaque session)
- https://argon2-cffi.readthedocs.io/en/stable/api.html

Packages được resolve bằng tool thật và giữ pubspec.lock/requirements.txt. Không tái sử dụng code app khác.

Preferences: xem PREFERENCES_SYNC.md cho durable field-patch queue và last-server-accepted rule.

ProtectedReader giữ online content riêng cho route, TTL/epoch guard/polling quyền; không ghi vào
account snapshot. AppController serialize note grant mutations qua nhiều reader routes; xem
NOTE_PROTECTION.md cho khóa/mở/đổi/tắt và giới hạn chỉ đọc.

AttachmentSession là ChangeNotifier riêng theo route/account/token, RAM-only, poll15s/epoch guards;
metadata/binary không đi vào encrypted account snapshot hoặc note outbox. Private API kiểm tra
read/edit/grant trước stream và trước upload commit; Range cho native player, Web dùng authorized
bytes→Blob URL, Android export ACTION_CREATE_DOCUMENT. Attachments table là additive extension
schema2, giữ nguyên v1 migration/journal. Chi tiết và limits: PRIVATE_ATTACHMENTS.md.

ShareSession quản lý owner recipients qua atomic batch/CAS/idempotent API, route RAM-only.
AppController nhận server role/owner/time/count; lost edit/revoke chuyển latest draft vào recovery
mã hóa, giữ frozen editor base. Catalogue người nhận không ghi vault, note khóa không metadata.
Xem SHARING_AND_PERMISSIONS.md cho mốc sharing; SSE mới xem REALTIME_COLLABORATION.md.

RealtimeFeed riêng một authenticated GET /events per account foreground. Backend SQLite triggers
tăng counter trong transaction; server kiểm tra session/version250ms và stream thông báo không
content/ID/metadata. Controller coalesce100ms, giữ tín hiệu giữa sync, route sessions refresh;
15s HTTP sync vẫn fallback. Editor sạch nhận remote text/selection, base không tự đổi, explicit
CTA mở phiên mới. Dirty/outbox giữ nguyên để CAS409/recovery khi quyền mất. Không OT/CRDT.
