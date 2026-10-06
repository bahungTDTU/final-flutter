# NoteTogether - trạng thái 06/10/2026

## Publication Git —06/10/2026

- Người dùng đã ủy quyền commit/push toàn bộ thay đổi hiện có lên
  https://github.com/bahungTDTU/final-flutter, nhánh master. Dùng cấu hình Git
  Bahung <523K0006@student.tdtu.edu.vn>, không thêm GPT/Codex co-author.
- Bản cập nhật gom AI, protected offline editing/recovery, transaction email outbox,
  Writing Studio và UI/responsive/performance đã nghiệm thu local ở các mốc bên dưới.
  Gate gần nhất161 Flutter/88 backend PASS;Web/Android debug có evidence riêng.
- Các câu “chưa commit/push” bên dưới là trạng thái lúc chạy QA từng đợt. HEAD/remote
  hiện tại kiểm tra bằng git log và git ls-remote origin refs/heads/master; evidence
  manifest giữ baseADED41e trước publication và hashes của snapshot, không fake timestamp.
- Release/HTTPS/signing vẫn hoãn; chưa nghiệm thu Gemini thật/thư Internet/physical.

## UI đồng bộ và performance —06/10/2026

- ReadingCanvas/Prism chung cho ordinary editor, AI Q&A và protected reader; adaptive spacing,
  không double keyboard inset. Gallery6tone, footer compact/preview dialog/cửa sổ thấp/chữ lớn;
  bỏ backdrop lặp. Card preview480+ellipsis, không split surrogate; full-text search vẫn đủ.
- Route-local listing cache invalidates nguồn/account/labels/role/query; suffix-only search rebuild,
  literal Unicode matching tránh lowercase toàn note; locked pin/date/group/semantics được ẩn.
  Giữ home scroll/filter và editor ID/frozen base/caret; không đổi schema/controller sync.
- 161 Flutter/88 backend/analyze PASS;6 regression mới. Native API36 debug3 reused real workflows
  PASS47s; actual IAB debug gallery/theme/AI form resize/protected unlock/relock/search100000chars/
  SSE lock cached Home PASS; direct HTTP4roles PASS. Không AI provider call/physical/FPS claim.
- Benchmark host NotoSans11 medians: paragraph4279→165µs;500note prefix query348926→388µs,
  cache repeat10µs. Đây là workload kiểm soát, không suy ra FPS/mọiquery. Docs/evidence:
  docs/UI_COHESION_AND_PERFORMANCE.md; evidence/2026-10-06-ui-cohesion/INDEX.md.
  Release vẫn hoãn; chưa commit/push/deploy.

## Xưởng ghi chú — 06/10/2026

- Bổ sung sáng tạo liên quan trực tiếp đến note:6 mẫu có preview/durable account draft,
  dàn ý/checklist tương tác theo text + tiến độ/thời gian đọc, viết tập trung/phiên25 phút.
  Offline, không dependency/API/table mới; không gọi công cụ xác định này là LLM.
- Checkbox sửa nội dung qua draft/save/outbox hiện có; giữ frozen base/caret, stale-text guard,
  viewer/new-base readonly, lock/revoke che panel. Protected reader chưa nối công cụ sáng tạo.
- 155 Flutter/88 backend PASS/analyze sạch;320px/chữ200%/reduced motion; actual HTTP4roles
  và IAB Web debug template/check/focus/reload/SSE-lock PASS. API36 debug real API/keys/
  encrypted Sembast offline close-reopen PASS;1 functional scenario, teardown không thêm case.
- Hướng dẫn/demo: docs/WRITING_STUDIO.md; evidence/2026-10-06-writing-studio/INDEX.md.
  Không bảo đảm điểm sáng tạo; không FPS/physical/screen-reader/OS kill claim. Release vẫn hoãn,
  không push/deploy/commit/Gemini thật/thư Internet; audit cũ giữ snapshot lịch sử.

## Email bền và retry — 06/10/2026

- Theo yêu cầu mới, release để sau cùng; không triển khai signing/Docker/HTTPS trong lượt này.
  Bổ sung auth email chức năng: transaction outbox, FastAPI lifespan worker, lease120s,
  backoff/max6, retry/restart cùng mã, invalidation theo token TTL/used/resend. Auth không chờ SMTP.
- HMAC-SHA256 với nonce32 byte/user/kind và server key riêng; DB không mã thô, private key
  ngoài SQLite/Git. Key loss fail-closed giữ job; forgot known/unknown vẫn generic khi lỗi key.
- Authenticated email-status scoped theo account; UI queued/retrying/accepted/failed,
  check trạng thái; public reset request-resend/email input/cooldown, không status oracle.
- 146 Flutter PASS/analyze sạch,88 backend PASS (9 queue regressions có real TLS retry;
  3 widget regressions mới). HTTP owner/viewer/editor/stranger + actual SMTP/TLS receipt +
  verify/reset/session revoke PASS local. API36 debug Skia software verify/status/banner/
  reset/manual login PASS; Web debug actual status/verify/public resend/cooldown PASS.
- Evidence: evidence/2026-10-06-email-queue/INDEX.md, docs/EMAIL_DELIVERY.md. Thư ngoài/Gemini
  thật/physical/public release/video chưa nghiệm thu. Không commit/push hoặc gọi dịch vụ ngoài.
  Audit/readiness06/10 trước đợt này giữ snapshot lịch sử; release plan hoãn theo yêu cầu.

## Ghi chú bảo vệ — 05/10/2026

- Protected reader nay có edit/autosave650ms, confirmed owner delete, pin/owner labels,
  metadata shared/pinned/role sau unlock, editable private files và owner shares. Server
  role/grant check cho mỗi operation; payload không cấp permission/protection.
- Password-encrypted cache/draft/immutable operation: PBKDF2-SHA256600000 + AES-GCM,
  AAD account+note, fresh nonce, nằm trong encrypted account snapshot; không vào ordinary
  notes/drafts/outbox/search, không persist password/derived key. Device key/storage vẫn cần.
- Offline password unlock cho bản đã tải; DB reopen/Web reload giữ latest draft. Reconnect
  che content và cần server unlock trước gửi. Revoke/delete/password change giữ bản nháp
  bằng mật khẩu cũ để copy ID mới riêng, không mở lại source. Account/field-merge/race guards.
- SSE cập nhật clean content nhưng freeze base; explicit new-version edit; dirty409 giữ
  bản local. Lost ack replay cùng payload/op_id, input in-flight nối own ack. Delete409 refetch
  và xác nhận mới; revoke trong delete dialog che title/vô hiệu hành động.
- Web local IAB actual unlock/realtime/new-base edit/autosave/private TXT chooser/upload/
  share list/offline backend-unreachable/reload/password reopen/revalidation/same-ID sync PASS.
  Actual HTTP owner/viewer/editor/stranger, minimal locked list, private files, replay409/revoke/
  password change/delete PASS. Android API36 debug real API/SSE/keys/Sembast flow có log riêng.
- Host143 Flutter/79 backend PASS/analyze sạch; build/source verification kết quả trong
  evidence/2026-10-05-protected-notes/INDEX.md. Test KDF thực default600000 có timeout2 phút
  riêng sau lượt chạy song song timeout30s; không giảm KDF production.
- Final source native integration PASS43s; Web40resources/workeraaf0baf19a213a73 và APK56.2MB
  build PASS. Served main JS/worker bytes khớp build, actual IAB reload/unlock/edit/API autosave
  PASS sau build; không claim biết exact browser-cache executable hash. README/Readme equality
  và source/evidence/artifact SHA-256 trong manifest, không thay rerun mọi historical flow.
- Docs NOTE_PROTECTION/ENCRYPTED_RECOVERY/README/matrix cập nhật; audit05/10 trước AI/protection
  vẫn là snapshot lịch sử. Không push/deploy mới. Không E2EE/key backup/OS force-kill/physical/
  public HTTPS/release functional/all32-criteria claim.

## AI Summary và Q&A — 05/10/2026

- Đã nối Gemini REST backend, authenticated Summary/Questions/Validate API, provider
  disabled khi không có key; summary/regenerate không mutate note, Q&A BM25 chunk retrieval
  từ notes authorized/unlocked, synthesis JSON/citations server-validated, no-data/error UI.
- Recheck mọi context source/session/grant/revision trước gửi và sau inference; không giữ
  SQLite transaction qua network. Client account/epoch/gate/remote/poll/lifecycle che result;
  result RAM-only, không lưu vào cache/vault/outbox/history. Frozen editor base giữ nguyên.
- UI: editor Summary; Home Hỏi ghi chú; protected reader Summary/Hỏi AI sau unlock.
  Gemini key chỉ backend; config script nhập che ký tự/file local ignored; app budgets bền.
- 131 Flutter/73 backend PASS, analyze sạch ở check05/10; 17 backend AI cases và8 Flutter
  AI regressions. Actual HTTP owner/viewer/editor/stranger/locked/revoke/no-data PASS với
  **provider fixture**; API8000 thiếu key trả503 đúng, không fake success.
- Actual Web local release Summary/Q&A2sources/citation open/insufficient/remote-lock hide
  và Android API36 debug Skia software Summary/regenerate/Q&A/citation PASS qua fixture.
  Scope/commands/logs/screenshots ở evidence/2026-10-05-ai/INDEX.md, docs/AI_FEATURES.md.
- **Gemini thật chưa chạy**: người dùng chọn hoàn tất mã/local QA trước. Key cũ hiện có
  đã xuất hiện trong output công cụ do redaction chỉ nhận format cũ; không lưu/sử dụng
  key đó. Cần người dùng thay/config key mới; không nâng trạng thái27/28 thành full.
- Không public deploy, physical-device/full release acceptance, video hoặc push mới.
  Final Web40resources/worker0b3445ebf15f821a và APK55.9MB build PASS, API8000 mặc định;
  không để final build nối fixture8012; release-functional/HTTPS vẫn chưa nghiệm thu.
  Audit docs/FINAL_PROJECT_AUDIT_2026-10-05.md giữ snapshot trước triển khai AI.

## Mốc hiện tại

M0 đã dựng nền tảng và kiểm chứng nhiều spike local; chưa hoàn thành mọi spike dịch vụ.
M1/M2 đã triển khai một phần. M3 có sync/conflict/protection/ACL backend spine; chưa nghiệm thu đầy đủ.
M4 sharing/SSE realtime đã có local QA; chưa nghiệm thu mọi gate.
M5 AI đã có code/local fixture QA, chưa real-provider acceptance; M6–M7 chưa hoàn thành.
Route editor đã cố định ID/base; remote sạch hiển thị live, chỉnh sửa phiên bản mới phải explicit.
Không tuyên bố đạt đủ 32 mục hoặc sẵn sàng nộp.

## Đã thực hiện

- Bảo trì03/10: batch GET /notes giữ ACL/minimal lock response; index merge sync, bỏ archive
  cho clean notes; HTTP plain-error giữ status, timeout abort; background/dispose guards.
  Dọn309 generated files cũ/trùng, bỏ unused PaperIllustration/cupertino_icons,
  chuyển legacy contrast script ra evidence. Xem docs/PERFORMANCE_AND_MAINTENANCE.md.
- Đọc/extract lại PDF gốc 19 trang và đối chiếu rubric; tạo matrix 32 mục tổng 10 điểm.
- Scaffold một Flutter project Web/Android, state ChangeNotifier, Sembast local, FastAPI/SQLite.
- Auth register tự login, persistent unverified banner, login/logout, profile name/private avatar,
  SMTP/TLS + mã kích hoạt/reset UI hai bước; email ngoài/Gmail/Outlook chưa nghiệm thu.
- Preferences font/theme/grid có outbox bền + server field merge/idempotency; editor chung/create/edit, immediate local draft,
  debounce650ms, Back/lifecycle flush, CRUD/delete confirm, search300ms, pins/order, nhãn server IDs + AND filter.
- Immutable outbox, operation ID/revision/idempotency, account namespaces/generation guard,
  conflict copy/remote choice; backend lock/grants/roles/revoke spike với direct API negative tests.
- SSE authenticated theo account, transactional SQLite counters, reconnect/foreground guards;
  cập nhật sạch ngay trong editor, giữ dirty draft/base khi concurrent edit/lock/viewer/revoke.
- Custom static-only Web offline worker sau khi browser test phát hiện offline reload thất bại.
  Worker và manifest sinh từ build thật, local CanvasKit, không cache API/session/note/private file.
- UI/UX toàn diện: light/dark tokens và Material Việt hóa, adaptive home/search/pinned cards,
  editor paper/status, auth/profile/labels/share/files/protection dialog; giữ draft/ID/base/caret.
- UI đa sắc/lăng kính:6 accent tones, rim/CTA gradient, static optical backdrop/crystal,
  hover/route/theme/reveal ngắn, reduced motion; nền đọc kín, không looping decoration.
- ADR/architecture/permission/offline/tests/demo/team/submission documents và setup/check/build scripts.
- GitHub repository: https://github.com/bahungTDTU/final-flutter. Người dùng ủy quyền initial
  commit/push02/10 với danh tính Bahung; không gán initial import thành bằng chứng teamwork4 tuần.
  Lịch sử/ref hiện tại kiểm tra bằng git log và git ls-remote; xem docs/GITHUB_PUBLISH.md.

## Bằng chứng đã chạy

Windows 11, Flutter3.47.1/Dart3.13.1, Python3.12, Android SDK36/JDK21, Chrome154,
Android API36 emulator taskflow_api36. Maintenance03/10 chạy trên base35ee911 + working changes;
source hashes/commands/results trong evidence/2026-10-03-maintenance/INDEX.md.
Các QA snapshots01–02/10 chốt trước initial commit giữ commitnull đúng phạm vi lịch sử.

| Check | Kết quả / phạm vi |
|---|---|
| Format/check/analyze | PASS, không issue; evidence/2026-10-03-maintenance/check-final.txt |
| Flutter tests | 123 PASS;5 HTTP/lifecycle regressions mới; hover/reduced/no restart/129 contrast/adaptive200%/privacy/base/durability/recovery/preferences/labels/sharing/SSE suites giữ PASS |
| Backend | 56 PASS; thêm bounded list queries/detail parity/current ACL/labels/lock;1 TestClient deprecation warning; direct actual HTTP owner/viewer/editor/stranger PASS |
| Web release | PASS API8000/40 static resources/workerfe2154b5779bb956; navigation main JS SHA trong maintenance index; chưa public HTTPS |
| APK release | Build55.8MB PASS sau native integration/pub get; debug signing/local HTTP URL, chưa HTTPS/release core acceptance |
| Android integration | Maintenance final source note_flow real API/Sembast/keys/register/autosave/offline/reopen PASS; API36 debug Skia software; UI/sharing/realtime PNG/flow mốc trước có scope riêng |
| Browser local | Maintenance final bundle: actual Chrome login/home/editor/theme-resize/offline draft/reload/reconnect; actual API ID/count/content assertions trong maintenance index; các flow khác giữ historical scope |

Benchmark local ASGI/SQLite1.000 notes: owner/viewer SELECT5.803/7.753→4;7 measured requests
median64.248/76.335ms→52.397/58.701ms. Hai lần đo host có nhiễu,10-note latency không ổn định;
không claim network/production/FPS/jank improvement. Details: PERFORMANCE_AND_MAINTENANCE.md.

Actual integration dùng port65530 không lắng nghe để tạo lỗi kết nối thật (không HTTP mock).
DB close/reopen là trong test process; chưa chứng minh OS force-kill/relaunch hay Wi-Fi toggle Android.
Native functional integration là debug APK; release install/launch chỉ smoke màn hình login.
Web ở http localhost, không thay public deployed HTTPS.

Đợt màu sắc/lăng kính mới: `evidence/2026-10-02-prism-ui/INDEX.md`, source/build hashes
và README equality được verify riêng. 4 host tests mới có129 cặp contrast được chọn,
không thay full WCAG audit. Native PASS dưới Skia software, không sửa flag production;
hai lượt emulator mất kết nối giữ log/không kết luận nguyên nhân. Chưa FPS/jank/physical QA.

Đợt UI/UX toàn diện: `evidence/2026-10-02-ui-upgrade/INDEX.md`, `docs/UI_UX_QA.md` và
`docs/UI_UX_DESIGN.md` ghi checks/ảnh/contrast/giới hạn. Sửa lỗi surface Ink bị che,
AlertDialog intrinsic layout, cửa sổ thấp/chữ200%, pinned card/lazy scroll và badge realtime
khi offline. Native screenshot driver chạy mã cuối; Web worker cần reload và đối chiếu response
thật, không suy từ cache đã update. Chưa NVDA/TalkBack/physical/history/deep-link/full release QA.

## Chưa làm / blocker / next work

Internet SMTP delivery/receipt và production mail-worker vận hành; attachment offline queue/full OS/release QA;
key backup/transfer; protected reader native OS picker/full media/AI real-provider acceptance;
full distributed/two-device stress races; Gemini key mới/real LLM acceptance;
production abuse protection/session storage/signing/backups; public HTTPS; clean clone setup;
GitHub contribution4 tuần/video/Rubric.xlsx/Insights/final ZIP.

Ưu tiên chức năng tiếp: nghiệm thu các UI core còn thiếu (native nhãn/filter, protected
file/share/media/AI flow), concurrent permission/cache races và lỗi lifecycle. LLM/SMTP ngoài
khi nhóm sẵn sàng cấu hình; release/signing/hosting/đóng gói để cuối theo yêu cầu06/10.

GitHub repo đã được người dùng cung cấp và ủy quyền push; cloud/domain/budget/LLM key sẽ xử lý sau,
không tự deploy/tạo phí.
Ngày deadline chính xác và ngày bắt đầu chính thức/phân công vẫn chưa xác định.
Người dùng xác nhận 2 thành viên Hùng–Long và được dùng AI toàn phần; xem TEAM_CONTRIBUTIONS.

Remote lock nay giữ draft/upsert qua encrypted recovery; chi tiết và lỗi ghi ở ENCRYPTED_RECOVERY.md.
Rủi ro trước M3 nghiệm thu: Web key provider experimental, key backup/loss, multi-tab/physical/release QA.
Session local plaintext chưa production hardening.
Preference/label outbox/cross-session đã triển khai; retry cố định15s chưa backoff.

Nhóm cần hiểu operation ID khác revision, grant khác permission, local draft khác server saved,
và vì sao backend test/build pass chưa phải full feature/production/video evidence.

## Tiêu chí tiếp theo đã triển khai: 8 – Preferences

- Durable preference queue per-account, field-patch API + server journal chống stale replay; UI pending/retry.
- Last-server-accepted cho cùng trường; merge trường khác; local edit in-flight không mất.
- Analyze sạch, 12 Flutter tests (6 unit/6 widget), 14 backend tests PASS; 1 Android real-backend
  integration PASS bao gồm offline preference/reopen/reconnect/second-session update.
- Source/results: docs/PREFERENCES_SYNC.md, evidence/2026-10-01-preferences.
- Chrome Web release PASS: offline list/dark/font18 → offline reload giữ pending3 →
  reconnect pending0; SQLite xác nhận server nhận đúng ba trường. Web/APK release build PASS.
- Chưa video/public deployment; Android integration debug/emulator, không claim physical/release feature parity.

## Đợt UI/UX theo PROMPT_UI_UX_NOTETOGETHER.md

- Design system teal/giấy ấm, Noto Sans offline (OFL), sidebar/rail/bottom nav thích nghi,
  segmented view, pinned sections, note metadata/privacy, empty/search/offline states.
- Auth responsive + password toggle/Enter/busy; editor canvas + trung thực local/server save,
  stable ID/frozen revision; settings groups/font preview/email; label validation; password dialog
  giữ input/error và chặn double submit. Backend/controller stack giữ nguyên.
- Spec/state matrix + dependency preview tách riêng; share/lock/files/AI vẫn chưa integrated.
- scripts/check.ps1: analyze sạch,37 Flutter tests (6 unit +31 widget/harness),14 backend PASS.
  Responsive6 sizes x3 scales; labeled48 targets phạm vi home;14 contrast pairs đo PASS.
- Android integration1 PASS real API/Sembast; debug main install/login/screenshot smoke.
  Chrome release login/validation, theme/edit/resize/Back, pin/group/view/search-clear,
  offline edit/reload/reconnect + SQLite ID/count/content assertions PASS.
- Web release build41 static resources; APK release51.9MB PASS, chưa release core HTTPS/signing.
- Evidence: evidence/2026-10-01-ui; spec docs/UI_UX_DESIGN.md, QA docs/UI_UX_QA.md.
- Chưa full history Back/deep link, TalkBack/NVDA, physical-device/force-kill, full two-session
  revoke/conflict UI, SMTP/avatar/files/shares/realtime/LLM/public deploy/video. Không đạt đủ32.

## Bước tiếp theo: durable outbox và conflict recovery — 01/10/2026

- Serialize session write/remove cùng snapshot, chờ write trước load account; generation check
  sau local await để logout không ghi lại session/gửi preference queue cũ.
- Sync phải ghi snapshot trước gửi operation; lỗi local báo chưa ghi, giữ operation ID cho retry.
- Conflict copy dùng draft mới nhất, tạo bản mới/outbox base0 trong cùng transaction với bỏ bản cũ;
  invalid draft giữ riêng. Write failure rollback và UI báo thử lại.
- scripts/check.ps1 PASS: format/analyze sạch,45 Flutter tests,14 backend tests gồm direct API
  owner/viewer/editor/stranger/lock/revoke (FastAPI TestClient),1 warning deprecation thư viện.
- 8 tests mới gồm file Sembast thật close/reopen Windows host, lost ack/replay, edit in-flight,
  logout/write race và fault injection. HTTP race dùng doubles, không claim browser/2 thiết bị.
- Android emulator-5554 integration1 PASS với backend thật, debug HTTP + Sembast reopen;
  không force-kill/physical device/release acceptance. Logs: evidence/2026-10-01-durability.
- Web release build PASS, worker notetogether-static-321ef473f248fcdf gồm41 static resources;
  chưa chạy browser regression cho lượt durability này. APK release chưa rebuild lượt này.
- Commit: chưa có. Remote lock vẫn có nguy cơ xóa draft/pending; encrypted recovery + key lifecycle
  là ưu tiên ở thời điểm đợt durability; đã được xử lý trong đợt tiếp theo bên dưới.

## Phục hồi mã hóa khi khóa từ xa — 01/10/2026

- Account snapshots AES-256-GCM, fresh nonce/AAD account+version, device key riêng qua
  flutter_secure_storage11.2.0; cryptography2.9.0 pinned. Main/integration dùng encrypted store.
- Legacy migration trước load, compact log với durable retry marker. Missing key/tamper/load error
  giữ ciphertext, chặn overwrite/sync. Device key không xóa khi logout/reset/note-password change;
  rotation primitive atomic đã test, giữ old keys, chưa rotation UI/key backup.
- Lock snapshot chuyển local draft/upsert mới nhất sang recovery cùng transaction trước loại source;
  không archive chỉ cached server content. Editor clear/cancel debounce, chặn draft/save source khóa.
- POST423 archive/che ngay cả khi GET list lỗi, skip các operation nguồn đã archive; local write failure
  banner nói chưa ghi và giữ app mở. Regression + Android real unreachable-backend queued edit PASS.
- Home recovery count → dialog không preview content → explicit copy dưới draft ID mới; invalid draft
  giữ được, copy không mở source, retry dùng cùng ID không ghi đè copy đã sửa.
- Locked API metadata thêm role server-authoritative cho owner/shared tab; không lộ title/content/labels/pin.
  Owner/viewer/editor/stranger API regression trong14 backend tests PASS.
- scripts/check.ps1 PASS: analyze sạch,60 Flutter tests (15 mới),14 backend tests;1 deprecation warning.
- Android encrypted recovery integration PASS real backend + second session + platform keys/Sembast
  close/reopen + UI copy/server assertion/source423. Baseline integration với wrapper mới cũng PASS.
- Chrome release PASS register/create → offline unfinished draft → second API session lock → offline
  reload → reconnect archive → online reload giữ recovery → new draft/copy, API exact-content/ID/count2,
  source423. IndexedDB envelope không plaintext fixture; screenshots gồm390x844 mobile.
- Web release workeraf8d3638dfa4eed3/41 resources PASS; APK release52.0MB build PASS,
  debug signing/HTTP local chưa phải release core acceptance; xem apk-build.txt.
- Evidence: evidence/2026-10-01-encrypted-recovery; doc docs/ENCRYPTED_RECOVERY.md.
  Commit chưa có; chưa deploy/push/video. Không nghiệm thu đủ23/24 và offline hay toàn bộ32 tiêu chí.
- Giới hạn: Web provider experimental/exportable browser master key, không chống XSS/profile reader;
  session plaintext, không key export/cloud backup, không full offline note unlock/force-kill/physical-device.

## UI khóa ghi chú và phiên đọc online — 01/10/2026

- Home owner menu bật khóa (password2x), thẻ khóa mở password gate; đọc tạm online tối đa5 phút.
  Owner đổi/tắt bằng current password; Khóa lại hủy grant chỉ session hiện tại.
- ProtectedReader giữ content ở RAM route, không đưa vào ordinary notes/cache/search/drafts/outbox.
  Epoch/TTL guard che nội dung khi phản hồi muộn, lifecycle, logout, lỗi network/permission hoặc đóng route.
  Kiểm tra quyền mỗi15s và nút refresh; chưa realtime. Unlock/relock serialize qua controller cả hai route.
- Mutation chặn khi draft/outbox nguồn còn; bật khóa redacts/persist trước refresh và giữ recovery
  nếu local edit đến trong request. Frozen editor base revision và encrypted recovery regression giữ nguyên.
- POST /notes/{id}/lock và protection response ok/revision/locked; list vẫn neutral kể cả có grant.
  Direct API tests owner/viewer/editor/stranger + session isolation + idempotent relock PASS.
- scripts/check.ps1 PASS: format/analyze sạch,67 Flutter tests (7 mới),15 backend tests (1 mới);
  còn Starlette TestClient deprecation warning. Evidence checks.txt là lần chạy chốt.
- Android integration mới PASS emulator-5554 + backend thật + platform keys/Sembast + dialogs:
  enable → 423 → wrong/retry/read → lifecycle notification che → change → old403/new read → disable200.
  Background có mô phỏng lifecycle; chưa OS force-kill/physical-device. Tests cũ không chạy lại native đợt này.
- Chrome local release PASS menu enable → neutral cards → wrong/retry/read → explicit relock → change
  → new unlock → disable; second API session asserts revision3/4, old403/new200/relock423,
  exact fixture content/count2 và original vẫn423. Web tab-background chưa nghiệm thu: automation
  báo visible ở cả hai tab; không coi tab-select là hidden event PASS. Full screen-reader chưa nghiệm thu.
- Web workeraf10e1047aa661e6/41 resources và APK release52.3MB build PASS. Debug signing/local HTTP
  vẫn là spike; chưa public HTTPS/signing release acceptance. Đã cập nhật README/Readme/matrix/docs.
- Evidence evidence/2026-10-01-note-protection; docs/NOTE_PROTECTION.md. Commit chưa có;
  không push/deploy/nộp/video. Chưa full23/24: protected edit/offline unlock/key backup còn thiếu.
- Ưu tiên tiếp theo: SMTP thật/avatar/server labels, rồi private attachments/shares/realtime/LLM;
  mở rộng protected editing/offline và nghiệm thu release theo matrix.

## SMTP/TLS và UI mã kích hoạt/reset — 01/10/2026

- Transport SMTP STARTTLS/SSL đọc environment, kiểm tra certificate/hostname; không plaintext fallback.
  Main bỏ mailbox memory. Chưa cấu hình thì báo not_configured, không giả email đã gửi.
- Mã ngẫu nhiên dùng một lần30 phút, DB chỉ digest; resend60s thay mã cũ. Register tự login và
  chưa verified vẫn dùng core. Forgot trả response chung cho email tồn tại/không tồn tại; timing còn khác.
- Home mở form xác minh/gửi lại; public forgot → kiểm tra mã → password2x → manual login.
  Backend kiểm tra lại code khi reset atomic, thu hồi sessions; UI giữ input khi lỗi/chặn double submit.
- scripts/check.ps1 PASS: format/analyze sạch,71 Flutter/22 backend tests;7 backend mới có socket
  SMTP TLS thực local (STARTTLS/SSL/AUTH, CA/refusal/fail closed),4 widget mới. Không SMTP internet.
- Android integration email_flow PASS debug emulator API36, backend8011 + TLS SMTP8025 fixture,
  code reader8026 chỉ QA; note vẫn giữ sau reset, old session401, new login200. Không thiết bị vật lý.
- Chrome release390x844 PASS register/auto-login → verify/banner gone → logout → forgot →
  code check/password2x → manual login. Direct API/SQLite xác nhận verified, old password401,
  new200, hai mã reuse400/digest/used. Screenshots/logs: evidence/2026-10-01-email.
- Web release/API8000 và APK release52.3MB build PASS; release signing vẫn debug, HTTP local.
  Đợt này không install/test core release APK; Android functional QA là debug integration.
- docs/EMAIL_DELIVERY.md có cấu hình và fixture tái lập. Không gửi tới bên ngoài hoặc dùng credentials thật.
  SMTP accepted chỉ là server nhận thư; receipt/SPF/DKIM/HTTPS/email queue/retry/video chưa chạy.
  Commit chưa có; chưa push/deploy/nộp. Tiêu chí2/4 còn partial; bước kế tiếp avatar/server labels.

## Avatar và catalogue nhãn server — 01/10/2026

- Avatar file_selector1.1.0 Web/Android PNG/JPEG≤2 MiB; server Pillow12.3.0 decode/canonical PNG
  ≤512×512 bỏ metadata. SQLite private BLOB/CAS revision; authenticated download/no public URL,
  default delete atomic. Canonical bytes cache trong encrypted account snapshot, generation guards.
- Nhãn server ID/name/revision/tombstone/account unique; immutable label outbox trước note sends,
  CAS/journal/replay/conflict/duplicate resolution. Rename/delete không đổi note content/revision;
  ID filter giữ selected qua rename, AND filter và owner/editor ACL vẫn giữ.
- Migration schema0/1→2 stable legacy IDs, giữ pending v1 note operations/fingerprint; factory startup
  không migrate DB default khi import tests. Encrypted vault/preferences policy/editor base giữ nguyên.
- Regression phát hiện label-create conflict chặn GET notes/remote-lock recovery: note dependent
  chờ nhãn, sync vẫn refresh lock và archive latest draft. Log trước sửa và81 Flutter/29 backend
  PASS sau sửa ở evidence/2026-10-01-avatar-labels; format/analyze sạch,1 deprecation warning.
- Android API36 debug integration dùng DocumentsUI thật chọn PNG, API/second session/platform keys/
  Sembast close/reopen/offline draft-label queues/peer rename/delete/default PASS. Native assign và
  offline rename qua controller; UI picker/upload/create/delete/default thật. Không OS kill/physical.
- Chrome release390×844 actual chooser/upload → offline reload cache avatar → UI assign/filter/
  offline rename → reload pending1 → online sync → peer rename → delete/default PASS. Second API/
  SQLite asserts count1/content/note revision2 unchanged, label revision1→4/tombstone,
  avatar1→2/BLOB NULL/private anonymous401. Không full screen-reader/history.
- Web/APK release build PASS; hash/logs/index và giới hạn signing/debug HTTP ghi trong evidence.
  Kotlin incremental=false xử lý different-roots C:Pub cache/D:project; không sửa generated Java.
- README/Readme.txt/matrix/UI QA/API docs đã cập nhật. Commit chưa có, chưa push/deploy/quay/nộp.
  Cloud storage/production rate limits/backups/physical/release HTTPS chưa nghiệm thu;5/6/20–22 partial.
- Ưu tiên tiếp theo: private attachments cho15/16, rồi share manager/realtime/LLM và release gates.

## Đính kèm riêng tư ảnh/video/file — 01/10/2026

- Tiêu chí15/16: editor note đã sync → nhiều PNG/JPEG/MP4/PDF/TXT/CSV/ZIP, validate/limits,
  upload/private list/preview/download/xóa-confirm; viewer chỉ đọc. Protected reader nối nút xem
  theo grant hiện tại nhưng actual UI flow này chưa chạy. Ảnh canonical≤2048px bỏ metadata.
- Backend attachments.py/schema2 additive BLOB table: ACL/grant trước stream và trước commit,
  immutable ID/fingerprint retry/tombstone, count10/100 MiB, Range206/416/private headers;
  note delete null BLOB atomic. Owner không bypass lock, attachment không đổi note revision/content.
- Route AttachmentSession RAM-only/account/token/epoch/poll15s; không snapshot/media outbox.
  Web authorized bytes→Blob video/download; Android native video Bearer/private URL + export
  ACTION_CREATE_DOCUMENT. Account/lock/revoke/network/background/peer delete che preview;
  retry trong cửa sổ giữ ID/payload, đóng cửa sổ bỏ lựa chọn chưa upload, online-only.
  Xóa-confirm che tên/vô hiệu Xóa tệp khi lock/revoke/delete thay đổi quyền/ID; regression widget
  và actual Chrome/Android remote-lock-confirm PASS.
- scripts/check.ps1 PASS88 Flutter/40 backend (7/11 mới), format/analyze sạch; final analyze
  sau integration assertion mới PASS. Có direct owner/viewer/editor/stranger/anonymous,
  grant session/revoke/replay/type-size/count/canonical/restart/cleanup và lock-during-normalize race.
- Chrome actual local release390×844/DPR1 chọn3 files/upload/image/video2s Blob, TXT download
  SHA-256 khớp, UI delete BLOBNULL/content/revision2 giữ, phiên API khác lock423 che preview.
  Restore protection revision4 trước final-source peer-delete; note content giữ nguyên.
- Android API36 emulator debug integration PASS: actual DocumentsUI PNG picker/image upload,
  peer delete che active preview, native H264 position>0, peer API MP4/TXT, DocumentsUI Save
  TXT42 bytes hash khớp, UI delete giữ note revision1/content; test bật/tắt khóa riêng tăng revision3
  đúng protection mutation, nội dung giữ. Không physical/OS kill/release functional.
- Web release worker300d8deb084e2b7e/41 static resources và APK release54.0MB build PASS.
  Denied/cancel/scale2 chỉ widget doubles; chưa mọi codec/antivirus/OS provider/media durability,
  protected-reader files actual UI, HTTPS/public/video. Tiêu chí15/16 vẫn partial toàn bộ nghiệm thu.
- Docs README/Readme/PRIVATE_ATTACHMENTS/architecture/security/offline/UI QA/matrix đồng bộ;
  evidence/2026-10-01-attachments có exact commands/logs/hash/ảnh/errors. Commit chưa có,
  không push/deploy/quay/nộp. Ưu tiên kế tiếp: share manager/metadata/quyền rồi realtime và LLM;
  SMTP delivery/release signing/HTTPS/submission vẫn là các gate riêng cần thông tin/dịch vụ thật.

## Quản lý chia sẻ và thay đổi quyền — 02/10/2026

- Tiêu chí25/18: ShareDialog email batch1–20, viewer/editor, owner catalogue name/email/time/role,
  dropdown change/revoke-confirm. Recipient tab owner/time/role, owner shared icon/count; khóa
  không owner/email/time. Share API strict owner/grant + batch atomic/CAS/share journal; legacy
  writes tăng share revision, UI dùng sync mới; không đổi note content/revision/pin/labels.
- ShareSession RAM-only/account/token/epoch; pending retry immutable, CAS requires review;
  background che và chặn polling đến foreground. Không offline share outbox/realtime subscription.
- Incoming viewer/403/404/revoked chuyển latest draft/upsert vào encrypted recovery, bỏ source
  queue cùng snapshot. Viewer readonly server content; revoked editor che và chặn source save;
  reopen giữ recovery, copy UUID mới. Attachment role downgrade vô hiệu open delete-confirm.
- scripts/check.ps1 PASS97 Flutter/48 backend (9/8 mới), format/analyze sạch. Đã sửa regression
  locked+viewer điền title sau khi clear, giữ encrypted_recovery_test assertion controller rỗng.
- Chrome390×844/DPR1 actual UI missing-email atomic, batch2, role dropdown, recipient owner/time,
  invalid draft + owner revoke-confirm → hidden editor/recovery/reload/copy. API note revision1
  và content giữ, share revision3/count1, recipient404; final-source hash/cache đối chiếu riêng.
- Android API36 debug real API8000/platform keys/Sembast/socket65530 PASS trên source cuối:
  UI batch2/dropdown/recipient editor edit → peer viewer/revoke → readonly/hidden editor →
  encrypted DB reopen offline → UI recovery UUID mới; note revision2 đúng một editor save.
- Web final worker7e5e4205a9ecb007/41 resources và APK54.5MB build PASS. Chưa physical/OS kill/
  release functional/protected-reader share UI/full two-device races/screen reader/HTTPS/video.
  Docs/evidence: SHARING_AND_PERMISSIONS.md, evidence/2026-10-02-sharing/INDEX.md. Không commit/
  push/deploy/phí/nộp; bước kế tiếp là authorized realtime subscriptions rồi LLM/release gates.

## Cộng tác realtime —02/10/2026

- Authenticated SSE /events, private/no-store/Origin/header-only token; SQLite counters theo
  account tăng trong note/share/attachment/label/profile/avatar/preferences transaction. Payload
  chỉ version; session revalidated250ms; cap3/session8/account per-process, heartbeat10s.
- Production app một feed foreground, epoch/account guards/abort/backoff1–30s, ready catchup,
  coalesce100ms/drain event giữa sync; ShareSession/AttachmentSession nhận refresh signals.
  HTTP15s fallback giữ, không OT/CRDT hay production scale claim.
- Editor sạch hiển thị update ngay/selection giữ; frozen base không tự nâng, nút mở phiên mới
  rõ ràng cho sửa tiếp. Dirty/draft/pending/conflict giữ local; stale409, lock/viewer/revoke
  chuyển latest edit vào encrypted recovery; không thay preference merge/immutable ops.
- scripts/check.ps1 PASS106 Flutter/53 backend (9/5 mới), format/analyze sạch. Socket SSE tests
  uvicorn/httpx thật: owner/editor/viewer/stranger/auth/origin/cap/disconnect/lock/expiry/revoke/
  rollback/replay/counter persistence. Native phát hiện cancellation error; parser/await-cancel
  cleanup sửa và actual Android run PASS. Logs fail không tính PASS.
- Android API36 debug real SSE/API/platform keys/Sembast: clean update, editor save→owner peer,
  lifecycle reconnect, concurrent409/frozen base4, viewer/revoke/hide, encrypted offline DB reopen
  socket65530 PASS. Hai controllers/account cùng test; peer mutations API, recipient UI thật.
  Không physical/OS kill/Wi-Fi toggle/release functional/protected-reader acceptance.
- Chrome local release owner/editor contexts độc lập: sạch hiển thị update, UI editor save→
  owner editor update, backend stop/restart tự nối/catchup; permissions/reload scope trong index.
  Final-source navigation hash/draft status/remote lock→hide/2 encrypted recoveries reload và
  UI restore latest draft PASS; metadata4fields/owner-editor-viewer423 qua API.
  Web workeraf4ed9f3afad7268/41 resources, navigation response main JS hash khớp; APK54.6MB build PASS sau
  pub get regenerate plugins (không patch generated Java). Public HTTPS/signing/video chưa có.
- Docs REALTIME_COLLABORATION/evidence/2026-10-02-realtime ghi protocol/commands/date/targets/
  hashes/limitations; README/Readme/matrix cập nhật. Commit chưa có, không push/deploy/phí/nộp.
  Bước tiếp theo: LLM Summary/Q&A có nguồn/quyền; SMTP ngoài/release/submission gates vẫn riêng.
