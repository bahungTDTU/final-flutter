# Phục hồi chỉnh sửa khi khóa từ xa

Đợt02/10/2026 mở rộng recovery cho viewer/permission/revoked: latest local draft/upsert giữ
trong cùng encrypted snapshot trước bỏ source queue; readonly/hidden editor, reopen offline,
phục hồi UUID mới. Không archive server content khi người dùng chưa sửa. Reason được giữ theo
account; source accessUnavailable chặn save sau revoke. Xem SHARING_AND_PERMISSIONS.md và
evidence/2026-10-02-sharing; Android debug/Web local release có QA thật, không OS kill claim.

## Hành vi đã triển khai

Production main và hai integration harness dùng EncryptedAccountStore bọc SembastLocalStore.
Mỗi record account:<user UUID> là envelope AES-256-GCM: vault_version, key_id, nonce, ciphertext,
mac. JSON bên trong chứa notes/drafts/outbox/conflicts/preferences/labels/recoveries. Nonce mới
mỗi lần encrypt; AAD bind account key và phiên bản. Không tự viết thuật toán mã hóa.
Session token/profile vẫn lưu riêng theo hiện trạng, chưa được hardening cùng đợt này.

Khi GET /notes nhận locked hoặc POST /sync trả423, controller đọc draft mới nhất hoặc upsert cuối của note,
lưu title/content đã có local vào recoveries với source ID và thời gian thực. 423 che source ngay
cả khi list request sau đó thất bại, bỏ các operation cùng source khỏi vòng gửi. Trong cùng snapshot transaction,
loại draft/outbox/conflict của source và thay note bằng metadata khóa. Chỉ cached server content,
không có draft/upsert, không tạo recovery. Delete operation không tự gửi lại sau khóa.
Không gộp pin/labels/permission/protection vào recovery. Poll15s/nút sync phát hiện lock, chưa realtime.

Editor đang mở hủy debounce, xóa TextEditingController khi nhận lock và che màn hình. draft/save
không ghi lại source đã khóa. Home/dialog chỉ hiện số lượng/thời điểm, không hiện title/content
của recovery trong search/preview. Chọn Phục hồi → Bản chỉnh sửa đã giữ mở draft dưới UUID mới;
chưa tự gửi lên server. Draft thiếu title/content vẫn giữ được. Người dùng hoàn thiện thì auto-save
tạo note mới base revision0. Source vẫn cần note unlock grant của backend.

Recovery giữ lại sau copy; chọn lại dùng cùng ID, không ghi đè copy đã sửa. Logout xóa visible
recovery state, giữ namespace để lần đăng nhập đúng account mở lại. Không có chức năng xuất khóa,
backup cloud hoặc xóa riêng recovery trong đợt này. Dữ liệu tồn tại trên thiết bị/browser origin này.

## Vòng đời khóa và giới hạn

- cryptography2.9.0 và flutter_secure_storage11.2.0 pin trong pubspec.yaml/pubspec.lock.
  Khóa32 byte ngẫu nhiên; mỗi generation UUID riêng, lưu tên notetogether.vault.v1:<account>:<id>
  qua platform secure storage. Sembast không chứa key bytes hoặc mật khẩu.
- Ghi khóa và đọc lại thành công trước publish envelope. Khóa thiếu/hỏng không tự tạo khóa thay thế
  cho record đã mã hóa; giữ ciphertext, báo lỗi và chặn load/write/sync account để tránh mất draft.
- Logout/account password reset/note protection password change không xóa hoặc thay device vault
  key. Key không derive từ các mật khẩu này; backend session/grant vẫn có chính sách riêng.
- rotateAccount() là primitive đã test: decrypt bằng key cũ, persist key mới trước, transaction
  thay envelope; old/orphan keys giữ lại để không phá backup/in-flight readers. Chưa có UI rotation
  hoặc garbage collection key. Không claim automatic rekey sau đổi mật khẩu.
- Android dùng default RSA OAEP + AES-GCM của plugin, khóa wrapping qua Android KeyStore.
  allowBackup=false để giảm restore dữ liệu thiếu keystore key; chưa nghiệm thu backup/device transfer.
  Không bật biometric/PIN gate; người đang dùng app với session local có thể copy bản chỉnh sửa đã giữ.
- Web provider dùng WebCrypto và localStorage, yêu cầu HTTPS/localhost; chính nhà phát triển đánh
  dấu experimental. Provider có lưu master key có thể export trong browser storage. Tách key khỏi
  IndexedDB không chống XSS, extension độc hại hoặc người đọc toàn bộ browser profile. Không gọi
  đây là hardware keystore Web, E2EE, chống mất thiết bị hoặc production security acceptance.
- Clear site data/uninstall/key loss có thể làm mất khả năng đọc recovery. Không có server escrow.
  App không hứa phục hồi khi mất key hoặc storage eviction; không lưu plaintext fallback.
- Nhiều tab cùng browser profile ghi snapshot/key đồng thời chưa nghiệm thu; chưa merge outbox
  local giữa tab. Luồng second-session đã test dùng phiên API riêng, không phải stress test nhiều tab.
- Account snapshots có thể giải mã trong memory của app; Dart strings/GC không bảo đảm zeroization.
  Offline chưa biết lock/revoke mới vẫn có dữ liệu đã tải hợp lệ. Không thể thu hồi dữ liệu khỏi
  thiết bị đang offline; backend kiểm tra quyền/grant khi kết nối lại. Không có anti-rollback vault.

Nguồn package/thuật toán: [cryptography](https://pub.dev/packages/cryptography),
[flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage).
Kiểm tra Web provider từ flutter_secure_storage_web2.1.1/lib/flutter_secure_storage_web.dart
trong Pub Cache để đối chiếu việc export/store master key; không hardcode wrap key vào app.

## Migration, crash và lỗi ghi

Legacy account được encrypt transaction trước khi controller load. Sembast log cần compact để bỏ
dòng plaintext cũ: envelope có needs_compaction marker, retry trước khi trả dữ liệu nếu compact
bị ngắt. Sau compact thành công mới xóa marker. Migration account khác diễn ra khi account đó
được mở. Không hứa secure erase sector/backups hay plaintext của account chưa được migrate.

Lock transition lỗi ghi: UI đã che source, bản recovery ở memory và snapshot trước đó vẫn chứa
edit trong envelope. Giữ app mở/thử sync lại; không báo durable thành công. Nếu restart trước commit,
snapshot cuối cùng còn draft/outbox và có thể archive lại khi nhận lock. Crash trước lần local write
đầu tiên, OS kill, quota/eviction vẫn có thể mất keystroke; local storage không phải backup.
Restore lỗi ghi không xóa recovery. Retry persist trước mở draft; không đổi operation ID của queue
khác. Không gửi lại original locked operation hoặc ghi đè server note khi tạo copy.

Locked list metadata bổ sung role do server xác định để owner/shared tabs đúng; chỉ id/locked/
revision/role, không title/content/labels/pin. access(unlocked=False) chỉ dùng cho metadata list;
read/mutation/grant protection tiếp tục kiểm tra unlock. Payload không cấp quyền owner.

## Bằng chứng và giới hạn nghiệm thu

Xem evidence/2026-10-01-encrypted-recovery và STATUS.md. Tests test/encrypted_recovery_test.dart
bao gồm crypto tamper/AAD, missing key, migration/key/write/compaction failure, rotation, 423/list failure, locked
in-flight draft, không archive cached remote content, encrypted file reopen và dialog/copy mới.
Key/fault/HTTP adapters ở unit tests là doubles; test AES-GCM và Sembast file là thư viện thật.
Integration Android dùng platform key store và real backend; reopen cùng process, không force-kill.
Web dùng real browser offline/reload/reconnect và phiên API thứ hai; xem web-lock/verify JSON.
Online note protection/read UI đã nối sau đợt này; xem NOTE_PROTECTION.md và evidence đợt riêng.
Không nâng tiêu chí23/24 và offline thành hoàn thành toàn bộ: protected edit, offline note-password unlock,
key backup/realtime/physical-device/public HTTPS vẫn còn.
