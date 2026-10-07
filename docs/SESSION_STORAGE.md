# Session storage và migration — 07/10/2026

F5 trong audit ghi nhận record `session` chứa token/profile plaintext. Hiện
EncryptedAccountStore mã hóa cả record này, dùng AES-256-GCM v1 và **khóa thiết bị riêng**
với namespace `notetogether.vault.v1:session:device`. Sembast chỉ giữ vault_version/key_id/
nonce/ciphertext/mac và marker khi cần compact; không có token, user ID hoặc profile thô.
AAD `NoteTogether:account:v1:session` tách record khỏi account và draft projection.
Nonce mới mỗi publish; device key được xác nhận đọc lại trước ghi ciphertext.

Khóa nằm trong DeviceRecoveryKeys/flutter_secure_storage như account vault. `key_id=device`
là tên slot, không phải key bytes hoặc danh tính tài khoản. Cùng slot được dùng lại khi login
sau logout; không tạo hàng loạt key generation mỗi lần đăng nhập. Account key/password vault
và chính sách note protection, frozen editor base/immutable ops không thay đổi.

## Luồng và migration

Mọi session write hiện có (login/registration, refresh profile/sync, avatar) đi qua wrapper.
Controller vẫn dùng logical map user/token; envelope là ranh giới persistence, không đổi API.
Login chỉ mở Home sau account load + session persist thành công. Nếu server vừa cấp token nhưng
persist lỗi, controller bỏ phiên trong RAM, báo lỗi và cố thu hồi **token mới đó** trên server.
Không báo đăng nhập thành công chỉ vì HTTP auth đã thành công.

Khi initialize đọc session legacy:

1. Kiểm tra user ID/token có dạng hợp lệ, tạo/đọc lại device key riêng.
2. Publish envelope bằng transaction Sembast, kèm needs_compaction marker.
3. Compact database để bỏ token/profile cũ khỏi lịch sử log, rồi bỏ marker.
4. Chỉ sau khi các bước hoàn tất mới trả session cho controller mở account/Home.

Lỗi key publication/transaction giữ record legacy gốc. Compact lỗi sau publish giữ encrypted
record có marker; lần mở sau giải mã và thử compact lại trước trả token. Không fallback plaintext
hoặc gọi API khi initialize chưa mở được session. Account snapshots/draft projections giữ nguyên.
Legacy của account vẫn migration riêng khi account đó được mở; compaction session không tự mã
hóa các account chưa migrate. Thiếu/hỏng key/cipher/AAD/version: giữ record và báo lỗi, không
tự sinh key thay thế cho encrypted session. Ghi phiên mới cũng không overwrite envelope hỏng.

## Logout và lỗi lưu trữ

Native/Web Sembast publish tombstone `session_removed` trước compact rồi remove record.
Nếu compact bị ngắt, tombstone còn bền: lần mở sau hoàn tất dọn và trả null, không khôi phục
token cũ. Logout giữ encrypted account/drafts/outbox để đúng người đăng nhập lại tiếp tục.
Nếu tombstone publish lỗi, controller vẫn che Home, hiển thị lỗi + **Thử xóa phiên trên thiết bị**;
không claim session đã xóa. Server revoke vẫn được thử ngay cả khi local cleanup thất bại.
Test doubles không có Sembast compaction vẫn dùng remove logical record như trước.

Logout online làm bearer cũ nhận401. Khi server unreachable, revoke không được bảo đảm;
backend TTL24h vẫn áp dụng. Nếu local publish thất bại trước tombstone, encrypted session cũ
còn ở disk; cần retry cleanup. Không coi xóa logical record/compact là secure erase sector,
backup hoặc phục hồi key sau mất thiết bị. Slot session key giữ lại, không xóa key account.

## Ranh giới Web và nghiệm thu

Android dùng plugin với Android KeyStore/wrapping; chưa thêm biometric hoặc device-transfer.
Web dùng provider WebCrypto/localStorage hiện có trên localhost/HTTPS. Mã hóa IndexedDB
giúp token/profile không còn plaintext ở DB, **không chống XSS, extension độc hại hay người
đọc toàn bộ browser profile và key storage**. Token vẫn ở RAM để gọi bearer API/SSE.
Chưa chuyển sang BFF/HttpOnly cookies, thêm refresh-token protocol, đổi thời hạn backend
hoặc nghiệm thu public HTTPS/physical/OS kill/quota/multi-tab. Release vẫn để cuối.

- 8 Flutter regressions mới: file migration/history/reopen, nonce/key/AAD/rotation isolation,
  key readback/transaction rollback, interrupted compaction/no API, missing/tampered key và
  rejected login, logout tombstone/server revoke/reopen, refresh/logout/login B race, UI retry.
  Case UI dùng memory fault double; crypto/durability dùng AES + file Sembast thật.
- Android API36 debug: 1 workflow + teardown PASS5s, actual local API/platform keys/file
  legacy migration, file token/profile không plaintext, offline reopen, logout401 và manual
  UI login giữ encrypted draft. Ba PNG; không phải2 chức năng chỉ vì teardown được đếm.
- IAB Web debug: khôi phục fixture từ phiên bản cũ, reload offline, logout/reload/login và
  profile roundtrip theo scope trong evidence. Không đọc token thật trong browser tool/logs.

Gate/commands/ảnh/hashes: [evidence/2026-10-07-session-storage/INDEX.md](../evidence/2026-10-07-session-storage/INDEX.md).
Base5b82996 + performance/session working changes; chưa commit/push đợt này. Các bản audit và
manifest trước đây giữ snapshot lúc đo, không được sửa để giả thành kết quả của source mới.
