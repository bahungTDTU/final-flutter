# Bảng màu giao diện —16/10/2026

IMPLEMENTED:6 tổ hợp màu, mỗi tổ hợp có bản sáng/tối (12theme).
Mở Hồ sơ và tùy chỉnh → Giao diện → Bảng màu giao diện.
Trong editor PC dùng biểu tượng palette; điện thoại mở Công cụ ghi chú → Bảng màu giao diện.
Chọn mẫu để áp dụng và lưu trên thiết bị, rồi đồng bộ theo tài khoản khi kết nối.
Công tắc sáng/tối độc lập, đặt trước gallery trong settings; gallery preview dùng brightness hiện tại.

| ID ổn định | Tên | Tổ hợp |
|---|---|---|
| atelier | Atelier (mặc định) | Giấy kem / mực trầm / vàng đồng |
| ocean | Đại dương | Lam / ngọc biển / san hô |
| iris | Diên vĩ | Tím mực / thạch nam / xanh sương |
| rose | Thạch anh hồng | Hồng mận / tím khói / vàng cát |
| amber | Hổ phách | Nâu mật / ô liu / đất nung |
| forest | Rừng ngọc | Lục bảo / lá non / đồng đỏ |

## Thiết kế và triển khai

Dùng skill ui-ux-pro-max theo yêu cầu. Query design-system đầu trả pattern marketing,
không áp bố cục đó vào app ghi chú; retry domain color khớp Notes & Writing App và Productivity Tool.
Áp dụng semantic tokens, reading canvas opaque, palette previews có nhãn/check và native buttons;
đo tương phản thực tế thay vì chép màu dataset. Giữ bố cục Deskbook, font NotoSans bundled,
48dp targets, focus và reduced motion. [Override](../design-system/notetogether-deskbook/pages/color-palettes.md).

`domain/app_palette.dart` giữ IDs; `ui/palette_tokens.dart` giữ primitive/ColorScheme/chrome tokens;
`noteTheme` trong design_system.dart cache theo (brightness,palette), tối đa12ThemeData.
Gallery tái sử dụng cache, không tạo theme liên tục theo thông báo đồng bộ.
MaterialApp, PrismPalette, brand gradient/action, background, panel, toolbar, button,
navigation, dialog/field/card và contrasting pinned cover nhận cùng palette.
Error/cảnh báo giữ ý nghĩa và icon/text. Không lưu decoration theo note, không thêm blur/ticker/package.
ThemeExtension lerp theo theme animation hiện có, không remount nội dung hay làm hit bounds dịch chuyển.

Gallery hai cột nếu có ít nhất440dp và text<150%; còn lại một cột cuộn trong modal/settings.
Mỗi mẫu có thumbnail trang/nút, tên/tổ hợp, viền+check và semantics selected gộp vào button.
Footer giải thích nội dung không đổi; nếu ghi local lỗi có thông báo thử lại. Disable lựa chọn khi
local write đang chạy hoặc account/token đã đổi. Không lấy theme của account A làm theme public/B.
Hỗ trợ Việt/Anh; không dùng nội dung ghi chú trong preview.

## Preferences và tương thích

Thêm trường `palette` trong JSON preference, không đổi schema SQLite/Sembast.
Tài khoản cũ thiếu palette và giá trị local không biết dùng Atelier. Màn chưa đăng nhập dùng Atelier.
POST `/me/preferences/sync`: `{op_id, palette: "iris"}`; chỉ nhận6ID, strict/no-null/extra-forbidden.
Field merge/idempotency/account namespace và immutable operations dùng cơ chế hiện có.
Retry op cũ không đảo lựa chọn mới; op_id trùng payload khác409; mất mạng giữ queue.
Palette là preference; không dùng last-server-accepted cho nội dung ghi chú.
Legacy PATCH thiếu palette/locale giữ giá trị mới đã lưu; client mới cần backend mới nhận palette.
Thiết bị khác nhận trong lần sync tiếp theo, không claim realtime preference.

Đổi palette giữ title/body/rich Delta, user-applied text colour, controller/document/selection,
ID/frozen base revision, query/filter/scroll và quyền/grant. Ghi chú khóa tiếp tục che title/body/
labels/date/share identities trong visual/semantics/cache. Public pin/shared flags giữ chính sách cũ.

## Nghiệm thu16/10

PASS format129files0changes/analyze/308Flutter/147backend;6regression mới về contrast/cache,
offline reopen/account isolation, immutable inflight operation,320px/chữ200% hai locale/mode,
keyboard/selected semantics/account gate, và editor picker giữ document/selection/base7.
Test settings cũ thêm ensureVisible trước click công tắc, giữ nguyên toàn bộ assertions.
Tương phản chữ nội dung/muted trên các surface kiểm thấp nhất4.93:1 (Atelier sáng);
5bảng mới thấp nhất5.51:1, action/container/error text>=4.5:1, outline>=3:1.
Không coi đây là chứng nhận accessibility của tất cả nội dung do người dùng định dạng.

PASS Web IAB riêng7382/backend8063:6tổ hợp gồm mặc định và5lựa chọn thay thế, sáng/tối,
PC1280×1000/tablet768×1024/phone375×812/landscape844×390; editor mobile mở palette qua menu,
cuộn gallery/chọn Amber, Việt→Anh, đổi khi đang gõ→HTTP ACK, query giữ qua chọn Iris,
reload giữ palette/account và locked DOM không lộ dữ liệu fixture. API4roles và palette schema/
replay/legacy/account/note-array unchanged PASS. Web release local và APK debug compile PASS.
[Evidence đầy đủ](../evidence/2026-10-16-color-palettes/INDEX.md).

NOT RUN: Android runtime/OS/IME/picker, screen reader thực, profile GPU/FPS, provider thật,
CI newest-head/public release/video/submission. Chữ200% là widget test, không giả browser/OS scaling.
Không push/merge/deploy. Các snapshot trước vẫn giữ nguyên trong evidence.
