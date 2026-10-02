# Kế hoạch kiểm thử

Không dùng pass backend hoặc mock để suy ra Web/native pass. Kết quả thật: STATUS + evidence.

## Bộ đã có
- Backend pytest: registration/unverified, token verify/reset expiry/reuse, session revocation,
  password hashes, profile/preferences, immutable idempotency, revision/delete conflict,
  owner/viewer/editor/stranger, locked list redaction, session-bound/versioned/expired grant,
  failed unlock cooldown, replay after revoke/lock. TestClient dùng DB SQLite thật trong tmp,
  adapter ghi thư được inject chỉ trong tests; main không mailbox. Email transport tests mới
  dùng socket SMTP local thực + STARTTLS/SSL/certificate, không chứng minh internet delivery.
- 4 Dart unit: pin/time/tie-break, invalid draft, immutable outbox/base revisions, account namespace/logout.
  HTTP offline fake + memory store được ghi rõ; chưa phải durable disk bằng chứng.
- 5 widget: unverified không chặn tạo note, auto-save validation, delete cancel/confirm, compact layout,
  editor giữ base revision cũ khi remote update.
- integration_test/note_flow_test.dart: real backend + Sembast; register → editor auto-save →
  GET server → close/open database → verify content; actual backend-unreachable port → edit/create offline
  → close/open database → reachable backend sync. Đây là real socket, không HTTP mock; không OS process restart.

## Gates
Preferences (ID8): backend field-merge/idempotency replay/isolation/restart/validation;
controller offline reopen + in-flight edits; settings theme/pending/logout widget;
native real-backend offline preferences/reopen/reconnect/second-session update.
Kết quả lượt này riêng: evidence/2026-10-01-preferences (12 Flutter tests,14 backend tests,1 integration).

`powershell -ExecutionPolicy Bypass -File scripts/check.ps1`.
Build Web/APK: scripts/build.ps1. Integration target command chỉ bổ sung vào README khi đã thử thật.
Không coi 3+3+1 là toàn bộ nghiệm thu 32 mục.

## Cần bổ sung
OS force-kill/relaunch Android và physical-device offline; full two-device conflict/race;
subscription race; protected attachment actual UI/full cache guards; internet SMTP receipt/outbox
(UI mã + TTL/reuse đã QA qua local TLS fixture hai target); OS picker denial/cancel và avatar quota/rate limiting;
AI Summary/Q&A nhiều nguồn, thiếu dữ liệu, prompt injection,
revoke/lock trước/sau generation; browser Back/deep link/refresh; text scaling/keyboard/
landscape; release APK install/run; sạch source reinstall; public HTTPS từ mạng độc lập.

Evidence mỗi lần: date, target, exact command/scenario, expected/actual, version, commit
(hiện chưa có commit), test double/service thật, logs/screenshots không chứa token/content riêng tư.

## Email increment 01/10/2026

71 Flutter/22 backend PASS trong scripts/check.ps1. SMTP socket tests không phải mock send;
RecordingDelivery chỉ dùng để inject failure/resend/known-vs-unknown. Android email_flow_test.dart
PASS real API8011/TLS SMTP8025 + platform vault/Sembast; debug emulator, không physical/release.
Chrome release390x844 verify/reset/manual-login + API/SQLite assertions PASS. Fixture reader8026
chỉ nhận disposable @example.test và không nhập production app. Lệnh/phạm vi đầy đủ ở
evidence/2026-10-01-email/INDEX.md và docs/EMAIL_DELIVERY.md. Frozen editor/recovery tests giữ nguyên.

## Avatar/label increment 01/10/2026

81 Flutter/29 backend PASS:10 Flutter mới cho stable legacy IDs/immutable payload, offline reopen,
in-flight rename, duplicate resolution/new note op/draft, label dependency + remote-lock recovery,
avatar account-switch response/cache, cancel/denied picker và scale2/filter ID. HTTP race/picker
denial dùng doubles, không claim OS denial. Backend7 mới (PNG/JPEG param) dùng direct API owner/
viewer/editor/stranger, CAS race/journal/restart/migration/locked metadata và canonical/type/size/private access.
Android avatar_labels integration PASS với actual DocumentsUI/file_selector/API/platform keys/
Sembast close/reopen + offline label/draft/peer/delete/default. Native assign/offline rename đi
qua controller, create/delete/avatar qua UI. Chrome release actual chooser/create/editor label/
selected-filter rename/offline reload/reconnect/peer/delete/default PASS với API/SQLite assertions.
Evidence/2026-10-01-avatar-labels; AVATAR_AND_LABELS.md. OS kill/physical/release signing/public
HTTPS/full keyboard/screen-reader/permission denial chưa nghiệm thu. Đây không phải full32 gates.

## Attachment increment 01/10/2026

88 Flutter/40 backend PASS; thêm7 Flutter +11 backend. Direct API owner/editor/viewer/stranger/
anonymous, grant theo session/revoke/replay, private headers/range, altered ID/delete tombstone/
note cleanup/restart, type/signature/size/count/canonical metadata và khóa trong normalize trước
commit. Flutter account switch bỏ late binary, retry immutable không note outbox/revision, lifecycle/
permission hide, viewer controls, picker denied/cancel/scale2 doubles, peer-deleted image preview
và remote-lock che tên/vô hiệu open delete-confirm.
Native attachments_test actual DocumentsUI picker, private image/native H264 position>0,
SAF save/hash, UI delete/peer delete giữ note revision/content; peer MP4/TXT upload dùng API;
lock khi xóa-confirm → tên che/nút disabled, tắt khóa giữ content/protection revision đúng.
Chrome release actual chooser3 files/Blob image-video/download hash/UI delete/peer lock + API/
SQLite assertions; final-source peer-delete preview riêng. Không claim full OS permission denial,
protected-reader attachment UI, release/physical/OS force-kill/media durability/public HTTPS.
Commands/fixtures/logs: PRIVATE_ATTACHMENTS.md và evidence/2026-10-01-attachments/INDEX.md.

## Sharing increment 02/10/2026

97 Flutter/48 backend PASS;9 Flutter/8 backend mới. Atomic registered-email batch, CAS/journal/
replay-after-revoke/restart/grant/strict owner payload; metadata recipient-only/locked redaction.
Immutable pending retry, account-switch late response, background poll blocked, scale2 modal/
revoke-confirm, real host Sembast encrypted recovery/reopen, readonly downgrade and open
attachment delete-confirm disabled. Một lỗi editor viewer+locked điền lại title đã được sửa;
encrypted_recovery_test giữ assertion controller rỗng.

Android sharing_test actual API8000 + platform keys/Sembast + unreachable socket65530 PASS:
UI batch2/role dropdown/recipient metadata/editor edit; peer API viewer/revoke; readonly/hidden
editor; encrypted offline reopen/recovery UI UUID mới. Chrome actual local release owner batch/
missing-email/role/revoke-confirm, recipient metadata/editor draft/reload/recovery, API404/revision
assertions. Final source/build/hash và mọi giới hạn: evidence/2026-10-02-sharing/INDEX.md,
SHARING_AND_PERMISSIONS.md. Poll15s không subscription; protected-reader share UI, OS kill,
physical/release functional/full screen reader/public HTTPS/video chưa nghiệm thu.

## Realtime increment 02/10/2026

106 Flutter/53 backend PASS,9/5 mới; format/analyze sạch. Backend SSE dùng uvicorn/httpx TCP
thật, auth header/query denied/Origin/caps/disconnect, owner-editor-viewer/stranger, revoke cuối
rồi stop new edits, locked redaction/session termination, rollback/replay/counter persistence.
Flutter chunk parser/strict payload/reconnect/dedup/account stop/expiry/foreground; signal khi
GET đang chờ không bỏ lượt refresh, draft giữ; clean editor selection/rebase explicit và dirty
frozen operation base. Đây là meaningful races, không coverage mirrors.

Android integration/realtime_test.dart dùng SSE/API8000/platform key/encrypted Sembast thật:
clean UI update, editor save→peer controller update, lifecycle stream reconnect, concurrent409
giữ typed content/base4, viewer/revoke chuyển recovery, offline socket65530/DB reopen còn dữ
liệu. Chrome owner/editor contexts riêng, final Web source/automatic updates/server restart/
permissions có scope từng stage trong evidence/2026-10-02-realtime/INDEX.md. Cancellation
socket lỗi native ban đầu đã sửa trong stream parser/await-cancel cleanup; không coi log fail
là PASS. Pub get sau integration→release build, không patch generated Java. Protected-reader
actual realtime/full two-device load/OS kill/physical/release functional/HTTPS/video chưa chạy.
