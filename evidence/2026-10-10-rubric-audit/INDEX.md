# Rubric audit —10/10/2026

[Báo cáo đủ32 tiêu chí](../../docs/FINAL_PROJECT_AUDIT_2026-10-10.md).
Source `a5e5ec60568b7ee2b0c50290a3e6502a4d490110`; chỉ thêm report/evidence,
không sửa application code, không commit/push/deploy/merge trong lượt audit này.

| Kiểm tra | Command/target | Kết quả/bằng chứng |
| --- | --- | --- |
| PDF gốc19trang | pypdf layout extraction + pdfium render, xem tr.13/14/16/17 | SHA256/paths/pages trong audit.json; text/render local ở tmp/pdfs/audit-2026-10-10 |
| Source drift | SHA256192inputs đối chiếu manifest editor09/10 | Runtime/tests/README khớp; chỉ STATUS publication thay đổi, README/Readme byte-identical |
| Git inventory | git fetch origin; git log --all --no-merges --format | git-history.txt,8 non-merge commits cùng Bahung,2 tuần; không chứng nhận meaningful/independent contribution |
| GitHub CI | GET commit check-runs + PR/reviews, không mutation | github-status.json:3 success trên head a5e5ec6; PR#3 open, chưa reviews |
| Probe rubric17 | flutter test tmp/audit-2026-10-10/locked_order_probe_test.dart --no-pub --reporter expanded | **FAIL,exit1**; expected protected-new trước ordinary-old, thực tế ngược; locked-order-probe.txt + probe source |
| Full suites/Web/native/providers hôm nay | Không chạy lại | NOT RUN;210/108/Web14ảnh/build là evidence09/10, không cộng probe vào suite |

Probe chạy Flutter host unit fixture, không tác động DB người dùng hoặc service.
Không bỏ assert/sửa runtime để tạo PASS. Ghim luôn trước đã được regression cũ kiểm tra;
defect mới ở nhóm chưa ghim không dùng ngày cho locked note. Giữ riêng tư metadata khi sửa.

Các missing paths trong audit.json chỉ là inventory workspace đang audit, không tìm toàn
bộ máy hoặc kết luận nhóm không có artifact ở nơi khác. Không đọc Gemini key/SMTP password/user DB.
Secret của credential helper GitHub chỉ giữ trong bộ nhớ khi đọc API, không xuất vào artifact.
