# Bảng kế hoạch, UI và chuyển động — 10/10/2026

Source: branch `codex/adaptive-word-editor`, HEAD/base
`a5e5ec60568b7ee2b0c50290a3e6502a4d490110` + working changes. Giữ các sửa ordering,
workspace và focus từ yêu cầu trước. Chưa commit/push; CI ở HEAD cũ không đại diện source
local. [Thiết kế và cách sử dụng](../../docs/WORKSPACE_PLANNER_AND_MOTION.md).

## IMPLEMENTED

- Kanban cá nhân: Dự kiến / Đang làm / Hoàn thành; chọn ghi chú, ưu tiên và ngày hạn,
  đổi chặng, sửa, bỏ khỏi kế hoạch có xác nhận. Không xóa/sửa note qua thao tác kế hoạch.
- Tìm theo tiêu đề, lọc quá hạn/hôm nay/7 ngày/ưu tiên cao; progress và counts chỉ tính
  note hiện khả dụng. Metadata kế hoạch mã hóa theo account, durable/reopen, không cloud sync.
- PC ba cột cuộn riêng; mobile/tablet/chữ lớn chọn chặng qua dropdown, rows lazy.
  Bố cục và màu tím/xanh/mint đồng bộ theme sáng/tối; title/preview/metadata tách rõ.
- Entrance fade/lift 220ms, press scale 180ms, progress 220ms; giảm chuyển động và không
  chạy animation nền vô hạn. Filter/query giữ trong route khi resize/theme/đổi tab.
- Lock/revoke bỏ thẻ/picker/form/calendar ngay. Reset progress khi tập note nguồn thay đổi,
  không animate từ tỷ lệ riêng tư cũ; account switch bỏ cả từ khóa picker của account cũ.

## PASS và lệnh thực tế

| Kiểm tra | Lệnh/target | Kết quả và bằng chứng |
|---|---|---|
| Gate tổng | `powershell -File scripts/check.ps1` | 250 Flutter / 109 backend; format 105 files, 0 changes; analyzer sạch: [check.txt](check.txt). Backend có 1 pinned Starlette/httpx deprecation warning. |
| Source cuối | `flutter analyze`; `flutter test --reporter expanded`; `dart format --output=none --set-exit-if-changed lib test integration_test test_driver` | 250 PASS sau navigation và hai privacy guards; no issues; 105 files, 0 changes: [tests](flutter-final.txt), [analyze](analyze-final.txt), [format](format-final.txt). Backend không đổi sau gate tổng. |
| Web QA | `scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8051` | PASS, 40 static resources: [build](web-qa-final.txt), [hashes](web-qa-hashes.json). |
| Web mặc định | `scripts/build.ps1 -Target web` | PASS, API8000; worker `notetogether-static-a4cf7ad3c14b36b3`: [build](web-default-final.txt). Không giữ API test trong build mặc định. |
| Android compile | `flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8000` | PASS source cuối: [apk-debug.txt](apk-debug.txt). Chỉ compile, chưa chạy thiết bị/emulator. |
| HTTP ACL thật | Python HTTP → FastAPI/SQLite QA8051, email/LLM disabled | Owner/viewer/editor/stranger; current/stale revisions, viewer403, stranger404, locked edit423, revoke và six-field projection: [report](http-roles.json). |
| Planning không sửa note | UI tạo/chuyển chặng/sửa metadata/reload → GET ba note trên QA8051 | Revision1/title/content fixture khớp, hash content giữ nguyên trước remote protection actor: [server-unchanged.json](server-unchanged.json). Sau đó protection actor có chủ ý tăng revision; không gộp với thao tác planning. |
| Kanban Chrome thật | Chrome release7371; `playwright-cli -s=nt-planner run-code --filename=plans-final.js` | Ba references, priority Low→High, Today, cancel remove, search/high/day filters, reload metadata PASS: [log](chrome-plans-final.txt). |
| Responsive/theme | Chrome; `gallery.js`, `landscape-check.js` | 1440×1080 / 390×844 / 768×1024 / 844×390, sáng/tối; chọn chặng mobile, mở calendar, cuộn landscape đến card PASS: [gallery](chrome-gallery.txt), [landscape](chrome-landscape.txt). Ảnh viewport chụp trực tiếp, không sửa ảnh. |
| Remote protection | Owner HTTP POST protection khi calendar Chrome đang mở → SSE | POST200/six-field listing: [HTTP](remote-lock.json). Calendar thành generic message, stale form không lưu được, private card bị ẩn, board từ3→2: [Chrome](chrome-remote-lock.txt). QA owner restore bằng password giữa hai lượt đã trả200: [restore](remote-restore.json); lượt cuối reload thấy lại3 references trước khi khóa. |
| Cache đúng source | Chrome CacheStorage đọc static-only; `cache-proof.js` | Một cache `2d7c6fb7d9f140cd`, 40 resources, main SHA256 khớp build, worker activated/no waiting/installing, không API/private URLs: [proof](chrome-cache-proof.txt). Không đọc session/account storage để chụp evidence. |
| Console phiên cuối | `playwright-cli -s=nt-planner console` | 0 errors / 0 warnings: [console](chrome-console-final.txt). Đây là console của reload cuối, không phải claim mọi log trước đó sạch. |

8 tests mới: date boundary/malformed migration/sort; durable failure/retry/merge với draft và
focus; queued lock/revoke/account switch; form retry/move/remove confirmation; private progress/
calendar/entrance cleanup; 320px/text200%/keyboard/picker account isolation; lazy500/filter
retention; press/reduced motion/no infinite frames. File encryption/reopen/logout test hiện có
được mở rộng cho plan metadata. Privacy animation checks quan sát frame ngay sau lock, trước settle.

Lượt targeted đầu FAIL do test chưa pump frame bắt đầu press tween; sửa test timing, không
thay motion để né assertion. [Log đầu](targeted.txt), [39 targeted PASS](targeted-final.txt).
Driver Chrome đầu dùng locator text cho metadata đã gộp trong group semantics; luồng tạo/reload
đạt nhưng locator FAIL. [Log đầu](chrome-plans-first-attempt.txt); driver cuối dùng group/menu
và kiểm lại. Fingerprint QA lấy từ `build/web/offline_worker.js`; cache proof đọc giá trị thực,
không suy ra đúng bundle từ việc UI vẫn chạy. Bản cuối đã chụp lại sau privacy fixes.

## Giới hạn nghiệm thu

NOT RUN: Android UI/IME/FPS trên source mới, thiết bị thật, screen reader thực, public HTTPS,
release signing/provider Internet/video/teamwork. Widget reduced motion/Chrome responsive không
thay các nghiệm thu này. Không có số đo FPS mới.

OUT OF SCOPE: OS/email reminder, drag-and-drop, cloud sync kế hoạch cá nhân. Hạn là calendar date
trong app; update qua nửa đêm/resume, không tick toàn app mỗi giây. Tất cả note còn bật bảo vệ
đều ẩn khỏi board, kể cả reader đã unlock. Kế hoạch lưu tối đa500 references, không snapshot
title/content/grant. Remove reference không xóa note. Form disk failure/retry và viewer planning
được kiểm bằng controller/widget; không claim gây lỗi disk thật hoặc chạy viewer UI trên Chrome.

QA sử dụng accounts/SQLite test riêng ngoài repo, không copy DB/token/auth state vào evidence.
Sau QA đóng riêng browser `nt-planner`, dừng API/static QA8051/7371: [cleanup](cleanup.json).
Web build trở về API8000, APK debug dùng emulator8000. [Manifest SHA256](manifest.json) ghi
source/artifact/evidence sau hoàn tất docs; chỉ build compile không phải public release.

## Ảnh để kiểm tra

- [PC Kanban — sáng](02-kanban-desktop-light.png), [PC — tối](07-kanban-desktop-dark.png).
- [Form ưu tiên/ngày hạn](01-plan-form-light.png), [search + filters](03-kanban-filter-light.png), [sau reload](04-kanban-reload-light.png).
- [Mobile đầu trang — sáng](05-planner-mobile-top-light.png), [mobile card — sáng](06-planner-mobile-card-light.png).
- [Mobile đầu trang — tối](08-planner-mobile-top-dark.png), [mobile card — tối](09-planner-mobile-card-dark.png).
- [Tablet — tối](10-planner-tablet-dark.png), [landscape đầu trang](11-planner-landscape-dark.png), [landscape cuộn đến card](15-planner-landscape-card-dark.png).
- [Calendar](12-calendar-dark.png), [calendar khi lock remote](13-calendar-remote-lock-dark.png), [board sau lock](14-board-remote-lock-dark.png).

Scripts ở đây mô tả luồng đã quan sát, cần fixture phù hợp và semantics bật. `plans-final.js`
giả định ba plans fixture có sẵn và theme sáng; `gallery.js` tiếp nối mobile light và kết thúc
tại calendar; HTTP protection actor chạy trước `remote-check.js`. `landscape-check.js` tiếp nối
board dark. Không tự chạy các scripts trên dữ liệu thật, không gọi chúng là integration CI tests.
