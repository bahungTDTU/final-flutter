# Hai ưu tiên cao — 07/10/2026

Đã xử lý F1/F2 của audit07/10 ở phạm vi local, giữ các thay đổi UI có sẵn.
Base `f8ff8fa` + working changes chưa commit/push; release tiếp tục để cuối.

## Dùng chung giới hạn mật khẩu

`verify_note_password()` ở backend/app.py dùng scope bền hiện có `unlock:<user>:<note>`
cho unlock và kiểm tra mật khẩu hiện tại khi đổi/tắt bảo vệ. Counter được dùng chung
giữa các session cùng account và qua backend restart; viewer/editor vẫn không có quyền
đổi/tắt bảo vệ. Mỗi account/note có counter riêng.

5 lần sai trả403 và được commit; trong60 giây tiếp theo mọi lần thử ở cả ba thao tác
đều429, gồm mật khẩu đúng, với Retry-After. Hết cooldown bắt đầu cửa sổ5 lần mới;
thành công xóa counter. Protection/version/revision/grants không đổi khi bị từ chối.
Đổi/tắt thành công vẫn vô hiệu grants theo policy cũ. Enable note chưa bảo vệ vẫn
owner-only, có confirmation và không yêu cầu mật khẩu hiện tại chưa tồn tại.

UI đổi/tắt bảo vệ hiển thị thông báo đợi một phút. Không đổi password account/session
storage ở đợt này; F5 vẫn là việc riêng.

## Ghim và chỉ báo khi khóa

Người dùng trực tiếp xác nhận07/10: cho hiện ghim/chia sẻ và giữ thứ tự ghim khi khóa;
tiếp tục ẩn title/content/labels và thông tin người chia sẻ. Quyết định này thay policy
cũ ẩn toàn bộ metadata trước unlock. AGENTS/README/STATUS/matrix/security/UI docs đã
ghi policy mới; các báo cáo/ảnh/log cũ giữ nguyên phạm vi lịch sử.

Locked listing chỉ có6 fields: `id, locked, revision, role, pinned_at, shared`.
`shared` là boolean, không phải số người nhận. Không trả title/content/labels/updated_at,
owner identity/recipients/shared_at. Grant sống cũng không mở rộng response danh sách;
read/edit/delete/files/shares/AI vẫn kiểm tra grant và role như trước.

Home giữ thẻ trung tính và thông báo mở khóa; chip ghim + icon chia sẻ + icon khóa có
thể xuất hiện đồng thời trong list/grid, kèm nhãn semantics. Tooltip khi khóa không
hiện số người nhận. Comparator/section dùng pinned_at cho cả note thường và bảo vệ,
pin mới trước pin cũ, tie-break theo ID. Search/label filter không đọc private fields.
Unpinned locked note tiếp tục không hiển thị thời gian sửa; không claim đã công khai
toàn bộ metadata hoặc đủ mọi nhánh của rubric17 trên bản cuối.

Note.fromListingJson/toListingJson sanitize cả record cũ khi mở/cache/sync; title/body/
labels/identity không đi vào ordinary listing snapshot. Codec Note.fromJson/toJson
đầy đủ vẫn phục vụ reader có grant và password-encrypted vault; không làm mất protected
draft/operation/base revision. Immediate lock/423 fallback cũng giữ public pin/shared
trước khi refresh server. SSE unpin/revoke/share cập nhật listing cache theo nguồn mới.

## Kiểm chứng

| Target | Kết quả | Phạm vi |
|---|---|---|
| scripts/check.ps1 |173 Flutter/93 backend PASS, format/analyze sạch |6 Flutter mới,5 backend mới;1 upstream TestClient warning |
| Final format/analyze |81 files0changes; analyzer sạch |Bao gồm integration mới sau khi bổ sung; không rerun toàn bộ suites chỉ vì thêm docs |
| Backend regressions |Mixed unlock/change/disable errors, all-action429, other-session/restart, expired-window reset, current-role rules/public flags |Real Argon2/temp SQLite/TestClient; clock điều khiển chỉ trong test cooldown |
| Actual HTTP8016 |Owner/editor/viewer/stranger PASS; minimal fields, read423, viewer403/stranger404, editor không sửa owner pin, unpin/revoke/re-pin, all-action429 |Disposable accounts/SQLite; no mail/LLM |
| IAB Web debug7365 |1280×900 grid/list +390×844 list,3 flags before unlock, persisted list/reload, SSE clear/restore flags |Actual UI/HTTP; protected-card title/body/identity/counts che; ordinary fixture body có cùng chuỗi mẫu nên không dùng global text absence để suy privacy |
| Android API36 debug |1new workflow +teardown PASS7s,4PNG: grid/list/cooldown/platform keys/Sembast encrypted close-reopen/socket65530 offline |Skia software; không OS force-kill/Wi-Fi toggle/physical/default-renderer/release |
| Existing protected regressions |Frozen base/draft/recovery/immutable op/lost ACK/account-field merge giữ PASS trong bộ đầy đủ |Không đổi preferences LWW hoặc quyền trong payload |

Analyzer loại tmp/evidence (generated harness và frozen audit snapshots) khỏi source scope;
lib/test/integration_test/test_driver vẫn được kiểm tra đầy đủ. Không tắt lint của mã app/tests.
Các QA script hiện có được cập nhật contract6 fields, giữ exact-field/privacy assertions.

Actual QA commands/logs/screenshots/checksums:
[evidence/2026-10-07-protection-status/INDEX.md](../evidence/2026-10-07-protection-status/INDEX.md).
Các lỗi test fixture/locator ban đầu được giữ trong logs, không gọi là PASS.
Gemini/mail Internet/public HTTPS/video/physical/accessibility audit/FPS chưa chạy ở đợt này.
