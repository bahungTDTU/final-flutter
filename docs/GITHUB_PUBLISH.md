# GitHub initial import — 02/10/2026

## Publication workspace/planner —10/10/2026

Người dùng yêu cầu push sau ordering fix và workspace/focus/Kanban/motion. Branch mới
`codex/workspace-planner` từ master13e0ffc sau PR#3, giữ các working changes và không sửa
nhánh mặc định. Source250 Flutter/109 backend/analyze/format PASS;24code hashes khớp gate
cuối, base tree không đổi. Author/committer Bahung, không co-author trailer/backdate.
[Gate và phạm vi](../evidence/2026-10-10-workspace-publication/INDEX.md); trạng thái remote/CI
phải tra head thực tại PR mới, không gọi local PASS là status CI. Chỉ branch/PR, không merge.

Từ yêu cầu07/10/2026, quy trình hiện tại là feature branch → PR → checks/review → merge.
Không direct push master/default hoặc force/bypass. docs/BRANCH_WORKFLOW.md mô tả ruleset
Active và required CI; các direct-push commands/đợt publication bên dưới là lịch sử.

Người dùng đã cung cấp https://github.com/bahungTDTU/final-flutter và ủy quyền commit/push.
Remote kiểm tra bằng git ls-remote trước import không có branch/tag/HEAD.
Nhánh local hiện có là master; giữ nhánh này. Không rewrite/force-push hoặc backdate.

Danh tính Git đã cấu hình trên máy: Bahung <523K0006@student.tdtu.edu.vn>.
Initial import dùng cùng author/committer theo yêu cầu của người dùng, không thêm GPT/Codex
hoặc Co-authored-by. Code được AI hỗ trợ như TEAM_CONTRIBUTIONS đã ghi; initial import
không phải bằng chứng contribution độc lập hoặc đủ4 tuần teamwork.

## Phạm vi source được đưa lên

Flutter/Web/Android, backend/tests/scripts, fonts/OFL, prompts/design/QA/status và evidence
local đã kiểm chứng. Không đưa .env, backend/state, .venv, build, keystore, Playwright session,
output generated hoặc Git credentials. Kiểm tra pattern token/private key/SMTP password
trên các file định đưa lên và compressed evidence chưa phát hiện candidate secret.
Các email/password example.test trong tests/evidence là fixture local công khai.

UI code không sửa trong đợt push. Gate cuối trước import:118 Flutter/53 backend PASS,
Chrome và Android debug Skia software UI driver PASS; Web/APK release build PASS.
Chi tiết và giới hạn ở evidence/2026-10-02-prism-ui/INDEX.md.

## Snapshot và lịch sử hiện tại

Manifest/logs UI được chốt trước initial commit; giữ nguyên timestamp/commitnull/hash
của snapshot đó. Docs hiện tại đổi theo thông tin repository mới nên full historical manifest
--verify không áp dụng cho docs/HEAD đã thay đổi; không regenerate evidence cũ thành QA mới.
Code/build hashes và raw logs vẫn giữ để đối chiếu; không rerun/claim test vì chỉ cập nhật Git/docs.

Kiểm tra tác giả và remote sau push:

```powershell
git log -1 --format=fuller
git log --format='%an <%ae> | %cn <%ce>%n%B'
git status --short
git ls-remote --symref origin HEAD
git ls-remote origin refs/heads/master
```

Push chỉ được coi là hoàn tất khi remote refs/heads/master bằng local HEAD. Upload source
không triển khai app, không tạo release artifact/HTTPS hoặc nộp bài.

## Publication07/10/2026

Người dùng yêu cầu push sau sửa hai ưu tiên cao. Phạm vi: UI editor tách title/content,
audit snapshot, shared note-password throttle và public pinned_at/shared status theo lựa chọn
người dùng, tests/integration/docs/evidence đã chạy.173 Flutter/93 backend/analyze PASS;
Web/HTTP/API36 debug có evidence scoped, không suy thành production acceptance.
Author/committer tiếp tục Bahung, không GPT/Codex/co-author trailer hoặc thay lịch sử cũ.
Một commit có nội dung rõ; không chia nhỏ/backdate để tạo contribution giả. Snapshot
manifests giữ basef8ff8fa/timestamps của QA. Publication kiểm tra refs thực theo lệnh ở trên.

## Publication performance và session07/10/2026

Theo yêu cầu push mới, xuất bản F3/F4 (encrypted draft projection/atomic fold và metadata
attachment queries) cùng F5 (session encryption/legacy migration/durable logout/retry).
Giữ author/committer Bahung và nhánh master, một commit có nội dung rõ; không force/rewrite,
thêm GPT/Codex co-author hoặc giả đóng góp nhóm. Source188 Flutter/94 backend/analyze PASS;
actual Web/HTTP/API36 debug có evidence ở performance và session-storage, scope riêng.
Manifest vẫn ghi base5b82996/timestamps thật lúc QA. Ghi nhận publication ở STATUS/README
là thay đổi docs sau QA; source khác và toàn bộ evidence được kiểm tra hash trước commit.
Remote master phải bằng local HEAD trước báo push hoàn tất. Không tạo release/deploy/nộp bài.
