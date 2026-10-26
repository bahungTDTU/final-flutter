# GitHub, yêu cầu nộp và hiệu năng — 23/10/2026

## GitHub đã kiểm tra trực tiếp

- PR15 đã merge ngày22/10, merge commit `9003d65e33dafbef21bc18a5cf45df07139cbfae`.
- Ba checks **Flutter quality / Backend tests / Build smoke** trên PR15 và master
  đều completed/success. Không có PR đang mở hoặc GitHub Releases tại lúc kiểm tra.
- API reviews của PR15 trả danh sách rỗng: không có bằng chứng approval từ người
  khác trong dữ liệu này. Không suy merge thành đạt quy trình review của repo;
  không thay ruleset/approval hoặc tự tạo bằng chứng.
- Đã fetch rồi fast-forward từ8d3de71 đến9003d65, tree giống nhau; giữ `.agents/`
  và bản trích đề local. Nhánh mới `codex/submission-performance-audit`.
- Các sửa đổi lượt này chưa commit/push; CI trên master chưa kiểm tra bản sửa mới.

## Đối chiếu đề gốc và trạng thái nộp

Nguồn: PDF gốc503107-FinalProject-V1, 19trang, bản trích đã đọc ở lượt22/10;
PROMPT_CHO_AGENT, REQUIREMENTS_MATRIX, SUBMISSION_CHECKLIST và các evidence21–22/10.
Đây là audit bằng chứng, không tự chấm đủ32mục và không thay Rubric.xlsx chính thức.

| Phạm vi | Trạng thái có bằng chứng | Cần trước khi nộp |
|---|---|---|
| 1–8 tài khoản/preferences | Code/local tests; SMTP TLS fixture; profile/session/preferences QA có phạm vi riêng | Email Internet đến inbox thật và các luồng trên hai artifact cuối |
| 9–22 CRUD/editor/search/labels/attachments | Code, unit/API và Web/Android QA lịch sử; có regression recovery/Unicode mới | Phủ đủ video và luồng native picker/lifecycle trên artifact cuối |
| 23–26 lock/share/realtime | Backend ACL, encrypted recovery, Web/native integration đã có | TTL/OS background/IME/native UI variants; không quy đổi injected input thành IME thật |
| 27–28 AI | Adapter/ACL/citation và fixture có test | LLM thật, đánh giá câu trả lời và demo hai nền tảng |
| 29–31 UI/architecture/offline | One Flutter/ChangeNotifier/FastAPI/SQLite/Sembast; tests và QA nhiều đợt | Accessibility/native OS/final artifact và khả năng giải thích của nhóm |
| 32 build/deployment | Build local Web và APKdebug PASS22/10; CI master PASS | Public Web/backend HTTPS ổn định, APKrelease ký và install/run đúng source |
| Gói nộp | Checklist/readme/source/history có sẵn | Rubric.xlsx, demo1080p mọi thành viên, URL, native release, ZIP/unpack |
| Teamwork | Lịch sử Git thật được giữ | Insights screenshot, phân bố meaningful commits bốn tuần và đóng góp thật; không suy từ tổng commits |

Kiểm tra local: chưa có `android/key.properties`, chưa có thư mục `release/`,
không thấy Rubric.xlsx ở root; output hiện có là QA/ZIP UI cũ. Không khẳng định
những file hoặc dịch vụ này không tồn tại ở nơi khác. Chưa có endpoint production
được xác minh trong lượt này. Không có GitHub Release không đồng nghĩa chưa từng
build APK; chỉ là chưa có release được công bố trên GitHub.

**Chưa sẵn sàng nộp.** Theo phần Output requirements, thiếu source/demo/Rubric/
public Web URL/native artifact có thể làm cả nhóm nhận0. Source nộp phải giữ.git,
loại cache/state/secrets; GitHub Download ZIP không đáp ứng yêu cầu lịch sử.
Không tạo video, tài khoản chấm, timestamp, approval hay lịch sử contribution giả.

## Điểm nghẽn đã tái hiện và sửa

Hai truy vấn danh sách dùng OR giữa `n.owner_id` và LEFT JOIN shares. Khi tài khoản
chỉ được xem49notes, thêm20.000notes của tài khoản khác làm tăng từ khoảng5.400
lên905.400SQLite VM steps, median0,301→11,313ms. Số SELECT cố định không có nghĩa
lượng dữ liệu quét cố định.

Sửa cả truy vấn nội dung và nhãn: lấy tập ID từ notes_owner/shares_user bằng UNION
trước khi join/project. Giữ deleted filter, thứ tự updated_at/id, role backend,
label order/tombstone/owner, six-field locked projection và không thêm cache riêng tư.
Không đổi schema, dependency, payload quyền, outbox hay frozen editor revision.

| Fixture:49notes nhìn thấy | Trước | Sau |
|---|---:|---:|
| Không có notes ngoài tài khoản, median | 0,301ms | 0,374ms |
| Thêm20.000notes ngoài tài khoản, median | 11,313ms | 0,354ms |
| Thêm20.000notes, VM steps xấp xỉ | 905.400 | 7.200 |

Khoảng31,96x nhanh hơn trong fixture nhiều tài khoản, giảm99,2%VM steps.
Trường hợp nhỏ có overhead khoảng0,073ms. Đây là11runs sau warmup, in-memory SQLite;
không phải throughput production, HTTP latency, Android FPS hoặc load test.

ASGI+SQLite disk,1000notes đều visible: owner52,934→48,560ms; viewer56,360→53,720ms
(7runs). Các mẫu nhỏ có nhiễu; không dùng các số này để claim speedup phổ quát.
Số SELECT gồm auth vẫn4; số query không đổi là chủ đích.

## Kiểm chứng và phạm vi

- Regression growth FAIL trước sửa, PASS sau sửa. Kiểm tra VM work thay vì threshold
  thời gian; so sánh toàn payload trước/sau thêm20k unrelated, roles, lock redaction,
  nhãn, deleted, revoke và tài khoản trống.
- Nhóm listing6tests PASS; HTTP thật4roles PASS với backend QA riêng, không provider.
- Full backend153tests PASS (90,58s), một Starlette/httpx deprecation warning.
  Không dùng CI cũ để claim bản sửa mới đã chạy CI.
- Flutter không thay đổi; không rerun UI/native/build/FPS vì thay đổi nằm ở backend.
- Không truy cập DB người dùng, không thay quyền hai cache bị chặn, không deploy/nộp.

[Evidence và lệnh tái lập](../evidence/2026-10-23-submission-performance/INDEX.md).
