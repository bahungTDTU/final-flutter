# Đánh giá kỹ thuật và kế hoạch hoàn thiện NoteTogether

Ngày 19/10/2026. Snapshot checkout `bae3159`,
base master đã biết `d59fdfd`. Đây là phân tích và kế hoạch, không phải nghiệm thu mới.
Lượt này không chạy lại test/runtime, không kiểm tra trạng thái GitHub trực tiếp và không
thay đổi app. PR10/CI/approval phải truy vấn lại trước hành động Git tiếp theo.

## 1. Kết luận kỹ thuật

NoteTogether đã vượt giai đoạn prototype về phạm vi tính năng và bảo vệ dữ liệu local.
Việc còn lại chủ yếu là ổn định bản cuối, nghiệm thu tích hợp thực tế và vận hành/phát hành.
Chưa đủ căn cứ gọi là production-ready hoặc sẵn sàng nộp. Không gán phần trăm hoàn thành:
số lượng test không đo được khả năng gửi email thật, nhập tiếng Việt bằng IME hay khôi phục
sau OS kill. Rủi ro mất dữ liệu/lộ quyền và thiếu đầu ra nộp quan trọng hơn thêm màn hình.

Giữ Flutter + ChangeNotifier + Sembast + FastAPI/SQLite. Chưa có bằng chứng cần đổi state
management, chuyển Firebase, microservices hoặc CRDT. SQLite hợp lý cho quy mô nhóm nhỏ;
không suy ra khả năng nhiều instance hoặc tải lớn. Chỉ refactor nhỏ khi giải quyết lỗi đã
tái hiện hoặc giảm rủi ro của thay đổi đang thực hiện.

## 2. Những gì đã làm và mức chứng minh

| Nhóm | Đã triển khai | Bằng chứng/giới hạn hiện có |
|---|---|---|
| Tài khoản | Đăng ký/login/logout, profile/avatar, preferences, verify/reset, quản lý phiên | API/widget và local TLS; inbox Internet và đổi password UI bản cuối chưa đủ |
| Ghi chú | Quill Delta, CRUD/autosave, grid/list/search/pin/labels, inspector adaptive | Web thực, native integration theo từng snapshot; native IME bản cuối còn mở |
| Offline | Encrypted account store, local drafts, immutable outbox, idempotency/CAS, recovery | DB reopen, Web reload, socket lỗi và conflict thực; chưa thay OS force-stop/relaunch |
| Bảo vệ | ACL server, session-bound grant, password vault, TTL/relock/revalidation | Nhiều test âm tính/race và UI lịch sử; OS background/TTL/cache bản cuối cần chạy |
| Tệp/chia sẻ | Private BLOB/Range, viewer/editor, revoke, authenticated SSE | API nhiều vai trò và UI; protected picker/cancel, một số hai-client variants còn thiếu |
| AI | Gemini adapter, summary, BM25 retrieval + synthesis/citations, ACL trước/sau inference | Fixture/mock có chủ đích; chưa có nghiệm thu Gemini thật và chất lượng đầu ra |
| UI bổ sung | Deskbook, inspector, planner/focus/workspace, light/dark, responsive | Đã có nhiều vòng cải tiến; nên giữ thiết kế hiện tại và sửa lỗi đo được |
| Release | HTTPS config guard, signing riêng, Compose/volume, backup/restore | Local guard/tests; engine/container, public HTTPS và APK ký thật chưa nghiệm thu |
| Git/CI | Branch/PR, pinned CI, ba required checks, evidence theo ngày | CI build smoke chỉ Web local + APK debug; không chứng minh release chạy đúng |

Evidence 19/10 ghi 148 backend tests PASS, 16 backup/email queue và 7 backup/CLI.
Evidence integration 13/10 ghi 279 Flutter/143 backend. Đây là các lần chạy khác nhau,
không ghép thành tuyên bố đã chạy toàn bộ suite tại `bae3159` trong lượt phân tích này.
PR8/9 đã có merge trong local history. Hai commit mới sửa key/snapshot pairing và raw-log
line endings; mail PRF giữ nguyên. Không có pending nonce thì validator không chứng minh
được danh tính key; SHA256 không xác thực nguồn backup. Xem INDEX19/10 và RELEASE_AND_BACKUP.

## 3. Vấn đề cần ưu tiên

### P0: dữ liệu, quyền và điều kiện phát hành

- Nghiệm thu rich draft sau process death, reconnect và lost acknowledgement: đúng UUID,
  nội dung/Delta, không trùng note, không mất bản local khi conflict/revoke.
- Nghiệm thu note khóa ở visual, semantics, preview, search, AI và cache; quyền phải do
  backend kiểm tra. Owner cũng phải unlock. Không coi mã hóa client là E2EE: server có plaintext.
- SMTP Internet, Gemini thật, HTTPS và signed APK cần đầu vào bên ngoài. Chuẩn bị runbook
  và kiểm tra config an toàn ngay; chờ đúng đầu vào để chạy phần phụ thuộc.
- Bộ nộp cần bản rubric gốc, video thật và artifact/URL chạy được. Các quy định điểm trong
  tài liệu là bản phân tích có sẵn, cần đối chiếu PDF/Rubric gốc trước chốt.

### P1: tài liệu đang gây hiểu nhầm

- LOCAL_BASELINE_AND_ROADMAP có cập nhật mới nhưng bảng cũ vẫn ghi R01 “Chưa triển khai”.
- REQUIREMENTS_MATRIX có phần cập nhật nhưng một số hàng vẫn ghi native rich editor chưa
  chạy, trong khi đã có integration12/10. Cần giữ riêng thiếu IME thật và đã chạy harness.
- TEST_PLAN còn mở bằng 4 unit/5 widget và câu “hiện chưa có commit”; không phản ánh snapshot mới.
- SECURITY_AND_PERMISSIONS còn nói release dùng debug signing và mail outbox chứa encrypted
  token; RELEASE_AND_BACKUP/code đã chặn debug fallback, EMAIL_DELIVERY mô tả nonce/PRF.
- AGENTS còn author Bahung trong đoạn cũ; yêu cầu hiện hành là Nguyễn Bảo Long. Sửa quy ước
  tương lai sau đối chiếu, không đổi author lịch sử.
- README dài với nhiều nhật ký trước phần setup. Nên đưa quickstart/current state lên đầu,
  chuyển nhật ký sang trang lịch sử có link, giữ README.md và Readme.txt đồng nhất byte.

Đây là nợ tài liệu xác định được, không phải chứng minh code lỗi. Ưu tiên một bảng trạng thái
hiện hành ở REMAINING_GATES; matrix ánh xạ rubric đến bằng chứng, STATUS chỉ tóm tắt mới nhất.
Không xóa hoặc sửa raw evidence lịch sử để làm trạng thái đẹp hơn.

### P2: hoàn thiện có điều kiện

Đánh giá retry/backoff (hiện tài liệu mô tả 15s cố định), multi-tab, quota/storage failure,
abuse controls registration/reset, backup retention và quan sát lỗi trước public release.
Chỉ mở ticket có trigger, tác động và test nghiệm thu; không tự coi mọi giới hạn là lỗi bắt
buộc phải xây thêm. Không thêm offline media queue, key transfer, semantic vector DB,
OT/CRDT hoặc DOCX/PDF export vào đường găng khi rubric chưa yêu cầu.

## 4. Kế hoạch thực thi theo chặng

| Chặng | Việc thực hiện | Điều kiện đóng | Phụ thuộc |
|---|---|---|---|
| C0 — Baseline và tài liệu | Fetch, kiểm tra PR10/head/base/CI, giữ working changes; đối chiếu các mục lệch ở trên; lập checklist hiện hành | SHA rõ, bảng gate thống nhất, lệnh đúng repo/toolchain, danh tính Git đúng | GitHub để xác minh remote; local vẫn làm được |
| C1 — Editor/offline native | N01/N02: IME Telex/VNI, compose/selection/paste/undo/format; offline edit, process force-stop/relaunch, reconnect | Nội dung/Delta/UUID đúng; UI saved/pending đúng độ bền; không duplicate/mất draft | Emulator/device điều khiển được, keyboard thật |
| C2 — Quyền và luồng còn thiếu | N03–N05: hai client conflict/delete/revoke/downgrade; TTL/background; protected picker/avatar/cancel; AND labels/rename; account password | Original không overwritten; recovery cô lập; không leak; password mới login thủ công, token cũ401; Web và Android theo phạm vi | API test riêng, 3–4 account QA, UI/OS thật |
| C3 — Dịch vụ thật | P01 verify/reset từ inbox; P02 summary/Q&A/citations/no-info/prompt-injection/nguồn đổi quyền | Email receipt thật; mã một lần/expiry; AI dùng nguồn có quyền, không overwrite, lỗi/quota rõ; ghi provider/model/target | Nhóm cấu hình SMTP và Gemini key mới riêng |
| C4 — Vận hành và release | R01–R04: container context, recreate, restore volume mới; HTTPS/CORS/proxy SSE; signed APK; clean production clone/build/install | Data/hash/ACL giữ sau restore; cert ký đúng; public Web + APK cùng source chạy từ mạng độc lập; rollback/runbook có thể làm theo | Engine hoặc host tương đương, hosting/domain, signing của nhóm |
| C5 — Nghiệm thu cuối và bàn giao | Freeze release candidate, mapping32 mục, demo hai target theo đề, Rubric/Insights/video, package/unpack | Artifact/hash/source khớp; không secrets/cache; .git hợp lệ; URL/APK/video/Rubric và hướng dẫn đủ | Bản đề/rubric và thành viên ghi hình/review |

C0 → C1 → C2 → C3 → C4 → C5. Chuẩn bị config/runbook C3/C4 và giấy tờ C5 song song
về công việc, không yêu cầu nhiều agent. Nếu provider bị chặn, làm phần local độc lập của
C4/C5; không đánh dấu đóng C3. T01 đóng góp/vấn đáp theo dõi xuyên suốt. Không hứa lịch
hoàn thành khi chưa có deadline chính thức, thiết bị, provider và người review.

Mỗi chặng chia thành thay đổi đủ nhỏ để review; test phù hợp → evidence → cập nhật trạng
thái → commit có ý nghĩa. Không commit chỉ để tăng số lượng. Push branch/PR theo ủy quyền
đã có; merge vẫn theo ruleset và approval người khác sau push cuối.

## 5. Cách nghiệm thu có thể tái lập

Mỗi case ghi: gate/rubric ID, source SHA và dirty diff nếu có, artifact hash, nền tảng/OS,
API environment, tiền điều kiện, thao tác, expected/actual, log/ảnh, loại fixture/provider,
kết quả PASS/FAIL/BLOCKED/NOT RUN. BLOCKED phải nêu đầu vào thiếu và bước mở lại.

Ví dụ N02: tài khoản QA → note có tiếng Việt và định dạng → xác nhận local write đã xong
→ mất kết nối thật → sửa → force-stop process → launch lại offline → đối chiếu Delta/UUID
→ reconnect → GET backend so dữ liệu và số note. Thử kill ngay lúc ghi là case riêng với
ranh giới bảo đảm được mô tả; không hứa giữ keystroke chưa commit xuống storage.

Ví dụ N03: owner A/editor B/viewer C/stranger D; B có dirty draft, A revoke hoặc delete.
B không tiếp tục ghi source, có recovery riêng khi policy cho phép; copy UUID mới không
trở thành bản chia sẻ cho A/C/D. Kiểm cả API âm tính, UI và dữ liệu bền sau reopen.

AI evaluation đề xuất: bộ note demo cố định, câu hỏi một/nhiều nguồn, không đủ nguồn,
nguồn không liên quan, locked/revoked và prompt injection. Lưu expected sources và tiêu
chí đúng/sai trước chạy; không kỳ vọng câu chữ LLM giống hệt. Không source trái quyền,
không citation bịa là điều kiện cứng; chất lượng grounding cần người đọc nguồn kiểm tra.

Full scripts/check.ps1 trước release candidate; test tập trung sau từng sửa và full suite
khi thay đổi có ảnh hưởng rộng. Chỉ rerun runtime cần thiết theo tác động; khi chốt artifact
cuối chạy lại bộ critical flows trên chính artifact đó. CI green không thay runtime QA.

## 6. Đầu vào nhóm cần chuẩn bị

- Thiết bị/emulator với bàn phím tiếng Việt và khả năng thao tác picker/background/relaunch.
- SMTP Internet/sender/inbox QA; Gemini key mới đã cấu hình server, không gửi secrets vào chat.
- Hosting/domain/API HTTPS, engine/container chạy được; lựa chọn chi phí do nhóm xác nhận.
- Keystore của nhóm, cấu hình signing ignored và cách bảo quản/khôi phục.
- PDF/Rubric.xlsx chính thức, deadline, video hai thành viên, Insights thật và reviewer khác.

Agent có thể chuẩn bị checklist, sửa code và scripts; không thay được email receipt,
human approval, provider credentials, đóng góp thực tế hay video tham gia của thành viên.

## 7. Nguồn đã đối chiếu và giới hạn review

Đọc các tài liệu điều phối: AGENTS, PROMPT_CHO_AGENT, STATUS, LOCAL_BASELINE_AND_ROADMAP,
REMAINING_GATES, NEXT_STEP_RELEASE_READINESS, REQUIREMENTS_MATRIX; tài liệu kiến trúc,
security/offline, AI/email, test/submission; INDEX backup19/10 và workflow Git/CI. Đối chiếu
source backup.py, scripts/check.ps1, build.ps1 và quality.yml; rà mục lục/điểm liên quan của
README, phân tích đề, audit10/10, UI QA/inspector, current-source acceptance và teamwork.
Không tuyên bố đã đọc toàn bộ mọi dòng của mọi Markdown/evidence hoặc audit toàn bộ code.
Các tài liệu lịch sử/thẩm mỹ không phải backlog mặc định cần triển khai lại.

Prompt thực thi ở [PROMPT_6_1_SOL_COMPLETION.md](PROMPT_6_1_SOL_COMPLETION.md).
Prompt nêu đầu ra, file nguồn và tiêu chí nghiệm thu; không thay thế đầu vào bên ngoài.
