# Ma trận yêu cầu 32 tiêu chí

Nguồn: đề 503107-FinalProject-V1.pdf tr.9–14; đối chiếu 02/10/2026. Tổng 10.0 điểm.
Không tự chấm điểm đạt. Không mục nào hiện được tuyên bố hoàn thành toàn bộ trên cả hai target.
Ban đầu chưa triển khai/chưa đo; bảng đã cập nhật theo code/test thực ở lượt triển khai đầu.
Web là local release, Android integration là debug nếu có; build ≠ feature pass ≠ public deployment.
Logs thực theo từng mốc ở evidence và STATUS được chốt trước initial commit (commitnull).
Repository hiện tại: https://github.com/bahungTDTU/final-flutter; refs/history kiểm tra bằng Git.
Initial import không thay bằng chứng teamwork4 tuần. Video/timestamp: chưa quay cho mọi mục.

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
| 1 | Đăng ký | 0.25 | ui/ + state/; backend/app.py | flutter-tests/backend-tests; xem STATUS đúng scope | Đã code một phần; chưa nghiệm thu đủ | Đã code một phần; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Chưa regression đầy đủ Web + native/video |
| 2 | Kích hoạt tài khoản | 0.25 | Home/TokenScreen; verify/resend; email_delivery.py | evidence/2026-10-01-email; SMTP TLS/TTL/reuse/cooldown | Chrome release code/banner PASS local TLS fixture | Debug emulator code/banner PASS local TLS fixture | Chưa deploy/demo | Chưa quay | SMTP ngoài/receipt/outbox/HTTPS chưa nghiệm thu; mã tương đương OTP theo đề |
| 3 | Đăng nhập và đăng xuất | 0.25 | ui/ + state/; backend/app.py | flutter-tests/backend-tests; xem STATUS đúng scope | Đã code một phần; chưa nghiệm thu đủ | Đã code một phần; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Chưa regression đầy đủ Web + native/video |
| 4 | Reset mật khẩu | 0.25 | forgot/reset-check/reset; TokenScreen2 bước | evidence/2026-10-01-email; atomic reuse/session revocation | Chrome release code/password2x/manual login PASS local fixture | Debug emulator cùng flow + note/session assertions PASS | Chưa deploy/demo | Chưa quay | Email ngoài/receipt/outbox/production timing/abuse/HTTPS chưa nghiệm thu |
| 5 | Xem profile/avatar | 0.25 | AccountAvatar/controller + GET /me/avatar | evidence/2026-10-01-avatar-labels; private/cache/account guards | Canonical avatar + offline reload PASS local release | Canonical + encrypted DB reopen PASS debug | Chưa deploy/demo | Chưa quay | Physical/public HTTPS/video/quota/rate limits chưa nghiệm thu |
| 6 | Sửa profile/avatar | 0.25 | AvatarEditor/file_selector + POST/DELETE /me/avatar | API type/size/metadata/CAS; actual Web/native picker | Choose/upload/default PASS local release | Actual DocumentsUI/upload/default PASS debug | Chưa deploy/demo | Chưa quay | OS denied/cancel chưa chạy; widget coverage; upload online-only; public storage/HTTPS chưa nghiệm thu |
| 7 | Đổi mật khẩu tài khoản | 0.25 | ui/ + state/; backend/app.py | flutter-tests/backend-tests; xem STATUS đúng scope | Đã code một phần; chưa nghiệm thu đủ | Đã code một phần; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Chưa regression đầy đủ Web + native/video |
| 8 | Preferences | 0.25 | settings/controller + POST /me/preferences/sync | 12 Flutter/14 backend tests; Android integration; evidence/2026-10-01-preferences | Chrome release PASS offline/reload/reconnect + SQLite | Debug emulator PASS offline/reopen/cross-session | Chưa deploy/demo | Chưa quay | Chưa production/physical-device/video |
| 9 | List view | 0.25 | ui/ + state/; backend/app.py | flutter-tests/backend-tests; xem STATUS đúng scope | Đã code một phần; chưa nghiệm thu đủ | Đã code một phần; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Chưa regression đầy đủ Web + native/video |
| 10 | Grid view | 0.25 | ui/ + state/; backend/app.py | flutter-tests/backend-tests; xem STATUS đúng scope | Đã code một phần; chưa nghiệm thu đủ | Đã code một phần; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Chưa regression đầy đủ Web + native/video |
| 11 | Tạo note | 0.25 | ui/ + state/; backend/app.py | flutter-tests/backend-tests; xem STATUS đúng scope | Đã code một phần; chưa nghiệm thu đủ | Đã code một phần; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Chưa regression đầy đủ Web + native/video |
| 12 | Sửa note | 0.25 | ui/ + state/; backend/app.py | flutter-tests/backend-tests; xem STATUS đúng scope | Đã code một phần; chưa nghiệm thu đủ | Đã code một phần; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Chưa regression đầy đủ Web + native/video |
| 13 | Xóa note | 0.25 | ui/ + state/; backend/app.py | flutter-tests/backend-tests; xem STATUS đúng scope | Đã code một phần; chưa nghiệm thu đủ | Đã code một phần; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Chưa regression đầy đủ Web + native/video |
| 14 | Auto-save và lifecycle | 0.25 | ui/ + state/; backend/app.py | flutter-tests/backend-tests; xem STATUS đúng scope | Đã code một phần; chưa nghiệm thu đủ | Đã code một phần; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Local draft + debounce + Back; kill/lifecycle còn test |
| 15 | Đính kèm ảnh/video | 0.25 | AttachmentsDialog/AttachmentSession + private API/SQLite BLOB | evidence/2026-10-01-attachments; ACL/grant/validation/race/canonical/Range | Actual chooser/upload/image/H264 Blob video/remote lock/peer delete PASS local release | Actual PNG DocumentsUI/upload/image/peer delete + H264 native position PASS debug | Chưa deploy/demo | Chưa quay | Online-only; protected-reader actual file UI/OS denied-cancel/full codecs/physical/release/HTTPS/video còn thiếu |
| 16 | Đính kèm file | 0.25 | PDF/TXT/CSV/ZIP; authenticated download; Android SAF save/delete | API/private retry/tombstone/restart/note cleanup + download hash | Actual TXT chooser/upload/download/delete giữ note content/revision PASS | Actual TXT ACTION_CREATE_DOCUMENT/save hash/UI delete PASS; TXT upload qua peer API | Chưa deploy/demo | Chưa quay | Chưa durable media queue/full OS providers/cancel-denied/antivirus/physical/release/public/video; giới hạn loại/size ghi trong docs |
| 17 | Ghim và sắp xếp note | 0.25 | ui/ + state/; backend/app.py | flutter-tests/backend-tests; xem STATUS đúng scope | Đã code một phần; chưa nghiệm thu đủ | Đã code một phần; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Chưa regression đầy đủ Web + native/video |
| 18 | Chỉ báo shared/pinned/locked | 0.25 | Home + server shared_count/by/at; locked redaction | evidence/2026-10-02-sharing; UI locked metadata tests | Owner/recipient icon+owner/time/role actual local release | Recipient owner/time actual debug; owner count API assertion | Chưa deploy/demo | Chưa quay | Locked chỉ metadata tối thiểu; full mixed indicators/physical/video chưa nghiệm thu |
| 19 | Live search | 0.25 | ui/ + state/; backend/app.py | flutter-tests/backend-tests; xem STATUS đúng scope | Đã code một phần; chưa nghiệm thu đủ | Đã code một phần; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Chưa regression đầy đủ Web + native/video |
| 20 | Quản lý nhãn | 0.25 | Manager/controller + /labels/sync CAS/journal | API ACL/race/migration/late ops; evidence/avatar-labels | CRUD/offline reload/reconnect/peer/delete PASS | UI create/delete + controller rename/reopen/peer PASS debug | Chưa deploy/demo | Chưa quay | Full conflict UI hai thiết bị/physical/HTTPS/video chưa nghiệm thu; conflicts covered controller/API |
| 21 | Gắn nhãn vào note | 0.25 | Editor IDs + note sync owner rules | Direct owner/viewer/editor/stranger API; immutable dependency/recovery tests | Actual editor assign + rename/delete content/revision PASS | Controller assign/sync/delete content/revision PASS debug | Chưa deploy/demo | Chưa quay | Native editor assignment UI chưa rerun; full two-device release/OS kill/video chưa nghiệm thu |
| 22 | Lọc theo nhãn | 0.25 | Home selected ID AND filters | Widget AND/delete/rename; Chrome selected filter evidence | Rename giữ selected ID/result PASS | Widget filter regression; chưa native filter interaction | Chưa deploy/demo | Chưa quay | Physical/native filter interaction/multiple live-session filter/video chưa nghiệm thu |
| 23 | Bật/tắt khóa note | 0.5 | home/note_protection/controller + protection API | evidence/2026-10-01-note-protection;67 Flutter/15 backend | Online enable/disable PASS; chưa nghiệm thu đủ | Debug emulator enable/disable PASS; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Protected editing/offline unlock/key backup, release/physical-device còn thiếu |
| 24 | Mở khóa/đổi mật khẩu note | 0.5 | ProtectedReader + unlock/lock/protection APIs | Browser/Android protection + API/session/race/TTL tests | Online read/relock/change PASS; chưa nghiệm thu đủ | Debug emulator read/change/lifecycle notification PASS; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Chỉ đọc; offline unlock/physical-device/browser hidden/full accessibility còn thiếu |
| 25 | Chia sẻ/nhận/quản lý quyền | 0.5 | ShareDialog/ShareSession + owner atomic batch/CAS/journal APIs | evidence/2026-10-02-sharing; direct owner/editor/viewer/stranger/grant/replay tests | Batch/missing email/role dropdown/recipient metadata/revoke/draft recovery actual release | Batch/dropdown/recipient edit/peer viewer-revoke/encrypted offline reopen/new-ID recovery actual debug PASS | Chưa deploy/demo | Chưa quay | Online-only; protected-reader share UI/full two-device race/physical/release/HTTPS/video chưa nghiệm thu |
| 26 | Cộng tác realtime | 0.5 | Authenticated /events SSE + transactional counters + controller/editor/route sessions | evidence/2026-10-02-realtime;106 Flutter/53 backend; real socket ACL/cap/revoke/lock/expiry | Chrome local release automatic editor updates; exact reconnect/permissions scope trong index | API36 debug real SSE clean update/editor save/reconnect/base409/viewer-revoke/encrypted reopen PASS | Chưa deploy/demo | Chưa quay | Revision conflicts, không OT/CRDT; protected-reader actual realtime/physical/release functional/load/HTTPS/video chưa nghiệm thu |
| 27 | AI Summary | 0.25 | Chưa có | Chưa chạy | Chưa triển khai; chưa nghiệm thu đủ | Chưa triển khai; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Cần triển khai |
| 28 | AI Q&A có nguồn | 0.25 | Chưa có | Chưa chạy | Chưa triển khai; chưa nghiệm thu đủ | Chưa triển khai; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Cần triển khai |
| 29 | UI/UX/accessibility/adaptive | 0.5 | All implemented lib/ui routes + design_system/prism/localizations; docs/UI_UX_DESIGN | evidence/2026-10-02-prism-ui; motion/reduced/no restart/129 selected contrast; responsive320/360/390/768/desktop/landscape200%; lock/base/draft regression | Chrome final local release auth/home hover/theme/resize/settings; scope/ảnh trong INDEX | API36 debug Skia software real registration/labels/preferences/theme/editor;3 PNG; other flows historical | Chưa deploy/demo | Chưa quay | NVDA/TalkBack/physical/FPS/default-renderer/history/deep-link/release-all/protected reader advanced chưa đủ |
| 30 | Kiến trúc/state/automated tests | 0.5 | Controller/API/local/vault/schema2 + SSE/sessions; UI components giữ state contracts | evidence/2026-10-02-prism-ui/check-final.txt + api-acl.txt | 118 Flutter/53 backend PASS; chưa nghiệm thu đủ | UI real backend Skia software PASS; core/sharing/realtime mốc trước giữ regression host | Chưa deploy/demo | Chưa quay | Clean clone/release/physical/full rubric còn thiếu; không fabricated coverage/teamwork |
| 31 | Offline persistence và sync | 0.5 | backend/app.py / docs/ | flutter-tests/backend-tests; xem STATUS đúng scope | Đã code một phần; chưa nghiệm thu đủ | Đã code một phần; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Sembast + immutable queue/conflict; actual Web reload/pending/sync + native DB reopen PASS; OS kill/physical còn test |
| 32 | Build và public deployment | 0.5 | backend/app.py / docs/ | flutter-tests/backend-tests; xem STATUS đúng scope | Đã code một phần; chưa nghiệm thu đủ | Đã code một phần; chưa nghiệm thu đủ | Chưa deploy/demo | Chưa quay | Local build spike Web/APK; chưa public HTTPS/signing production |
