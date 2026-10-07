# Phân tách editor và sửa bố cục —06–07/10/2026

Người dùng phản hồi chữ bị đè và khó phân biệt tiêu đề/nội dung sau khi xem bộ ảnh UI.
Đối chiếu đề gốc tr.5–6/13, UI_UX_DESIGN/QA và source hiện tại trước sửa.

- NoteTextField dùng NoteSection chung: nhãn/biểu tượng cố định ngoài ô nhập, nền/viền/focus
  rõ, bộ đếm riêng. Không còn floating label cùng vùng vẽ với tiêu đề lớn/nội dung nhiều dòng.
  Title24px compact/28px desktop, line-height1.35; nội dung giữ preference14–24px/1.6.
- Editor trình bày trạng thái → tiêu đề → nội dung → Sắp xếp → dàn ý/checklist. ReadingCanvas
  có lựa chọn bỏ mặt giấy ngoài để các khối có nền kín riêng và khoảng cách16px.
  App bar chuyển menu khi chữ lớn, tránh ép tiêu đề cạnh nhiều nút. Trạng thái dùng icon+
  Expanded text để không tách icon sang một hàng không có nội dung.
- Protected reader/editor có cùng khung tiêu đề/nội dung; thông tin ghi chú, công cụ và
  bảo vệ/quản lý có tiêu đề nhóm. Nhãn và nội dung chỉ được render sau unlock như trước.
- ExpansionTile checklist đặt tên và hướng dẫn trong cùng Column với khoảng cách rõ,
  tránh hai vùng title/subtitle tranh không gian khi xuống nhiều dòng. Regression kiểm tra
  vùng vẽ của cả hai nằm trong tile, không chỉ kiểm tra RenderFlex exception.

Route tiếp tục sở hữu TextEditingController/FocusNode/ScrollController. Giữ key, note ID,
frozen base revision, caret/selection, local draft, immutable outbox và permission gates.
Không thay API/schema/crypto/preference merge và không thêm dependency/assets/template.

## Nghiệm thu

167 Flutter/88 backend PASS06/10; analyzer sạch. Sau hoàn thiện driver và bổ sung assertion
bounds07/10:6 geometry/input regression PASS, format/analyzer sạch. NotoSans Regular/Bold
thật ở320×568,390×844,844×390,1280×900, text200%, cả light/dark; field/label/counter
không giao nhau, counter và hướng dẫn nằm trong section/tile. Test nhập qua keyboard inset,
đổi theme/resize vẫn giữ controller/selection và pending base7. Đây là widget scope.

Actual IAB Flutter Web debug7364/API8015: edit note thật→same-ID API revision2, theme→mobile
giữ text/range287–288, nhóm nhãn/checklist, protected edit→exact API content revision4,
reader/edit/relock và expiry che nội dung. Android API36 debug Skia software chạy3 workflows
có sẵn bằng ui_cohesion_test + teardown, PASS46s;8 PNG mới. HTTP4roles ACL PASS riêng.
Logs/ảnh/base commit + hashes ở evidence/2026-10-06-editor-sections/INDEX.md.

Driver cho phép đặt UI_SCREENSHOT_DIR; mặc định cũ vẫn là output/native-ui-cohesion.
Bản nghiệm thu này dùng output/native-editor-sections rồi sao chép ảnh nguyên byte vào evidence.

## Giới hạn

Không tuyên bố hết mọi lỗi UI trên mọi thiết bị. Font200%/keyboard inset là widget kiểm tra,
không phải browser/OS accessibility scaling toàn bộ. Native là emulator debug, không physical/
production renderer/release acceptance. Chưa NVDA/TalkBack/full keyboard/history/FPS.
API/email/AI fixture ở loopback và database riêng; lượt này không gọi Gemini/Internet mail.
Release/HTTPS/signing vẫn được hoãn; không commit/push trong đợt UI này.
