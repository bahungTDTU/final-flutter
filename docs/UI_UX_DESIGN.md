# NoteTogether – UI/UX design, cập nhật 03/10/2026

Maintenance03/10 giữ giao diện prism; bỏ PaperIllustration không còn caller và dependency
cupertino_icons không dùng. Theme/motion/metadata vẫn theo spec dưới; HTTP/lifecycle/sync
fixes và cleanup có regression ở docs/PERFORMANCE_AND_MAINTENANCE.md.

## Đợt màu sắc và lăng kính 02/10/2026

Theo yêu cầu mới của người dùng: đa sắc, bắt mắt, animation hiện đại nhưng dễ đọc.
Hướng này thay palette giấy/teal ở các mốc lịch sử bên dưới; không thay các invariant dữ liệu.
Semantic theme vẫn ở `lib/ui/design_system.dart`; `lib/ui/prism.dart` cung cấp
PrismPalette ThemeExtension và các component trang trí dùng chung, không dependency mới.

- Sáu tông tím, xanh dương, cyan, hồng, amber, mint; nền sáng #F5F5FC/tối #101426,
  primary #5B50D0/#C8BDFF, chữ #19223B/#EEF0FF. Màu chữ/outline tách khỏi viền trang trí.
- Nền ánh sáng radial và một mặt cắt lăng kính tĩnh; hero tinh thể được vẽ bằng CustomPainter.
  Viền chuyển sắc mảnh, panel có nền kín và vùng đọc thoáng. Không BackdropFilter/blur nặng,
  không animation nền vô hạn. Trang trí không nhận pointer hoặc xuất hiện trong semantics.
- Thẻ/nhãn chọn tông ổn định từ ID opaque, không từ title/content/metadata bí mật,
  không thêm trường note hoặc màu lưu server. Thẻ khóa trung tính, không có accent strip.
- Hover nâng thẻ 2px trong180ms, fade/lift hero420ms, chuyển theme300ms,
  chuyển route fade/slide ngắn theo thời lượng route. Không stagger/delay nội dung ghi chú
  hoặc giữ private content để chạy exit effect. Value equality của palette tránh restart theme
  khi controller cập nhật realtime/sync.
- Hệ thống giảm chuyển động: thời lượng trang trí bằng0, hover không đổi vị trí,
  reveal hiện ngay, route trả child trực tiếp, không ripple. Không hứa FPS khi chưa profile.
- Giữ key/card ordering, home scroll/filter và editor ID/base revision/text/selection.
  Theme, panel, auth CTA và create CTA dùng chung; các màn quản lý thừa hưởng semantic theme.

Kiểm chứng và ảnh thực: `evidence/2026-10-02-prism-ui/INDEX.md`, `docs/UI_UX_QA.md`.
Các bảng màu và kết quả đợt trước dưới đây là lịch sử.

## Đợt nâng cấp toàn diện 02/10

Audit bằng source và ảnh Chrome trước sửa: `evidence/2026-10-02-ui-upgrade/before-*.png`.
Giao diện 01/10 đã có adaptive navigation và tokens, nhưng sidebar thiếu ngữ cảnh tài khoản,
card/metadata ít phân cấp, editor chưa có mặt giấy, dialog chưa dùng cấu trúc chung.
Giữ hướng giấy sáng/xanh trà, NotoSans và core hiện có; không thêm framework hoặc asset template.

- Sidebar có số ghi chú/nhãn thực và avatar; rail cho cửa sổ thấp dưới700px hoặc chữ>=150%.
- Search Ctrl+F hoạt động khi Home có focus; bỏ bộ lọc nhãn giữ từ khóa. Count và AND không đổi.
- Thẻ có biểu tượng trung tính, metadata pills, footer và trạng thái; một ghi chú ghim dùng hàng
  rộng gọn để các ghi chú khác xuất hiện sớm hơn. Grid khác giữ virtualized slivers/thứ tự.
- Editor có mặt giấy giới hạn800px, trạng thái thật, số ký tự và pin/nhãn hiện có. Bản nháp chưa
  hợp lệ khi mở lại không báo đã đồng bộ; ID/base/selection không đổi khi theme/resize.
- Auth có hero riêng trên desktop đủ cao; register/login busy-disable và autofill. Material
  locale tiếng Việt cả semantics mặc định, không chỉ các Text do app tự viết.
- DialogHeading/SectionHeading/SurfacePanel/StatusNotice dùng chung cho hồ sơ, nhãn, avatar,
  mật khẩu, bảo vệ, chia sẻ, đính kèm, recovery/conflict và mã email. SurfacePanel dùng Material
  để không che ink; StatusNotice tương thích intrinsic sizing của AlertDialog.
- Sheet nhãn cuộn toàn bộ, đọc được tên dài/chữ200%, có Đóng rõ ràng. Settings có nhóm, font
  preview, dark và pending thực. Thông báo mobile không ép nội dung vào một hàng khi chữ lớn.
- Q&A chưa có LLM: thông báo trung thực và CTA trở lại tìm kiếm; không dựng câu trả lời/presence.

Thiết kế, code và integrated áp dụng cho các flow có backend; mức verified Web/native và các
flow chưa chạy được ghi riêng ở UI_UX_QA và INDEX evidence. Không claim TalkBack/NVDA bằng semantics.

## Audit lịch sử trước đợt 01/10

Code audit: home dùng app bar và một wrap trộn sync, điều hướng, view và nhãn; không có
navigation thích nghi. Card thiếu ngày cập nhật, phân nhóm ghim và empty search/filter rõ.
Editor có hai khung input lớn, status chưa phân biệt server ack; settings chưa có font preview.
Auth thiếu toggle password. Dữ liệu/route hiện có phải giữ nguyên ID, frozen base revision,
namespace, draft và immutable preference operations.
Browser baseline thật: evidence/2026-10-01-ui/before-*.png. Những phát hiện từ đọc code
không được gọi là kiểm chứng screen reader hoặc Android.

| Mức | Vấn đề / nguồn quan sát | Xử lý |
|---|---|---|
| P1 usability/state | Code: local/server save chưa rõ; locked card dùng title/content payload | Status dựa ack/pending, neutral locked representation + semantics regression |
| P1 regression | Editor revision và ID dễ bị phá khi theme/resize | Giữ state/controller và test frozen revision/text selection |
| P2 visual | Baseline browser: hierarchy phẳng, editor hai hộp input lớn | Workspace shell, grouping và canvas viết |
| P2 accessibility | Code: auth chưa show password, view toggle chưa rõ selection | Toggle semantics, segmented view, guideline + scaled layouts |
| P2 service dependency | SMTP/files/share/lock/AI chưa đủ | Design spec + fixtures tách riêng, không fake success |

## Hướng thiết kế

Không gian ghi chú yên tĩnh: nền giấy #F7F8F5, surface trắng, primary #176B57, chữ #17251E;
dark #111816/#1A2320, primary #83D8B8, chữ #E6EEE8. Surface phụ #EFF3EF/#24312B,
chữ phụ #52645A/#AFBEB4. Control outline dùng màu mạnh hơn outline trang trí.
Semantic tokens tập trung trong ui/design_system.dart; không dùng outline nhẹ làm focus.
Spacing 4/8/12/16/24/32/48, card radius16, input12, dialog24, tap target48.
Noto Sans Regular/Bold bundled offline, OFL trong assets/fonts; không runtime font fetch.
Text title32/section22/card18/body16/meta13, editor line height1.6 + font preference14–24.
Việt hóa Material bằng flutter_localizations từ SDK; không thêm backend schema vì redesign.
Note colors neutral/sage/sand/sky/lilac
chỉ ở component preview trước khi có contract lưu màu; production neutral.

## Navigation & responsive

Constraints <600: bottom navigation3 mục + FAB tạo; 600–1023 rail; >=1024 sidebar248.
Ở text scale>=1.5 hoặc height<700, sidebar chuyển rail; grid giảm cột theo scaled min extent.
Desktop CTA ở header; mobile FAB duy nhất. Home giữ PageStorage scroll, query/filter state khi
route editor pop. Virtualized slivers, grid đều thứ tự compareNotes; group ghim trước.
Editor full route, nội dung max width800; không thêm ba pane. SafeArea/scroll keyboard insets.
Ctrl+F ở Home đưa focus đến search; các shortcut khác giữ hành vi nền tảng. Material focus/hover/pressed;
theme animation tắt khi disableAnimations, không animation danh sách lúc search/save.

## Màn hình và trạng thái

| Screen/state | Trigger/message/action | Dependency & level |
|---|---|---|
| Auth default/loading/validation/error | labels, show password, Enter submit, busy guard, inline error | Existing authenticate; integrated |
| Verify banner | Email chưa xác minh; Xác minh mở form mã/gửi lại; gửi lỗi nói rõ | /me + verify/resend thật; SMTP TLS transport, inbox ngoài chưa nghiệm thu |
| Recovery/reset | Request → token check → password confirmation → login thủ công; invalid/expired message | SMTP/TLS transport + two-step code UI; internet inbox chưa xác minh |
| Home loading | static skeleton/initial progress; cached notes vẫn hiển thị khi sync | Controller ready/syncing |
| Home empty/search-empty | Tạo ghi chú đầu tiên / xóa tìm kiếm & filters | Real count/AND filter |
| Home offline/error | pending notes+preferences+labels; retry thật | Durable queues + encrypted lock recovery |
| Card owner/viewer/editor/locked | title/snippet/date/labels/status; only owner menu; locked neutral | API role; không fetch nội dung bị khóa |
| Editor dirty/local saved/pending/ack/error | phân biệt local và server; retry, preserve caret/controllers; ẩn realtime label khi offline | Existing draft/save/hasPending; frozen revision |
| Editor read-only/revoked/locked | đọc/copy nếu còn quyền; che nội dung sau lock/revoke, phục hồi riêng | SSE/refetch + encrypted recovery; protected password cache/draft + offline unlock/revalidate05/10 |
| Conflict | Hai phiên bản; local/remote preview nếu được phép; copy hoặc remote + hệ quả | resolveConflict thật; không merge giả |
| Labels empty/validation | add/rename/delete-confirm; pending/conflict/remote; note còn; AND IDs | Server catalogue/revisions/outbox + SSE invalidation integrated |
| Settings/profile | groups, verified, font preview, name/password; choose/upload/default avatar | Private avatar API/canonical encrypted cache; online changes |
| Share owner flow | email batch1–20 + viewer/editor, recipient list/change/revoke | Real ShareSession + ACL/revision/idempotency integrated; protected-reader full acceptance chưa đủ |
| Lock/unlock flow | password2x/current/new, pending/network/errors/rate-limit | Enable/read/edit/autosave/delete/relock + cached offline unlock; metadata chỉ sau unlock; server grant trước sync |
| Attachments | picker→validate→upload/private list→image/video preview/download/delete-confirm | Private API/RAM session integrated; online-only, retry trong route, ACL/grant/epoch guards |
| AI summary/Q&A | note scope, source cards, loading/error/no sources, regenerate/copy | Production AiSession/Gemini adapter/citations; fixture QA local, Gemini thật chưa chạy |

Preview fixtures không đi vào production navigation; không đưa fake note/AI vào account.
Q&A production báo lỗi cấu hình khi thiếu key; fixture component vẫn tách riêng, không presence giả.
Lock UI đã nối endpoint sau encrypted draft recovery; không tuyên bố encryption E2E.
Share spec: owner nhập email và chọn Chỉ xem/Có thể chỉnh sửa trước cấp quyền; mỗi recipient
có permission menu; revoke ngừng đọc/source open. AI source open phải reauthorize, không cache câu
trả lời từ nguồn revoked. Attachments chỉ thumbnail khi server cho phép, size/type/error riêng.

## Component map & references

design_system: tokens/theme/brand/empty/status; home: adaptive shell + sections/cards + managers;
editor: route writing canvas giữ logic draft; app: auth/token + ThemeData. Preview harness nằm
test/ui_preview_test.dart, fixtures được ghi rõ, không phải tính năng tích hợp.

Tham khảo đã mở: [Flutter adaptive](https://docs.flutter.dev/ui/adaptive-responsive/general),
[accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing),
[Noto OFL](https://github.com/notofonts/noto-fonts/blob/main/LICENSE).
Contrast đo bằng script, kết quả và target QA tách trong UI_UX_QA.md; không suy từ Material.


## Xưởng ghi chú06/10

Gallery dùng Prism tone/selected border/check, preview hai cột rộng/một cột hẹp hoặc chữ lớn. Home có icon gọn giữ list height. Editor outline/checklist collapse, focus timer route-local/toolbar overflow mobile; giữ controller/selection/base. Local deterministic analysis, không preview fixture/LLM. Protected reader chưa nối. Xem WRITING_STUDIO.md.


## UI đồng bộ/responsive/performance06/10

ReadingCanvas dùng chung editor/AI/protected, width800/adaptive spacing/Scaffold keyboard resize;
gallery không backdrop lặp,6tones/compact footer/preview dialog, short landscape/chữ200%.
Bound card preview480UTF16+ellipsis, source/account/query/role/label-aware view cache, suffix-only
search input rebuild/literal Unicode search. Locked pin/date/group và semantics được ẩn.
161 Flutter/88 backend/analyze PASS;native debug3 reused workflows, actual Web gallery/theme/
AI form breakpoint/protected unlock-relock/tail100000 search/remote lock cached Home PASS.
Host benchmark NotoSans có phạm vi, không FPS. Xem UI_COHESION_AND_PERFORMANCE.md và
evidence/2026-10-06-ui-cohesion/INDEX.md;physical/screen-reader/production/release chưa nghiệm thu.
