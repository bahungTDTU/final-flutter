# Rà soát NoteTogether — 07/10/2026

## Kết luận

Phần lớn chức năng đã có triển khai local, bao gồm AI adapter, email outbox bền,
ghi chú bảo vệ có chỉnh sửa/offline/recovery, chia sẻ và realtime. Chưa thể coi dự án
đã hoàn thành đề: còn lỗi giới hạn thử mật khẩu, hành vi ghim/chỉ báo khi khóa,
nghiệm thu dịch vụ thật, một số luồng native và hồ sơ nộp.

Ưu tiên tiếp theo: sửa bảo vệ mật khẩu → giảm lượng ghi/đọc không cần thiết →
đồng bộ tài liệu và nghiệm thu các nhánh UI còn thiếu → AI/email thật khi nhóm sẵn sàng.
**Release/public hosting/signing/gói nộp thực hiện cuối**, theo lựa chọn của người dùng.
Không quy đổi số tests thành phần trăm hoàn thành hoặc dự đoán điểm.

Lượt này chỉ rà soát, chạy probe với dữ liệu dùng một lần và tạo báo cáo/bằng chứng.
Không sửa mã ứng dụng, không commit/push/deploy, không gọi Gemini/SMTP Internet.
Các thay đổi UI đang có được giữ nguyên.

## Nguồn, phiên bản và phạm vi kiểm tra

- PDF gốc `503107-FinalProject-V1.pdf`: đọc mô tả trang2–7, rubric13–14,
  teamwork15–16 và output17–18; xem ảnh trang14. PDF là nguồn yêu cầu học phần,
  không phải ủy quyền thực hiện hành động bên ngoài.
- Đọc prompt triển khai/UI, AGENTS, STATUS, matrix, team và tài liệu các module.
- Rà các module tài khoản, preferences, notes/labels/avatar, cache/mã hóa/outbox,
  protection/recovery, sharing/realtime, attachments, AI, UI/tools và cấu hình
  Web/Android/backend/scripts/tests/evidence. Không thay cho pentest hoặc kiểm toán
  lỗ hổng toàn bộ thư viện phụ thuộc.
- HEAD local: `f8ff8fa427b3d490255c0522699f1a9650a3cb73` + working changes UI.
  Đọc remote master hôm nay bằng
  `git -c http.sslBackend=openssl ls-remote origin refs/heads/master`: cùng `f8ff8fa`.
  Lệnh Git mặc định gặp lỗi Windows schannel; override chỉ cho lần đọc đã thành công,
  không đổi cấu hình Git hoặc remote.
- Git hiện có3 commit, đều Bahung. UI mới chưa commit/push. Điều này không chứng minh
  đóng góp từng thành viên trong4 tuần theo đề.
- Manifest editor ngày06–07/10 kiểm tra `--verify` PASS. Log bộ đầy đủ gần nhất:
  **167 Flutter +88 backend PASS**, format/analyze sạch;1 TestClient deprecation warning.
  Hôm nay không chạy lại toàn bộ bộ test hoặc browser/native. Probe mới không cộng vào
  số167/88 và không thay nghiệm thu nền tảng thật.
- Xem lại ảnh editor desktop/mobile mới: phân tách title/content/counter rõ trong ảnh
  đã chụp; không khẳng định mọi màn hình hoặc mọi text scale đều hết lỗi từ hai ảnh này.

## Phát hiện trực tiếp cần xử lý

| ID / ưu tiên | Phát hiện và tác động | Cơ sở / hướng xử lý |
|---|---|---|
| F1 — P1 | Giới hạn thử sai mật khẩu note có thể bị vòng qua bằng API đổi/tắt bảo vệ. Sau5 lần sai ở unlock, lần6 bị429; cùng lúc6 lần sai qua protection vẫn403 và mật khẩu đúng vẫn tắt khóa được. Đây là khoảng trống chống đoán mật khẩu cho owner/session có quyền, không phải stranger vượt ACL. | `backend/app.py:502–513` không dùng attempts; unlock ở515–538 có. Probe thật Argon2/SQLite tái hiện. Dùng chung scope user+note cho mọi thao tác kiểm tra mật khẩu hiện tại; commit failed attempts trước trả lỗi; giữ TTL/grant/version và ACL. Regression cho unlock/change/disable, đúng mật khẩu trong cooldown, owner/viewer/editor/stranger. |
| F2 — P1 | Note đã ghim và chia sẻ mất pin/shared metadata khi bật khóa; bị đưa vào nhóm không ghim và chỉ còn lock/role trên home. Reader sau unlock có metadata nhưng không thay yêu cầu list/grid. Mục17/18 chưa đáp ứng đầy đủ trường hợp kết hợp. | `backend/note_listing.py:35–39`; `lib/state/note_listing.dart:8–12,101–110`; `lib/ui/home.dart:1054–1082`. Probe xác nhận pin/shared_count bị bỏ. PDF tr.3/5 yêu cầu ghim luôn trước và nhiều chỉ báo đồng thời. **Giữ policy riêng tư hiện hành**: không tự trả title/labels/pin/shared trước unlock. Cần chốt thiết kế dung hòa và test list/grid sau khi xác thực, lock/TTL/revoke/background; chưa coi vấn đề đã giải quyết. |
| F3 — P2 | Mỗi thay đổi bản nháp ghi lại toàn bộ kho tài khoản, gồm notes/outbox/avatar/recovery; khi sync còn nhiều lần ghi tương tự. Kho càng lớn, chi phí JSON/mã hóa và queue càng tăng. | `lib/ui/editor.dart:142–156`; `lib/state/app_controller.dart:323–362,592–607`; `lib/data/encrypted_account_store.dart:123,174–185`. Probe500 notes ×1.000 ký tự,20 draft updates:20 envelopes, **16.686.660 bytes (~15,9 MiB)**. AES-GCM thật, records/keys trong RAM; không đo disk latency/FPS. Tách record theo note/draft/outbox hoặc journal giao dịch; chỉ coalesce khi vẫn bảo đảm latest draft durable và immutable operation ordering, field merge protected vault. |
| F4 — P2 | API danh sách đính kèm dùng `SELECT *`, kéo cả BLOB dù chỉ trả metadata. Với giới hạn100 MiB/note, một lần lấy danh sách có thể đọc lượng file lớn không cần thiết. | `backend/attachments.py:99`: đổi projection sang id/name/kind/media_type/size/created_at, giữ access trong transaction. Đây là nhận xét từ source/giới hạn, chưa benchmark RAM/latency endpoint này. |
| F5 — P1 trước public | Bearer token nằm trong record `session` không mã hóa; EncryptedAccountStore chỉ mã hóa key bắt đầu `account:`. Cô lập UI account không thay bảo vệ token lưu trên thiết bị. | `lib/state/app_controller.dart:534–535,582`; `lib/data/encrypted_account_store.dart:162–185`; `docs/ARCHITECTURE.md:15–16` cũng ghi giới hạn. Chuyển token sang storage phù hợp nền tảng, migration xóa bản cũ sau publish durable; kiểm tra reopen/logout/account switch. Web vẫn cần policy riêng, không tuyên bố secure storage loại bỏ mọi rủi ro same-origin/XSS. Chưa đọc token thật hoặc chứng minh có khai thác trong lượt này. |
| F6 — P2 | Tài liệu dễ làm người đọc hiểu sai hiện trạng: architecture còn ghi AI/retrieval/protected editing/offline unlock/email outbox chưa làm; README có câu Q&A chưa khả dụng; matrix row30 còn123/56 trong khi đầu file167/88. Báo cáo06/10 còn đề xuất release là bước ngay tiếp theo, trái thứ tự đã chọn sau đó. | `docs/ARCHITECTURE.md:57–63,77–80`; `README.md:192,351`; `docs/REQUIREMENTS_MATRIX.md` row30; `docs/PROJECT_REVIEW_2026-10-06.md:10`. Cập nhật tài liệu hiện trạng, tách phần lịch sử có nhãn rõ; giữ nguyên logs/manifest/báo cáo snapshot cũ. README/Readme phải tiếp tục bằng nhau. |

P1 là việc nên xử lý trước khi chốt chức năng hoặc nghiệm thu dịch vụ; P2 là cải tiến
độ ổn định/hiệu năng/bảo trì. Các phát hiện không đồng nghĩa mọi dữ liệu đã bị lộ hay
mọi luồng hiện tại đang lỗi.

## Đối chiếu đủ32 tiêu chí

“Có code/local evidence” dưới đây không đồng nghĩa đã nghiệm thu trên Web public và
native release cuối. Phạm vi từng ảnh/test/target nằm trong INDEX của evidence tương ứng.

| ID | Tiêu chí | Hiện tại | Phần còn thiếu hoặc chưa đủ |
|---:|---|---|---|
| 1 | Đăng ký | Email/name/password2 lần, hash, tự login, banner; local đã có bằng chứng | Register với email Internet và hai bản cuối; flow lỗi/duplicate trong demo |
| 2 | Kích hoạt | Code/TTL/one-time, durable SMTP queue/status, local TLS sink Web/native | Thư đến mailbox thật, verify và banner mất; SMTP accepted không chứng minh inbox |
| 3 | Login/logout | Session/backend guard/account cache isolation | Nghiệm thu session expiry/logout/account switch trên hai bản cuối; F5 |
| 4 | Reset mật khẩu | Email code/check/reset2 lần/session revoke/manual login; local TLS flow | Email thật và expected errors hai nền tảng cuối |
| 5 | Xem profile/avatar | Default/private avatar/cache theo account | Profile/avatar thống nhất trong nghiệm thu bản cuối |
| 6 | Sửa profile/avatar | Name/upload/canonical PNG/CAS/validation; actual picker có evidence | Native/Web cancel/denied và provider OS còn chưa đủ actual evidence |
| 7 | Đổi mật khẩu account | Kiểm tra current/new/confirmation, hủy sessions backend | Submit UI thật đầy đủ rồi login lại hai nền tảng; hiện một số evidence chỉ mở/hủy dialog |
| 8 | Preferences | Theme/font/grid, immutable field patches, server merge/idempotency, offline/reopen | Nghiệm thu hai bản cuối; không dùng last-server-accepted cho note content |
| 9 | List view | Responsive renderer, nhớ lựa chọn | Demo compact/tablet/desktop/bản cuối |
| 10 | Grid view | Mặc định grid, adaptive/lazy slivers, persist | Demo đổi/restore và text scale trên bản cuối |
| 11 | Tạo note | Stable ID, title/content, local draft/autosave/offline | Nghiệm thu create/reopen/sync hai bản cuối |
| 12 | Sửa note | Editor thường + protected editing/offline, frozen base/conflict | Protected editing đã có; không dùng báo cáo05/10 trước triển khai để gọi là thiếu. Full final flow vẫn cần chứng minh |
| 13 | Xóa note | Confirmation/owner/backend CAS; protected delete đã có | Protected Web actual confirm-delete chưa đủ bằng chứng; native debug đã có. Protected delete online-only, không có durable delete queue |
| 14 | Autosave/lifecycle | Immediate local draft,650ms debounce, save/failure status/Back/reopen tests | OS background/relaunch/force-kill thực chưa đủ; độ bền khác với test DB reopen; F3 |
| 15 | Ảnh/video | Private multi-attachment/validation/preview/Range; Web/native local | Protected native OS picker/media, cancel/denied/codecs/bản cuối cần nghiệm thu |
| 16 | File | PDF/TXT/CSV/ZIP; private download/native SAF/hash/delete | Native TXT upload bằng picker chưa đủ; protected native upload/download/OS cancel; F4 |
| 17 | Ghim/sắp xếp | Note thường đúng pin/time/tie-break; protected reader có pin | F2: home mất thứ tự ghim khi note khóa |
| 18 | Shared/pinned/locked | Note thường có kết hợp; protected metadata sau unlock | F2: list/grid note khóa chưa thể hiện đủ đồng thời |
| 19 | Live search | Title/content khi gõ300ms, cache, locked không đưa nội dung vào kết quả | Demo search/no-result/clear/phạm vi owned/shared trên bản cuối |
| 20 | CRUD nhãn | IDs/CAS/tombstones/rename-delete giữ notes; local/server evidence | Conflict UI nhiều thiết bị và native rename cần nghiệm thu trực tiếp |
| 21 | Gắn nhãn | Owner chọn nhiều label IDs, server role rules | Native editor thao tác gắn nhiều nhãn chưa đủ actual evidence |
| 22 | Lọc nhãn | AND theo IDs, rename giữ selection | Native tương tác lọc một/nhiều nhãn chưa đủ actual evidence |
| 23 | Bật/tắt bảo vệ | Password confirmation/current/hash/version/grants/backend rule | F1; full expected-error tests/actual flow hai bản cuối |
| 24 | Unlock/đổi password note | TTL/epoch/password encrypted cache/offline recovery/old-password handling | F1; protected AI/share/file advanced và đổi mật khẩu actual hai bản cuối; backup keys là cải tiến, không yêu cầu độc lập của đề |
| 25 | Chia sẻ/quyền | Batch registered emails, viewer/editor/revoke, Shared with me, owner/time/role, CAS | Protected native mutation/recipient UI và hai-client final acceptance; locked home owner/time đang ẩn theo policy |
| 26 | Realtime | Authenticated SSE invalidations/CAS/frozen base/clean updates/dirty conflict; protected đã có | Hai session Web/native với backend cuối và stress/reconnect/revoke; không cần viết CRDT/OT để đáp ứng đề |
| 27 | AI Summary | Gemini adapter/backend ACL/grant/budget, regenerate/no overwrite; fixture Web/native PASS | **LLM thật chưa chạy**; cần key mới/config khi nhóm sẵn sàng, quality/error/protected flow |
| 28 | AI Q&A nguồn | BM25 authorized chunks → LLM synthesis contract/citation/open/revalidation | **LLM thật chưa chạy**; multi-note quality/synonyms/insufficient data/prompt injection/protected sources cần evaluation thực |
| 29 | UI/UX/adaptive | Tokens/NotoSans/light-dark/prism/reduced motion/sections/200% widget/actual screenshots | Keyboard toàn luồng, NVDA/TalkBack, browser Back/deep link/refresh, native renderer mặc định/frame profiling chưa nghiệm thu đầy đủ |
| 30 | Architecture/state/tests | Một core Flutter/ChangeNotifier/data/backend; meaningful unit/widget/integration đã vượt tối thiểu | Tài liệu kiến trúc hiện trạng F6, clean clone reproducibility; không cần thêm tests chỉ để đếm; controller/home nên tách dần |
| 31 | Offline/sync | Account AES-GCM vault/Sembast, durable operations/conflict/recovery, password-bound protected cache | F3; multi-tab/quota/eviction/cold first-load/OS relaunch còn chưa đo; sync retry15s chưa backoff. Attachments online-only đã được nêu rõ |
| 32 | Build/public deploy | Local Web/APK build đã có; cùng Flutter source | Public Web HTTPS/backend ổn định/native final artifact chưa có; release API guard/signing/persistent hosting/clean clone làm cuối |

## Những cải tiến nên ưu tiên sau sửa lỗi

### Performance và độ ổn định

1. Giảm full-account writes theo F3, giữ journal/transaction/migration và test mất ACK,
   reopen, latest keystroke, account switch, remote lock/revoke. Không thay immediate
   draft persistence bằng debounce dài chỉ để có benchmark đẹp.
2. Giảm đọc BLOB ở attachment listing theo F4; giữ authenticated download và recheck
   quyền/grant. Upload/preview không tạo URL public lâu dài.
3. HTTP note sync vẫn mỗi15s đọc profile hai lần, catalogue và toàn bộ notes; SSE cũng
   kích hoạt refresh toàn bộ. Cân nhắc version/delta hoặc bounded paging sau khi định
   nghĩa cách giữ snapshot đầy đủ, deleted/revoked notes và offline cache. Chưa load-test.
4. Sync retry có backoff/jitter và retry theo lỗi; SSE đã có backoff1–30s, không gọi cả
   dự án “chưa có backoff”. GET routes dùng transaction BEGIN IMMEDIATE nên cạnh tranh
   write lock; chỉ tách read transactions khi vẫn giữ check quyền+snapshot nhất quán.
5. Backup/restore SQLite + mail key, bảo trì expired sessions/tokens/operation journals
   cần policy trước vận hành. Không tự xóa journal đang cần idempotent replay.

### UI/UX

- Giữ title/content/counter tách rõ đã sửa; ưu tiên kiểm tra dialog/permission errors,
  tên file/email/label dài,200% text và bàn phím mobile ở các màn hình còn lại.
- Thu gọn vùng trạng thái trên mobile theo không gian, giữ saving/local saved/pending/
  server synced/error dễ phân biệt. Tránh thêm nhiều khung/hiệu ứng làm giảm vùng viết.
- Tổ chức tools bằng nhóm có nhãn nhất quán giữa editor thường và protected reader.
  Outline/checklist/focus hiện chủ yếu ở editor thường; có thể đưa vào protected editor
  với đầy đủ grant/dirty/revoke guards. Đây là nâng cấp ngoài đề.
- Keyboard: kiểm tra Tab/Enter/Escape, focus quay về control mở dialog, Ctrl+F đã có;
  thêm phím tắt tạo note nếu hợp lý. Navigation hiện dùng MaterialApp home và imperative
  routes, chưa có routing theo URL note/deep links đã được chứng minh.
- Đo frame/input latency ở native renderer mặc định/Web profile trước thêm animation.
  Benchmark paragraph/search đang có không chứng minh animation60FPS. Có thể nghiệm thu
  trên emulator phù hợp; điện thoại thật là tăng độ tin cậy, không tự biến thành điều
  kiện bắt buộc khác đề.

### Kiến trúc và sáng tạo

- `AppController`1.382 dòng và `home.dart`1.633 dòng: tách profile/preferences/labels/sync
  và settings/label manager/card thành component/service có trách nhiệm rõ. Giữ
  ChangeNotifier và invariants, không rewrite toàn bộ framework.
- Chưa có `.github/workflows`: thêm CI format/analyze/unit/widget/backend tests, dùng
  fixtures và config rõ; CI không tự chứng minh real LLM/mail/native release.
- Có6 mẫu, outline/checklist/thống kê đọc/focus timer/prism responsive. Tiếp tục sáng tạo
  nên ưu tiên tiện ích giữ dữ liệu: lịch sử phiên bản/khôi phục xóa, upload progress/cancel
  và queue đính kèm bền, rồi tùy chỉnh màu từng note. Những tính năng này **chưa có**,
  cần thiết kế ACL/cache/offline trước implement; không bắt buộc bởi từng dòng rubric.
- Backup/transfer khóa local có thể tăng khả năng phục hồi khi mất thiết bị hoặc xóa
  browser storage. Hiện thiếu khóa thì giữ ciphertext nhưng không thể đọc; export
  backup phải có password gate, không xuất protected plaintext khi chưa unlock.

## Hồ sơ và dịch vụ còn thiếu

| Mục | Hiện tại / việc cần làm |
|---|---|
| Gemini | Code+fixture hoàn chỉnh local; provider thật chưa nghiệm thu. Không dùng lại key từng lộ output hoặc gửi key trong chat |
| SMTP Internet | Durable outbox/TLS sink PASS; chưa có mailbox receipt thật/production worker acceptance |
| Teamwork |3 commit cùng Bahung; chưa chứng minh Long có đóng góp riêng,4 tuần mỗi người≥2 meaningful commits/tuần. Không sửa tác giả/backdate/chia commit giả |
| Lịch và phân công |2 thành viên/deadline trước tháng12 đã xác nhận; ngày/giờ deadline,4 tuần chính thức/phân công thực tế chưa chốt |
| Rubric.xlsx | Chưa có file mẫu giảng viên đã điền; matrix không thay thế |
| Video | Chưa có video1080p/cả hai thành viên/timestamps thật. Mọi tiêu chí claim phải demo≥1 target; login/create-edit/attachments/offline/sharing hoặc realtime/≥1AI phải demo cả Web/native |
| Insights | Chưa có Screenshot.png hợp lệ cho4 tuần/contributors; Git log/ảnh app không thay thế |
| Public/release | Chưa URLs HTTPS/backend public/APK nghiệm thu cùng source cuối. API default loopback, Android release debug signing. Persistent deployment/backup/SMTP/LLM config còn cần làm |
| Source/gói nộp | Chưa clean clone/build/unpack final ZIP giữ .git và đủ source/release/video/rubric/readme/accounts. UI working changes hiện chưa trên GitHub |

Public deploy/video/Rubric/native artifact/source là điều kiện nộp theo PDF; không
phải “chỉ thiếu0,5đ release”. Mục teamwork có deduction0,5đ nếu không thỏa đủ, còn
vấn đáp xác minh hiểu biết/đóng góp từng người. Không tự dự đoán điểm nhóm.

## Bước tiếp theo cụ thể, giữ release cuối

1. **Sửa F1**, regression/API với bốn vai trò; giữ immutable operations/protection grants.
2. **Tối ưu F4 rồi F3**: F4 ít rủi ro; F3 cần migration/durability/reopen/race tests,
   đo lượng ghi và input latency cùng fixture trước/sau.
3. **Đồng bộ docs/matrix**, chuẩn hóa session storage và làm rõ F2 trước claim17/18 đầy đủ.
4. **Nghiệm thu các nhánh còn thiếu**: native labels/filter/password/avatar cancel-denied,
   protected attachment/share/AI, Web protected delete, keyboard/screen reader/relaunch.
5. **Nghiệm thu Gemini/email thật** khi nhóm chuẩn bị credentials; ghi đúng quality,
   permission/error/receipt, không dùng fixtures làm kết quả dịch vụ thật.
6. **Chuẩn bị teamwork/video/rubric song song**, rồi cuối cùng release/hosting/signing,
   clean-clone acceptance và gói nộp theo source đã publish được ủy quyền.

## Bằng chứng của lượt rà soát

- [Audit evidence](../evidence/2026-10-07-project-audit/INDEX.md).
- [Probe mật khẩu + metadata](../evidence/2026-10-07-project-audit/probe.json).
- [Lượng ghi encrypted envelopes](../evidence/2026-10-07-project-audit/write-volume.json).
- [Bộ kiểm tra hiện tại](../evidence/2026-10-06-editor-sections/INDEX.md).

Các probe hôm nay chạy ASGI/SQLite dùng một lần hoặc Flutter host với storage RAM.
Không đọc secrets/database người dùng, không nghiệm thu dịch vụ thật hoặc tạo bằng chứng
Web/native mới trong lượt này. Những phần chưa chạy được ghi là chưa nghiệm thu.
