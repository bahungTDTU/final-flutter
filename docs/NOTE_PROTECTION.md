# Ghi chú bảo vệ — cập nhật 10/10/2026

## Sử dụng

Menu ghi chú của mình → **Bật khóa ghi chú**, nhập mật khẩu riêng 10–128 ký tự hai lần.
Hoàn tất bản nháp và outbox trước khi bật/đổi/tắt khóa. Backend xác nhận owner; payload
không thể đổi owner, role, protection hoặc tự cấp grant. Home/list/search của ghi chú khóa
trả ID, revision, locked, role, pinned_at và shared boolean. Theo lựa chọn người dùng07/10,
ghim/chia sẻ/khóa hiện đồng thời và giữ thứ tự ghim; không trả title/content/labels/updated_at,
số người nhận, danh tính hoặc thời điểm chia sẻ. Unpinned locked notes giữ thứ tự updated_at
từ array server, không hiện timestamp; NOTE_LIST_ORDERING.md. Search/filter vẫn loại nội dung note khóa.

Chạm thẻ khóa → nhập mật khẩu → mở phiên tối đa 5 phút. Sau mở khóa mới hiển thị nội dung,
nhãn, shared/pinned/role, người chia sẻ và thời gian nếu có. Owner/editor chọn **Chỉnh sửa**;
tiêu đề/nội dung dùng cùng DocumentWorkspace với editor thường (từ09/10), autosave650ms và lưu bản nháp
mã hóa ngay khi nhập. Owner sửa nhãn/ghim; editor sửa title/content; viewer chỉ đọc. **Đồng bộ bản nháp**
retry khi có kết nối/grant. Không đưa protected content/draft/operation vào notes/drafts/outbox
thường hoặc tìm kiếm; route giữ dữ liệu giải mã trong RAM.

Owner có **Xóa ghi chú** với xác nhận và server role/grant/base revision check. Hộp xác nhận
che tiêu đề và vô hiệu nút nếu quyền bị thu hồi. Phải đồng bộ hoặc giải quyết bản nháp trước
khi xóa, đổi mật khẩu, tắt khóa hoặc dùng AI trên bản server. Summary/Q&A kiểm tra lại quyền
và nguồn; AI vẫn cần backend provider được cấu hình, không có kết quả giả khi thiếu key.

Sau mở khóa online, owner/editor chọn/tải lên/xóa tệp riêng tư; viewer chỉ tải/xem tệp.
Quản lý chia sẻ chỉ dành owner. Mọi request vẫn qua API permission + grant, không phụ thuộc
việc nút có hiện trên client. Đính kèm/chia sẻ/AI không hoạt động trong phiên mở offline.

Mọi kiểm tra mật khẩu note hiện tại (unlock/change/disable) dùng chung counter bền theo
user+note, cả khi đăng nhập phiên khác hoặc backend restart.5 lần sai tạo cooldown60s;
trong cooldown cả mật khẩu đúng cũng nhận429 + Retry-After. Hết cooldown có cửa sổ5 lần
mới; đúng mật khẩu xóa counter. Failed attempts commit trước trả403, không mất do rollback.
Enable note chưa có password không cần đoán mật khẩu hiện tại; quyền owner vẫn bắt buộc.

Note.fromListingJson/toListingJson chỉ giữ public flags trong cache danh sách, kể cả record
cũ có private metadata. Reader codec đầy đủ vẫn dành cho phiên có grant/password vault.
Kiểm chứng mới: [PROTECTION_STATUS_FIXES.md](PROTECTION_STATUS_FIXES.md).

## Cache và bản nháp offline

ProtectedNoteVault dùng PBKDF2 HMAC-SHA256600000 vòng, salt ngẫu nhiên32 byte để dẫn xuất
khóa AES-256-GCM từ mật khẩu ghi chú. Nonce mới mỗi lần seal; AAD bind account UUID + note ID
+ version. Mật khẩu/derived key không persist. Envelope version/iterations/salt/nonce/mac/
ciphertext/dirty/saved_at nằm trong field protected_vaults của encrypted account snapshot
hiện có. Hai lớp phục vụ hai gate khác nhau: device key để mở account, mật khẩu note để mở
nội dung bảo vệ. Không có plaintext fallback hoặc operation chứa nội dung trong outbox thường.

Chỉ ghi chú đã mở và tải hợp lệ trên thiết bị/origin này mới mở offline được. Nhập mật khẩu
giải mã cache, sai mật khẩu/tamper giữ ciphertext và báo lỗi. Có thể đọc và chỉnh sửa local
theo role đã tải; UI nêu rõ chưa biết quyền hiện tại trên server. Kết nối lại che nội dung,
yêu cầu mật khẩu để xác nhận quyền/grant/protection version trên server trước khi gửi draft.
403/423/404 không được biến thành offline bypass để truy cập server.

Nếu nguồn bị xóa, thu hồi quyền hoặc đổi mật khẩu, draft cũ được giữ mã hóa và đánh dấu
recovery_only. Home **Bản nháp bảo vệ** chỉ hiển thị số bản, không lộ tiêu đề. Nhập mật khẩu
cũ → xem phần đã chỉnh sửa → **Tạo bản sao riêng** dưới ID mới. Đây là dữ liệu local đã tải
hợp lệ, không mở/sửa source hoặc cấp lại permission. Copy ID bền, mở lại không ghi đè copy
đã sửa. Nếu quên mật khẩu note cũ hoặc mất device key/storage, chưa có đường backup phục hồi.

Sau khi copy đã persist thành công, envelope ghi nhận recovered_copy_id chỉ nếu ciphertext
nguồn vẫn đúng bản vừa copy; input mới hơn không bị đánh dấu đã phục hồi. Lần server unlock
bằng mật khẩu mới có thể thay cache cũ khi bản sao riêng vẫn tồn tại trong local draft/owned
note. Bản chưa copy tiếp tục được giữ và chặn overwrite; source permission vẫn kiểm tra độc lập.

## Đồng bộ và vòng đời

Editor freeze base revision lúc mở. SSE thông báo không chứa nội dung nhạy cảm; reader
GET lại qua grant. Clean content cập nhật live nhưng base không tự đổi: **Chỉnh sửa phiên bản
mới** mở phiên edit mới. Dirty draft không bị ghi đè bởi realtime; 409 cho phép giữ bản riêng
hoặc xác nhận dùng bản server vừa refetch. Không có OT/CRDT hay tự merge từng ký tự.

Immutable operation được ghi vào protected envelope trước send. Lost ack/reopen replay cùng
op_id/payload; input mới đến trong lúc gửi giữ lại và chỉ nối revision từ ack của chính thao tác
đó. Hàng đợi storage merge field protected_vaults với snapshot thường, bind account ở thời điểm
enqueue, không ghi dữ liệu account A vào B. Back chờ local writes, thử flush và relock; lỗi local
write không báo durable thành công. Crash trước write đầu tiên/quota/eviction vẫn có thể mất input.

Unlock/relock được serialize theo note/session kể cả request unlock chưa về khi đóng route.
Epoch/account guard bỏ late response. Grant tối đa5 phút, poll15s bổ trợ SSE. Expiry, background,
logout, quyền/protection thay đổi hoặc lỗi refresh che nội dung. Nút **Khóa lại** hủy grant của
session này; các session khác giữ grant theo chính sách riêng. Mất mạng có thể khiến revoke RPC
không đến server nhưng không kéo dài TTL cố định.

Ngoại lệ khi chọn tệp đã được người dùng khởi động: content bị che khi OS chooser mở; giữ
lease có TTL cố định rồi GET revalidate role/protection trước trả giao diện. Không áp dụng ngoại
lệ này cho background thông thường. Widget test mô phỏng lifecycle; Web có actual filechooser.

## Kiểm chứng và giới hạn

Tests: test/protected_editing_test.dart; backend/tests/test_protected_editing.py;
integration_test/protected_editing_test.dart; các regression protection/recovery/preferences/
SSE hiện có. Crypto/file reopen dùng thư viện AES/PBKDF2/Sembast thật; race unit tests inject
workFactor50 chỉ trong test để chạy nhanh. Constructor production mặc định600000; có test thật
ở cấu hình mặc định. Backend unit tests dùng FastAPI/SQLite TestClient; actual HTTP roles kiểm
riêng bằng scripts/qa_protected_notes.py. Commands/results/screenshots/hashes trong
evidence/2026-10-05-protected-notes/INDEX.md và STATUS.md.

Android API36 debug Skia software dùng real API/SSE/platform keys/Sembast: unlock, peer update,
autosave, lỗi socket thật65530, offline password unlock, DB close/reopen, online revalidate/sync,
confirmed delete. Reopen cùng process, không OS force-kill/Wi-Fi toggle/physical device. Web local
release dùng Codex in-app browser + API thật; backend tạm dừng để kiểm tra cache/reload/reconnect.
Không suy build PASS thành public HTTPS, release functional hoặc toàn bộ rubric acceptance.

Server vẫn lưu và xử lý nội dung; đây không phải E2EE. Cache password gate không chống XSS,
extension độc hại/browser profile reader, screenshot/OS recents hay dữ liệu đã sao chép. Dữ liệu
đã tải trên thiết bị offline không thể bị thu hồi vật lý. Dart strings/GC không bảo đảm zeroization.
Nhiều tab, backup/transfer keys, accessibility thật, load/two-device stress chưa nghiệm thu.
Mốc chỉ đọc01/10 là historical evidence; đợt05/10 bổ sung lifecycle nêu trên.

Nguồn thuật toán: [cryptography](https://pub.dev/packages/cryptography),
[OWASP PBKDF2 guidance](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html).
600000 vòng là cấu hình đã chọn cho KDF, không phải tuyên bố đã audit bảo mật toàn hệ thống.
