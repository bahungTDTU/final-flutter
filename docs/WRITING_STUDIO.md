# Xưởng ghi chú và không gian viết tập trung

Đã triển khai 06/10/2026 theo yêu cầu bổ sung chức năng sáng tạo. Đề gốc tr.1 cho phép
chức năng thêm khi liên quan trực tiếp đến quản lý ghi chú và không thay yêu cầu bắt buộc.
Đây là phần mở rộng để trình bày giá trị sử dụng và lựa chọn thiết kế; không tự cộng điểm
hoặc thêm tiêu chí thứ 33 vào matrix. Các yêu cầu LLM, protection, release và video vẫn riêng.

## Cách sử dụng

1. Home → biểu tượng **Xưởng ghi chú**. Chọn Cornell, biên bản họp, kế hoạch dự án,
   nhật ký quyết định, tổng kết tuần hoặc vườn ý tưởng; xem trước rồi **Dùng mẫu này**.
   Chỉ lựa chọn cuối mới tạo một bản nháp có UUID riêng, lưu bền theo account trước mở editor.
   Quay lại gallery không tạo dữ liệu. Mẫu là văn bản biên soạn sẵn, có thể sửa, dùng offline.
   Sau chỉnh nội dung/tick checklist, autosave đưa bản nháp hợp lệ vào note/outbox như bình thường.
2. Editor → **Dàn ý & checklist**. Nội dung `#` đến `######` tạo dàn ý có thể bấm để
   đặt caret tới dòng gốc. `- [ ]`, `* [ ]`, `+ [ ]` tạo checkbox; `[x]`/`[X]` là hoàn thành.
   Tick thay đúng một ký tự trong nội dung, tự lưu và đồng bộ qua API note hiện có.
   Có tiến độ tổng, số từ/ký tự và thời gian đọc ước lượng. Bỏ qua dàn ý/checklist trong
   code fence backtick/tilde; không phải một Markdown renderer đầy đủ.
3. Editor → **Viết tập trung**. Thu gọn phần giới thiệu/metadata/actions, giữ editor và
   trạng thái lưu, bắt đầu/tạm dừng/đặt lại phiên 25 phút. Dùng Stopwatch đơn điệu; timer chỉ
   trong route, cập nhật thanh phiên mỗi giây. Rời app tạm dừng; không tự chạy lại khi trở về.
   Thoát mode tạm dừng, rời editor kết thúc. Hoàn tất hiển thị thông báo trong thanh phiên;
   không có báo thức, background service, thống kê lịch sử hay notification bên ngoài.

Trên màn hình nhỏ/focus, menu **Công cụ ghi chú** vẫn có theme/sync/AI/files/shares đúng quyền.
Gallery hai cột khi rộng, một cột cuộn khi hẹp hoặc chữ lớn; màu lấy từ Prism tokens,
Material InkWell/selected border/check icon, transition ngắn và tôn trọng reduced motion.

## Dữ liệu, quyền và độ bền

- Không thêm dependency, table, endpoint hoặc quyền mới. Nội dung template/checklist dùng
  cấu trúc note thường và luồng encrypted account draft/outbox hiện có; không ghi đè note khác.
- Callback chọn template chụp account trước mở gallery và kiểm tra lại trước/sau ghi bền.
  Thất bại ghi local báo rõ, không mở editor với claim đã lưu thành công.
- Checklist chỉ chỉnh khi owner/editor còn quyền, không bị khóa, không ở trạng thái cần mở
  phiên mới. Giữ base revision đã freeze và selection; peer update không tự rebase. API vẫn
  quyết định ACL/409. Snapshot text cũ không được phép sửa nhầm offset sau khi text đã đổi.
- Công cụ chỉ phân tích nội dung của editor thường đang mở, không quét account/các note khóa.
  Lock/revoke/account end gỡ editor và panel; không thêm derived data vào cache/log/AI context.
  ProtectedNoteScreen vẫn dùng luồng password/grant hiện có; bộ công cụ này chưa được nối vào
  protected reader, và không dùng protected plaintext để tạo thống kê bên ngoài route đó.
- Parser dùng UTF-16 offsets tương ứng TextSelection, regex biên dịch lại dùng chung, một lượt
  theo dòng. Debounce 180ms khi text đổi, không phân tích lại chỉ vì caret/selection đổi. Hiển thị
  tối đa 100 heading và 100 task; tổng task/progress vẫn tính toàn văn. Content cap 100000 giữ nguyên.
  Số từ là ước lượng nhóm ký tự phân tách whitespace có chữ/số, thời gian đọc theo 200 từ/phút;
  không phải phân đoạn ngôn ngữ hay LLM. Chưa benchmark FPS/thiết bị vật lý.

## Kiểm thử và trình bày

- 9 regression mới: Unicode/fence/stale offset/100 mục; template cancel/persist/account switch;
  checklist frozen base/caret/theme/resize; viewer/new revision; lifecycle/lock semantics;
  320px/chữ 200%/reduced motion; heading navigation; timer completion/reset/dispose.
- Full gate: **155 Flutter + 88 backend PASS**, format/analyze sạch. Web debug IAB: gallery,
  create/edit/check/focus start-pause/reload, server ID/content/revision và remote SSE lock che UI.
- Android API36 debug Skia software: gallery → draft → edit → check → HTTP revision2 cùng ID →
  focus start-pause → encrypted keys/Sembast close → mở lại khi endpoint thật không kết nối được.
  Đây là 1 integration scenario; teardown không được tính là thêm feature case.
- Direct HTTP: editor tick thành công; viewer403/stranger404; owner stale409; revoked editor404;
  locked owner423; locked list chỉ id/locked/revision/role. Không payload permission shortcut.
- Command/log/ảnh/source hashes: [evidence index](../evidence/2026-10-06-writing-studio/INDEX.md).
  Không nghiệm thu production, NVDA/TalkBack, OS kill, physical device hoặc release trong đợt này.

Demo đề xuất khoảng 90 giây: chọn biên bản họp → thêm tên/người phụ trách → mở dàn ý → tick
một việc và chỉ ra văn bản gốc/server vẫn cùng ID → bật tập trung → reload thấy việc đã tick →
khóa ở phiên khác để chứng minh panel che dữ liệu. Chỉ gắn timestamp sau khi video được quay thật.
Giải thích ba giá trị: giảm thời gian bắt đầu, biến ghi chú thành hành động, và giữ tập trung mà vẫn
bảo toàn lưu/offline/quyền. Không gọi phân tích văn bản xác định này là AI Summary/Q&A.


UI cập nhật06/10: footer compact ghi “Dùng mẫu”, có “Xem trước mẫu” mở dialog cuộn; desktop
giữ “Dùng mẫu này” và preview cạnh. Gallery đổi sang một cột khi cửa sổ thấp/chữ lớn, dùng6
Prism tones/bỏ backdrop lặp. Phạm vi QA/hiệu năng mới xem UI_COHESION_AND_PERFORMANCE.md;
evidence Studio phía trên giữ snapshot trước đợt này.
