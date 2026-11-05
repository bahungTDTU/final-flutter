# Biên bản nghiệm thu kỹ thuật — 05/11/2026

## Phạm vi

Source local `ee7c8366506b6ebf66ba7974b0506841c872cddd`, không sửa mã ứng dụng.
Đối chiếu PDF gốc `503107-FinalProject-V1.pdf`, trang 6, 14, 17–18 và
`ORIGINAL_ASSIGNMENT_GAPS_2026-10-26.md`. Kết quả chỉ áp dụng checkout này;
không lấy CI/GitHub lịch sử thay cho lần chạy mới. Không pull/push/deploy trong lượt này.

Người dùng xác nhận ngày 05/11: nhóm chưa có URL Web/backend HTTPS, APK release
và cấu hình SMTP/LLM để nghiệm thu thực tế. Không gọi provider trả phí, gửi email
ra ngoài hoặc dùng test double để công nhận dịch vụ thật.

## Các kiểm tra đã thực hiện

Kết quả chốt và lệnh nằm ở `../evidence/2026-11-05-acceptance/INDEX.md`.

- Format/analyze, toàn bộ Flutter unit/widget và backend tests.
- HTTP thật trên backend QA riêng, SQLite tạm, bốn vai trò owner/viewer/editor/stranger:
  locked metadata/grant; protected edit/idempotency/frozen revision409;
  quyền tệp riêng tư; revoke/đổi password vô hiệu grant; owner delete.
- Benchmark listing: 49 ghi chú nhìn thấy, so sánh 0 và 20.000 ghi chú không liên quan;
  11 lần sau warmup. Chỉ đo SQLite, không phải FPS/HTTP/load production.
- Build Web release local và chuẩn bị offline shell; không phải nghiệm thu trình duyệt.
- Kiểm tra `adb devices -l`: không thiết bị kết nối; không cài đè app hoặc xóa dữ liệu
  emulator. Android UI/native release mới NOT RUN.

## Gate để nghiệm thu bản nộp

| Gate / rubric | Trạng thái | Bằng chứng cần để đóng |
|---|---|---|
| Mã nguồn, phân tích và regression (30; hỗ trợ các ID khác) | Xem kết quả local ở INDEX | Không thay bằng chứng hai bản release cùng source và phần giải thích của thành viên |
| Quyền backend, khóa/chia sẻ/tệp (15/16/23–26) | PASS phạm vi HTTP đã liệt kê | UI trên hai bản nộp; picker/cancel/error; thay quyền khi đang sửa; không lộ nội dung khóa |
| Autosave/offline/account isolation (14/31) | Test tự động local, chưa nghiệm thu bản nộp | Mỗi nền tảng: offline tạo/sửa → đóng/mở → reconnect; giữ ID/nội dung, không nhân bản; conflict và đổi tài khoản |
| Email activation/reset (2/4) | NOT RUN provider thật | SMTP và inbox QA được phép; nhận thư, verify/reset, reuse/expiry, manual login và session cũ bị từ chối trên Web/native |
| Summary/Q&A (27/28) | NOT RUN LLM thật | Provider/key riêng backend, ngân sách được duyệt; regenerate không ghi đè; tổng hợp có nguồn mở được; no-data/locked/revoke |
| Web/backend HTTPS (32) | NOT RUN; nhóm chưa có | URL thật ổn định, TLS hợp lệ, thử từ mạng độc lập, auth/files/SSE/offline/AI |
| Native release (32) | NOT RUN; chưa có artifact | Cấu hình ký riêng, build cùng source, hash/certificate, cài/mở và core flows; không gọi APK debug là bản nộp |
| UI/adaptive/input/accessibility (29) | Chưa nghiệm thu runtime mới | Thao tác touch/mouse/keyboard, resize/text scale, loading/error, bảo toàn editor và privacy trên bản cuối |
| Hồ sơ nộp | Chưa đạt | Rubric.xlsx gốc; Readme URLs/tài khoản chấm; video thật; release/web-url.txt và native artifact; ZIP giải nén/setup thử |
| Teamwork | Chưa xác minh | Kỳ chính thức, contribution thật từng người/từng tuần và ảnh GitHub Insights; không tạo commit/timestamp giả |

## Trình tự đóng các gate còn lại

1. Nhóm chọn nơi chạy backend/Web, SMTP/inbox QA và LLM; cấu hình secret ngoài Git,
   xác nhận phạm vi chi phí trước khi dùng dịch vụ. Chuẩn bị signing key riêng của nhóm.
2. Build/publish hai artifact cùng source, ghi hash/config không chứa secret.
3. Chạy core trên cả hai: login; create/edit/autosave; attachments; offline sync;
   sharing/realtime; ít nhất một AI. Nghiệm thu thêm activation/reset, labels,
   password/protection, preferences và các mục còn lại theo matrix.
4. Nhóm quay video ≥1080p, mọi thành viên tham gia, mỗi tiêu chí claim có timestamp
   thật; các core flows ở bước 3 phải có cả Web/native theo đề.
5. Điền Rubric chính thức, Readme, tài khoản chấm và Insights; clone source giữ `.git`,
   đóng gói đúng tên, loại cache/secret, kiểm tra giải nén và chạy lại từ gói cuối.

**Kết luận:** chỉ nghiệm thu kỹ thuật local trong phạm vi kết quả thực tế. Chưa công
nhận hoàn thành 32 tiêu chí hoặc sẵn sàng nộp. Đề gốc quy định thiếu source, video,
Rubric, public Web URL hoặc native artifact có thể dẫn đến 0 điểm cả nhóm.
