# Hệ thống UI thống nhất —12/10/2026

Snapshot trước Editorial Atelier. UI hiện hành: [UI_ATELIER](UI_ATELIER.md).
Evidence UI system refresh vẫn giữ nguyên và chỉ chứng minh source của snapshot này.

UI đã được nâng cấp tại source: dashboard, auth, editor PC/phone, reader bảo vệ,
AI, workspace/planner/focus và các form/dialog/sheet dùng theme chung. Đây là thay đổi
trải nghiệm và trình bày; backend, controller, schema và quy tắc quyền không thay đổi.
Branch `codex/ui-system-refresh`, base `f3b17a3d33e5d432320e1d8620f87d7fc33b30d3`,
working changes chưa commit/push. Bản cập nhật hỗ trợ bằng AI theo yêu cầu người dùng.

## Áp dụng ui-ux-pro-max

Đọc skill người dùng chỉ định tại `C:/Users/LENOVO/.agents/skills/ui-ux-pro-max/SKILL.md`.
Tra design-system cho notes/productivity và glassmorphism, Flutter adaptive/text scaling,
UX reduced motion. Dùng kết quả để chọn hierarchy, tương phản, vùng thao tác và chuyển
động; không áp nguyên mẫu landing page hoặc font đề xuất vào ứng dụng Flutter đã có.
Giữ NotoSans bundled, định dạng trực tiếp như Word trên PC và các quy tắc bảo vệ ghi chú.

## Tokens và cấu trúc

`lib/ui/design_system.dart` là nguồn semantic tokens/component; `prism.dart` cung cấp
surface/rim/motion. Canvas light `#F1F3FA`, dark `#101625`; chữ `#202B44`/`#F0F3FC`.
Sidebar navy; vùng thương hiệu indigo → blue → teal. Nội dung đọc/nhập dùng nền rõ,
viền nhẹ và bóng ngắn. Các semantic surface phân biệt paper, panel, notice, dialog và
control. Input giữ nhãn nổi để label/hint/value không đè nhau; selected/disabled/error
giữ ý nghĩa của Material. Icon button có viền focus; scrollbar/chips cùng typography.

`PageIntro` thống nhất icon/tiêu đề/mô tả/action. Mô tả dùng toàn chiều rộng; action
xuống dòng khi thiếu chỗ hoặc chữ lớn. Icon trang trí bị bỏ khi chữ >=150%, heading vẫn
có semantics. Workspace chỉ thêm intro trên PC đủ cao. Banner dashboard điện thoại và
cửa sổ thấp bỏ câu giới thiệu trang trí, vẫn giữ số ghi chú, đồng bộ và thông báo tài khoản.
Sidebar tách Ghi chú/Công cụ. SectionHeading, notice và empty state dùng cùng hệ thống.

Editor PC giữ ribbon, mục lục, paper và inspector riêng; phone giữ một cột và toolbar
dưới. Tiêu đề/nội dung có nhãn ngoài rõ ràng, divider và counter riêng. Reader chỉ đọc
hiển thị đúng “Chỉ đọc”. Controllers, document key, frozen base revision và selection
không chuyển sở hữu sang component trình bày; các regression hiện có giữ nguyên.

## Chuyển động và hiệu năng

Giữ entrance/press/progress hiện có, tôn trọng `disableAnimations`. Trang trí lăng kính
là paint/gradient tĩnh; không thêm blur, font mạng, ticker, shader animation hay exit
retention cho dữ liệu riêng tư. Danh sách vẫn lazy, timer không pulse toàn root, search/
filter/scroll theo route được giữ. Chưa đo FPS/native runtime trên source mới; không
suy cải thiện FPS từ build hoặc từ việc giảm chi phí trang trí.

## Nghiệm thu và giới hạn

PASS: format109files0changes/analyze,262 Flutter/118 backend, Web release compile cho QA,
APK debug compile. Bốn regression mới kiểm tra banner phone, action trong pane hẹp,
intro320px/chữ200% hai theme; tests cũ không bị sửa để pass.

Chrome thật với dữ liệu tổng hợp trên DB/server riêng: five viewport320/390/768/844/1440,
hai theme, navigation nhóm màn hình chính, theme/resize giữ bản nháp, autosave/API xác
nhận tiêu đề chính xác và nội dung/pin/share giữ nguyên. Locked projection chỉ sáu
public fields; reader bỏ title/content khi khóa lại. Cache cuối40static assets, SHA256
khớp build. Cặp token chính có ratio>=5.03; không thay thế audit WCAG toàn giao diện.

Ảnh, logs, lệnh, source hashes và giới hạn tại
[bộ nghiệm thu](../evidence/2026-10-12-ui-system-refresh/INDEX.md).
Android UI/IME/FPS, NVDA/TalkBack, SMTP/Gemini thật, HTTPS/signing/release và CI hosted
chưa chạy trong đợt này. Gallery và các form xác thực chỉ kiểm tra UI/điều hướng ở những
trạng thái đã ghi; không coi ảnh rỗng là nghiệm thu nghiệp vụ/provider mới.
