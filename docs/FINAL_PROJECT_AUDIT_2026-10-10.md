# Đối chiếu NoteTogether với đề cuối kỳ —10/10/2026

## Kết luận

Phần lớn chức năng bắt buộc đã có mã và bằng chứng local, gồm tài khoản, CRUD,
nhãn/avatar, bảo vệ, đính kèm, chia sẻ, realtime, offline và hai tính năng AI.
**Dự án chưa đủ điều kiện gọi là hoàn tất đề hoặc sẵn sàng nộp.**

Khoảng trống chính: AI/email với dịch vụ thật; nghiệm thu Android và các nhánh còn
thiếu trên editor/theme mới; lỗi thứ tự ghi chú khóa chưa ghim; tài liệu hiện trạng;
public Web/backend và artifact native cuối; video/Rubric/gói nộp; đóng góp thật hai
thành viên trong4 tuần. Không suy điểm hoặc phần trăm hoàn thành từ số test.

Release/public hosting/signing và đóng gói vẫn để cuối theo yêu cầu người dùng.
Các nâng cấp editor như Word, outline/checklist/focus timer liên quan đúng ứng dụng,
nhưng không thay thế yêu cầu bắt buộc hoặc tự tạo một mục điểm sáng tạo riêng trong rubric.

## Nguồn và phạm vi

- PDF gốc: [503107-FinalProject-V1.pdf](<C:/Users/LENOVO/Downloads/503107-FinalProject-V1.pdf>),
 19 trang; SHA256 `63ea45a11778b4b60bd71ae79038b991cda54f90d429365345fe488cb5c6f907`.
 Đọc mô tả tr.1–9,32 mục rubric tr.9–14, teamwork/vấn đáp tr.14–17 và đầu ra tr.17–19.
 Xem ảnh trang13/14/16/17. PDF quy định học phần, không phải ủy quyền nộp/merge/deploy.
- Source audit: `a5e5ec60568b7ee2b0c50290a3e6502a4d490110`, branch
 `codex/adaptive-word-editor`, [PR#3](https://github.com/bahungTDTU/final-flutter/pull/3).
 Master vẫn `efbb8e7`; editor/theme mới nằm trong PR, chưa merge khi đọc GitHub.
- Đọc AGENTS/prompt, STATUS, matrix, README/Readme, TEAM, submission/demo, kiến trúc,
 AI/email/release runbook; đối chiếu các module và tests/evidence liên quan.
- Source hash09/10:192 file, chỉ STATUS khác do thông tin publication10/10; runtime,
 test code và README còn khớp. README/Readme byte-identical.
- Hôm nay không chạy lại full suites, browser/native, SMTP Internet hoặc Gemini.
 Chạy thêm1 probe temporary cho thứ tự list, **FAIL**; không cộng vào210 tests.
 Không sửa runtime, matrix hoặc tài liệu cũ; báo cáo này giữ riêng.
- [Evidence audit](../evidence/2026-10-10-rubric-audit/INDEX.md) có probe, integrity,
 lịch sử Git và snapshot CI. Các PASS cũ áp dụng đúng phiên bản/target trong INDEX.

## Kết quả kiểm tra

| Kiểm tra | Trạng thái | Ý nghĩa/giới hạn |
| --- | --- | --- |
| Format/analyze/full Flutter09/10 | PASS,95files0changes/noissues/210 tests | Source runtime/test code còn khớp; không gọi đây là chạy lại10/10 |
| Full backend09/10 | PASS,108 tests | Source backend còn khớp;1 warning upstream không phải test failure |
| Chrome editor09/10 | PASS,8luồng/5viewport/14ảnh,0errors/warnings | Keyboard/format/save/reload/roles/protected; AI chỉ fixture |
| Web release và APK debug09/10 | PASS compile | Backend local; không public deployment/native release acceptance |
| CI PR#3 ngày10/10 | PASS cả3: Flutter quality/Backend tests/Build smoke | Trên đúng head a5e5ec6; PR vẫn open, reviews=[] khi đọc |
| Probe order10/10 | FAIL | Newest unpinned protected fixture bị đưa sau older ordinary fixture |
| Native editor/theme hiện tại, IME, accessibility thực | NOT RUN | Native lịch sử đã có, không chứng minh source Quill mới |
| AI LLM thật, email đến inbox Internet | NOT RUN theo evidence hiện có | Không kết luận key/provider chưa cấu hình chỉ từ thiếu bằng chứng |
| Public Web/backend/native final/clean-clone/video | Chưa có acceptance/đầu ra cuối | Các gate bắt buộc trước nộp |

## Đối chiếu32 tiêu chí

Điểm là **trọng số của đề**, không phải điểm tự chấm. IMPLEMENTED nghĩa là có mã;
PASS local/historical chỉ trong phạm vi evidence. Mỗi hàng còn cần hoạt động trên
hai bản được nộp; video phải demo32 mục, với các luồng cốt lõi trên cả hai nền tảng.

| ID | Yêu cầu/điểm | Hiện trạng xác minh | Còn thiếu hoặc cần nghiệm thu |
| ---: | --- | --- | --- |
|1| Đăng ký/0.25 | IMPLEMENTED: email/name/password2lần, hash, tự login, banner; local tests/UI | Register/lỗi/duplicate trên hai bản cuối, gửi email thật |
|2| Kích hoạt/0.25 | IMPLEMENTED: mã1lần/TTL/resend, SMTP TLS/outbox/status, fixture Web/native PASS | NOT RUN inbox Internet → nhập mã → banner mất trên hai bản cuối |
|3| Login/logout/0.25 | IMPLEMENTED: guard/session/account isolation, encrypted session/migration/logout tombstone; local/native historical PASS | Session expiry/account switch/logout và không revive protected screen trên hai bản cuối |
|4| Reset mật khẩu/0.25 | IMPLEMENTED: email/code check/new password2lần, session revoke, manual login; TLS local native PASS | Email thật; Web/native end-to-end success/expired/reused/error |
|5| Xem profile/avatar/0.25 | IMPLEMENTED: default/private avatar/cache per-account, historical Web/native PASS | Tính nhất quán và reopen trên hai bản cuối |
|6| Sửa profile/avatar/0.25 | IMPLEMENTED: name, PNG/JPEG type/size/canonicalization/default; OS/Web picker historical PASS | Cancel/denied/provider thực và bản cuối; không chỉ doubles |
|7| Đổi mật khẩu account/0.25 | IMPLEMENTED: current/new/confirmation, API hash/session revoke; widget validation/error | Success UI thật → manual login và old session401 trên Web/native; evidence hiện chưa đủ |
|8| Preferences/0.25 | IMPLEMENTED: theme/font/grid, durable immutable operations/server field merge; offline/reopen historical PASS | Apply/restore/sync trên source cuối, nhiều session |
|9| List view/0.25 | IMPLEMENTED: adaptive list, persist lựa chọn; Web/widget và native historical | Native/bản cuối, kết hợp locked/shared/pinned và text scale |
|10| Grid view/0.25 | IMPLEMENTED: default grid, adaptive cards, persist; Web/widget/native historical | Native/bản cuối, compact/tablet/landscape |
|11| Tạo note/0.25 | IMPLEMENTED: title/content, reusable editor, stable ID, draft/autosave/offline | Create/reopen/sync và rich input trên hai bản cuối |
|12| Sửa note/0.25 | IMPLEMENTED: ordinary/protected dùng DocumentWorkspace, frozen revision/CAS/recovery; Web rich edit PASS | Native rich editor; dirty conflict/remote lock/SSE/resize/theme trên source cuối |
|13| Xóa-confirm/0.25 | IMPLEMENTED: owner confirmation/CAS/ACL; protected delete đã có, native historical PASS | Actual protected Web confirm/cancel/delete/revoke; hai bản cuối; protected delete online-only được ghi rõ |
|14| Autosave/lifecycle/0.25 | IMPLEMENTED: durable draft projection, debounce650ms, status, lifecycle flush/reopen/race tests | Background/đóng-mở app thực với editor mới; không suy OS relaunch từ DB reopen |
|15| Đính kèm ảnh/video/0.25 | IMPLEMENTED: multi/private ACL/type-size/image/H264/Range; actual picker historical | Native protected picker, cancel/denied, playback trên hai bản cuối; media online-only |
|16| Đính kèm file/0.25 | IMPLEMENTED: PDF/TXT/CSV/ZIP, authenticated download/SAF/hash/delete; historical PASS | Native TXT upload qua picker và protected upload/export/cancel trên bản cuối |
|17| Ghim/sắp xếp/0.25 | PARTIAL: ghim đứng trước/pin time đúng, kể cả locked; **FAIL unpinned locked date order** | Sửa F1 mà không lộ ngày/metadata riêng tư; regression cho mixed list/grid/reload/offline |
|18| Shared/pinned/locked indicators/0.25 | IMPLEMENTED:3flags đồng thời, pin/shared boolean public; Web/native historical PASS | Nghiệm thu accessible labels/combination trên source cuối; giữ privacy policy |
|19| Live search/0.25 | IMPLEMENTED: title/visible content khi gõ300ms, rich text projection; Web PASS | Native search/clear/no-result; phạm vi locked theo policy được mô tả, không lộ content |
|20| CRUD nhãn/0.25 | IMPLEMENTED: server IDs/revision/tombstone, rename/delete giữ notes, offline outbox | Native rename/conflict UI thực; two-device final acceptance |
|21| Gắn nhiều nhãn/0.25 | IMPLEMENTED: editor IDs/owner rules; Web/controller/API PASS | Native thao tác nhiều nhãn trong editor mới, rename/delete vẫn đúng |
|22| Lọc nhãn/0.25 | IMPLEMENTED: AND selected IDs, apply/cancel/delete/rename giữ selection | Native tương tác một/nhiều nhãn trên source cuối |
|23| Bật/tắt bảo vệ/0.5 | IMPLEMENTED: password confirmation/current/hash/version, shared throttle unlock/change/disable, server grants | Hai bản cuối và expected errors; không dùng báo cáo cũ để gọi throttle chưa sửa |
|24| Unlock/đổi password note/0.5 | IMPLEMENTED: TTL/session/version, password-encrypted cache/draft/offline unlock/recovery; local historical PASS | Native rich editor sau unlock, change/relock/expiry/offline→online; dữ liệu/semantics bị che đúng |
|25| Share/receive/manage roles/0.5 | IMPLEMENTED: registered batch emails/viewer/editor/revoke, dedicated shared area/owner/time, backend ACL | Protected native mutation và recipient UI; owner/time hiện sau unlock theo policy; two-client final acceptance |
|26| Realtime/0.5 | IMPLEMENTED: authenticated SSE + refetch/CAS/frozen base, clean update/dirty conflict/revoke; historical Web/native | Hai client trên source rich hiện tại, reconnect/downgrade/lock; không cần CRDT/OT để đáp ứng đề |
|27| AI Summary/0.25 | IMPLEMENTED: Gemini server adapter, regenerate/no overwrite/ACL/error/unsynced gate; fixture Web/native PASS | **NOT RUN LLM thật**, chất lượng tóm tắt và protected/core trên hai bản cuối |
|28| AI Q&A có nguồn/0.25 | IMPLEMENTED: authorized BM25 retrieval + LLM synthesis/schema/citation open/source revalidation/no-data; fixture PASS | **NOT RUN LLM thật**, grounding/no-info/citation/đổi quyền trên hai bản cuối; BM25 không tự vi phạm đề vì answer có LLM synthesis |
|29| UI/UX/accessibility/adaptive/0.5 | IMPLEMENTED: theme chung, responsive desktop/phone riêng, keyboard/mouse/touch/loading/empty/error/read/zoom; Web rich QA PASS | Native hiện tại/IME/keyboard/accessibility thực; ảnh/widget không chứng minh TalkBack/NVDA |
|30| Architecture/state/tests/0.5 | IMPLEMENTED:1Flutter core, ChangeNotifier/domain/data/UI/backend/schema/docs; meaningful unit/widget/integration code vượt minimum3/3/1 | Full critical integration trên native mới; tài liệu F2 và clean-clone setup/build cần hoàn tất |
|31| Offline persistence/sync/0.5 | IMPLEMENTED: Sembast/encrypted account/session/drafts/password vault, immutable outbox/retry/CAS/account isolation; historical hai target | Rich document offline create/edit/reload/reopen/reconnect cùng ID/format trên hai bản cuối; OS lifecycle/quota/conflict |
|32| Cross-platform build/public deploy/0.5 | PARTIAL local compile; **public deployment và final native artifact chưa có** | Public HTTPS Web/backend hoạt động khi chấm; native release đúng source/API và install/run; config/build tái lập |

Tổng trọng số: account2.0 + simple notes3.5 + advanced2.5 + other2.0 =10.0.
Không đưa bảng/DOCX/PDF export, cursor đồng bộ, CRDT/OT, OAuth, push notification hay media
outbox thành yêu cầu độc lập của đề. Những thứ này là cải tiến tùy chọn; ưu tiên gate hiện có.

## Lệch chức năng cần sửa

### F1 —P2: thứ tự ghi chú khóa chưa ghim không theo ngày

PDF tr.3 yêu cầu mặc định sort creation/last-modified time, mới nhất trước; pinned đứng
trước unpinned. Phần pin đã đúng sau sửa07/10. Nhưng `lib/state/note_listing.dart:99–105`
dùng `''` thay updatedAt cho locked note. Kết quả: mọi locked unpinned xuống sau ordinary
unpinned có timestamp; giữa các locked unpinned dùng ID thay thời gian.
`backend/note_listing.py:34–43` cố ý không trả private dates và query không trả sort rank.

Probe10/10 từ một input list newest-first: expected `[protected-new, ordinary-old]`,
actual `[ordinary-old, protected-new]`; exit1. Đây là Flutter host unit probe trên dữ liệu
dùng một lần, không phải browser/API production acceptance. Test không sửa app hoặc tests
đang publish; [log](../evidence/2026-10-10-rubric-audit/locked-order-probe.txt).

Cần một cách bảo toàn thứ tự từ server/ordering metadata phù hợp và local fallback;
**không trả ngày/title/content/labels/share identities vào listing/cache để sửa sort**.
Đây là khoảng trống chức năng, không phải ACL bypass. Thêm regression mixed locked/ordinary,
pin/unpin, update/reload/offline và shared list trước khi gọi mục17 đầy đủ.

### F2 —P2: tài liệu hiện trạng chưa đồng bộ

- `docs/ARCHITECTURE.md:62–66` vẫn nói mail outbox, offline protected unlock/edit/realtime,
 LLM/retrieval chưa làm. Hiện code đã có; thiếu là dịch vụ thật/final acceptance.
- Matrix các hàng1/7/9/10/11/19 còn boilerplate “Đã code một phần”; row30 còn188/94,
 trong khi snapshot source hiện tại là210/108. Header có bổ sung lịch sử nhưng table chưa rõ.
- README/Readme vẫn có câu Q&A “chưa khả dụng” ở284/443, publication cũ; TEAM còn ghi
 editor/theme chưa được yêu cầu push dù đã có publication10/10.
- README và Readme giống nhau, nhưng giống nhau chưa chứng minh mọi câu đúng hiện tại.

Cần tách current summary và historical evidence. Cập nhật claim/links, giữ raw snapshots,
không viết lại ngày, test counts hoặc commit cũ. Không biến fixture thành nghiệm thu thật.

## Các gate ngoài32 tiêu chí

### Teamwork/Git/vấn đáp — chưa đáp ứng

PDF tr.15–16: mỗi người ≥2 meaningful commits mỗi tuần,4 tuần lịch liên tiếp Monday–Sunday
trong giai đoạn chính thức; các commits đã push và còn trong submitted history. Thiếu một
người/một tuần là không đủ, trừ0.5; không bù bằng số commit người kia hoặc backdate.

Refs fetch hôm nay:8 non-merge commits đều Bahung, từ02/10 đến10/10, trải2 tuần lịch.
Hai merge commits tên bahungTDTU cũng là Hùng, không phải thành viên thứ hai. Chưa thấy commit
của Long trong các refs đã fetch. Đây là inventory, không chứng nhận cả8 đều qualify hoặc
đã làm độc lập. Ngày bắt đầu4tuần chính thức và deadline chính xác chưa được xác nhận.

PR#3 còn open khi audit; branch chỉ push không chứng minh teamwork nếu cuối cùng bị bỏ
không đưa vào submitted history. Cần đóng góp thật/phân công đã xác nhận/merge sau review,
Insights screenshot đủ thời kỳ. Có AI hỗ trợ được phép theo xác nhận người dùng vẫn phải
giải thích/sửa được phần nhận trong vấn đáp (PDF tr.16–17/19).

### Submission — thiếu các đầu ra bắt buộc

Chưa tìm thấy trong tracked workspace: `Rubric.xlsx`, `demo.mp4`/link video đã quay,
`release/web-url.txt`, native release cuối/public URL, grading accounts đã nghiệm thu,
submission source clone sạch và ZIP cuối. Không kết luận file ở nơi khác của nhóm không tồn tại.
`Screenshot.png` Insights cũng chưa có; chỉ bắt buộc khi claim teamwork đủ. Theo tr.16 có thể
nhận -0.5 và không claim; tr.17 vẫn yêu cầu source clone giữ .git, nên chuẩn bị luôn theo đó.

PDF tr.18: thiếu source/video/Rubric/public Web URL/native release artifact là nguy cơ
**0 điểm cả nhóm**, không chỉ mất0.5 của tiêu chí32. Không tự tạo Rubric thay file giảng viên.
Video ≥1080p có cả hai người, demo32 mục; login/create/edit/attachments/offline/share hoặc
realtime/ít nhất1AI phải demo trên cả Web và native. Mục không demo bị coi chưa triển khai.

Build config hiện vẫn local: `scripts/build.ps1:1` mặc địnhAPI127.0.0.1, không có production
guard; `android/app/build.gradle.kts:33–36` release dùng debug signing. Đây là setup development,
chưa artifact cuối nối backend public. Release signing/preflight là bước chuẩn bị chất lượng;
đề yêu cầu artifact release chạy được, đúng source và không lộ secrets. Docker Compose không
tự động bắt buộc cho backend1serviceSQLite hiện tại; PDF chỉ yêu cầu khi cần multiple services.
Dockerfile/build local không thay public Flutter Web deployment.

## Thứ tự tiếp tục đề xuất

1. Sửa F1 và regression; đồng bộ current docs/matrix/TEAM (F2).
2. Nghiệm thu native editor mới: IME tiếng Việt, Select All/paste/undo/format/autosave,
 background/reopen/offline rich sync, protected TTL/relock/recovery, two-client SSE/conflict.
3. Đóng các nhánh còn thiếu: change account password success; protected Web delete;
 native labels/filter/rename; TXT/protected picker/export và OS cancel/denied.
4. Khi nhóm sẵn sàng provider: cấu hình key mới an toàn và chạy LLM thật Summary/Q&A
 với nguồn/ACL/no-data trên hai target; SMTP mailbox thật verify/reset. Chỉ ghi PASS sau receipt.
5. Teamwork/phân công/vấn đáp bắt đầu ngay và duy trì theo tuần; không chờ sát deadline.
6. Sau các phần trên mới release/public hosting/clean-clone/signing; cuối cùng quay video,
 điền Rubric giảng viên, tài khoản chấm/URLs/artifact và đóng gói đúng tên, giữ .git.

Các thứ tự này không phải ủy quyền tự deploy/merge/nộp bài. Lượt hiện tại chỉ audit và tạo report/evidence.
