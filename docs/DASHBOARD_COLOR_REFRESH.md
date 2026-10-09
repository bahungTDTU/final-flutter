# Dashboard màu sắc —09/10/2026

Theo phản hồi ảnh Home quá trắng, dashboard dùng sidebar indigo/navy, header tím-xanh,
canvas lavender-blue, notice amber và nền pastel phủ toàn thẻ. Giữ hệ Prism/NotoSans,
thứ tự navigation, copy, query/filter/scroll, dữ liệu và core controller hiện có.

`DashboardColors` ở design_system.dart cung cấp các màu chrome. dashboard.dart dựng nền,
sidebar và header; Theme chỉ giới hạn trong sidebar/notice. Material trong sidebar bảo đảm
ink/selected tile và chữ Brand đọc rõ trên gradient. Header CTA dùng icon ở màn hẹp/chữ lớn.
`SurfacePanel.backgroundColors` và `PrismCard.rich` là opt-in cho dashboard; component ở các
màn khác giữ behavior cũ. Thẻ khóa có tone=null, không tint/facet theo note; public pin/shared
flags vẫn theo chính sách07/10, không hiện nội dung/nhãn/identity/counts trước unlock.

Trang trí là gradient và polygon CustomPainter tĩnh, có shouldRepaint theo palette/variant,
IgnorePointer/ExcludeSemantics và RepaintBoundary cho nền. Không blur/backdrop filter/ticker
liên tục hoặc bitmap screenshot thay UI. Hover/theme/reduced-motion và lazy slivers vẫn dùng
hệ hiện có. Đợt này không đo FPS/frame time/native latency.

Concept ImageGen dựng từ ảnh người dùng, preview/design spec; không phải ảnh app chạy.
Các ảnh after là Chrome thật với backend/SQLite/tài khoản disposable riêng. Native concept
1536×1024, reference người dùng1440×960; kiểm tra cả hai và mobile390×844,1280×900,
tablet768×1024/landscape844×390. Copy giữ nguyên, count2/7 và chiều rộng sidebar248 giữ từ
app gốc; màu của chip từ ID opaque nên khác nhau giữa các fixture.

Regression cũ nay cuộn tới chip/thẻ lazy trước thao tác, không bỏ assertions private content,
owner/viewer menu, frozen revision, editor text/selection, AND filter và encrypted recovery.
198 Flutter tests PASS, analyzer sạch, format88 files0changes. Direct HTTP4roles PASS.
Web release compile/offline40 resources PASS; không deploy. Backend source không đổi;
94 backend PASS ở snapshot Home trước đó, không chạy lại để tạo claim mới. Không có native
UI/APK/release signing/physical/LLM/email Internet acceptance trong đợt màu sắc.

Ledger thiết kế, checks, ảnh, lệnh và hashes: [evidence](../evidence/2026-10-09-dashboard-color/INDEX.md).
Branch codex/ui-ux-performance, baseef2ece0 + working changes; chưa commit/push/merge.
