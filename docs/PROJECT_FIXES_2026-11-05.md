# Rà soát và sửa lỗi — 05/11/2026

## Đồng bộ và phạm vi

Backup 16 file local vào ZIP ignored và đọc lại đối chiếu byte trước khi pull.
`git pull --ff-only origin master` đưa checkout từ ee7c836 lên 7a8e84c;
merge commit không đổi source tree. Nhánh mới `codex/release-readiness-validation`.
Giữ `.agents`, bản trích PDF và evidence cũ; không thêm chúng vào commit này.

Đọc hướng dẫn repo, yêu cầu gốc và các gate nghiệm thu. Rà soát validation rich text,
nhập/xuất, backend authorization, offline build, release guard và cấu hình dependency;
chạy bộ kiểm tra toàn dự án. Đây không phải chứng minh không còn lỗi hoặc đủ32 tiêu chí.

## Sửa lỗi

1. Parser Dart trước đây chấp nhận `attributes: null`, cỡ chữ có dấu/khoảng trắng,
   line-height dạng số mũ/dấu/khoảng trắng trong khi backend từ chối. Import bundle
   vì vậy có thể qua validation client nhưng bị từ chối khi sync. Giờ parser từ chối
   các dạng này, chặn ngay ở import; giữ nguyên văn fallback cho dữ liệu cũ không hợp lệ.
2. Cả client/backend trước đây nhận mã màu 7 chữ số do regex `{6,8}`. Giờ chỉ nhận
   6 hoặc 8 chữ số (RGB/ARGB), chữ số size/line-height dùng cùng grammar ASCII.
   API trả422 trước khi tạo note/operation; màu hợp lệ và plain text vẫn roundtrip.
3. Build cảnh báo thiếu font Cupertino. Bổ sung `cupertino_icons: 1.0.8` và lockfile;
   build mới đóng gói font1472byte sau tree-shaking, hết cảnh báo thiếu font.

Không đổi schema, ACL, frozen editor revision, immutable outbox hoặc preferences merge.
Không tự migrate/rewrite nội dung legacy. Chuỗi rich legacy không hợp lệ hiển thị fallback
nguyên văn; cần sửa qua editor trước khi gửi lại theo grammar hợp lệ.

## Bằng chứng và giới hạn

`evidence/2026-11-05-project-fixes/INDEX.md` ghi lệnh và kết quả cuối.
Regression trước sửa: Flutter1FAIL/1PASS; backend2FAIL/19PASS.
Sau sửa: targeted Flutter21PASS và backend21PASS; thêm3 backend cases hợp lệ/legacy
được chạy trong full suite cuối. Các logs FAIL giữ lại, không đổi thành PASS.

Nghiệm thu local trước sửa giữ ở `evidence/2026-11-05-acceptance`, báo cáo gap gốc
và biên bản đã bổ sung trong docs. Không dùng kết quả trước sửa thay kiểm tra bản cuối.
Toolchain local Flutter3.47.9/Dart3.13.7/Python3.12.14; CI vẫn pinFlutter3.47.1.
API dùng DB disposable và provider fixture; session tạm được xóa sau test.

PublicHTTPS, SMTP/LLM thật, signing/native release, UI runtime hai bản cuối,
Rubric/video/Insights/ZIP vẫn chưa nghiệm thu. Người dùng xác nhận nhóm chưa có
đầu vào provider/release; không tạo tài khoản, phát sinh phí, deploy hoặc nộp bài.
Các điều kiện đóng gate nằm trong `ACCEPTANCE_2026-11-05.md`.

Người dùng ủy quyền commit/push branch và PR; author/committer Nguyễn Bảo Long
<523k0014@student.tdtu.edu.vn>, có AI hỗ trợ. Không tự merge hoặc giả approval.
