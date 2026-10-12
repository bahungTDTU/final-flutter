# Các gate còn lại —12/10/2026

Đã commit/push mốc native/Web acceptance và947802a production guard/backup preparation.
Clean clone đúng947802a PASS setup/format/analyze/270Flutter/142backend/Web local/debugAPK.
Hai UI Web độc lập PASS dirty conflict→newUUID copy và revoke→private recovery→newUUID,
backend kiểm tra original không bị ghi đè và ACL404 giữa các bản sao. Bằng chứng mới:
[evidence](../evidence/2026-10-12-clean-clone-two-ui/INDEX.md).
Không có thay đổi nghiệp vụ pending trong working tree; chưa thể đóng toàn lộ trình.

| Gate | Đã có | Còn cần để đóng |
|---|---|---|
| Merge PR8 | CI3/3 PASS tại947802a, không conflict | Approval của người khác sau push cuối, resolved reviews; newest-head CI khi thêm evidence |
| N01 | Quill/native injected input, autosave, Web rich text | IME Android Telex/VNI thật, selection/paste/format/theme/resize trên native |
| N02 | Web reload offline/reconnect cùng UUID/Delta, native encrypted DB reopen | Force-stop/relaunch process OS thật rồi reconnect, không mất rich draft |
| N03 | Native socket/SSE/frozen409, hai WebUI conflict/revoke/private copies | UI remote lock/delete/downgrade variants, native independent UI peers theo phạm vi rubric |
| N04 | Native unlock/change/disable, encrypted offline/revalidation, injected lifecycle | TTL thực, OS background/relock và visual/semantics/cache inspection trên artifact cuối |
| N05 | HTTP file ACL, native session migration/logout401/relogin giữ draft | OS picker protectedTXT/avatar/cancel/error, AND labels/rename, đổi mật khẩu account→oldtoken401 trên hai target |
| P01/P02 | Core/provider adapters và fixture tests | SMTP Internet/inbox receipt, Gemini key mới/project được nhóm cấu hình; UI/evaluation thật |
| R01 | Explicit HTTPS origin guard, missing signing fails, no debug fallback | Keystore do nhóm quản lý, inspect certificate và install/run signedAPK |
| R02 | SQLite/mailkey/WAL backup→new copy restore, actualHTTP file/hash/ACL PASS | Docker engine hoạt động; build/context/image inspection và volume recreate/restore thật |
| R03 | Compose loopback recipe, provider configuration hướng dẫn | Hosting/tên miền HTTPS của nhóm, proxySSE, independent network/core+AI hai bản release |
| R04 | Clean source clone .git/setup/check/Web local/debugAPK PASS | Clean build/run bản production sau public config/signing; không suy localdebug là release |
| S01 | Submission checklist/runbook | Rubric.xlsx gốc, video1080p hai thành viên/timestamps thật, Insights, URL/APKrelease, ZIP/unpack validation |
| T01 | Git commits đúng tác giả, công khai AI hỗ trợ | Nhóm xác nhận phân công/contribution thực và tự giải thích/sửa được code; không tạo lịch sử4tuần giả |

## Đầu vào còn thiếu

- GitHub: một thành viên khác review/approve PR8 sau push cuối. Không dùng bot COMMENTED
  thay approval, không đổi ruleset hoặc tạo approval bằng tài khoản người khác.
- Nhóm chọn tên miền/hosting và cấu hình SMTP/Gemini ở backend; chỉ thông báo nơi/khả năng
  cấu hình, không gửi secrets vào chat. `.env`/keyfile/keystore luôn ignored/private.
- Docker Desktop đã thử khởi động nhưng Linux engine pipe không xuất hiện; cần máy có
  engine hoạt động. Không tự chấp nhận EULA, đổi WSL/BIOS hoặc restart máy người dùng.
- Keystore/private config của nhóm để ký release. Chưa tạo khóa nộp bài thay nhóm.
- Rubric/PDF/video chưa thấy trong tracked repo, workspace Documents hoặc attachments
  được cung cấp. Cần bản giảng viên và đầu ra thực của nhóm; matrix không thay Rubric.

Các thao tác QA native IME/OS picker/force-stop cần UI thiết bị được điều khiển phù hợp
hoặc nhóm thực hiện theo runbook; hiện chỉ browser UI và integration harness đã nghiệm thu.
Không thay các gate này bằng assertion fixture hoặc injected lifecycle.

Nguồn quy trình merge: [AGENTS.md](../AGENTS.md), [branch workflow](BRANCH_WORKFLOW.md).
Nguồn kỹ thuật/config: [release/backup runbook](RELEASE_AND_BACKUP.md),
[roadmap](LOCAL_BASELINE_AND_ROADMAP.md), [current-source QA](CURRENT_SOURCE_ACCEPTANCE.md).
