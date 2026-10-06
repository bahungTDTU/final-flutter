# Kiểm tra NoteTogether và chuẩn bị bước tiếp theo — 06/10/2026

## Kết luận

Nền tảng chức năng local đã có bằng chứng đáng kể, bao gồm AI qua provider fixture và
vòng đời ghi chú bảo vệ. Dự án chưa sẵn sàng nộp: chưa nghiệm thu LLM/email thật, backend/Web
public HTTPS và native release với dịch vụ thật; hồ sơ/video/teamwork vẫn thiếu.
Không quy đổi số test thành phần trăm hoàn thành hoặc điểm dự kiến.

Bước tiếp theo đề xuất: **M6.1 — cấu hình release và backend tái lập**. Làm các guard/config/
kiểm thử local trước, rồi nối dịch vụ khi nhóm sẵn sàng. Kế hoạch thực hiện và điều kiện
nghiệm thu: [NEXT_STEP_RELEASE_READINESS.md](NEXT_STEP_RELEASE_READINESS.md).

Lượt này chỉ rà soát và tạo tài liệu chuẩn bị; không sửa mã ứng dụng/cấu hình build hiện có,
không bật Docker, không chạy container, không gọi Gemini/SMTP, không commit/push/deploy/nộp.

## Nguồn và phạm vi

- Đọc lại PROMPT_CHO_AGENT/AGENTS/STATUS/matrix/README/team/submission, các tài liệu AI,
  protection/UI/email và cấu hình backend/Android/scripts/Docker.
- PDF gốc19 trang, SHA-256 `63ea45a11778b4b60bd71ae79038b991cda54f90d429365345fe488cb5c6f907`.
  Đọc các phần bảo vệ/realtime/AI/offline/build/rubric/teamwork/output; xem ảnh trang6 và17.
  Trang6 yêu cầu public Web/backend và native release hoạt động, không chỉ build.
  Trang5 yêu cầu LLM thật; trang18 yêu cầu demo đủ và một số flow trên cả hai nền tảng.
- Git local HEAD và remote master đã đọc ngày06/10 cùng
  `aded41ec0ccdbfb46cae579b64ef3eab004f68bf`. AI/protection ngày05/10 còn là working changes
  và untracked files; chưa có trong hai commit hiện tại. Không được clone remote rồi gọi
  đó là source của artifact mới khi những thay đổi này chưa được publish theo ủy quyền.
- [Audit05/10](FINAL_PROJECT_AUDIT_2026-10-05.md) là snapshot trước AI/protection; các nhận xét
  “AI chưa triển khai”/“protected chỉ đọc” ở đó không đại diện hiện trạng. Không sửa log lịch sử.

## Kiểm tra đã thực hiện

| Check | Kết quả | Phạm vi |
|---|---|---|
| Protected manifest `--verify` | PASS156 inputs/44 evidence/3 artifacts | Hash đúng các file được manifest liệt kê; không tự bao phủ mọi file repo hoặc chạy lại QA |
| `git diff --check` | PASS | Không whitespace error; có thông báo CRLF thông thường |
| README/Readme equality | PASS byte equality | Hai tài liệu cùng nội dung |
| Matrix | PASS32 hàng tiêu chí | Kiểm đếm, không tự chấm từng mục |
| Log ngày05/10 | Xác nhận analyze sạch,143 Flutter/79 backend PASS | Log cũ khớp mã/build đã hash; hôm nay không chạy lại tests/browser/native |
| Git local/remote | PASS cùng HEADaded41e | Có2 commit, cùng tác giả Bahung; không chứng minh teamwork4 tuần |
| Docker | Client28.5.1 có sẵn; Linux engine không kết nối được | Read-only `docker version`, kể cả ngoài sandbox. Chưa build/run Docker; không khởi động engine |
| Backend8000 `/health` | Không kết nối được | Service local không đang truy cập được trong lúc kiểm tra; không kết luận lỗi code |

JSON kiểm tra: [preflight.json](../evidence/2026-10-06-readiness/preflight.json).
Các bộ kiểm thử/build ngày05/10: [protected INDEX](../evidence/2026-10-05-protected-notes/INDEX.md).
Không lặp QA chỉ vì sang ngày mới khi156 inputs và artifacts vẫn khớp; cần chạy lại phù hợp
khi sửa mã, cấu hình release, phụ thuộc hoặc gặp rủi ro mới.

## Phát hiện cần xử lý

| Ưu tiên | Phát hiện trực tiếp | Ảnh hưởng / xử lý tiếp |
|---|---|---|
| P0 | `lib/main.dart` và `scripts/build.ps1` mặc định API `http://127.0.0.1:8000`; build script chưa có chế độ production chặn URL local/fixture | Artifact local hiện tại chưa phải bản chạy độc lập cho giảng viên. Thêm production preflight/API URL guard, giữ lệnh local QA riêng rõ ràng |
| P0 | Android release dùng `signingConfigs.getByName("debug")`; chưa có `android/key.properties` | Chuẩn bị signing phát hành bằng secret local/service riêng, không fallback debug trong production; không tự tạo/đọc secret trong lượt này |
| P0 | Có Dockerfile nhưng chưa có Compose/volume/restart/backup runbook đã nghiệm thu | SQLite mặc định ở filesystem container; phải mount persistent volume và test recreate/restore trước claim durable deployment |
| P0 | Mã AI/protection mới chưa commit/push; remote vẫnaded41e | Cần source/artifact cùng phiên bản trước clean-clone QA và gói nộp; publishing chỉ khi được ủy quyền |
| P1 | `.dockerignore` đã loại `backend/state`, `.env`, cache, evidence; chưa bao phủ `.env.*`, signing material, `android/key.properties` | Không phát hiện leak đã xảy ra. Khi thêm credentials/signing, harden context và kiểm tra image/context; Git ignore không thay Docker ignore |
| P1 | SMTP gửi đồng bộ sau DB commit, chưa có durable email outbox; backend thiếu config thì disabled | Provider receipt/retry/timeout/restart cần nghiệm thu thật. SMTP fixture PASS không chứng minh inbox delivery |
| P1 | Gemini adapter/UI đã code; real provider chưa chạy theo lựa chọn của người dùng | Chỉ cấu hình key mới bằng cơ chế local đã chuẩn bị khi người dùng sẵn sàng; không đọc/dùng key cũ hoặc bật billing |
| P1 | Chưa có workflow `.github/workflows`; một số matrix rows còn chỉ dẫn generic/historical như row30 `123/56` | Chuẩn bị CI và cập nhật trạng thái theo evidence của phiên bản release sau; không viết lại hashes/logs trước đó |
| P2 | Protected native picker/media/share/AI flow, UI nhãn/filter native, accessibility, OS relaunch/two-device stress còn thiếu nghiệm thu | Đưa vào checklist hai nền tảng sau khi có môi trường release ổn định; widget/controller tests không thay thiết bị thật |

Debug signing được xác nhận từ cấu hình local; đây là phát hiện readiness, không phải tự diễn
giải đề thành yêu cầu Google Play. Native artifact phải hoạt động theo đề. Chuẩn bị signing
release theo [Android documentation](https://developer.android.com/studio/publish/app-signing).
Docker context cần lọc riêng theo [Docker documentation](https://docs.docker.com/build/concepts/context/).

## Phần còn phụ thuộc nhóm/dịch vụ

Không hỏi lại repo/cloud trong lượt này. Repo/2thành viên/quyền dùng AI đã xác nhận;
cloud và credentials sẽ xử lý khi nhóm sẵn sàng. Các mục pending gồm public URLs/persistent
hosting, Gemini key mới, SMTP mailbox thật, private release signing, thiết bị thật, deadline/
lịch phát triển chính thức, Rubric.xlsx gốc, video1080p/cả2 thành viên và Git Insights4tuần.
Backup/transfer device keys là rủi ro chưa xử lý; không tự nâng thành yêu cầu bắt buộc của rubric.
Không tạo commit/authorship/video/timestamp hoặc bằng chứng Git giả.
