# Checklist nộp - chưa sẵn sàng

- [ ] Deadline/ngày bắt đầu chính thức đã xác nhận.
- [ ] 32 mục có bằng chứng hai nền tảng theo phạm vi đề; self-assessment trung thực.
- [ ] Rubric.xlsx gốc giảng viên (chưa có; matrix không thay file này).
- [ ] demo.mp4 ≥1080p, hai thành viên, đủ coverage/timestamp; hoặc link YouTube hợp lệ.
- [ ] Readme.txt đúng version/config/lệnh/URLs/artifact/limitations/grading accounts.
- [ ] source clone từ GitHub thật và giữ .git; pubspec.lock, tests, backend/schema/config đầy đủ.
- [ ] Screenshot.png GitHub Insights, repo/contributors/4 tuần rõ nếu claim teamwork.
- [ ] public Flutter Web HTTPS + backend ổn định trong thời gian chấm.
- [ ] release/web-url.txt + app-release.apk có signing phù hợp, install/run đã test.
- [ ] Quét secrets trong source và history; không tự rewrite contribution history.
- [ ] Loại .dart_tool/build/cache/dependencies/state/secrets khỏi source; giữ .git và native release riêng.
- [ ] Test setup/build từ clone sạch, unpack ZIP, Git valid/checksums, mở web mạng độc lập.
- [ ] Thư mục `523K0006_NguyenBaHung_523K0014_NguyenBaoLong` và ZIP cùng tên.
- [ ] Nhóm nộp e-learning; không email; agent không tự gửi bài.

Thiếu source/video/Rubric/public Web URL/native artifact có thể 0 cả nhóm.
Tr.16 cho ngoại lệ Git evidence khi nhận -0.5 teamwork, tr.17 yêu cầu source clone có .git;
chọn luôn giữ .git và báo trung thực teamwork. Không có script tạo ZIP giả khi repo/video/rubric/URL
chưa có. Script package cuối cần fail-closed kiểm tra đầu vào và đường dẫn, clone đúng repo/commit,
loại cache bằng allowlist, bảo toàn .git, unpack và kiểm tra Git/artifact.
