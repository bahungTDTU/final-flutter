# Khóa ghi chú và phiên đọc online

Chọn menu **Thao tác ghi chú → Bật khóa ghi chú** trên ghi chú của mình đã đồng bộ,
nhập mật khẩu riêng 10–128 ký tự và nhập lại. Hoàn tất bản nháp/outbox trước khi đổi khóa.
Backend kiểm tra owner; UI không cấp quyền bằng payload. Bật khóa che ngay cache/list/search,
kể cả khi lần refresh sau mutation thất bại. Local edit đến trong lúc request chạy vẫn đi qua
encrypted recovery đã có; không gửi lại operation của nguồn khóa.

Chạm thẻ khóa và nhập mật khẩu để đọc. Sai mật khẩu giữ ô nhập để sửa; backend cooldown
5 lần sai/60 giây. Nội dung chỉ nằm trong ProtectedReader của route, không đưa vào ordinary
notes/drafts/outbox/snapshot. Phiên online tối đa 5 phút, kiểm tra quyền mỗi 15 giây hoặc bằng
nút **Kiểm tra quyền và cập nhật**; đây là polling, chưa realtime. Lỗi đọc/network/permission,
logout, background, expiry, đóng route hoặc **Khóa lại** đều che nội dung. Backend kiểm tra quyền
trên mỗi request; dữ liệu đang hiển thị có thể chờ lần polling tiếp theo để thấy revoke từ xa.

Owner đang đọc có thể **Đổi mật khẩu ghi chú** hoặc **Tắt khóa ghi chú**, đều phải nhập mật khẩu
ghi chú hiện tại. Đổi/tắt/bật tăng revision/protection version và hủy mọi grant cũ. Tắt khóa
cho phép người có quyền đọc xem nội dung bình thường. Viewer/editor không có owner controls;
backend vẫn chặn nếu tự gọi endpoint. Không thay frozen base revision của editor thường.

POST `/notes/{id}/lock` chỉ hủy grant của session gọi API. Các phiên khác không bị khóa lại bởi
thao tác này. Client serialize unlock/relock theo note+session qua controller, kể cả đóng/mở lại
route khi request cũ chưa xong; epoch guard loại phản hồi muộn. Nội dung được che trước revoke RPC;
khi offline, revoke có thể không tới server và grant vẫn có TTL cố định. Protection response chỉ
ok/revision/locked; GET list vẫn chỉ id/revision/locked/role cho note khóa, kể cả session có grant.

## Phạm vi và kiểm chứng

Phiên này **chỉ đọc**, không sửa protected note, không unlock offline bằng mật khẩu ghi chú,
không lưu protected content để mở lại sau restart. Account vault/recovery AES-GCM là cơ chế riêng,
không phải mã hóa end-to-end hoặc backup khóa. Web master-key/provider limitations giữ nguyên.
Che nội dung trong app không phải chống screenshot/OS recents/XSS hay thu hồi dữ liệu đã sao chép.

Tests ở test/note_protection_test.dart và backend/tests/test_security.py: permission barriers,
mutation/refresh failure, cache isolation, pending unlock/revoke ordering qua hai readers,
expiry + late GET, wrong/retry/logout, lifecycle và dialog error giữ input. HTTP/key adapters
ở unit tests là doubles; API tests dùng SQLite/FastAPI thật trong TestClient.
Native integration_test/note_protection_test.dart dùng backend thật + device key/Sembast + UI;
lifecycle notification có mô phỏng, không thay nghiệm thu physical-device/OS kill.
Lệnh/kết quả thực xem STATUS.md và evidence/2026-10-01-note-protection.
Chưa nghiệm thu toàn bộ tiêu chí 23/24/32, public HTTPS/signing/video.
