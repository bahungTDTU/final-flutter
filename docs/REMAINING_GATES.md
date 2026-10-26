# Các gate còn lại — cập nhật19/10/2026

## GitHub và hiệu năng danh sách — 23/10/2026

PR15 đã merge; master9003d65 và ba CI PASS, không PR mở/GitHub Releases.
API reviews PR15 rỗng, không suy merge thành có approval. Chưa đủ điều kiện nộp:
public HTTPS, signed native release, SMTP/LLM thật, Rubric/video/Insights vẫn cần.
Sửa backend tránh quét ghi chú tài khoản khác: fixture49visible +20kunrelated,
median11,313→0,354ms, ~905400→7200SQLite steps; không phải FPS/load production.
PASS153backend tests, listing6tests và HTTP4roles. Backend-only,
chưa push bản sửa mới, không đổi client/ACL/schema. [Báo cáo](SUBMISSION_PERFORMANCE_AUDIT_2026-10-23.md).

## Publication tiếp nối —19/10/2026

PR10 đã merge vào master db64d74 trong lúc thực hiện bàn giao. Ba commit C0/native
được giữ nguyên và tích hợp master trên nhánh nghiệm thu native.
Merge không đổi source so với db02a4b; không coi merge là lần chạy test mới.
279Flutter/analyze/format PASS; native OS-core và account-password UI PASS theo INDEX.
CI/approval cần kiểm trên PR/head mới. C1/C2 full UI/IME còn mở do giới hạn nghiệm thu;
Web UI bị chặn bởi lỗi kernel công cụ, không phải kết luận lỗi app.


## N05 account-password native —19/10/2026

Native UI settings→đổi password→manual login mới PASS; current/peer token cũ401,
password cũ401, encrypted session và invalid draft giữ nguyên. Actual debug API36,
input qua driver, không IME. Xem evidence/2026-10-19-account-password/INDEX.md.
Web compile/40staticresources PASS; browser UI chưa chạy do cả CUA/node runtime lỗi
“failed to write kernel assets”. N05 Web/picker/labels và C1/C2 final artifact còn mở.


## N02 core bổ sung —19/10/2026

Android16/API36 debug QA entrypoint PASS force-stop/relaunch PID4558→4729, encrypted
session/store, rich Delta/UUID, invalid draft, immutable pending fingerprint và reconnect
backend đúng một note. Input qua controller/socket refusal, không IME/UI/Wi-Fi toggle.
279Flutter tests/analyze/build debug PASS; source app production không đổi.
Xem evidence/2026-10-19-os-relaunch/INDEX.md và docs/NATIVE_OS_ACCEPTANCE.md.
Full C1/N02 trên editor/release cuối vẫn mở; không suy core probe thành full native PASS.


## Bàn giao C0 —19/10/2026

Đã fetch: master vẫn d59fdfd. PR10 open, head bae3159; GitHub báo ba required
checks success, chỉ bot COMMENTED, chưa có human approval (snapshot trước push mới).
C0 đồng bộ author hiện hành, signing/mail queue docs, tách baseline test/roadmap lịch sử
và bổ sung entrypoint README. Không đổi source app; README/Readme đồng nhất byte.
Kế hoạch và prompt C0–C5 đã lưu trong docs/COMPLETION_PLAN_2026-10-19.md và
PROMPT_6_1_SOL_COMPLETION.md. Evidence: evidence/2026-10-19-handoff/INDEX.md.
Trạng thái runtime: adb chưa có device; AVD taskflow_api36 có sẵn; Docker Linux engine
pipe chưa có. Không coi kiểm tra môi trường là native/container PASS.


PR8/9 đã merge, master d59fdfd. Lượt19/10 sửa thêm kiểm tra mail key/snapshot
và manifest trong backup/restore; xem evidence/2026-10-19-backup-hardening.
Các kết quả kiểm thử12/10 bên dưới là snapshot lúc chạy, không tự áp sang UI mới.

Đã commit/push mốc native/Web acceptance và947802a production guard/backup preparation.
Clean clone đúng947802a PASS setup/format/analyze/270Flutter/142backend/Web local/debugAPK.
Hai UI Web độc lập PASS dirty conflict→newUUID copy và revoke→private recovery→newUUID,
backend kiểm tra original không bị ghi đè và ACL404 giữa các bản sao. Bằng chứng mới:
[evidence](../evidence/2026-10-12-clean-clone-two-ui/INDEX.md).
Không có thay đổi nghiệp vụ pending trong working tree; chưa thể đóng toàn lộ trình.

| Gate | Đã có | Còn cần để đóng |
|---|---|---|
| Publication | PR8/9/10 đã merge vào master db64d74 | Nhánh mới cần PR, CI và approval riêng; không tái dùng approval/CI cũ |
| N01 | Quill/native injected input, autosave, Web rich text | IME Android Telex/VNI thật, selection/paste/format/theme/resize trên native |
| N02 | Web reload; native core QA entrypoint OS force-stop/relaunch, encrypted rich/draft/outbox + reconnect PASS19/10 | Editor UI/main-entrypoint và final artifact OS relaunch; Wi-Fi toggle/physical theo phạm vi |
| N03 | Native socket/SSE/frozen409, hai WebUI conflict/revoke/private copies | UI remote lock/delete/downgrade variants, native independent UI peers theo phạm vi rubric |
| N04 | Native unlock/change/disable, encrypted offline/revalidation, injected lifecycle | TTL thực, OS background/relock và visual/semantics/cache inspection trên artifact cuối |
| N05 | HTTP file ACL, native session migration; native UI đổi password/manual login, current+peer token401/draft PASS19/10 | OS picker protectedTXT/avatar/cancel/error, AND labels/rename; Web password UI và final artifact |
| P01/P02 | Core/provider adapters và fixture tests | SMTP Internet/inbox receipt, Gemini key mới/project được nhóm cấu hình; UI/evaluation thật |
| R01 | Explicit HTTPS origin guard, missing signing fails, no debug fallback | Keystore do nhóm quản lý, inspect certificate và install/run signedAPK |
| R02 | SQLite/mailkey/WAL backup→new copy restore, actualHTTP file/hash/ACL PASS | Docker engine hoạt động; build/context/image inspection và volume recreate/restore thật |
| R03 | Compose loopback recipe, provider configuration hướng dẫn | Hosting/tên miền HTTPS của nhóm, proxySSE, independent network/core+AI hai bản release |
| R04 | Clean source clone .git/setup/check/Web local/debugAPK PASS | Clean build/run bản production sau public config/signing; không suy localdebug là release |
| S01 | Submission checklist/runbook | Rubric.xlsx gốc, video1080p hai thành viên/timestamps thật, Insights, URL/APKrelease, ZIP/unpack validation |
| T01 | Git commits đúng tác giả, công khai AI hỗ trợ | Nhóm xác nhận phân công/contribution thực và tự giải thích/sửa được code; không tạo lịch sử4tuần giả |

## Đầu vào còn thiếu

- GitHub: một thành viên khác review/approve PR mới sau push cuối. Không dùng bot COMMENTED
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
