# Dashboard: UI, animation và hiệu năng —14/10/2026

IMPLEMENTED trên `codex/dashboard-motion-performance`, base `4a196ef`.
Chưa commit/push. Đây là cải thiện ngoài rubric, không đóng các gate release/provider.

Theo skill ui-ux-pro-max tại đường dẫn người dùng chỉ định, giữ chủ đề Deskbook/Atelier
và bố cục PC/phone hiện có. Thẻ có bóng nhẹ hơn, phản hồi nhấn bằng sắc nền và chuyển
động hữu hạn; vùng bấm không di chuyển theo hình ảnh. Viền focus2dp nằm trên nền thẻ,
hiện rõ khi Tab và kích hoạt đúng bằng Enter ở hai theme trong widget tests. Không thêm hiệu ứng chạy liên tục.

Ba lỗi được tái hiện trên snapshot base và sửa:

| Tình huống | Trước | Sau |
|---|---|---|
| Con trỏ đứng cách mép dưới thẻ1.5dp | Hover ra/vào lặp lại, ticker còn chạy sau2s | Animation kết thúc, vùng tương tác cố định |
| Xóa toàn bộ trong lúc truy vấn mới còn chờ debounce | Truy vấn cũ quay lại sau khi xóa | Hủy timer trước khi xóa |
| 20 thông báo chỉ đổi kết nối | Dashboard dựng lại20 lần, preview đọc lại20 lần | Dashboard/preview không dựng/đọc lại; nút trạng thái vẫn cập nhật |

PASS: format118files0changes, analyze, **287 Flutter/143 backend**. Có8 regression mới:
ba lỗi trên, nhấn sát mép, thay theme/cỡ chữ rồi đổi nội dung/khóa, cập nhật tên/nhãn/
pending/xóa, Tab/Enter hai theme và thư viện500 rich notes. Các regression về editor revision, draft, permission,
reduced motion, privacy và responsive hiện có cũng nằm trong full suite.

Probe500 rich notes, 30 đoạn Delta/ghi chú, chỉ6 preview được dựng ban đầu trong viewport.
Cùng20 thông báo kết nối: số lần chuyển nội dung thành preview thêm giảm **120→0**.
Wall time một mẫu widget harness là688695→77334µs; không phải frame time, không dùng
để tuyên bố FPS hay phần trăm cải thiện ngoài thiết bị/harness này.

PASS Web thực: release build riêng/IAB Chromium/API8059, tài khoản tổng hợp500notes/
30labels; desktop1280×1000 sáng/tối, phone375×812 sáng/tối và rail844×390 tối.
Menu thẻ mở đúng, tìm kiếm rỗng/clear-all phục hồi500notes, lưới/danh sách/cuộn hoạt động;
query được giữ khi chuyển PC→phone. Preview nhận cập nhật server qua realtime; khi
khóa từ xa, title/body sentinel bị loại khỏi visual và cây ngữ nghĩa. Console error0
trong phạm vi phiên kiểm tra; không claim screen reader thật hoặc browser history.

PASS API thực với owner/editor/viewer/stranger: private attachments, write403, stranger404,
anonymous401, locked423, replay và download hash/no-store. Backend/data schema không đổi.
QA dùng DB riêng trong tmp, mail/LLM tắt; không đọc dữ liệu cá nhân từ backend/state.
PASS Android debug compile (`app-debug.apk`, API emulator10.0.2.2:8000); đây là build,
không phải chạy ứng dụng trên Android. Inventory ADB không có thiết bị.

Web build có thông báo font CupertinoIcons từ toolchain; build thành công và không
quan sát icon lỗi trong các màn đã kiểm tra. Pytest có1 cảnh báo deprecation Starlette;
Android debug build có cảnh báo phiên bản SDK XML, build vẫn thành công.

NOT RUN cho source lượt này: FPS/GPU/profile thiết bị, Android runtime/IME, screen reader,
provider thật, CI mới, signing/release/deploy; full browser focus order chưa nghiệm thu.
Không có Android device trong lần kiểm tra.
Bản build local giữ API8000; bản QA/API8059 không dùng làm bản chạy thường.

[Ảnh, log và nguồn đã hash](../evidence/2026-10-14-dashboard-polish/INDEX.md).
Thiết kế tuân thủ việc giới hạn rebuild/paint scope trong
[Flutter performance guidance](https://docs.flutter.dev/perf/best-practices);
đo frame đáng tin cậy cần profile trên thiết bị theo
[Flutter UI performance](https://docs.flutter.dev/perf/ui-performance).
