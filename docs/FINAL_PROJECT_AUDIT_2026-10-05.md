# Đối chiếu NoteTogether với đề cuối kỳ — 05/10/2026

## Kết luận

NoteTogether đã có nền tảng chức năng đáng kể, nhưng **chưa sẵn sàng nộp bài**.
Hai chức năng AI chưa triển khai; Web/backend chưa triển khai công khai; luồng ghi chú
bảo vệ còn thiếu thao tác; email mới được kiểm chứng với SMTP TLS local. Hồ sơ nộp,
video và bằng chứng đóng góp bốn tuần chưa hoàn tất.

Không quy đổi số test hoặc số màn hình thành phần trăm hoàn thành/điểm dự kiến.
Điểm do giảng viên quyết định trên hành vi thật của các bản được nộp và vấn đáp.

## Nguồn và phạm vi rà soát

- Nguồn chính: `C:/Users/LENOVO/Downloads/503107-FinalProject-V1.pdf`, 19 trang.
  Đã đọc văn bản các trang 1–19, xem ảnh trang 14 và 18 để kiểm tra bảng rubric
  và điều kiện nộp. Mô tả chi tiết trang 2–8 cũng là yêu cầu, không chỉ bảng 32 mục.
- Đọc `PROMPT_CHO_AGENT.md`, `AGENTS.md`, `STATUS.md`,
  `docs/REQUIREMENTS_MATRIX.md`, `docs/TEAM_CONTRIBUTIONS.md`, README và các tài liệu
  protection/email/attachments/realtime/UI/offline/submission liên quan.
- Kiểm tra mã Flutter/backend, cấu hình build Android/Web, source tests và evidence.
  Lượt này là rà soát: không sửa mã ứng dụng, không deploy/push, không chạy lại bộ
  test hoặc browser/native QA.
- Local HEAD và `git ls-remote origin refs/heads/master` cùng là
  `aded41ec0ccdbfb46cae579b64ef3eab004f68bf`.
  Repository: <https://github.com/bahungTDTU/final-flutter>.
- Trước khi thêm báo cáo này, `git status --short --branch` sạch.
  Báo cáo là tài liệu local mới; không phải bằng chứng đã push hoặc đã nộp.

### Bằng chứng đã chạy và kiểm tra hôm nay

| Ngày | Lệnh/bằng chứng | Target và kết quả | Giới hạn |
|---|---|---|---|
| 05/10/2026 | `.venv/Scripts/python.exe evidence/2026-10-03-maintenance/collect_manifest.py --verify` | PASS integrity: 138 source/docs inputs, 41 evidence files, 3 build artifacts | Kiểm tra hash; không chạy lại test hoặc QA |
| 05/10/2026 | `git rev-parse HEAD`, `git log --format=...`, `git ls-remote origin refs/heads/master` | Local/remote cùng `aded41e`; 2 commit, cùng tác giả Bahung | Không chứng minh commit nào được giảng viên tính là meaningful contribution |
| 03/10/2026 | `scripts/check.ps1`; [check-final.txt](../evidence/2026-10-03-maintenance/check-final.txt) | Format 57 files, 0 changes; analyze không issue; 123 Flutter + 56 backend PASS | Có 1 TestClient deprecation warning; đây là log lần chạy trước |
| 03/10/2026 | [api-acl.txt](../evidence/2026-10-03-maintenance/api-acl.txt) | HTTP thật: owner/viewer/editor/stranger read/write/share/protection PASS | Local, không thay kiểm tra backend public |
| 03/10/2026 | [Maintenance INDEX](../evidence/2026-10-03-maintenance/INDEX.md) | Chrome release local: offline edit → reload → reconnect, giữ note ID/content, revision 1→2 | Không phải public HTTPS; các flow khác có scope lịch sử riêng |
| 03/10/2026 | [android-core.txt](../evidence/2026-10-03-maintenance/android-core.txt) | API36 emulator debug, backend thật, Sembast/keys/reopen/offline core PASS | Skia software; reopen trong process; không phải full release acceptance hoặc OS force-kill |
| 03/10/2026 | [build-web.txt](../evidence/2026-10-03-maintenance/build-web.txt), [build-apk.txt](../evidence/2026-10-03-maintenance/build-apk.txt) | Web release và APK release 55.8 MB build PASS | APK dùng API local/debug signing; chưa nghiệm thu chức năng với backend public |

Các bằng chứng 01–02/10 về email, avatar, nhãn, attachments, protection, sharing,
realtime và UI vẫn được đọc theo đúng phiên bản/phạm vi trong từng INDEX.
Không coi mọi flow đó đã được chạy lại trên bundle cuối ngày 03/10.

## Đối chiếu 32 tiêu chí

Tổng trọng số: tài khoản 2.0; ghi chú cơ bản 3.5; nâng cao 2.5; yêu cầu khác 2.0.
Trọng số dưới đây là điểm của đề, **không phải điểm tự chấm**.

“Đã làm” nghĩa là có triển khai và bằng chứng ở phạm vi nêu trong hàng.
Mọi chức năng còn phải chạy đúng trên Web public/native release được nộp và được demo
theo trang 18. Hàng “cần nghiệm thu” không có nghĩa phải viết lại chức năng đã có.

| ID | Tiêu chí / trọng số | Hiện trạng | Phần cần hoàn thiện hoặc chứng minh |
|---:|---|---|---|
| 1 | Đăng ký — 0.25 | Đã có email/name/password 2 lần, Argon2id, tự đăng nhập, banner chưa xác minh; API tests và UI native thật | Nghiệm thu đăng ký với email thật trên hai bản cuối; kiểm tra lỗi/duplicate account |
| 2 | Kích hoạt — 0.25 | SMTP/TLS + mã email dùng một lần/TTL; Web và native local fixture đã PASS | Cấu hình dịch vụ thật; chứng minh thư tới mailbox, nhập mã, banner biến mất trên Web public/native release |
| 3 | Đăng nhập/đăng xuất — 0.25 | Session, auth guard, home theo account; backend và Chrome/native local có bằng chứng | Kiểm tra hai bản cuối, logout/session hết hạn/account switch, protected screen không vào được khi chưa login |
| 4 | Quên/reset mật khẩu — 0.25 | UI kiểm tra mã rồi password 2 lần; reset hủy session cũ và yêu cầu login thủ công; local SMTP PASS | Email thật và toàn bộ flow hai nền tảng; không dùng fixture code endpoint khi nộp |
| 5 | Xem profile/avatar — 0.25 | Profile/avatar private/default/cache per-account; local Web/native PASS | Nghiệm thu đồng nhất profile trên hai bản cuối; tài khoản chấm có dữ liệu |
| 6 | Sửa profile/avatar — 0.25 | Name, ảnh PNG/JPEG, type/size validation, upload/default; actual OS/Web picker có bằng chứng | Kiểm tra cancel/denied trên nền tảng thật và bản cuối; hiện các nhánh này chủ yếu dùng doubles |
| 7 | Đổi mật khẩu tài khoản — 0.25 | UI current/new/confirmation; API kiểm tra mật khẩu cũ, hủy session; backend regression PASS | Submit flow UI thật trên Web/native release và login lại; không chỉ mở/hủy dialog |
| 8 | Preferences — 0.25 | Theme/font/grid, outbox bền per-account, server field merge/idempotency; Web/native offline/reopen PASS | Chứng minh phục hồi/sync trên bản cuối; giữ immutable operations và chính sách riêng của preferences |
| 9 | List view — 0.25 | Đã có cùng home renderer, thích nghi và lưu lựa chọn | Demo list trên compact/desktop; nghiệm thu bản cuối |
| 10 | Grid view — 0.25 | Đã có, mặc định `grid=true`, lưu preferences; responsive tests | Demo default grid và đổi/restore view trên hai bản cuối |
| 11 | Tạo note — 0.25 | Title/content, ID ổn định, local draft và autosave; local Web/native core PASS | Demo tạo và server sync trên cả Web/native, gồm offline create |
| 12 | Sửa note — 0.25 | Dùng chung editor, frozen base revision, autosave/conflict; local PASS | Note thường đã có; **note còn bật bảo vệ chưa có protected editor**; giữ ID/base/selection khi bổ sung |
| 13 | Xóa-confirm — 0.25 | Note thường có confirm và outbox/API owner rule | **Không có UI xóa note đang bảo vệ sau unlock**; không buộc người dùng tắt bảo vệ để thay cho thao tác được yêu cầu |
| 14 | Autosave/lifecycle — 0.25 | Immediate durable draft, debounce 650 ms, saving/saved/error, Back/lifecycle flush, reopen/race tests | Kiểm tra background/đóng-mở app thực trên bản cuối; DB reopen trong test chưa phải OS relaunch |
| 15 | Ảnh/video — 0.25 | Nhiều ảnh/video, private ACL, actual chooser/preview H264 Web/native PASS | Protected reader chỉ xem, chưa upload/xóa dù owner/editor có quyền; nghiệm thu protected flow và cancel/denied trên bản cuối |
| 16 | File — 0.25 | PDF/TXT/CSV/ZIP có validation, authenticated download; Web download/native SAF export/hash có bằng chứng | Native TXT upload bằng picker và protected file management cần nghiệm thu; public API/bản cuối. Allowlist/giới hạn đã có tài liệu |
| 17 | Ghim/sắp xếp — 0.25 | Note thường có pin time descending, unpinned updated time, stable tie-break; unit/UI evidence | Trường pin/time bị bỏ khỏi note khóa; home không còn nhận biết note đã ghim đó. Cần đối chiếu UX/order khi pin rồi bật khóa, giữ yêu cầu riêng tư |
| 18 | Shared/pinned/locked indicators — 0.25 | Note thường có shared/pin; note khóa có lock và role; local UI/ACL tests | Note khóa chưa có đầy đủ chỉ báo kết hợp; reader sau unlock chưa hiển thị các metadata này. Hoàn thiện trạng thái được phép sau unlock, không lộ metadata trước unlock |
| 19 | Live search — 0.25 | Title/content, delay 300 ms, không cần Search button; UI tests/Chrome có bằng chứng | Demo kết quả/empty/clear và hành vi note khóa trên bản cuối |
| 20 | CRUD nhãn — 0.25 | Server IDs/revision/tombstone, rename/delete giữ notes, offline outbox; Web/native/controller/API evidence | Nghiệm thu rename/delete/conflict UI trên hai bản cuối; không coi chỉ test controller là native UI flow |
| 21 | Gắn nhiều nhãn — 0.25 | Editor IDs, server owner rules, rename/delete liên kết; Web UI + native controller/API PASS | Native thao tác gắn nhãn trong editor cần nghiệm thu trực tiếp |
| 22 | Lọc nhãn — 0.25 | Home AND filters theo ID, rename giữ selection; Chrome + widget PASS | Native thao tác lọc một/nhiều nhãn cần chạy thực trên bản cuối |
| 23 | Bật/tắt bảo vệ — 0.5 | Mật khẩu riêng/hash, confirmation/current password, server rules; online Web/native PASS | Không coi đây là hoàn thành cả vòng đời note khóa: bổ sung protected edit/delete/files và kiểm tra expected errors |
| 24 | Unlock/đổi mật khẩu note — 0.5 | Online grant theo session/version/TTL, unlock/relock/change, late-response/privacy guards; local PASS | Reader chỉ đọc; không giữ protected content để dùng offline. Chốt/test hành vi offline bảo vệ và quyền theo mô tả trang 4, 6–7 |
| 25 | Share/receive/permissions — 0.5 | Batch email registered users, viewer/editor/revoke, dedicated section, owner/time/role, backend ACL; local Web/native PASS | Protected reader **đã nối ShareDialog**, cần nghiệm thu thật; shared owner/time sau unlock chưa hiển thị trong reader; nghiệm thu bản public/release |
| 26 | Realtime — 0.5 | Authenticated SSE, automatic clean-editor updates, reconnect, CAS/conflict/revoke; Web 2 contexts/native/API thật PASS | Protected reader che nội dung khi revision tăng và đòi unlock lại; chưa đáp ứng automatic content updates cho nhánh này. Kiểm tra hai client thật trên backend public |
| 27 | AI Summary — 0.25 | **Chưa triển khai** | LLM qua backend, generate/regenerate, không ghi đè note; server ACL + unlock grant; loading/error; chạy Web/native |
| 28 | AI Q&A có nguồn — 0.25 | **Chưa triển khai**; UI thông báo chưa khả dụng, không có API LLM/retrieval | Retrieve notes authorized/unlocked, câu trả lời có căn cứ, citation mở đúng note trên hai nền tảng, insufficient-data; không dùng live search thay AI |
| 29 | UI/UX/accessibility/adaptive — 0.5 | Light/dark/prism, touch/mouse, reduced motion, loading/empty/error, responsive 320px/landscape/200%, selected contrast tests; local screenshots | Nghiệm thu keyboard/focus/semantics và protected/AI screens; native renderer mặc định còn thiếu bằng chứng ổn định; chưa đo FPS, chưa manual screen reader audit |
| 30 | Architecture/state/tests — 0.5 | Một Flutter core, ChangeNotifier, presentation/state/data/backend tách; có ≥3 meaningful unit + ≥3 widget và real critical integration; analyze sạch trong log 03/10 | Nền tảng kỹ thuật/tối thiểu tests đã có. Verify clean clone/build tái lập; nhóm giải thích và sửa được code; không bắt buộc đổi framework/thêm tests chỉ để tăng số lượng |
| 31 | Offline persistence/sync — 0.5 | Sembast/IndexedDB, encrypted account snapshots, immutable queue/replay/conflict/recovery; Web offline reload/reconnect + native DB reopen PASS | Chứng minh read/create/edit/account switch/conflict hai bản cuối; protected content hiện online-only là giới hạn cần xử lý/giải thích riêng |
| 32 | Build/public deploy — 0.5 | Web/APK build release local PASS; **chưa có Web HTTPS/backend public** | Deploy Web + backend/email/LLM ổn định trong thời gian chấm; build APK trỏ HTTPS thật và test install/run/core; URL + artifact + reproducible configuration |

## Khoảng trống chức năng ưu tiên

### 1. AI Summary và Q&A — chưa có triển khai

Trang 5 và 13 yêu cầu cả hai. `.env.example:14–16` chỉ có LLM placeholders;
`lib/ui/home.dart:324` báo Q&A chưa khả dụng. Không có backend AI endpoint hoặc
retrieval/citation implementation. Fixture UI và live search không thay chức năng này.

Nghiệm thu cần dùng LLM thật; giữ key ở backend. Summary hỗ trợ regenerate, không ghi
đè note. Q&A chỉ dùng nguồn có quyền và đã unlock, có link mở source notes trên Web/native,
trả lời thiếu dữ liệu khi không có căn cứ. Kiểm tra viewer/editor/stranger, revoke,
lock/TTL trong quá trình request, lỗi mạng/provider và không đưa nội dung trái quyền
vào prompt/kết quả. Đề không bắt buộc vector DB hoặc một nhà cung cấp cụ thể.

### 2. Vòng đời note bảo vệ — có server spine nhưng client chưa đầy đủ

Trang 4 yêu cầu nhập mật khẩu trước xem/sửa/xóa/share/summary và các thao tác khác.
Source xác nhận:

- `lib/ui/note_protection.dart:419`: phiên chỉ đọc, chưa protected editing/offline unlock.
- `lib/state/app_controller.dart:534–535`: delete trả về ngay nếu `note.locked`;
  menu home không xuất hiện cho note khóa, reader không có delete-confirm.
- `lib/ui/note_protection.dart:369`: attachment dialog luôn `canEdit: false`, ngay cả
  khi owner/editor đã unlock. Xem file và quản lý chia sẻ **đã có nối UI**, không phải thiếu code.
- `lib/state/protected_reader.dart:36–37`: revision mới làm hide và yêu cầu mở khóa
  lại; đây là khoảng trống realtime protected content theo kiểm tra mã, chưa chạy
  lại browser/native để quan sát trong lượt audit này.
- `backend/note_listing.py:34–38` chỉ trả id/locked/revision/role cho note khóa.
  Home vì vậy mất pin time/shared metadata; reader cũng chưa thể hiện đủ sau unlock.

Cần bổ sung hành vi khi đang có grant và đúng role, giữ frozen base/recovery/race guards.
**Không giải quyết bằng cách trả metadata/nội dung khóa ra cache/list trước unlock**
hoặc bắt người dùng tắt bảo vệ để thao tác. Backend đã có grant/ACL cho nhiều endpoint;
phải kiểm chứng client và server cùng thực thi, không suy từ API support ra UI hoàn chỉnh.

Offline protected notes là giới hạn thật: chỉ RAM route, offline/background đóng phiên.
Trang 6 yêu cầu nội dung đã tải có thể dùng offline, trang 7 yêu cầu bảo vệ nhất quán
trên cache; cần chốt phương án an toàn và nghiệm thu. PDF không chỉ định cơ chế key backup,
E2E encryption hay thời hạn unlock cụ thể.

### 3. Email thật — đã có code, còn thiếu tích hợp và bằng chứng

Flow activation/reset đã chạy qua SMTP TLS sink local trên Web và Android.
`docs/EMAIL_DELIVERY.md` phân biệt `smtp_accepted` với thư thực sự đến inbox.
Chưa có bằng chứng mailbox Internet và backend public; không kết luận email production hoạt động.

Nghiệm thu tối thiểu: register auto-login và thư kích hoạt; resend/cooldown/sai-hết hạn;
verify bỏ banner; reset bằng mã email rồi manual login; session cũ bị hủy. Chạy trên
hai bản được nộp, không deploy QA code-reader endpoint. Durable mail outbox là giải
pháp nâng độ ổn định, không phải một dòng rubric độc lập.

### 4. Public deploy và native artifact thật — điều kiện chấm/nộp còn thiếu

Trang 6/14 yêu cầu Flutter Web HTTPS và backend public chạy suốt thời gian chấm.
Localhost, Dockerfile hoặc build PASS không thay triển khai công khai.

APK hiện tồn tại ở `build/app/outputs/flutter-apk/app-release.apk`, 58,544,388 bytes.
Lệnh build/log hiện dùng API local; `scripts/build.ps1` mặc định
`http://127.0.0.1:8000`. Thiết bị giảng viên không có backend của nhóm tại loopback này.
README xác nhận release Android chỉ dùng HTTPS; lần functional integration là debug
với adb reverse. Release smoke màn hình login chưa chứng minh mandatory core features.

Nghiệm thu cần public API/CORS/SMTP/LLM, SQLite/data lưu bền, SSE qua hosting/proxy,
Web từ mạng khác, APK cấu hình API HTTPS đúng, install/login/core/offline/collaboration/AI.
Không cần iOS hoặc đồng thời Windows/macOS: Web + một native target là đủ; nhóm đang chọn Android.

## Hồ sơ nộp và đóng góp

Trang 17–18 yêu cầu các thành phần dưới đây. File hướng dẫn/checklist hiện có chỉ
chuẩn bị cho việc hoàn thiện; không thay deliverable thật.

| Thành phần | Hiện trạng | Cần làm |
|---|---|---|
| `Rubric.xlsx` | Không tìm thấy; checklist ghi đang chờ mẫu giảng viên | Lấy mẫu gốc, tự đánh giá trung thực, điền public Web URL/native artifact/repo/grading accounts |
| `source/` | Có source đầy đủ trong repo nhưng chưa có bộ nộp clone sạch | Clone GitHub đúng commit, giữ `.git`, tests/lockfiles/backend/schema/config; bỏ caches/generated outputs; thử setup/build trên clone sạch |
| `release/web-url.txt` | Chưa có thư mục release hoặc URL public | Ghi URL Web HTTPS thật; backend phải truy cập được và hoạt động trong kỳ chấm |
| Native release | APK local đã build, chưa đủ functional public-release acceptance | Build từ source cuối với API HTTPS; kiểm tra cài/chạy; copy artifact đúng vào `release/` |
| `demo.mp4` hoặc YouTube link | Chưa có video; mới có `docs/DEMO_SCRIPT.md` | ≥1080p, rõ audio/narration, có cả Hùng và Long; xem yêu cầu coverage bên dưới |
| `Readme.txt` | Có SDK/lệnh/architecture/offline/config/limitations, khớp README hiện tại | Bổ sung hosting/public URLs/artifact thật/grading accounts có dữ liệu; kiểm chứng các lệnh từ source sạch |
| `Screenshot.png` Insights | Chưa có; history chưa đáp ứng teamwork | Chỉ lấy từ GitHub Insights khi đủ thực tế; CLI/Git log/screenshot UI khác không thay được |
| Thư mục/ZIP đúng tên | Chưa có gói nộp | `523K0006_NguyenBaHung_523K0014_NguyenBaoLong.zip`, nội dung trong thư mục cùng tên; giải nén thử, kiểm tra `.git`, URL, artifact và đủ files |
| Deadline/phân công | Deadline chỉ biết trước tháng 12/2026; chưa ngày/giờ/start chính thức/phân công xác nhận | Nhóm xác nhận lịch học phần và việc mỗi người thực sự làm; chuẩn bị vấn đáp/sửa code |

### Video là điều kiện nghiệm thu, không chỉ minh họa

Trang 18: mỗi tiêu chí đã triển khai phải được demo trên ít nhất một nền tảng được nộp;
tiêu chí không demo được xem là chưa triển khai. Ngoài ra, **login, create/edit,
attachments, offline synchronization, sharing hoặc realtime, và ít nhất một AI feature**
phải được demo trên **cả Web và native**. Giới thiệu architecture/state/backend/local
persistence/platforms; cả hai thành viên tham gia. Không yêu cầu tự đặt một thời lượng
video tối thiểu không có trong đề. Timestamp chỉ điền sau khi có video thật.

### GitHub teamwork chưa đạt

History hiện có:

- `35ee911`, 02/10/2026: initial import, author Bahung.
- `aded41e`, 03/10/2026: maintenance, author Bahung.

Cả hai nằm trong tuần 28/09–04/10/2026. Chưa thấy commit tác giả Nguyễn Bảo Long;
chưa có bốn tuần liên tiếp. Không tự gọi hai commit hiện có là hai meaningful commits
được chấp nhận: đề yêu cầu đóng góp thật, có thể nhận diện và giải thích được.

Trang 15–16 yêu cầu mỗi thành viên ≥2 meaningful commits/mỗi tuần trong **4 tuần lịch
liên tiếp**, thứ Hai–Chủ nhật, thuộc thời gian phát triển chính thức. Với hai người,
số tối thiểu là 16 commit đủ điều kiện, phân bố đúng người và tuần; tổng 16 tự nó không đủ.
Commit phải dùng GitHub identity riêng, push và còn trong history nộp. Không backdate,
đổi author, chia commit vụn hoặc gán code agent hỗ trợ thành đóng góp độc lập của Long.

Không đáp ứng hoặc không có bằng chứng xác minh: **trừ 0.5 điểm cả nhóm**, không phải
tự động 0 điểm toàn bài. Trang 16 cho phép bỏ Git evidence khi chấp nhận khoản trừ,
nhưng trang 17 vẫn yêu cầu source clone giữ `.git`; cách chuẩn bị ít rủi ro là luôn
giữ source clone hợp lệ và khai trung thực teamwork.

### Điều kiện 0 điểm và các khoản trừ đáng lưu ý

- Trang 18: thiếu **source, demo video, Rubric.xlsx, public Flutter Web URL hoặc
  required native artifact** khi nộp: cả nhóm 0 điểm. Đây là rủi ro hồ sơ quan trọng
  hơn việc chỉ thiếu một tính năng 0.25 điểm.
- Trang 19: hướng dẫn setup phức tạp/không đúng gây không build/run được: trừ 2 điểm;
  không dọn generated outputs/caches/thừa: trừ 0.5; thiếu thông tin chấm/URL không
  truy cập/native invalid/sai tên: trừ 1; mỗi ngày trễ trừ 1 điểm.
- Vấn đáp có thể điều chỉnh điểm cá nhân; nhóm được dùng AI theo xác nhận người dùng,
  nhưng mỗi người vẫn phải hiểu và sửa được phần việc mình nhận. Không giả contribution.

Các điều kiện trên áp dụng khi nộp; báo cáo hiện tại không khẳng định bài đang được chấm 0 điểm.

## Phân biệt yêu cầu bắt buộc với đề xuất tăng độ ổn định

Bắt buộc: đúng chức năng/ACL/hash/giữ offline edits/cô lập account/conflicts, hai AI
features, UI accessible/adaptive, tests tối thiểu có ý nghĩa, Web public HTTPS/backend,
native artifact hoạt động, hồ sơ/video và thông tin chấm chính xác.

Những mục sau hữu ích nhưng **không được ghi thành tiêu chí bắt buộc riêng trong PDF**:

- iOS, kiểm thử physical device cụ thể, NVDA/TalkBack cụ thể hoặc một con số FPS/60fps.
  Accessibility và app hoạt động đúng vẫn cần kiểm chứng; hiện chưa có các bằng chứng này.
- OT/CRDT, cursor/presence, merge từng ký tự. SSE + conflict strategy có thể đáp ứng
  realtime nếu người có quyền quan sát được cập nhật tự động và không mất bản local.
- Vector database, cloud provider/framework/state package cụ thể, CI workflow riêng.
- Offline upload queue cho media, hỗ trợ mọi codec/extension/camera và gallery đồng thời.
  Đề cho phép chọn cách picker phù hợp; phải validate và xử lý cancel/denied thật.
- Key backup/export hoặc E2E encryption cụ thể; đây là lựa chọn kỹ thuật để bảo vệ
  dữ liệu, không thay yêu cầu unlock/ACL/cache isolation.
- Keystore release riêng: cấu hình hiện dùng debug key; nên hoàn thiện trước phân phối,
  nhưng PDF không chỉ định loại keystore. Điều kiện trực tiếp là release artifact
  hợp lệ, cài/chạy được, đúng source/core features và không lộ private signing key.
- Durable email outbox, retry backoff, distributed quotas, malware scanner/full codec
  parser và load/stress benchmarks riêng. Ưu tiên khi cần để bảo đảm reliability/security;
  không dùng danh sách này để kết luận toàn bộ chức năng cơ bản chưa được triển khai.

## Thứ tự hoàn thiện đề xuất

1. **Bắt đầu ngay đóng góp thật của cả hai người trong các tuần hợp lệ.** Việc này
   diễn ra xuyên suốt, không thể làm dồn lúc đóng gói. Chốt phân công và ngày chính thức.
2. Hoàn thiện protected edit/delete/file management và metadata/realtime sau unlock;
   giữ privacy/frozen base/encrypted recovery. Chạy negative ACL và các race liên quan.
3. Triển khai cả AI Summary và Q&A/citations qua backend, kiểm chứng với LLM thật
   và quyền protected notes. Chưa có key/provider không được báo AI hoạt động.
4. Cấu hình email thật và Web/backend public HTTPS, persistent storage/SSE; build
   APK từ cùng source với API public. Chuẩn bị mọi cấu hình trước bước deploy được ủy quyền.
5. Nghiệm thu ma trận hành vi trên hai bản cuối: auth/profile/preferences, protected
   notes/files, labels native UI, offline/account isolation/conflict/realtime/AI,
   keyboard/adaptive/accessibility; thêm evidence theo ngày/command/target/result/commit thật.
6. Quay video đúng coverage, nhận/điền Rubric.xlsx, tạo grading accounts có dữ liệu,
   hoàn thiện Readme/Insights, clone sạch và đóng gói/giải nén kiểm tra bộ nộp.

**Bước kỹ thuật nên làm tiếp: vòng đời ghi chú bảo vệ, sau đó AI.** Làm song song
với việc nhóm xây dựng lịch sử đóng góp thật và chuẩn bị điều kiện hosting/email/LLM.
Không cần tiếp tục thêm trang trí UI trước các khoảng trống bắt buộc này.

Ma trận hiện tại dùng một số nhãn chung “đã code một phần/chưa nghiệm thu đủ” cho các
luồng đã có bằng chứng local. Báo cáo này phân biệt rõ thiếu implementation và thiếu
final-platform acceptance; chưa tự sửa STATUS/matrix hoặc tự đánh dấu full điểm.
