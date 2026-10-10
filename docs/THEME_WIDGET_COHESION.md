# Đồng bộ widget với theme dashboard —09/10/2026

Working tree trên `codex/ui-ux-performance`, base `717f0ab6b04b6f63ad7f921a82b91cd2f4b41319`.
Đợt này đồng bộ component theo palette dashboard đã có; không tạo layout/feature mới hoặc
thay controller, quyền truy cập, persistence, frozen editor revision hay outbox.

| Nhóm | Theme được dùng chung |
|---|---|
| App bar Home mobile, editor, protected reader, AI, token/reset, studio, preview | `noteAppBar` trả về AppBar framework, nền `BrandGradient` tím-xanh, chữ/icon sáng, giữ callbacks và keys |
| Đăng nhập/đăng ký | `BrandPanel` theo gradient dashboard; Theme + DefaultTextStyle giữ tương phản đoạn mô tả; form trên panel lavender |
| Dialog profile/avatar/password/shares/files/AI/protection/confirm/input | DialogTheme lavender, border/radius chung; field trắng hoặc nền navy tối, nút và feedback từ ColorScheme |
| Sheet hồ sơ/nhãn/bộ lọc | BottomSheetTheme đồng bộ nền/handle/radius; section, divider, controls và account row theo semantic surfaces |
| List/grid controls, chips, navigation bar/rail | Primary indigo/secondary blue, selected state rõ; dùng state mapping có value equality |
| Vùng viết thường và bảo vệ | NoteSection gradient nhẹ; title/content giữ nhãn bên ngoài, counter riêng, field nền đọc được |
| Menu, tooltip, snackbar, progress, cards và empty/status | Theme chung, semantic error vẫn riêng; NotoSans bundled, không thêm package/font mạng |

Các cấp `surfaceContainerLowest/Low/Container/High/Highest` được định nghĩa cho cả light/dark.
Nền app cùng lavender/navy của dashboard, primary lấy từ header. Bề mặt đọc giữ độ sáng và
không dùng gradient đậm phía sau nội dung dài. Không thêm blur, shader hoặc ticker lặp.

Một regression trong lượt đầu phát hiện state resolver tạo callback mới khiến hai theme cùng
giá trị bị xem là khác, khởi động AnimatedTheme thừa trong reduced-motion test. Đã thay bằng
`WidgetStateProperty.fromMap`; regression giữ nguyên và đạt lại. QA ảnh cũng phát hiện đoạn
mô tả auth kế thừa màu từ Material ngoài Theme; sửa bằng DefaultTextStyle trắng trong BrandPanel.

Gate local: format90files0changes/analyze sạch,198 Flutter tests và94 backend tests PASS.
Sau sửa tương phản auth, chạy lại toàn bộ198 Flutter tests, analyze và build Web/APK debug.
Backend không đổi;94 tests đã chạy trong chính đợt này, có1 upstream deprecation warning.
Direct HTTP owner/editor/viewer/stranger PASS qua backend/database QA riêng.

Chrome154.0.8037.99 headless:12 luồng,4viewport,24 PNG,0console errors/warnings.
Autosave được GET xác nhận; shares lưu recipient viewer và tệp được server lưu thật.
Unlock→reader→edit→relock che lại metadata. Editor giữ nội dung qua theme/resize;
caret không được đo trong lượt browser này. Dialog password chỉ thử mở/cancel.
QA trình duyệt và ảnh: xem [evidence](../evidence/2026-10-09-theme-cohesion/INDEX.md).
Browser plugin absent; dùng Playwright bundled/Chrome và semantic locators + pointer thật.
AI của QA là `fixture-not-an-llm` tường minh; không đọc key, gọi Google hay claim Gemini thật.
Không dùng snapshot benchmark cũ làm FPS cho theme mới. Native runtime/physical/screen reader,
FPS mới, release/signing/HTTPS/submission chưa chạy trong đợt này. Chưa commit/push thêm bản theme.
