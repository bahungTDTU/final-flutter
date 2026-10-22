# Kiểm tra, sửa lỗi và dọn file tạm — 22/10/2026

Source: `ad21cf8889dd40fc615eebdbe0904fac8dc7123f`, nhánh
`codex/full-function-audit`, working tree có thay đổi Android/Web từ trước.
Đã giữ nguyên các thay đổi đó; không commit/push/merge/deploy. Có AI hỗ trợ.
Đã đọc hướng dẫn, trạng thái, matrix và PDF gốc 19 trang.

## Lỗi đã tái hiện và sửa

`validPortable` dùng thêm `String.length` (UTF-16) trong khi `validNote` và
backend dùng Unicode code point. Ghi chú hợp lệ chứa nhiều emoji bị từ chối khi
xuất/nhập, và template cùng loại bị bỏ qua khi đọc lại snapshot.

Bỏ giới hạn UTF-16 trùng lặp, dùng validation chung. Hai regression FAIL trước
sửa và PASS trong suite sau sửa: roundtrip tiêu đề 200 emoji/nội dung 100.000 emoji
giữ nguyên dữ liệu, vượt giới hạn vẫn bị từ chối; template 150 emoji tồn tại sau
snapshot reload. Giới hạn 5 MiB/50 notes, bảo vệ owner/locked, rich document,
immutable outbox và frozen base revision không thay đổi.

## Kiểm chứng hiện tại

| Kiểm tra | Kết quả |
|---|---|
| Dart format | PASS, 137 files, 0 changes |
| Flutter analyze | PASS, no issues |
| Flutter unit/widget suite | PASS, 331 tests |
| Backend suite | PASS, 152 tests; một Starlette/httpx deprecation warning |
| HTTP thật, backend QA riêng | PASS owner/viewer/editor/stranger, lock/grant/list redaction, edit/replay/conflict409, attachment ACL, revoke/password change/delete |
| Web release local | PASS, offline shell 40 resources |
| Android APK debug | PASS compile; không phải runtime hay signed release |
| Git diff whitespace | PASS |
| Browser UI/Android runtime mới | NOT RUN trong lượt này |
| SMTP/Gemini Internet, public HTTPS, signing, FPS, submission, hosted CI | NOT RUN; không đóng các gate còn lại |

Lần backend trong sandbox lỗi tạo thư mục pytest: 27 PASS/125 setup ERROR,
không tính là lỗi ứng dụng. Chạy ngoài sandbox PASS toàn bộ. Log thất bại giữ lại.
Build có cảnh báo Cupertino font và SDK XML toolchain; không nâng dependency
chỉ để xóa cảnh báo. Không có bằng chứng cam kết dự án không còn mọi lỗi.

## Dọn dẹp

Đã xóa 1.062 file (360.138.050 bytes, khoảng 343,45 MiB) và 259 symlink cache:
bản Web build tạm đã rà soát, PDF render/extract trung gian và pytest outputs cũ.
Không đi theo symlink; không xóa nguồn đích của link. Manifest giữ đường dẫn,
số file và dung lượng. Giữ evidence lịch sử, mã nguồn, môi trường/toolchain,
backend/state, các backup Git và dữ liệu QA chưa xác nhận có thể bỏ.

Hai thư mục `tmp/pytest-avatar-cache` và `tmp/pytest-email-cache` còn lại vì
Access denied cả khi kiểm tra ngoài sandbox. Auto-review từ chối recursive delete
do không xác minh được nội dung/phạm vi và khả năng phục hồi. Không đổi ACL,
take ownership hoặc vượt qua quyết định này.

[Lệnh, log và manifest](../evidence/2026-10-22-project-check/INDEX.md).

## Publication follow-up

Người dùng đã ủy quyền dọn cache và push. Fast-forward tới master66f11bc,
tree giống ad21cf8; tạo nhánh codex/unicode-portability-qa. Quyền xóa cache
đã xác nhận nhưng Windows vẫn Access denied. Auto-review từ chối takeown/icacls
vì chưa có ủy quyền riêng cho thay ownership/ACL; hai thư mục giữ nguyên.
CI/approval cần kiểm trên PR mới, không tự merge.
