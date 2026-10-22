# Rà soát chức năng và tối ưu đồng bộ — 21/10/2026

Đã `git pull --ff-only origin master` trước khi sửa: từ `fc843b7` lên `26636e6`
(PR #13 đã merge), rồi tạo `codex/full-function-audit`. Giữ nguyên dữ liệu local và
`.agents/`. Báo cáo ghi nhận snapshot local trước xuất bản; trạng thái PR/CI được theo dõi trên GitHub. Không merge/deploy, nâng cấp dependency hoặc đổi backend trong lượt audit.

## Lỗi đã xác nhận và sửa

### Bản nháp của owner bị bỏ lại khi ghi chú bị xóa từ thiết bị khác

Trước sửa, remote disappearance chỉ xử lý ghi chú được chia sẻ. Với owner, draft
không hợp lệ (ví dụ tiêu đề trống) bị bỏ lại ngoài danh sách và editor xóa input;
update bị server từ chối404 cũng có thể giữ một ghi chú xung đột không còn tồn tại.
Hai regression trước sửa đều FAIL; test dùng kho account mã hóa và kiểm tra reopen.

Bây giờ, ghi chú đã tồn tại trên server nhưng biến mất sẽ giữ edit mới nhất trong
recovery mã hóa với reason `deleted`, retire outbox/conflict/draft của ID cũ và
ngăn ghi trở lại ID đó, cả sau reopen. Phục hồi tạo draft/ghi chú UUID mới. Một ghi
chú mới chưa từng được server chấp nhận (pending create/base_revision0) vẫn ở luồng
validation/conflict để sửa; không bị nhận nhầm thành remote delete. Shared revoke,
locked recovery, immutable payloads và frozen editor revision giữ nguyên.

Web thật đã nhập draft tiêu đề trống → phiên thứ hai cùng owner xóa source → SSE
che editor → dashboard Phục hồi → mở draft mới → nhập tiêu đề → ACK trên server →
reload. HTTP xác nhận source404, copy UUID mới/đúng nội dung, ghi chú khác revision1
không đổi. Console không có error trong luồng này. Ảnh PC/phone kèm INDEX.

### Request hồ sơ bị lặp trong mỗi lượt đồng bộ thông thường

Trước sửa, một cycle luôn GET `/me` hai lần. Bây giờ dùng profile của lần đọc đầu
nếu không có preference operation nhận ACK; khi có ACK vẫn đọc lại để lấy giá trị
canonical từ server và giữ overlay thay đổi đang chờ. Probe idle giảm2→1 GET `/me`
(giảm50% request hồ sơ/cycle), preference ACK vẫn2. Đây là phép đếm request, không
phải đo độ trễ tổng thể hoặc FPS.

## Phạm vi rà soát và bằng chứng

| Nhóm | Kiểm tra lượt này |
|---|---|
| Auth/session/email | Suite backend/Dart; HTTP register/login/profile. Email/reset/password/session-revoke qua test fixtures, chưa thử inbox Internet |
| CRUD/rich text/search/pin/labels | Full Flutter/backend suite; HTTP create/labels rename; Web edit/recovery/server ACK/reload |
| Offline/durability/conflict | Full suite và regression encrypted reopen, 404 update, chưa tạo/base0, preference ACK; không đổi CAS/base revision |
| Protection/sharing/attachment | HTTP thật owner/viewer/editor/stranger: lock/unlock/redaction, edit/replay409, viewer-write403, editor-delete403, revoke404, attachment upload/private read/delete |
| Profile/avatar/preferences | HTTP name, avatar upload/read/delete với revision CAS, label create/rename, preference ACK/replay; locale/palette kiểm trong suite |
| Realtime | HTTP SSE ready/version-only; Web nhận peer delete. Full suite kiểm parser/reconnect/account isolation |
| AI | Full backend/client suite kiểm adapters/ACL/sources/throttle/errors bằng fixture; chưa gọi Gemini thật |
| Workspace/planner/focus/import-export | Full Flutter suite; không khẳng định đã thử OS picker hoặc mọi thao tác UI thủ công lượt này |
| UI/responsive/theme | Full suite; luồng phục hồi Web PC1280×900 và phone375×812, reload và console. Chưa quét thủ công mọi màn hình ở mọi breakpoint |

Baseline **324 Flutter +152 backend PASS**; cuối **329 Flutter PASS**, 135 files format,
analyze sạch. Năm regression mới gồm2 case owner delete,1 guard pending create và2
case profile request/ACK. Nhóm liên quan39 tests PASS. Web QA API8071 release build
+offline manifest40assets và APK debug API10.0.2.2:8000 build PASS. Pub get offline
với enforce-lockfile PASS; pubspec/lock không đổi. SDK XML/Cupertino font warnings
được giữ trong log, không nâng cấp toolchain ngẫu nhiên để xóa warning.

## Giới hạn còn lại

Không suy bộ test thành cam kết không còn bug. Android IME/picker/OS lifecycle,
profile FPS/GPU, SMTP/Gemini Internet, signed release/public HTTPS và CI mới chưa
chạy. Các gate release/submission cũ vẫn mở theo REMAINING_GATES.md; lượt này chỉ
sửa client và bổ sung kiểm thử/tài liệu. Không thay snapshot bằng chứng cũ.

[Bằng chứng, kết quả và ảnh](../evidence/2026-10-21-function-audit/INDEX.md).
