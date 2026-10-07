# Hướng dẫn tiếp tục NoteTogether

Đọc PROMPT_CHO_AGENT.md, đề PDF gốc nếu có, STATUS.md và matrix trước sửa. Yêu cầu người dùng
đã xác nhận trong TEAM_CONTRIBUTIONS; không lặp hỏi repo/cloud trong lúc chưa sẵn có.

Một Flutter project Web/Android, ChangeNotifier controller, FastAPI/SQLite local, Sembast local.
Không chép app/module hoàn chỉnh từ repo khác. Không đổi owner/permission/protection qua payload.
Không biến mock/email memory thành claim production. Không fake AI/Git/commit/video/timestamp.
Không push/deploy/tốn phí/nộp bài khi chưa được ủy quyền. Git đã có initial import35ee911
lên bahungTDTU/final-flutter; author/committer Bahung theo người dùng, không giả teamwork/authorship.

Quy trình Git người dùng yêu cầu07/10: từ giờ chỉ push branch làm việc, mặc định codex/<mô-tả>;
không push trực tiếp master/default branch, không force-push hoặc bypass ruleset. Tạo PR vào
master và attach PR vào task. Trước merge: local checks phù hợp PASS, ba required CI checks
Flutter quality/Backend tests/Build smoke PASS trên code mới nhất, branch cập nhật với master,
mọi review thread giải quyết và1 approval từ người khác sau push cuối. Giữ merge commit để
không squash mất lịch sử contribution; không tự approve bằng tài khoản người khác. Yêu cầu
“push” chỉ xuất bản branch/PR; không coi là yêu cầu merge ngay. Xem docs/BRANCH_WORKFLOW.md.

Lệnh thật: `scripts/setup.ps1`, `scripts/check.ps1`, `scripts/start_backend.ps1`, `scripts/start_web.ps1`,
`scripts/build.ps1`. Flutter executable discovery trong toolchain.ps1, Python dependency versions pinned
backend/requirements.txt. Đọc README trước chạy integration (cần backend và thiết bị thật/emulator).

Sau thay đổi: format/analyze/tests phù hợp, test direct API với owner/viewer/editor/stranger,
actual browser/native nếu claim. Thêm evidence date/command/target/result/commit; chưa chạy ghi chưa chạy.
Không tăng coverage bằng test mirrors. Không sửa GeneratedPluginRegistrant.java bằng tay.

Editor đã freeze base revision lúc mở; giữ invariant này và regression test.
Preferences đã có pending_preferences theo account + POST /me/preferences/sync; giữ immutable operation
và server field merge/idempotency. Chính sách last-server-accepted chỉ dành preferences; xem docs/PREFERENCES_SYNC.md.
Ưu tiên ngay: giữ local draft khi lock remote bằng encrypted recovery; durable/reopen/outbox race tests;
SMTP real + avatar + server labels; lock UI/cache; private attachments; shares/realtime; LLM;
HTTPS/release signing và submission. Giữ README.md/Readme.txt/STATUS/matrix khớp code.

UI: đọc docs/UI_UX_DESIGN.md và UI_UX_QA.md. Tokens/theme ở design_system.dart,
font NotoSans bundled/OFL; previews.dart chỉ fixture, không nối production navigation.
Giữ home scroll/filter, editor ID/base revision/selection khi theme/resize. Banner mobile gọn;
Trước unlock, title/content/labels/date và danh tính/thời điểm/người nhận chia sẻ không trong
visual/semantics/cache danh sách. Người dùng xác nhận07/10 cho hiện pinned_at (giữ thứ tự ghim)
và shared boolean khi khóa; không hiện số người chia sẻ. Full protected content chỉ trong
reader có grant và password-encrypted vault. Không claim screen reader/history/deep link từ widget test.
Evidence UI ở evidence/2026-10-01-ui; repeat checks chỉ khi có thay đổi/rủi ro mới.
