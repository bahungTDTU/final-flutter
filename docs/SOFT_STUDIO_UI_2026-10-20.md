# Soft Studio: nâng cấp UI/UX — 20/10/2026

Đã fetch và cập nhật base 87f9e49 (PR #12 đã merge) trước khi sửa; làm việc trên nhánh
`codex/soft-studio-refresh`. Báo cáo ghi nhận snapshot local trước commit/push; trạng thái PR/CI được theo dõi trên GitHub. Dùng skill
ui-ux-pro-max và [đặc tả đã chọn](../design-system/notetogether-deskbook/pages/soft-studio.md).
Master, kiến trúc, dependency, API/storage/ACL và source backend giữ nguyên.

## Thay đổi

- Nền chuyển sắc nhẹ, bề mặt có chiều sâu, bo góc theo cấp 14/20/24/28 dp và chữ có
  phân cấp rõ. Sáu palette sáng/tối dùng semantic tokens; cache 12 ThemeData giữ nguyên.
- Dashboard có khung tiêu đề rõ, hình sổ vector tĩnh, điều hướng chọn nhẹ hơn và
  ngăn công cụ được phân vùng. CTA tạo ghi chú lấy màu primary/onPrimary của palette.
- Thẻ ghi chú và giấy soạn thảo mềm hơn; inspector, nút, form và dialog đồng bộ.
  PC giữ ribbon/trang viết/drawer; điện thoại giữ vùng viết và toolbar riêng.
- Nhãn nhanh trên điện thoại thành một hàng cuộn, tối đa 6 widget; nút lọc 152 dp luôn
  thấy và không đổi vị trí khi số chọn thay đổi. Chip vừa chọn giữ thứ tự catalog.
  Chữ lớn >=150% dùng Wrap. Bộ lọc đầy đủ và nút bỏ lọc vẫn hoạt động.
- Cửa sổ ngang thấp gom title/count/sync/create thành hàng gọn. Tablet đủ chỗ đặt
  CTA cạnh heading; pane hẹp hoặc chữ lớn đặt CTA xuống dưới, tránh tràn chữ.

Hiệu ứng hover/press/route hiện có giữ vùng hit ổn định và reduced motion. Nền/artwork
là tĩnh, không có blur hoặc animation lặp. Lazy lists, preview có giới hạn và sync
notifier riêng vẫn hoạt động; workload probes không được gọi là bằng chứng FPS.

## Kiểm tra

| Phần | Kết quả |
|---|---|
| Source Flutter cuối | PASS: 134 files, format 0 changes, analyze sạch, 324 tests |
| Backend | PASS: 152 tests từ full check; mã backend không thay đổi sau lần chạy đó |
| Test mới | 4: contrast 12 themes, heading 200%, vi/en, nhãn cuối/cuộn/filter, header landscape/tablet |
| Web local release | QA API 8065 và bản chạy thường API 8000 đều build PASS, 40 static assets mỗi bản |
| APK debug | Build PASS; không cài/chạy Android lượt này |
| Browser thật | Dashboard/editor/preferences/filter, PC/phone/tablet/landscape, sáng/tối và vi/en |
| Data qua HTTP | 8 notes / 5 labels / 2 pins; title/body/revision của note đang mở không đổi; palette/locale/theme ACK |
| Privacy và state | Suite giữ query/filter/scroll, editor document/selection/base revision, locked redaction, account isolation |

Đợt final dùng `--no-pub` sau khi pub get bị treo ở Downloading packages; lockfile và
package config đã có sẵn, không nâng cấp dependency. Native IME/runtime, screen-reader
thủ công, FPS/GPU, SMTP/Gemini thật, signed release/deploy và CI mới NOT RUN.
Chữ 200% và reduced motion được kiểm bằng widget runtime; không nhận là browser/native 200%.

[Bằng chứng và ảnh](../evidence/2026-10-20-soft-studio/INDEX.md). Build Web dùng thường
đã cập nhật trong build/web với API 8000; ứng dụng/DB thật không được khởi động hay thay.

Ảnh phone từ viewport yêu cầu 375×812 được IAB chụp 375×811; ảnh giữ nguyên,
không resize. Các kích thước capture khác khớp viewport được yêu cầu.
