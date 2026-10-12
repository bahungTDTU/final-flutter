# Publication UI / Deskbook —12/10/2026

Người dùng yêu cầu push lên GitHub. Target `codex/ui-system-refresh` → PR vào `master`
của bahungTDTU/final-flutter. Author/committer Bahung <523K0006@student.tdtu.edu.vn>,
không thêm AI co-author trailer. Không tự merge, approve hoặc đổi ruleset.

## Local gate và baseline

UI final QA ở [Deskbook](../2026-10-12-deskbook-layout/INDEX.md): format112files0changes,
analyze0issues,270 Flutter PASS;118 backend PASS, Web/APK debug compile. Chrome7viewport/
hai theme,30ảnh, autosave API, reader privacy và cache40static khớp build. Các snapshots
[UI system refresh](../2026-10-12-ui-system-refresh/INDEX.md) và
[Atelier](../2026-10-12-atelier-ui/INDEX.md) là lịch sử, giữ nguyên nội dung và hashes.

Trước publication, master nhận merge PR#6 thành `41eb180`. Tree của commit này giống
baseline `f3b17a3` đã dùng làm QA: `git diff --name-only f3b17a3 origin/master` trống.
Nhánh UI fast-forward tới master rồi commit bản sửa. Không có source UI/backend mới
do tích hợp; không chạy lại browser/full suites chỉ vì merge metadata và tài liệu
publication. Local hashes/preflight và staged diff được kiểm tra trước commit/push.

`preflight.json` ghi thời điểm thật, baseline/branch, hashes code QA, evidence, candidate
file bytes và kết quả quét mẫu secret. `source_manifest.json` ghi hashes LF của source
được xuất bản; thông tin commit cuối và CI lấy từ branch/PR thật trên GitHub.
Không thay metadata trong các snapshot cũ bằng commit/publication mới.

## Phạm vi

Commit gồm theme/components, library Deskbook, editor/phone layout, regressions và
tài liệu/bằng chứng ba đợt UI. `.agents/` là skill cài local của người dùng, không stage.
Private config/DB, credentials, tmp, runtime logs và build binaries không được stage.
Snapshots QA dùng fixtures tổng hợp và tài khoản thử, không auth token hoặc key thật.

Local checks không xác nhận hosted CI. Ba required checks Flutter quality/Backend tests/
Build smoke và human approval được tra trên PR/commit mới nhất. Chỉ merge khi chúng
PASS, base cập nhật, hết review threads và có1approval hợp lệ sau push cuối. Yêu cầu
push chỉ xuất bản branch/PR; không tự bật auto-merge hoặc nhắn reviewer.

Native runtime/IME/FPS, screen reader, provider/cloud/SMTP thật, HTTPS/release signing,
video/submission vẫn chưa được nghiệm thu trong publication này.
