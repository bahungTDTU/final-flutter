# Tập trung, checklist và UX — 10/10/2026

Bổ sung theo yêu cầu người dùng sau workspace ban đầu, ngoài 32 tiêu chí bắt buộc.
Không gian cá nhân vẫn local encrypted theo account; ghi chú/checklist vẫn đi qua
server sync/ACL/revision hiện có. Không thêm quyền hoặc snapshot nội dung protected.

## Chức năng mới

- Pomodoro: phiên 5/15/25/50 phút, nghỉ 5 phút, tạm dừng/tiếp tục, xác nhận kết thúc sớm.
- Mục tiêu 1–12 phiên/ngày, số phút hoàn thành và tổng hợp 7 ngày; lưu tối đa 100 phiên.
- Bảng công việc: tìm theo task/tên note, nguồn của bạn/được chia sẻ, tất cả trạng thái
  và tiến độ hoàn thành trong tập kết quả. Giữ query/scope khi chuyển phần; rows lazy.

Timer lưu deadline UTC epoch và phần còn lại khi pause, không lưu mỗi giây. Reload/
reopen/đổi màn hình không khởi động lại phiên. Phiên hết giờ ghi nhận khi panel được
mở lại; tính ngày từ deadline theo timezone thiết bị, không từ ngày reopen. Chỉ phiên
focus hết giờ được tính, không tính nghỉ hoặc reset. Completion kiểm tra session ID,
idempotent và chỉ công bố RAM sau durable write. Callback phiên cũ không kết thúc
phiên mới; lỗi disk cho retry, account switch không publish vào account khác.

Timer dùng đồng hồ hệ thống, không phải đo thời gian làm việc thực tế. Không có alarm/
notification OS khi đóng app; không tự chạy nền Android. Timer/goal/history chưa cloud
sync. Không ghi note title/content/reference vào lịch sử tập trung.

## Sửa UX

Form bộ sưu tập/mẫu giữ mở và giữ input khi validation/storage lỗi; hiện lỗi inline,
khóa thao tác khi đang lưu và đóng sau durable success. Tạo/sửa bộ sưu tập chọn đúng
bộ sưu tập vừa lưu. Xóa mẫu/bộ sưu tập có xác nhận; không xóa note bên trong.

PC giữ chips navigation; dưới 600px hoặc text scale từ 150% dùng dropdown có label.
Mỗi phần giữ scroll riêng. Các form cuộn với keyboard, timer co vừa vùng hiển thị;
menu mục tiêu dùng Expanded để sửa overflow 103px quan sát trong regression 320px/200%.
Palette/draft/editor và policy pin/shared/locked giữ nguyên.

Ticker chỉ rebuild panel tập trung, không notify controller hoặc parse checklist mỗi
second. Task cache bounded 200 notes/100 items, purge locked/revoked kể cả tab khác;
rows tiếp tục lazy. Các từ khóa người dùng tự nhập không phải nội dung note từ cache.

## Kiểm thử

Gate source: 242 Flutter / 109 backend PASS, analyzer sạch; 8 regression mới kiểm tra
reopen/pause, ngày deadline, completion retry/idempotency, stale callback, durable
concurrency/account switch, migration validation, form failure/retry/delete confirmation,
task search/scope/privacy, mobile dropdown/keyboard/text200% và ticker isolation.

Kết quả Chrome, build và ảnh được ghi ở
[evidence](../evidence/2026-10-10-workspace-polish/INDEX.md). Không suy ra native UI,
physical FPS hoặc screen reader từ widget/browser/compile. Release vẫn để cuối.

Chrome + FastAPI thật trên loopback: pause 04:58 → reload vẫn 04:58, goal 6 giữ nguyên,
resume rồi pause 04:56; checklist lưu GET revision 2, query/source/progress đúng. Form
validation giữ input, save lại thành công, hủy xóa giữ mẫu và collection mới chọn ngay.
Ảnh light/dark ở 1440×960, 390×844, 844×390 và 768×1024. Phiên Chrome cuối: 0 errors/
warnings. Web release và APK debug compile PASS; chưa chạy Android UI/IME/FPS mới.

## Cache khi nâng cấp Web

QA phát hiện cache release mới chứa main.dart.js cũ từ browser HTTP cache. Worker install
dùng Request(cache: reload), fetch tôn trọng reload/no-store; fingerprint bao gồm template
worker và bootstrap đăng ký updateViaCache: none. Giữ allowlist static, không cache API/
session/private files. Trong phiên upgrade không xóa cache thủ công, mã QA đã chuyển đúng
API 8034. Build cuối: main.dart.js/bootstrap trong cache khớp SHA256 build, 40 static
resources, không còn mã API 8000. Sau QA dựng lại Web API mặc định 8000.
