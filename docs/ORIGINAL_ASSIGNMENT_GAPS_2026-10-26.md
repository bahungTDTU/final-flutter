# Đối chiếu phần còn thiếu với đề gốc — 26/10/2026

## Phạm vi và kết luận

Đọc trực tiếp `C:/Users/LENOVO/Downloads/503107-FinalProject-V1.pdf` (19 trang),
đối chiếu source local ee7c836, matrix, tài liệu provider/release và evidence hiện có.
Đây là audit chỉ đọc và bổ sung báo cáo; không chạy lại test, không sửa ứng dụng,
không deploy hoặc nộp bài. Kết quả331Flutter/155backend là lần kiểm tra26/10 trước đó.

**Chưa sẵn sàng nộp.** Phần lõi có code và nhiều bằng chứng local, nhưng chưa đủ
bằng chứng vận hành trên hai bản nộp và chưa đủ bộ đầu ra bắt buộc. Không đồng nhất
“chưa xác minh” với “chưa có code”; không tự chấm điểm hoặc phần trăm hoàn thành.

GitHub kiểm tra trực tiếp: PR16 đã merge, ba checks Backend tests/Flutter quality/
Build smoke đều success ở ee7c836. API báo master7a8e84c; checkout chưa pull merge
commit trong lượt audit này. Merge/CI không thay nghiệm thu rubric hoặc video.

## Các thiếu sót ưu tiên cao

| Ưu tiên | Mục thiếu / chưa đủ bằng chứng | Đề gốc | Đầu ra cần có để đóng |
|---|---|---|---|
| P0 | Chưa xác minh Flutter Web và backend công khai, HTTPS, hoạt động trong kỳ chấm | tr.6,14,17–18; ID32 | URL thật, truy cập từ mạng khác, chạy core/auth/files/SSE/offline/AI; release/web-url.txt |
| P0 | Chưa nghiệm thu native release đúng source | tr.6,14,17; ID32 | APKrelease ký hợp lệ, kiểm certificate, cài/mở và chạy core; hoặc một native artifact khác được đề chấp nhận |
| P0 | Chưa tìm thấy Rubric.xlsx chính thức trong root/tracked files/output đã kiểm | tr.17–18 | Mẫu giảng viên, tự đánh giá32ID trung thực, URL/repo/native artifact và tài khoản chấm |
| P0 | Chưa tìm thấy demo.mp4 hoặc link demo được nghiệm thu | tr.18 | Video≥1080p, rõ tiếng, mọi thành viên; mapping criterion→thao tác→timestamp thật |
| P0 | Chưa có gói nộp cuối được kiểm tra giải nén | tr.17–19 | Folder/ZIP đúng tên; source clone có.git; release, Rubric, video/link, Readme; loại cache/state/secrets, thử setup/build/run |
| P1 | Email kích hoạt/reset thật chưa được xác minh | tr.2–3; ID2/4 | SMTP provider của nhóm, email đến inbox, mã hết hạn/dùng lại, activation/reset trên Web và native cuối |
| P1 | AI Summary/Q&A chưa có nghiệm thu LLM thật | tr.5,13; ID27/28 | Gọi provider thật, regenerate không ghi đè note; Q&A tổng hợp có nguồn mở được, thiếu nguồn báo đúng, khóa/revoke không lộ dữ liệu |
| P1 | Readme và grading accounts chưa hoàn chỉnh cho bản nộp | tr.18–19 | URL, SDK/build/config chính xác, thông tin artifact, tài khoản preload owned/shared/locked/labels/AI; credentials cung cấp riêng an toàn |
| P1 | Teamwork chưa được chứng minh theo từng người/từng tuần | tr.15–16 | Bốn tuần lịch liên tiếp, mỗi người≥2meaningful commits/tuần trong kỳ chính thức; có trong history nộp; ảnh Insights rõ repo/người/thời gian |

Tr.18 quy định thiếu source/video/Rubric/public Web URL/native artifact dẫn tới0
cả nhóm. Thiếu teamwork đủ điều kiện bị trừ0,5; không bù bằng tổng commits.
Không có GitHub Release không tự chứng minh thiếu APK; đây không phải nơi lưu bắt
buộc của đề. Chỉ kiểm tra vùng project liên quan, không khẳng định file/dịch vụ
không tồn tại ở nơi khác.

## Đối chiếu toàn bộ32ID theo nhóm

| ID | Đã có theo code/evidence | Phần chưa đóng |
|---|---|---|
| 1,3 | Register/login/logout, auto-login và guards; tests/API/UI lịch sử | Chạy trên hai bản nộp, demo |
| 2,4 | Verify/reset code, SMTP TLS/queue và UI fixture | Email đến inbox thật; end-to-end trên Web/native công khai |
| 5,6 | Profile/avatar, validation/private bytes và QA local | Native picker/cancel/error và tính nhất quán trên artifact cuối |
| 7 | Đổi password, session invalidation; native UI PASS19/10 | Web password UI/final-artifact acceptance; không gọi tính năng này là chưa code |
| 8 | Preferences persist/sync, themes/fonts/grid/locale/palettes | Hai bản cuối/reopen/cross-account và demo |
| 9,10 | List/grid, adaptive views và persistence | Nghiệm thu bản nộp/feedback/input modes |
| 11,12,13 | Chung editor, create/edit/delete-confirm; regression recovery | Native input thật và core flows trên bản nộp |
| 14 | Autosave, encrypted drafts; Web reload/native core reopen/process-death probe | Lifecycle trên main editor/artifact cuối; không suy QA entrypoint thành toàn app |
| 15,16 | Multi-attachment/image/video/file, private ACL/range/download | OS picker cancel/denial/error và protected-file path còn thiếu bằng chứng đầy đủ |
| 17,18,19 | Sorting/pin, concurrent indicators, live search; redaction tests | Demo trên bản nộp; không phát hiện yêu cầu cần viết lại các tính năng này |
| 20,21,22 | CRUD nhãn, IDs, assignment/filter AND và sync | Native UI gắn/lọc/rename/delete đủ luồng; không chỉ controller tests |
| 23,24 | Backend password/grants, reader/edit/vault, change/disable | Nghiệm thu khóa/đổi/tắt và background/expiry trên artifact cuối |
| 25,26 | Share manager/roles/revoke, recipients metadata, SSE; Web/native integration | Hai UI trên release cuối, thay quyền khi đang sửa và demo |
| 27,28 | Gemini adapter, UI, retrieval/citations, ACL/error fixtures | Provider thật và chất lượng câu trả lời, cả hai nền tảng |
| 29 | Design system/adaptive/keyboard/semantics/widget và browser QA | Interaction/accessibility trên bản cuối; không quy widget test thành screen-reader acceptance |
| 30 | Một Flutter core/ChangeNotifier/layers, nhiều unit/widget/integration tests | Code đủ nền tảng; cả hai releases và hiểu biết từng người vẫn cần chứng minh |
| 31 | Offline/account isolation/outbox/conflict/encrypted recovery; QA local | Offline→reopen→reconnect và conflict trên hai bản nộp |
| 32 | Local Web/APKdebug compile, CI build smoke | PublicHTTPS/backend và working native release tương ứng source |

Các dòng “chưa native source mới” trong matrix cũ phải đọc cùng evidence21/10:
đã có5Android integration workflows và main startup. Không được lùi trạng thái
thành “native chưa chạy lần nào”; cũng không suy thành full release acceptance.

## Điều kiện video và teamwork dễ bỏ sót

- Mỗi tiêu chí claim phải xuất hiện ít nhất trên một nền tảng trong video.
- Bắt buộc demo trên **cả Web và native**: login, create/edit, attachments,
  offline sync, sharing hoặc realtime, và ít nhất một tính năng AI.
- Mục không demo được xem là chưa triển khai dù tự đánh giá có làm.
- Ảnh Insights thật mới đáp ứng bằng chứng teamwork; terminal/git-log screenshot
  không thay thế. Không dùng merge-only/generated/trivial/fake commits bù số lượng.
- Tr.16 có ngoại lệ bằng chứng Git nếu chấp nhận trừ0,5, nhưng tr.17 vẫn yêu cầu
  source clone giữ.git: chọn giữ.git trong gói cuối để đáp ứng cấu trúc đầu ra.
- Mỗi thành viên phải giải thích/sửa được phần việc khi vấn đáp; AI assistance
  không thay contribution hay hiểu biết của người học.

## Không biến khuyến nghị nội bộ thành yêu cầu mới

Đề không bắt buộc một framework backend, hãng LLM, cloud key backup, OT/CRDT,
offline attachment upload, riêng camera capture, tên miền mua riêng, Docker nếu
không cần nhiều dịch vụ, một FPS mục tiêu, hay một công cụ screen reader cụ thể.
IME/OS-kill/TalkBack là cách kiểm chứng chất lượng và lifecycle, không phải các
tính năng độc lập cộng thêm ngoài32ID. Approval/CI/PR workflow là quy định repo,
không thay điều kiện teamwork và đầu ra của đề.

## Thứ tự hoàn thiện đề xuất

1. Cấu hình email/LLM thật và nơi chạy Web/backend HTTPS của nhóm; không gửi secret vào chat.
2. Tạo native release phù hợp, cố định source/config của hai bản để nghiệm thu.
3. Chạy core end-to-end hai nền tảng; đặc biệt email, AI, attachment, offline,
   permissions/realtime; ghi đúng PASS/FAIL/NOT RUN.
4. Điền Rubric, chuẩn bị tài khoản chấm, cập nhật Readme và quay video đủ mapping.
5. Chụp Insights/đánh giá teamwork trung thực; clone source giữ.git, đóng gói,
   giải nén thử và nhóm nộp e-learning.

## Nguồn trong repository

- docs/REQUIREMENTS_MATRIX.md; docs/SUBMISSION_CHECKLIST.md.
- docs/EMAIL_DELIVERY.md:121–122 và docs/AI_FEATURES.md:122: provider acceptance còn thiếu.
- docs/RELEASE_AND_BACKUP.md; android/key.properties và release/ chưa có ở checkout.
- docs/NATIVE_OS_ACCEPTANCE.md; evidence/2026-10-21-android-web/INDEX.md.
- evidence/2026-10-19-account-password/INDEX.md.
- evidence/2026-10-26-project-verification/INDEX.md: phạm vi local checks mới nhất.
- PR16: https://github.com/bahungTDTU/final-flutter/pull/16 (trạng thái đọc trực tiếp).
