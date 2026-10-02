# Nhóm và đóng góp thật

Thông tin người dùng xác nhận 01/10/2026:
- 523K0006 – Nguyễn Bá Hùng.
- 523K0014 – Nguyễn Bảo Long.
- Deadline: trước tháng 12/2026; chưa có ngày/giờ cụ thể.
- GitHub repo sẽ tạo sau; cloud sẽ xử lý sau; người dùng xác nhận được dùng AI toàn phần.

Cập nhật người dùng xác nhận02/10/2026: repository https://github.com/bahungTDTU/final-flutter,
ủy quyền initial commit/push bằng danh tính Git Bahung <523K0006@student.tdtu.edu.vn>,
không gắn tác giả/co-author GPT hoặc Codex. Đây là initial import code được AI hỗ trợ,
không chứng minh mỗi người đã làm đủ số commit/tuần theo rubric.

Chưa có phân công được nhóm xác nhận. Đề xuất để nhóm xem xét:
Hùng: Flutter UI/controller/local sync và tests; Long: backend/ACL/email/files/AI/deploy và tests.
Cả hai review lẫn nhau, tự làm bài sửa nhỏ và giải thích phần nhận trước khi claim đóng góp.
Mọi code hiện tại do agent hỗ trợ tạo; initial import theo ủy quyền không được tự gán thành
đóng góp thực hiện độc lập hoặc contribution của Long.

Chờ ngày bắt đầu phát triển chính thức và deadline cụ thể để lập 4 tuần lịch liên tiếp
thứ Hai–Chủ nhật. Mỗi người/mỗi tuần ≥2 meaningful commits đã push và còn trong history.
Không backdate, không dùng chung tác giả, không squash làm mất lịch sử cần chấm.
Các QA snapshots trước initial import có commitnull và không remote; giữ nguyên bằng chứng đó.
Lịch sử Git hiện tại kiểm tra bằng git log/git ls-remote; xem docs/GITHUB_PUBLISH.md.

Vấn đáp/bài thực hành trước claim:
1. Giải thích controller → local transaction → immutable op → server ACL/revision → ack.
2. Viết thêm test timeout-replay và account switch khi sync đang chạy.
3. Giải thích vì sao owner vẫn cần unlock và why hiding button không đủ bảo vệ viewer.
4. Thay validation/rule và tự chứng minh qua unit + direct API test.
5. Phân biệt local pass, email mailbox test, production delivery và video evidence.
