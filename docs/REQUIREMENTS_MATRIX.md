# Ma trận yêu cầu 32 tiêu chí

Publication workspace/planner10/10 được người dùng ủy quyền trên `codex/workspace-planner`,
base master13e0ffc sau merge PR#3;250 Flutter/109 backend/local gate PASS, code hashes khớp.
Xem evidence/2026-10-10-workspace-publication. Các trạng thái chưa push trong snapshots sau là
trước publication; CI mới nhất/approval vẫn phải kiểm tại PR, không tự merge/đóng release gates.

Planner/motion10/10 theo yêu cầu ngoài rubric: Kanban ưu tiên/ngày hạn/tìm-lọc, responsive
ba cột/dropdown, entrance/press/progress finite + reduced motion, lock/revoke/calendar privacy.
250 Flutter/109 backend/analyze sạch PASS; tổ chức local encrypted, không đổi server ACL/note.
Chrome4viewport/light-dark/filter/edit/reload/calendar remote lock/cache SHA256 PASS;15ảnh,
Web default/API8000 + APK debug compile PASS. Không chạy native UI/FPS mới.
WORKSPACE_PLANNER_AND_MOTION.md và evidence/2026-10-10-planner-motion. Hỗ trợ trải nghiệm
29/30/31 và sáng tạo; không tự tăng tiêu chí/điểm, không đóng native/FPS/release/provider gates.

Tập trung/UX10/10: Pomodoro, daily goal/7-day history và task search/scope/progress;
form save failure giữ input, delete confirmation, adaptive dropdown/chữ lớn. Ngoài
rubric, hỗ trợ29/30/31. Gate242 Flutter/109 backend; WORKSPACE_FOCUS_AND_UX.md.
Timer local encrypted, không OS alarm/cloud sync/native runtime claim.
Chrome loopback + backend thật PASS: timer reload, checklist GET, forms và4viewports;
Web/APK debug compile, cache SHA256/40static PASS. Ảnh/logs: evidence/2026-10-10-workspace-polish.
Các kiểm thử không thay nghiệm thu native UI/IME/FPS/release/provider thật.

Đối chiếu code ngày10/10/2026: base `a5e5ec6` + working changes ordering và workspace sáng tạo.
IMPLEMENTED là đã có mã; PASS chỉ trong phạm vi test/evidence ghi ngày, không tự chấm điểm.
Tiêu chí17 đã sửa unpinned locked date order bằng server array order, không thêm ngày vào
locked list/cache; NOTE_LIST_ORDERING.md và evidence/2026-10-10-ordering-and-docs.
Gate ordering10/10: format/analyze sạch,215 Flutter/109 backend PASS; direct HTTP4roles + Chrome
ordering/offline/reconnect/mobile và Web compile PASS. Native/FPS/IME không chạy lại đợt này.
Các hàng dưới đây mô tả hiện trạng; snapshots theo ngày giữ kết quả lịch sử. Editor/theme
đã publication10/10 ở PR#3; bản sửa mới chưa push. Release/provider thật/video/teamwork vẫn
còn gate riêng, không coi mã hoặc compile là hoàn thành toàn bộ tiêu chí.

Workspace sáng tạo10/10: Ctrl+K/favorites/recent/smart views/checklist board/custom templates/
journal/import-export. Tổ chức cá nhân local encrypted, không cloud claim; notes/tasks/import
qua sync và ACL hiện có.234 Flutter/109 backend/analyze sạch PASS; Chrome actual download/
offline import/reload/reconnect đúng fresh IDs; Web/APK debug compile PASS. Bổ sung trải
nghiệm cho9/10/19/22/29/30/31 và mục sáng tạo, không tăng số tiêu chí hay tự chấm điểm.
Xem PRODUCTIVITY_WORKSPACE.md và evidence/2026-10-10-productivity-workspace. Release/
provider thật/teamwork4weeks/video/native runtime source mới giữ gates riêng.

Editor trực tiếp09/10 sau theme: PC và phone bố cục riêng; rich formatting được lưu qua
content string versioned, không đổi ACL/revision/immutable outbox. Projection visible text
cho search/card/AI, protected reader dùng cùng workspace sau unlock. Cải thiện trải nghiệm
các tiêu chí9/10/19/22/30; đây là nâng cấp sáng tạo do người dùng yêu cầu. Không đóng gate
teamwork, native runtime/FPS/IME, Gemini thật, release/signing/HTTPS hay submission.
Kết quả source hiện tại: ADAPTIVE_DOCUMENT_EDITOR.md và evidence/2026-10-09-document-editor.
Các số đo/số test trong snapshots dưới đây thuộc các phiên bản trước.

Theme cohesion09/10, sau publication UI/performance: app bar/auth/editor/protected/AI/
studio/dialog/sheet/form/navigation/feedback cùng palette dashboard light/dark.198 Flutter/
94 backend/analyze/HTTP4roles PASS, Chrome12luồng/4viewport/24ảnh,0console errors/warnings.
Web compile/offline40static/APK debug compile PASS. Cải thiện evidence UI các tiêu chí
9/10/19/22/30; không đóng gate native UI/FPS/Gemini thật/release/submission của source mới.
Xem THEME_WIDGET_COHESION.md và evidence/2026-10-09-theme-cohesion; base717f0ab + working changes.
Các kết quả benchmark bên dưới thuộc source trước khi đổi theme toàn app.

Benchmark bổ sung09/10 sau dashboard:3 native workflows API36 debug và2 profile workflows
500notes/30labels PASS. GPU host Impeller OpenGLES52.6–56.7FPS, raster p95=23–28ms; target
60FPS chưa đạt đều, physical/native presentation chưa chạy. Web12samples/5search/filter
và HTTP4roles PASS, rAF không GPU FPS. Bổ sung bằng chứng tiêu chí9/10/19/22/29/30, không
đóng release/submission gates. Xem PERFORMANCE_BENCHMARK.md/evidence2026-10-09-frame-performance.

Dashboard color09/10 theo phản hồi ảnh: indigo sidebar/gradient header/rich pastel cards/amber
notice/static facets, opt-in; locked neutral/copy/state giữ nguyên.198Flutter/analyze/HTTP4roles
PASS, Chrome6viewport + Web compile/offline PASS; không native/APK/FPS claim mới. Các tiêu chí
9/10/19/22/30 cải thiện visual/responsive; xem DASHBOARD_COLOR_REFRESH.md và evidence mới.

UI/performance09/10: Home/search/view/labels tách vùng,6 chips nhanh + lazy filter sheet/
search/AND/apply/cancel; CTA mobile không phủ thẻ; chữ200%/keyboard. Shell/theme/hidden Home
20→0 replacements trong probe500notes/20pulses không đổi source; source đổi vẫn purge widgets
riêng tư ở Home bị che ngay khi khóa/thu hồi.198Flutter/94backend/analyze/HTTP4roles PASS,
Web compile/offline40static/APK debug compile PASS.9/10/19/22/29/30 cải tiến; native UI đợt
này chưa chạy, không full rubric/FPS/release claim. Xem HOME_UI_UX_PERFORMANCE.md và evidence
2026-10-09-home-experience; baseef2ece0 + working changes trên codex/ui-ux-performance.

Session07/10(F5): AES-GCM token/profile/device key riêng, legacy migration/compaction trước
Home, durable logout tombstone/retry và rejected-login guard.188Flutter/94backend/analyze
PASS; actual HTTP4roles/API36 debug1workflow+teardown PASS5s/platform keys/legacy/file reopen/
logout401/manual login giữ draft; Web encrypted-session offline reload/logout/manual login/
profile persist và actual API roundtrip PASS.3/30/31 cải tiến;
SESSION_STORAGE.md + evidence/2026-10-07-session-storage, không public/physical/XSS immunity.

Performance07/10 (F3/F4): ordinary drafts dùng encrypted projection + atomic fold, attachment
list/replay SELECT metadata.180 Flutter/94 backend/analyze PASS; actual HTTP4roles và native
API36 debug encrypted reopen/failed socket/reconnect same ID PASS; IAB Web debug offline
reload/restored draft/autosave ACK/actual API revision3→4 PASS.14/15/16/30/31 cải tiến;
không full rubric/FPS/physical/release. PERFORMANCE_DRAFTS_AND_ATTACHMENTS.md + evidence
2026-10-07-performance; các kết quả theo ngày dưới đây là snapshots lịch sử.

Protection/status07/10: shared throttle unlock/change/disable + public pinned_at/shared theo
lựa chọn người dùng; title/content/labels/share identities/counts vẫn redacted list/cache.
173 Flutter/93 backend/analyze PASS; HTTP4roles, actual Web debug list/grid/reload/SSE flags,
Android API36 debug1new workflow+teardown PASS7s/platform encrypted reopen,4PNG.
17/18/23/24 cải tiến, không full rubric/public/video. Xem PROTECTION_STATUS_FIXES.md và
evidence/2026-10-07-protection-status/INDEX.md; policy trước07/10 bên dưới là lịch sử.

UI editor07/10: nhãn cố định/khung nhập/bộ đếm, Sắp xếp và nhóm bảo vệ rõ; geometry chữ200% với NotoSans thật.167 Flutter/88 backend và3 reused native debug workflows PASS;actual IAB input/API ack/theme/resize/protected relock PASS. Cải tiến29/30; không full-rubric/release/FPS/screen-reader claim. Xem EDITOR_SECTIONS_AND_LAYOUT.md và evidence/2026-10-06-editor-sections/INDEX.md.

UI06/10: shared ReadingCanvas/Prism, compact gallery/preview/keyboard spacing, bounded card
shaping/semantics, account/source-aware listing cache + Unicode literal search/debounce.
161 Flutter/88 backend/analyze PASS;3 reused native debug workflows + actual IAB debug
responsive/theme/AI input/protected/search/remote lock PASS; host benchmark có scope riêng.
29/30 cải tiến; không full rubric/FPS/physical/LLM/production claim. Xem
UI_COHESION_AND_PERFORMANCE.md + evidence/2026-10-06-ui-cohesion/INDEX.md.

Sáng tạo06/10:6 template/durable draft, local outline/checklist/progress/read estimate, focus timer.
Bổ sung cho29/30 và trải nghiệm11/12/14; không thêm ID/điểm hoặc thay yêu cầu mandatory.
155 Flutter/88 backend PASS, actual HTTP4roles, IAB Web debug reload/SSE-lock và API36 debug
keys/Sembast/offline reopen PASS. Protected reader chưa nối các công cụ này; no physical/FPS/
screen-reader/release claim. docs/WRITING_STUDIO.md + evidence/2026-10-06-writing-studio/INDEX.md.

Email06/10:146 Flutter/88 backend PASS; transaction outbox/HMAC nonce/private server key,
lease/retry/restart/TTL/resend invalidation; authenticated status/UI + reset request-resend.
Actual HTTP owner/viewer/editor/stranger/TLS receipt, Web debug status/verify/public resend,
API36 debug verify/reset/status/manual login PASS; không Internet mailbox acceptance.
Source/evidence: evidence/2026-10-06-email-queue/INDEX.md. Release được hoãn theo yêu cầu;
các mốc bên dưới giữ phạm vi lịch sử và không được tính thành full rubric.

Nguồn: đề 503107-FinalProject-V1.pdf tr.9–14; đối chiếu 10/10/2026. Tổng 10.0 điểm.
Không tự chấm điểm đạt. Không mục nào hiện được tuyên bố hoàn thành toàn bộ trên cả hai target.
Bảng cập nhật theo code hiện tại; bằng chứng Web/native được ghi riêng theo source và ngày.
Web là local release, Android integration là debug nếu có; build ≠ feature pass ≠ public deployment.
Logs thực theo từng mốc ở evidence và STATUS;01–02/10 trước initial commit (commitnull),
maintenance03/10 base35ee911 + working changes/source hashes.
Repository hiện tại: https://github.com/bahungTDTU/final-flutter; refs/history kiểm tra bằng Git.
Initial import không thay bằng chứng teamwork4 tuần. Video/timestamp: chưa quay cho mọi mục.

Protection05/10:143 Flutter/79 backend PASS; protected edit/autosave/delete, password-encrypted
cache/draft/offline unlock/recovery/revalidate, metadata sau unlock và SSE frozen base.
IAB Web local actual realtime/edit/private TXT picker-upload/hash/share list/offline reload/
reconnect same-ID sync; Android API36 debug real API/SSE/keys/Sembast/offline close-reopen/
confirmed delete. Commands/hashes/scopes: evidence/2026-10-05-protected-notes/INDEX.md.
Các đoạn theo mốc01–03/10 bên dưới giữ scope lịch sử. Native protected picker/media, real
Gemini, OS kill/physical/public HTTPS/release/video/key backup vẫn chưa đủ; không full rubric.

AI05/10: Gemini REST adapter/ACL-before-context + recheck all sources after inference,
Summary/regenerate no-mutation, Q&A BM25 + synthesis/citations/no-data, RAM-only UI/gates.
131 Flutter/73 backend PASS; actual HTTP/Web local/Android debug flow dùng explicit fixture,
không Gemini thật. Key cũ đã xuất hiện trong tool output, không lưu/sử dụng; cần thay/config
key mới. Xem AI_FEATURES.md và evidence/2026-10-05-ai/INDEX.md;27/28 chưa full nghiệm thu.

Maintenance03/10:123 Flutter/56 backend + direct HTTP ACL PASS; batch notes query/detail
parity/lock/current roles/labels, HTTP status/timeout abort, lifecycle guards và sync ID indexes.
Android API36 debug Skia software core/offline/reopen PASS; Chrome actual offline/reload/
reconnect và API ID/count/content assertions; Web/APK builds PASS. Local query benchmark
ở evidence/2026-10-03-maintenance, không nâng thành FPS/physical/HTTPS/full rubric completion.

Prism visual02/10:6 accent tones, iridescent rim/static backdrop, short/reduced motion;
118 Flutter/53 backend PASS,129 selected contrast pairs. Chrome final bundle responsive/auth/
home hover/editor theme-resize/settings; native API36 debug Skia software UI driver PASS.
Direct actual HTTP owner/viewer/editor/stranger PASS; Web/APK release build PASS.
Evidence/limits: evidence/2026-10-02-prism-ui/INDEX.md. Chưa default-renderer/physical/FPS QA.

UI upgrade02/10: adaptive shell/card/writing canvas + management components + Material tiếng Việt;
114 Flutter/53 backend và native registration/labels/theme/editor/sharing với API thật PASS.
Phạm vi Chrome, ảnh trước/sau, artifacts và giới hạn xem evidence/2026-10-02-ui-upgrade/INDEX.md.
Không thay gates screen-reader thật/physical/public HTTPS/video/LLM.

Sharing02/10/2026:97 Flutter/48 backend + Android actual sharing/revoke/offline recovery PASS;
Chrome local release batch/role/recipient owner-time/revoke/reload recovery có API assertions.
18/25/30 cập nhật theo evidence/2026-10-02-sharing; ở mốc sharing chỉ có poll15s. Xem scope/giới hạn
SHARING_AND_PERMISSIONS.md và STATUS. Không thay gates protected-reader/physical/HTTPS/video.

Realtime26 increment02/10/2026:106 Flutter/53 backend PASS, authenticated SSE/transactional
counters/no sensitive payload/ACL/grant/refetch, giữ draft/frozen base và conflict/recovery.
Android API36 debug real SSE/API/reconnect/concurrent409/viewer-revoke/encrypted DB reopen;
Chrome owner/editor contexts/automatic updates/server restart/final-source lock/draft/reload/
recovery có actual evidence. 26/30 cập nhật theo evidence/2026-10-02-realtime/INDEX.md;
protected-reader realtime/physical/release functional/load/public HTTPS/video chưa nghiệm thu.

Durability regression 01/10/2026: evidence/2026-10-01-durability,45 Flutter/14 backend +1 Android
integration PASS. Bổ sung bảo đảm cho12/14 và offline: snapshot trước send, atomic conflict copy/latest draft,
logout/write guard và file reopen. Fault/race dùng HTTP doubles; không nâng trạng thái nghiệm thu.
Encrypted recovery đã triển khai đợt kế tiếp: evidence/2026-10-01-encrypted-recovery,
60 Flutter/14 backend +2 Android integration files PASS; Chrome offline/reload/lock/copy API assertions.
Khóa remote không bỏ local draft/upsert; device vault không thay offline note unlock/key backup.
Online protection UI đợt kế tiếp:67 Flutter/15 backend +1 Android protection integration PASS;
Chrome menu enable/read/relock/change/disable + API assertions PASS. Evidence/2026-10-01-note-protection.
Chưa full23/24: protected editing/offline unlock/key backup; xem NOTE_PROTECTION.md.

SMTP code UI đợt kế tiếp:71 Flutter/22 backend +1 Android email integration PASS;
Chrome release verify/reset/manual login + SQLite/API reuse assertions PASS qua SMTP TLS local.
Evidence/2026-10-01-email. Internet mailbox delivery/outbox/HTTPS chưa nghiệm thu;2/4 vẫn partial.

Avatar/labels:81 Flutter/29 backend + Android actual OS picker integration PASS; Chrome release
actual chooser/label editor/filter/offline reload/reconnect/peer/delete/default + API/SQLite PASS.
Evidence/2026-10-01-avatar-labels; migration schema2/CAS/idempotency/account ACL/private image.
Avatar/label functional local có bằng chứng; physical/release/public/video chưa đủ, không full32.

Attachments:88 Flutter/40 backend + Android actual PNG picker/native video/SAF export/hash/UI
delete/peer-delete preview PASS; Chrome local release actual chooser/image/video Blob/download/
delete/remote lock + API/SQLite PASS. Evidence/2026-10-01-attachments, PRIVATE_ATTACHMENTS.md.
Online-only/RAM retry, private ACL/grant/Range/tombstone; attachments không đổi note revision.
Final-source Web/native remote-lock xóa-confirm che tên/vô hiệu nút PASS; lock/unlock tăng revision đúng.
OS denied/cancel chỉ doubles; protected-reader actual file UI/physical/release/public/video chưa đủ.

| ID | Yêu cầu | Điểm | Màn hình/API/rule | Test / bằng chứng | Web | Native | Deploy/demo | Timestamp | Lỗi tồn đọng |
|---:|---|---:|---|---|---|---|---|---|---|
| 1 | Đăng ký | 0.25 | AuthScreen/register + /auth/register; email/name/password2lần/hash/auto-login | auth/security/email tests; UI/theme/registration evidence01–09/10 | Actual Chrome register/auth validation historical PASS; bản cuối cần regression | API36 debug registration historical PASS; editor source mới chưa rerun native | Chưa deploy/demo | Chưa quay | Inbox Internet/final hai target/physical/release/video chưa nghiệm thu |
| 2 | Kích hoạt tài khoản | 0.25 | TokenScreen/status + transaction mail outbox/lifespan worker | email01/10 + email-queue06/10; actual TLS/retry/key loss/no raw code | Web debug status/verify/banner PASS local TLS fixture | API36 debug queued/status/verify/banner PASS real local TLS | Chưa deploy/demo | Chưa quay | SMTP ngoài/inbox/production worker/HTTPS/physical chưa nghiệm thu |
| 3 | Đăng nhập và đăng xuất | 0.25 | Controller/Auth + encrypted session/migration/tombstone + server sessions | session07/10/file/crypto/failure/race/retry; HTTP roles | Actual debug legacy restore/encrypted offline reload/logout/reload/manual login PASS | Actual debug legacy migration/platform keys/file reopen/logout401/manual UI login/draft retention PASS | Chưa deploy/demo | Chưa quay | Web XSS/full-profile reader; physical/OS kill/release/public/video chưa nghiệm thu |
| 4 | Reset mật khẩu | 0.25 | forgot generic/outbox/reset-check/reset/session revoke + public resend | email-queue06/10; restart/retry/TTL/known-unknown/key-failure guards | Web debug reset request/resend/cooldown; password completion historical/widget | API36 debug real TLS/reset/password2x/manual login PASS | Chưa deploy/demo | Chưa quay | Inbox ngoài/production abuse/physical/full release/HTTPS chưa nghiệm thu |
| 5 | Xem profile/avatar | 0.25 | AccountAvatar/controller + GET /me/avatar | evidence/2026-10-01-avatar-labels; private/cache/account guards | Canonical avatar + offline reload PASS local release | Canonical + encrypted DB reopen PASS debug | Chưa deploy/demo | Chưa quay | Physical/public HTTPS/video/quota/rate limits chưa nghiệm thu |
| 6 | Sửa profile/avatar | 0.25 | AvatarEditor/file_selector + POST/DELETE /me/avatar | API type/size/metadata/CAS; actual Web/native picker | Choose/upload/default PASS local release | Actual DocumentsUI/upload/default PASS debug | Chưa deploy/demo | Chưa quay | OS denied/cancel chưa chạy; widget coverage; upload online-only; public storage/HTTPS chưa nghiệm thu |
| 7 | Đổi mật khẩu tài khoản | 0.25 | Settings + /auth/password; current/new/confirmation, revoke sessions/grants, manual login | Widget validation/error + backend password/session tests | IMPLEMENTED; success UI thật trên bản cuối NOT RUN | IMPLEMENTED; success UI thật trên bản cuối NOT RUN | Chưa deploy/demo | Chưa quay | Cần success→manual login/old session401 trên Web/native; không gọi thiếu evidence là thiếu code |
| 8 | Preferences | 0.25 | settings/controller + POST /me/preferences/sync | 12 Flutter/14 backend tests; Android integration; evidence/2026-10-01-preferences | Chrome release PASS offline/reload/reconnect + SQLite | Debug emulator PASS offline/reopen/cross-session | Chưa deploy/demo | Chưa quay | Chưa production/physical-device/video |
| 9 | List view | 0.25 | Home adaptive list/NoteListingCache + grid preference | Widget geometry/200%/privacy; Chrome/home/frame-performance09/10; ordering10/10 | Actual Chrome mixed locked order/offline reload/reconnect PASS10/10; features khác historical | Historical API36 list/profile09/10 PASS; Quill source mới native NOT RUN | Chưa deploy/demo | Chưa quay | Native source mới/text scale/accessibility thực/release/video chưa nghiệm thu |
| 10 | Grid view | 0.25 | Home adaptive grid/default cards + grid preference | Widget geometry/200%/privacy; Chrome/home/frame-performance09/10; ordering10/10 | Actual Chrome mixed locked order/resize390px PASS10/10; features khác historical | Historical API36 grid/profile09/10 PASS; Quill source mới native NOT RUN | Chưa deploy/demo | Chưa quay | Native source mới/compact/tablet/landscape/physical/release/video chưa nghiệm thu |
| 11 | Tạo note | 0.25 | Editor/DocumentWorkspace + stable UUID/draft/save /sync | domain/durability/document tests; actual editor/Web evidence09/10 | Actual create/input/server ACK historical; rich save/reload PASS09/10 | Actual create/autosave/offline historical; native rich editor mới NOT RUN | Chưa deploy/demo | Chưa quay | Tạo/reopen/sync rich document trên hai bản cuối/lifecycle/physical/video |
| 12 | Sửa note | 0.25 | Editor/ProtectedReader + DocumentWorkspace; /sync ACL/grant/frozen base | durability/realtime/protected/document-editing tests; evidence05/10 +09/10 | Actual rich ordinary/protected edit/save/reload/relock PASS09/10 | Protected core/edit/peer SSE/offline sync PASS05/10 debug; native rich editor mới NOT RUN | Chưa deploy/demo | Chưa quay | Native rich editor/dirty conflict/remote lock/theme-resize trên hai bản cuối/physical/release/video |
| 13 | Xóa note | 0.25 | owner confirm + /sync delete ACL/grant/base | protected dialog revoke + delete409/refetch/reconfirm; API roles | Host revoke dialog + actual HTTP owner delete; protected Web UI delete chưa rerun | Protected owner confirmed delete + GET404 actual debug PASS | Chưa deploy/demo | Chưa quay | Full release/physical/video; no persistent protected-delete queue |
| 14 | Auto-save và lifecycle | 0.25 | Editor/controller + encrypted draft projection/atomic fold | performance07/10;7 file/crypto/race regressions + existing lifecycle | Actual debug invalid draft/offline reload/restored/autosave ACK/same-ID PASS | Actual debug failed socket/encrypted file reopen/restored editor/reconnect same-ID PASS | Chưa deploy/demo | Chưa quay | Immediate local writes + debounce note/outbox; OS kill/full lifecycle/quota/physical/release còn thiếu |
| 15 | Đính kèm ảnh/video | 0.25 | AttachmentsDialog/AttachmentSession + private API/SQLite BLOB | evidence/2026-10-01-attachments; ACL/grant/validation/race/canonical/Range | Actual chooser/upload/image/H264 Blob video/remote lock/peer delete PASS local release | Actual PNG DocumentsUI/upload/image/peer delete + H264 native position PASS debug | Chưa deploy/demo | Chưa quay | Online-only; Protected TXT Web picker/upload PASS05/10; native protected picker/OS denied-cancel/full codecs/physical/release/HTTPS/video còn thiếu |
| 16 | Đính kèm file | 0.25 | PDF/TXT/CSV/ZIP; authenticated download; Android SAF save/delete | API/private retry/tombstone/restart/note cleanup + download hash | Actual TXT chooser/upload/download/delete giữ note content/revision PASS | Actual TXT ACTION_CREATE_DOCUMENT/save hash/UI delete PASS; TXT upload qua peer API | Chưa deploy/demo | Chưa quay | Chưa durable media queue/full OS providers/cancel-denied/antivirus/physical/release/public/video; giới hạn loại/size ghi trong docs |
| 17 | Ghim và sắp xếp note | 0.25 | Server updated_at DESC/id ASC + NoteListing pin grouping/source array; no locked date fields | note_ordering/locked_status/API6fields/real encrypted reopen/in-flight edit/ACK; evidence10/10 | Probe/grid-list host/actual Chrome order/offline reload/reconnect update PASS10/10 | Historical public pin/grid-list/reopen PASS07/10; bản sửa native NOT RUN | Chưa deploy/demo | Chưa quay | Legacy mixed cache cần một successful refresh; offline giữ order gần nhất; release/video chưa đủ |
| 18 | Chỉ báo shared/pinned/locked | 0.25 | Home public pin/shared boolean + locked neutral card; no identities/counts | exact6-field codec/API/privacy/200% widget semantics; protection-status07/10 | Actual debug3flags before unlock + SSE clear/restore PASS | Actual debug grid/list3flags/platform cache reopen PASS | Chưa deploy/demo | Chưa quay | Không title/content/labels/share identities/time/count; no screen-reader/full release/video claim |
| 19 | Live search | 0.25 | Home 300ms debounce/title/visible content/clear + literal Unicode; rich plain projection | note_listing/UI/domain/projection tests; Home/benchmark/document evidence09/10 | Actual query/clear/no-result/rich text excluding format metadata PASS09/10 | Historical API36/search-profile09/10; rich search trên native source mới NOT RUN | Chưa deploy/demo | Chưa quay | Locked content vẫn bị loại; native source cuối/physical/release/video chưa nghiệm thu |
| 20 | Quản lý nhãn | 0.25 | Manager/controller + /labels/sync CAS/journal | API ACL/race/migration/late ops; evidence/avatar-labels | CRUD/offline reload/reconnect/peer/delete PASS | UI create/delete + controller rename/reopen/peer PASS debug | Chưa deploy/demo | Chưa quay | Full conflict UI hai thiết bị/physical/HTTPS/video chưa nghiệm thu; conflicts covered controller/API |
| 21 | Gắn nhãn vào note | 0.25 | Editor IDs + note sync owner rules | Direct owner/viewer/editor/stranger API; immutable dependency/recovery tests | Actual editor assign + rename/delete content/revision PASS | Controller assign/sync/delete content/revision PASS debug | Chưa deploy/demo | Chưa quay | Native editor assignment UI chưa rerun; full two-device release/OS kill/video chưa nghiệm thu |
| 22 | Lọc theo nhãn | 0.25 | Home selected ID AND filters | Widget AND/delete/rename; Chrome selected filter evidence | Rename giữ selected ID/result PASS | Widget filter regression; chưa native filter interaction | Chưa deploy/demo | Chưa quay | Physical/native filter interaction/multiple live-session filter/video chưa nghiệm thu |
| 23 | Bật/tắt khóa note | 0.5 | protection API + password vault + server grants | protection01/10 historical; protection05/10 edit/cache/recovery | Enable/disable historical PASS; advanced protected edit/files/offline reload PASS05/10 | Enable/disable historical; actual protected core/offline/edit/delete PASS05/10 debug | Chưa deploy/demo | Chưa quay | Key backup/transfer/multi-tab/physical/release/public/video còn thiếu |
| 24 | Mở khóa/đổi mật khẩu note | 0.5 | ProtectedReader/unlock + PBKDF2/AES-GCM cache/draft | crypto actual + lost ack/account merge/revoke/recovery/TTL/API password-change | Actual cached offline unlock/edit/reload/password reopen/server revalidation/sync PASS | Actual device keys/Sembast offline password unlock/reopen/revalidation/sync PASS debug | Chưa deploy/demo | Chưa quay | Change UI historical; physical/full accessibility/key backup/public/release/video còn thiếu |
| 25 | Chia sẻ/nhận/quản lý quyền | 0.5 | ShareDialog/ShareSession + owner atomic batch/CAS/journal APIs | evidence/2026-10-02-sharing; direct owner/editor/viewer/stranger/grant/replay tests | Batch/missing email/role dropdown/recipient metadata/revoke/draft recovery actual release | Batch/dropdown/recipient edit/peer viewer-revoke/encrypted offline reopen/new-ID recovery actual debug PASS | Chưa deploy/demo | Chưa quay | Online-only; protected share list Web PASS05/10, mutations historical; full two-device/native protected share/physical/release/HTTPS/video chưa nghiệm thu |
| 26 | Cộng tác realtime | 0.5 | Authenticated SSE + counters + editor/ProtectedReader frozen base | realtime02/10 + protection05/10; actual peer/API + dirty409 unit | Protected actual clean live update/explicit new-base edit PASS; ordinary historical | Protected actual SSE peer update/edit PASS debug; ordinary reconnect/revoke historical | Chưa deploy/demo | Chưa quay | Revision conflicts, không OT/CRDT; physical/release/load/HTTPS/video còn thiếu |
| 27 | AI Summary | 0.25 | AiSummaryDialog/AiSession + GeminiProvider + /notes/{id}/ai/summary; ACL/grant/revision; không overwrite | Backend/Flutter no-mutation/late/gate/error tests; evidence/2026-10-05-ai | Actual local release summary/remote-source invalidation với fixture | Actual API36 debug Skia software summary/regenerate giữ original với fixture PASS | Chưa deploy/demo | Chưa quay | Đã code; Gemini thật chưa chạy; cần thay/config key mới, protected flow/public/release/video acceptance |
| 28 | AI Q&A có nguồn | 0.25 | AiQuestionsPanel/Source open + /ai/questions/retrieve/Gemini schema/citations + /ai/validate | ACL before/after inference/revoke/delete/grant expiry/uncited sources/no-data; AI evidence | Actual local fixture2sources/citation open/no-data/source lock hide PASS | Actual debug fixture2sources/citation mở đúng note PASS | Chưa deploy/demo | Chưa quay | Gemini thật/quality/prompt-injection evaluation chưa chạy; BM25 có giới hạn từ đồng nghĩa; protected/public/release/video còn thiếu |
| 29 | UI/UX/accessibility/adaptive | 0.5 | Shared design_system/prism/localizations; PC/phone DocumentWorkspace; docs/UI_UX_DESIGN | Theme/geometry/200%/privacy/base/draft tests; theme + document evidence09/10 | Actual Chrome rich editor8flows/5viewport/14ảnh PASS09/10; ordering bản sửa xem INDEX | Historical API36 UI/studio/protected/profile; source Quill mới native NOT RUN | Chưa deploy/demo | Chưa quay | NVDA/TalkBack/native IME/physical/FPS current-source/history/deep-link/release-all chưa đủ |
| 30 | Kiến trúc/state/automated tests | 0.5 | One Flutter core/ChangeNotifier/domain/data/UI; API/vault/schema2/SSE/email/AI/ordering | evidence/2026-10-10-ordering-and-docs/check-final.txt; architecture + matrix đồng bộ | Format/analyze sạch/234 Flutter/109 backend PASS10/10; Chrome workspace/ordering scopes riêng | Integration code có; historical actual native PASS; rich editor runtime mới NOT RUN | Chưa deploy/demo | Chưa quay | Clean clone/critical integration source mới/release/full rubric/teamwork còn thiếu |
| 31 | Offline persistence và sync | 0.5 | Sembast/account vault + encrypted ordinary projection + password cache/draft/immutable ops | performance07/10/rollback/lost ACK/lock/empty projection; protection05/10 | Actual ordinary draft offline reload/restored/same-ID sync PASS debug; protected historical local release | Actual ordinary failed socket65530/platform keys/file close-reopen/reconnect same-ID PASS debug; protected historical | Chưa deploy/demo | Chưa quay | Cold first-load/OS kill/Wi-Fi toggle/quota/eviction/multi-tab/key backup/physical/release còn thiếu |
| 32 | Build và public deployment | 0.5 | Flutter Web/Android + backend/Dockerfile/scripts/build.ps1 | Web release/APK debug compile PASS09/10; source sửa Web build xem INDEX | IMPLEMENTED local build/static-only worker; public HTTPS NOT RUN | APK debug compile PASS09/10; final signing/install/run NOT RUN | Chưa public deploy | Chưa quay | Release hoãn theo người dùng; cần public backend/Web, production signing, clean-clone/final artifact |
