# Kiểm tra và sửa UI/UX —20/10/2026

Đã fetch và cập nhật nhánh `codex/dashboard-motion-performance` từ `d59fdfd` tới
`6fba5a6`, trùng `origin/master`, trước khi chỉnh mã ứng dụng. Giữ nguyên các thay đổi
local, sao lưu ZIP có CRC/SHA-256 và giữ safety stash. Sáu file tài liệu giao nhau được
ghép cả hai phía; index trống, không có conflict. Fetch cuối vẫn ahead/behind 0/0.
Đây là source có thay đổi chưa commit, không phải cây sạch của commit GitHub.

## Lỗi xác nhận và cách sửa

1. **Chia sẻ tiếng Anh báo thành công nhưng giữ email vừa gửi.** Điều kiện UI so sánh
   thông báo Việt của state với câu đã dịch. `ShareSession.submit/retry` nay trả kết quả
   ACK kiểu bool, chỉ thành công trong cùng account/token/epoch còn hoạt động. UI xóa
   email sau ACK của thao tác mời, kể cả retry; lỗi/ACK thất lạc giữ email để thử lại.
   Retry giữ payload/op_id bất biến; thay quyền/thu hồi không xóa nội dung form mời.
2. **Lỗi tiêu đề bị cắt ở điện thoại chữ200%.** `errorMaxLines:3` làm mất một phần
   hướng dẫn. `DocumentWorkspace` dùng error widget có chiều cao tự nhiên, xuống dòng
   theo vùng còn lại bên cạnh bộ đếm. Dùng chung cho editor thường và bảo vệ; không
   thay controller, validation, draft, outbox hoặc frozen revision.

Probe trước sửa tái hiện hai FAIL này. Chỉnh thao tác cuộn trong harness trước khi
lấy baseline cuối; cảnh báo tap hụt của probe nháp không được tính là lỗi app.
Dropdown kế hoạch ở320px/chữ200% và bộ lọc khi màn ngang có bàn phím đều PASS;
không chỉnh hai phần đó. Giữ thiết kế Deskbook và các palette hiện có.

Skill `ui-ux-pro-max` được áp dụng qua query `form success feedback --domain ux`
(kết quả Success Feedback/Submit Feedback phù hợp) và `dropdown large text overflow
--stack flutter` (Support large fonts). Không đổi Master hoặc thêm dependency.

## Kiểm thử hiện tại

| Kiểm tra | Kết quả / phạm vi |
|---|---|
| `scripts/check.ps1` | PASS132file format0changes, analyze sạch,320Flutter,152backend |
| 4 widget test mới | PASS: mời thành công/thất bại/ACK thất lạc ởvi/en; payload retry giống nhau; lỗi tiêu đề không vượt max lines; dropdown kế hoạch và bộ lọc với keyboard |
| Web release local QA | PASS, API8064 riêng,40staticresources; không thay bản Web chạy thường |
| Browser UI thật | PASS1280×960,360×800,844×390; dashboard/editor/chia sẻ, sáng/tối; query giữ qua resize/quay lại |
| HTTP sau thao tác UI | PASS8notes, một viewer được mời, title/body giữ nguyên, theme persist; gửi form rỗng chỉ validation |
| Privacy thẻ khóa | Dashboard thực chỉ hiện Locked note/helper/icon; full privacy regressions trong suite PASS |
| APK debug | Build PASS; chưa cài hoặc chạy Android lượt này |
| Evidence cũ | Hash toàn bộ payload có trước lượt này giữ nguyên |
| Git | Không commit/push/merge/deploy; README/Readme byte-identical |

Browser không ghi nhận console error trong các luồng đã thử. Test chữ200% là widget
runtime, không gọi là đã kiểm tra browser/native ở200%. Không đo FPS/GPU, không chạy
IME/screen-reader thủ công, SMTP/Gemini thật, signing/release hoặc CI mới.
Các nghiệm thu native đã có trên GitHub giữ nguyên phạm vi lịch sử riêng.

[Bằng chứng mới](../evidence/2026-10-20-ui-ux-audit/INDEX.md).
