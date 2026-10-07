# Branch, PR và ruleset —07/10/2026

Theo yêu cầu người dùng, mọi thay đổi mới được commit/push trên branch làm việc rồi đưa vào
PR tới master. Không direct push master/default branch, force-push hoặc bypass. Các đợt direct
push ghi trước ngày này là lịch sử; quy trình mới áp dụng từ yêu cầu07/10.

Ruleset `NoteTogether master quality gate` có template tại .github/rulesets/master.json:
target default branch và master, Active, không bypass actors; cấm xóa/force-push; require PR,
1 approval từ người khác sau push cuối, dismiss stale approvals, giải quyết review threads.
Required checks nguồn GitHub Actions(app15368): Flutter quality, Backend tests, Build smoke;
strict up-to-date với base. Dùng merge commit để giữ lịch sử meaningful commits, không squash
hoặc rebase qua ruleset này. Không yêu cầu signed commits/CodeQL/deployment khi chưa có hạ tầng.

Repo hiện public, Actions enabled; hai người có quyền ghi là bahungTDTU và Long-D176 theo
API inventory. Người tạo PR không tự approve PR của mình. Có quyền repo không chứng minh
contribution hoặc review thực; không dùng tài khoản/approval giả. Admin vẫn có thể sửa cấu hình
repo, nhưng không có bypass actor trong ruleset đã chọn.

## CI và nghiệm thu

.github/workflows/quality.yml chạy mọi PR tới master, push/merge tới master và manual dispatch;
không path filters bỏ qua required checks. Contents token read-only, concurrency hủy run cũ,
timeout hữu hạn; actions pin SHA đọc từ publisher tag, Flutter3.47.1/Python3.12/Java21.

- Flutter quality: lockfile enforced, format lib/test/integration_test/test_driver, analyze, full tests.
- Backend tests: install requirements pinned rồi chạy toàn bộ backend/tests.
- Build smoke: compile Web/static offline manifest và Android debug APK. Đây là compilation
  check, không production signing/release/deploy; không upload hoặc gửi artifact cho dịch vụ khác.

Không dùng local PASS để giả status CI hoặc bỏ rule khi CI lỗi. Pipeline hosted cần download
toolchain từ vendor; nếu bootstrap/network/package lỗi, giữ PR blocked và sửa đúng nguyên nhân.
UI/API/native checks theo phạm vi thay đổi vẫn cần local QA; CI build/test không thay physical,
screen-reader, provider, public HTTPS hay nghiệm thu full rubric. Required check được GitHub
thực thi theo trạng thái Actions; báo kết quả thực trong evidence, không giả green.

## Cách làm việc

```powershell
git switch master
git pull --ff-only origin master
git switch -c codex/mo-ta-thay-doi
powershell -ExecutionPolicy Bypass -File scripts/check.ps1
git add -- <cac-file-can-commit>
git commit -m "Mo ta thay doi"
git push -u origin codex/mo-ta-thay-doi
```

Tạo PR với problem/behavior/validation và attach vào task. Chỉ merge sau review code,
local checks phù hợp + required CI đạt ở commit mới nhất, base cập nhật, hết conflict và có
approval hợp lệ. Không bật auto-merge khi chưa có kiểm tra/review; yêu cầu “push” không tự
chuyển thành merge. Không gửi lời nhắc/nhắn reviewer nếu người dùng chưa yêu cầu.

Sau clone có thể đọc template/AGENTS để kiểm tra chính sách; server ruleset mới là enforcement.
GitHub docs: [available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets),
[REST rulesets](https://docs.github.com/en/rest/repos/rules#create-a-repository-ruleset).
