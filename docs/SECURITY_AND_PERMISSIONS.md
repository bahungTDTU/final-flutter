# Quyền và giới hạn bảo mật

11–12/10: session catalogue/revoke own-account, password confirmation shared cooldown,
private validation errors và read authentication. Xem SECURITY_CENTER_AND_AUTH_PERFORMANCE.md
và evidence/2026-10-11-security-center; native runtime/public deployment phần mới chưa nghiệm thu.

Đối chiếu tài liệu chuyên đề12/10/2026 trên source35db810. Đây là mô tả thiết kế,
không phải chứng nhận security audit hoặc nghiệm thu public deployment.

| Operation | Owner | Editor | Viewer | Stranger / anonymous |
|---|---|---|---|---|
| List/read | Có; content khóa cần grant | Có; content khóa cần grant | Có; content khóa cần grant | Không |
| Sửa title/content | Có, phải unlock | Có, phải unlock | 403 | 404 / 401 |
| Pins/labels | Owner | Payload bị bỏ qua, không có quyền quản lý | Không | Không |
| Label catalogue/mutations | Chỉ catalogue của session account; note IDs validate owner | Catalogue riêng, không đổi owner labels | Catalogue riêng | Không đọc catalogue người khác; anonymous401 |
| Avatar read/replace/default | Chỉ session own-user; revision CAS | Avatar riêng của account | Avatar riêng của account | Không public/userId endpoint; anonymous401 |
| Delete/protection/share/revoke | Owner; delete/share/catalogue cần unlock | 403 | 403 | 404 / 401 |
| Files list/read | read/grant; không bypass lock | read/grant | read/grant | 404 / 401 |
| Files upload/delete | edit/grant | edit/grant | 403 | 404 / 401 |
| AI đọc nội dung | Read ACL + grant khi khóa | Read ACL + grant khi khóa | Read ACL + grant khi khóa | 404 / 401 |
| Realtime | SSE phiên hợp lệ, chỉ counter; refetch kiểm tra ACL | Tương tự | Tương tự | Không nhận stream tài khoản khác / 401 |
| Sessions list/revoke | Chỉ session account; revoke cần account password | Tài khoản riêng | Tài khoản riêng | Không target session account khác; anonymous401 |

`access()` kiểm tra session đang còn hiệu lực trong cùng mutation transaction, quyền và grant.
List note khóa chỉ trả ID, locked, revision, role, pinned_at và shared boolean do server xác định.
Người dùng xác nhận07/10 cho hiện trạng thái ghim/chia sẻ khi khóa. Không trả title/content/labels,
updated_at, owner/recipient identity, share timestamps hoặc số người nhận; unlock không mở rộng list.
Grant bind session (gián tiếp user), note, protection version, TTL 5 phút.
Đổi/tắt/bật password xóa grant; role change/revoke xóa grant của recipient; logout/reset/change
password xóa session và grant cascade. Owner không bypass unlock. API sync kiểm tra quyền
trước replay; operation result chỉ metadata, không lưu/replay content.

Mật khẩu tài khoản/note Argon2id qua thư viện chuẩn. Token 32-byte ngẫu nhiên chỉ lưu digest server.
Auth chưa bắt buộc verified để dùng app. Endpoint activation/reset public và one-time.
Login có cooldown5 lần sai/60s; unlock/change/disable note dùng chung durable user+note scope
5 lỗi/60s qua nhiều session/restart, đúng cũng bị429 trong cooldown và có Retry-After.
Hết cooldown note bắt đầu cửa sổ5 lần mới; đúng password xóa counter. Resend/forgot có60s.
Đổi password/thu hồi session dùng chung account counter5/60s, persistent/restart-safe;
hết cooldown bắt đầu cửa sổ mới. Login scope dùng hash email và giữ cooldown khi migration.
Registration/reset, distributed abuse limits và timing enumeration còn cần hoàn thiện trước public deployment. Protection note
đã dùng chung throttle với unlock; xem PROTECTION_STATUS_FIXES.md và test_note_password_limits.py.

SMTP/TLS verify certificate/hostname, auth sau TLS; thiếu STARTTLS không gửi plaintext.
Email code random32-byte, digest/TTL/kind/used kiểm tra atomic; reset/check public không tiêu thụ
mã, reset cuối kiểm tra lại và revoke mọi session. Main không giữ mailbox/token thô/log.
Forgot response/cooldown known/unknown giống nhau; chưa bảo đảm chống timing enumeration.
SMTP accepted không chứng minh inbox receipt; transactional mail outbox/worker
đã có nonce/metadata và dẫn xuất mã bằng PRF, lease/retry/cancel; không lưu mã thô. Key lifecycle và giới hạn nghiệm thu Internet
xem EMAIL_DELIVERY.md.

Avatar input PNG/JPEG≤2 MiB/dimensions bounded; backend decode/EXIF orientation rồi tạo PNG mới
≤512×512 không metadata. BLOB replace/delete atomic, authenticated download private/no-store;
ảnh cache trong encrypted account snapshot và generation/revision guards bỏ stale response.
Label names NFC/casefold owner-unique; label IDs/revisions/tombstones server-authoritative,
shared read chỉ có names của note được phép đọc. CAS/conflict không dùng preferences LWW;
immutable pending label dependency không chặn GET notes/remote-lock draft recovery.
Chi tiết/migration/giới hạn ở AVATAR_AND_LABELS.md; chưa cloud storage.

Attachments có private BLOB/note ACL+grant, bounded raw upload/canonical image/MIME/container
validation, server quota, immutable retry fingerprint và tombstone; kiểm tra lại quyền sau normalize
trước commit chống lock/revoke race. Binary private/no-store/nosniff/CSP sandbox/attachment;
không public URL/token query. Metadata và preview RAM-only, che theo account/token/epoch/15s
poll/list membership/lifecycle, player dispose. Không execute/extract/render PDF/ZIP; validation
signature không là antivirus. Export là bản người dùng chọn lưu, không thể thu hồi. Xem
PRIVATE_ATTACHMENTS.md; quota/rate limits/codec breadth/public release còn cần nghiệm thu.

Backend local DB chứa note plaintext, cần quyền file/backups server phù hợp khi deploy.
Client account snapshot (notes/drafts/outbox/recovery) mã hóa AES-GCM với device key riêng;
session/profile cũng mã hóa bằng envelope/device key/AAD riêng từ07/10; xem SESSION_STORAGE.md. Web key provider experimental/localStorage không chống người đọc
browser profile hay XSS. Migration legacy theo account, có compaction retry. Chi tiết ở ENCRYPTED_RECOVERY.md.
Client có protected edit và offline note-password unlock cho dữ liệu đã tải hợp lệ.
Protected content/draft/operations chỉ nằm trong password-encrypted vault, không ordinary cache/
outbox; background/expiry/role loss che nội dung. Reconnect cần server revalidation trước sync.
SSE và polling15s bổ trợ kiểm tra quyền. Xem NOTE_PROTECTION.md cho TTL/cache/recovery và giới hạn.
Không đánh dấu mục 23/24 hoàn thành chỉ vì spike backend pass.

Khi reconnect phát hiện lock, client chuyển draft/upsert chưa sync vào encrypted recovery trong cùng
snapshot transaction rồi xóa source content/draft/outbox. Recovery là copy nội dung đã có local,
không mở source hay đổi protection. Lỗi ghi giữ snapshot cũ và báo retry; không tự bỏ edit.
Khi downgrade/revoke, latest draft/upsert vào encrypted recovery, source không tự sync lại;
viewer UI dùng content server, revoked UI che nội dung. Copy local dùng UUID mới do người dùng
chọn; giữ được dữ liệu đã nhận hợp lệ trước revoke. Share catalogue owner-only/RAM-only,
atomic batch+CAS+journal replay không reapply quyền; xem SHARING_AND_PERMISSIONS.md.
Không thể thu hồi ngay dữ liệu đã tải trên thiết bị mất mạng.

SSE `/events` dùng Bearer header và Origin allowlist, kiểm tra session mỗi250ms. Payload chỉ
counter version, không ID/content/title/roles/recipient metadata. Revoke thông báo account bị
gỡ rồi các edits sau không broadcast cho account đó; ACL/grant vẫn kiểm tra lại mọi API.
Cap3/session8/account per-process và private/no-store; không production/distributed rate-limit
claim. Logout/background/account switch ngắt feed theo epoch. Xem REALTIME_COLLABORATION.md.

Không log password, token hoặc content; Uvicorn chạy --no-access-log. CORS allowlist local,
không dùng wildcard credential. HTTPS bắt buộc khi public; Dockerfile chỉ là cấu hình chưa deploy.
Release Android cần INTERNET; cleartext chỉ cho debug build. Release dùng signing config riêng và từ chối thiếu key/alias/password; không fallback
debug signing. Keystore thật/certificate/install-run còn phải nghiệm thu; xem
RELEASE_AND_BACKUP.md. Không commit private signing material.
