# Nghiệm thu Web và Android local ngày 18/11/2026

Kiểm tra từ `master` tại `8782a333d099ecc532161c1ece709ec420ba46ea`
trên nhánh `codex/web-android-runtime-acceptance`. Flutter 3.47.9, Chrome
157 và Android 16/API 36 (AVD QA riêng). Web release local dùng
`http://127.0.0.1:7390`, backend FastAPI dùng cổng 8090 và SQLite riêng.
Android debug build từ `lib/main.dart` dùng cùng API qua `10.0.2.2:8090`.

## Lỗi đã sửa

- Đường dẫn tệp khóa Gemini không còn tồn tại từng làm FastAPI thoát khi
  khởi động. Backend hiện cảnh báo, tiếp tục phục vụ tính năng ghi chú và báo
  AI `not_configured`. Sau khi sửa đường dẫn cần khởi động lại backend.
- Script chạy Web có thể dùng bundle đã chứa API URL cũ. Thêm `-ApiUrl`
  để build lại trước khi phục vụ, `-Rebuild` để chủ động build lại và
  `-Port` cho backend local. Lần kiểm tra cuối dùng Chrome trên origin mới
  để không vướng service worker đã cài ở origin trước.

## Đối chiếu tiêu chí

| ID | Bằng chứng runtime local | Phạm vi còn lại |
|---|---|---|
| 1, 3 | Chrome đăng ký HTTP 201, tự vào trang ghi chú. Android đăng nhập bằng tài khoản vừa tạo trên Web và thấy ghi chú đồng bộ. | Bản phát hành và demo cuối. |
| 11, 12, 14, 31 | Chrome nhập tiếng Việt, tự lưu HTTP 200. Chrome sửa offline, reload thấy nội dung mới và một thay đổi chờ, sau đó bấm Thử lại để sync. Android tắt Wi-Fi/data, sửa tiêu đề, force-stop/mở lại và cuộn tới thẻ có thay đổi đang chờ. Kết nối lại đưa cùng UUID lên revision 3, vẫn một bản ghi. | Offline create và conflict trên hai bản phát hành. |
| 15, 16 | Chrome mở picker và tải TXT. SQLite lưu đúng byte. Android hiển thị tệp trên cùng ghi chú, mở DocumentsUI và hủy, tệp cũ vẫn giữ, nút tải lên vẫn tắt. | Video/ảnh, chọn và lưu tệp Android toàn luồng, các trường hợp từ chối quyền trên bản cuối. |
| 23–26 | HTTP thật kiểm tra owner/viewer/editor/stranger, grant/lock, sửa có revision, quyền tệp, revoke và đổi mật khẩu. Chrome đang mở nhận tiêu đề mới từ Android sau sync. | Hai client UI xử lý đổi quyền trong bản nộp. |
| 29, 30 | Chrome desktop và APK mở đúng giao diện Android tầm 393×698 dp. Format/analyze PASS, 164 backend tests PASS. | Kiểm tra interaction/accessibility rộng hơn. |
| 2, 4, 27, 28 | Backend báo SMTP và AI chưa cấu hình. | SMTP/inbox thật và LLM thật vẫn chưa nghiệm thu. |
| 32 | Web release local 41 tài nguyên offline và Android debug build/cài/mở PASS. | Web/API HTTPS công khai và APK release ký bằng khóa nhóm. |

## Giới hạn và kết quả âm

- Bộ năm integration Android có lần mất VM service ngay sau cài. Khi chạy
  `--no-dds` ở 320×640, năm ca dừng ở bước tìm note/control. Sau khi đổi
  kích thước, lỗi kết nối VM service vẫn xuất hiện. Chưa xác định nguyên nhân
  của các assertion ở viewport nhỏ. Kết quả APK trực tiếp ở trên có phạm
  vi riêng, dùng thao tác ADB và hệ thống Android, chưa kiểm tra Telex/VNI.
- Kiểm tra Chrome đầu tiên trên 7388 gọi API cũ ở 8000. Kiểm tra cuối trên
  7390 xác nhận request thực tới 8090. Lỗi ngắt mạng xuất hiện khi chủ động
  đặt Chrome offline. Các lần chờ locator ban đầu sai tên đã được đối
  chiếu lại với snapshot và request thật.
- Còn thiếu Rubric.xlsx của giảng viên, video của nhóm, thông tin chấm và
  gói nộp được kiểm tra cùng các artifact phát hành.

Chi tiết lệnh, đầu ra và SHA256 ở [bằng chứng](../evidence/2026-11-18-runtime/INDEX.md).
