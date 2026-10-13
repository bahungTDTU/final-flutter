# PR9 — tích hợp master mới,13/10/2026

PR9 head ban đầu`f0267d15fe2915777bae5aedd5f189ea13423480` đã có3requiredCIchecks
success. Trong lúc CI chạy, PR8 được merge vào master`eaf39b469dc91ead9f94e979b0310c85174ab87b`.
Branch được tích hợp master bằng merge commit, không squash/rebase/force-push hoặc merge
PR9 vào master. Giữ nguyên các commit của Nguyễn Bảo Long và Bahung.

Xung đột README/Readme.txt/matrix là các phần bổ sung tài liệu; giữ cả hai nhánh và
thêm thông tin hiện hành phía đầu. STATUS auto-merge giữ cả hai snapshot. Không thay
library UI/controller/data/dependency hoặc ACL để xử lý xung đột.

Master mới có native acceptance scripts/tests, signing/production guards, backend backup/
restore, Docker/Compose và evidence riêng. Local check được chạy lại sau integration;
format/analyze/279 Flutter/143 backend PASS trong`check.txt`.
`source_manifest.json` ràng buộc source và hai merge parents,`SHA256SUMS.json` giữ raw
evidence; CI được chạy lại trên merge head mới, không dùng3greenchecks của f0267 thay nó.

Browser/API inspector acceptance vẫn thuộc source trước integration; library UI và note
authorization không đổi khi tích hợp. Evidence của PR8 ghi native debug/driver theo scope
riêng; không coi là native UI/IME/FPS acceptance cho inspector mới.
Không đóng gates public HTTPS, real provider, release signing certificate, video/submission.

PR9 đã attach task. Chờ3requiredCIchecks mới nhất và1humanapproval sau push cuối theo
ruleset; không tự approve hoặc merge. `before-integration-ci.json` ghi trạng thái thực
của head cũ và master vừa đổi; không sửa snapshot cũ.
