# Publication gate — UI và sửa lỗi,13/10/2026

Người dùng ủy quyền push current source vào bahungTDTU/final-flutter. Target branch
`codex/bug-audit-fixes`, base master`46df286302cc88e07c98ba1b14160cc64491e2df`.
Không push trực tiếp master, force-push, bypass, merge, deploy hoặc phát hành artifact.

## Source được xuất bản

- Editor: tìm ngược đúng, nhận nội dung mới, chặn thay thế khi readonly, purge private
  input cả controller/DOM sau khóa; outline Material và large-text caption có constraint.
- Attachment API: byte-range offset lớn được giới hạn theo kích thước tệp, không gây500.
- Inspector: information/AI/tools/protection thành thẻ; action đồng đều, tự wrap, primary
  edit/error delete; badge metadata semantics và ordinary/protected editor đồng bộ.
- Offline helper: output directory trong workspace để QA build tách user build đang chạy.

## Local acceptance và phạm vi

`gate.json` so source code với accepted LF hashes; không có code mới sau nghiệm thu.
279 Flutter/119 backend, format/analyze và Web/APK debug compile đã PASS trên source đó.
Vì source code không đổi, không chạy lại toàn bộ tests chỉ để tạo log publication mới.
CI của PR mới vẫn chạy riêng trên GitHub.

[Bug audit](../2026-10-12-bug-audit/INDEX.md):7nhóm lỗi, direct HTTP4roles/ranges,
browser remote update/lock/DOM private purge. [Inspector](../2026-10-13-inspector-ui/INDEX.md):
WebIAB PC-phone/hai theme, owner/viewer, edit/pin/API/dialogs/relock; widget200%/controller/caret.
Hai evidence payloads giữ nguyên bytes; source/doc snapshot cũ vẫn thuộc ngày nghiệm thu cũ.

Các file cấu hình bí mật, DB/cache, logs đang hoạt động, build outputs, tmp và công cụ
local`.agents` không trong commit. `staged-review.json` ghi scope/size/secret-pattern check;
`source_manifest.json` ghi normalized source hashes; `SHA256SUMS.json` giữ gate payload.
Tác giả/committer dùng cấu hình người dùng Bahung, không đổi lịch sử contribution.

PR được tạo vào master và attach task; status CI/approval phải đọc tại commit head mới nhất.
Required checks:Flutter quality,Backend tests,Build smoke. Giữ1approval người khác sau
push cuối, branch cập nhật và resolved review threads; không tự approve/auto-merge.
Native runtime/IME/FPS/real screen-reader/provider/public HTTPS/release/video vẫn NOT RUN.
