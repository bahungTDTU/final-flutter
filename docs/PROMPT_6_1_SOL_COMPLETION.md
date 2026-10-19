# Prompt bàn giao cho GPT-6.1 Sol

Chọn 6.1 Sol trong Codex, mở đúng repo rồi dán phần dưới. Khuyến nghị thực hành: dùng
reasoning High cho công việc thông thường; tăng khi điều tra race/security khó nếu giao
diện hỗ trợ. Đây là lựa chọn vận hành đề xuất, không bảo đảm chất lượng. Không cần API key
OpenAI chỉ để dùng prompt này trong phiên Codex đã đăng nhập.

## Prompt để sao chép

```text
Hãy tiếp tục hoàn thiện NoteTogether bằng GPT-6.1 Sol. Thực hiện công việc, không dừng ở
việc nhắc lại kế hoạch. Mục tiêu là một release Web + Android chạy được, tái lập được,
đúng quyền/offline và có bộ nghiệm thu/nộp trung thực theo yêu cầu chính thức.

Repo: https://github.com/bahungTDTU/final-flutter
Checkout đã biết:
C:\Users\Nguyen Long\Documents\Codex\2026-10-11\https-github-com-bahungtdtu-final-flutter\final-flutter
Hãy xác minh đường dẫn và Git state thật. Snapshot bàn giao19/10: branch
codex/backup-restore-hardening, HEAD bae3159, master d59fdfd; PR10 cho backup hardening.
Đây chỉ là snapshot, không giả định remote/CI/approval vẫn như vậy.

Đọc trước khi sửa:
1. AGENTS.md và docs/COMPLETION_PLAN_2026-10-19.md.
2. STATUS.md, docs/REMAINING_GATES.md, docs/LOCAL_BASELINE_AND_ROADMAP.md,
   docs/REQUIREMENTS_MATRIX.md, README.md và docs/BRANCH_WORKFLOW.md.
3. PROMPT_CHO_AGENT.md như yêu cầu nền; không chạy lại scaffold M0 của prompt cũ.
4. Tài liệu chuyên đề và evidence của gate đang làm. Đối chiếu code/tests trước kết luận.
Nếu tìm thấy PDF/Rubric gốc, đối chiếu; nếu thiếu, giữ blocker và không tạo bản giả.

Chính sách hiện hành của tôi:
- Đã cho phép sửa, kiểm thử, commit và push branch/PR; mỗi chặng xong phải commit có ý nghĩa.
- Author và committer: Nguyễn Bảo Long <523k0014@student.tdtu.edu.vn>.
  Kiểm tra repo-local identity trước commit; yêu cầu này thay đoạn author cũ trong AGENTS.
  Giữ lịch sử tác giả người khác, ghi nhận có AI hỗ trợ, không giả đóng góp/teamwork.
- Chỉ dùng branch codex/*, không direct push master, force push, reset bỏ thay đổi của tôi.
  Kiểm tra PR hiện có trước tạo mới. PR phải được attach vào chat khi tạo/tiếp tục.
  Chỉ merge khi đã có ủy quyền merge áp dụng và đủ ruleset: đúng head mới nhất,
  Flutter quality/Backend tests/Build smoke PASS, up-to-date base, hết review threads,
  approval thật từ người khác sau push cuối. Không tự approve hoặc bypass.
- Tôi đã xác nhận SMTP/Gemini chưa cấu hình và muốn tiếp tục local. Chỉ thay trạng thái
  khi có bằng chứng/cấu hình mới. Không hỏi lại liên tục; không xin key/password trong chat.
- Không tự tạo chi phí, chấp nhận license, đổi BIOS/WSL/reboot, ký bằng danh tính giả,
  công bố dịch vụ hoặc nộp bài khi chưa có ủy quyền cụ thể. Chuẩn bị đầy đủ phần local trước.
- Không tự tạo subagent nếu tôi chưa yêu cầu. Không gửi tin nhắn reviewer/thành viên thay tôi.

Làm theo C0–C5 trong COMPLETION_PLAN:
C0 xác minh remote/PR10 và thống nhất trạng thái tài liệu.
C1 native editor IME và OS relaunch/offline.
C2 conflict/permissions/protected lifecycle/picker/labels/account password hai target.
C3 SMTP/Gemini thật khi nhóm cấu hình.
C4 container persistence/restore, HTTPS, signed APK, clean production build/run.
C5 final acceptance, video/rubric/Insights/package/unpack và bàn giao.
Trong từng chặng: tái hiện/kiểm tra trước, chỉ sửa nếu có lỗi hoặc khoảng trống cụ thể;
thêm regression meaningful; chạy checks phù hợp; kiểm UI/API/OS đúng claim; lưu evidence;
cập nhật gate; commit/push theo policy. Tiếp tục chặng độc lập tiếp theo, không dừng để hỏi
“có làm tiếp không”. Nếu thiếu đầu vào thật, ghi BLOCKED chính xác và làm phần không phụ
thuộc; không đóng gate bằng fixture. Nếu hết việc khả thi, báo việc cần người dùng cung cấp.

Giữ các invariant:
- Editor UUID và frozen base revision; immutable operation ID/payload; CAS/idempotency.
- Local draft durability, atomic encrypted recovery, account namespace/session epoch.
- Note khóa chỉ public6fields; không title/content/labels/identity/count leak trước unlock.
- ACL/grant tại backend cho note/files/share/AI; kiểm lại quyền khi async response về.
- Viewer không sửa; owner không bypass unlock; revoke không âm thầm bỏ draft hợp lệ.
- Không gọi encryption client là E2EE; không hứa thu hồi dữ liệu đã tải khi offline.
- README.md và Readme.txt byte-identical; raw evidence lịch sử bất biến.

Không redesign toàn app hoặc đổi stack để “hoàn thiện”. Không thêm CRDT, offline media,
key transfer, vector DB, DOCX/PDF export nếu chưa có yêu cầu chứng minh cần thiết.
Tách rõ: code đã có / tests local / UI thật / native OS thật / provider / public release.
279Flutter và148backend trong bàn giao là kết quả ở các snapshot khác nhau, phải đọc INDEX;
không mặc định đó là kết quả kiểm thử lượt này. CI build smoke là APK debug, không signed release.

Môi trường: Windows PowerShell; Flutter3.47.1/Dart3.13.1, Python3.12 theo repo.
Đọc scripts/toolchain.ps1, setup.ps1, check.ps1, build.ps1 và current-source acceptance
trước chọn lệnh. Không đoán path F: hoặc emulator đang chạy. QA dùng DB/account/port riêng,
không overwrite database/volume của tôi. Không in env/credentials hoặc compose config có secrets.

Evidence mỗi gate gồm source SHA, artifact hash nếu có, target/OS/API, case, expected/actual,
lệnh, kết quả, giới hạn, log/ảnh đã loại bí mật. Mock/injected lifecycle/DB reopen không
thay IME/OS kill/inbox/LLM thật. Không tạo test chỉ để tăng số lượng hoặc viết PASS chưa chạy.

Định nghĩa hoàn tất: các gate bắt buộc đã được kiểm chứng trên đúng release candidate;
critical flows đúng trên Web HTTPS và APK ký thật; setup/build/restore tái lập; artifact,
source và config liên kết rõ; tài liệu/rubric/video/Git evidence trung thực và gói giải nén
kiểm tra được. Nếu chỉ hoàn thành local, báo đúng “local complete; external gates blocked”.

Hãy bắt đầu bằng kiểm tra working tree/remote/PR và đối chiếu C0, sau đó thực hiện ngay
việc ưu tiên cao nhất có thể làm. Mỗi cập nhật nêu kết quả, bằng chứng và bước kế tiếp;
báo cuối ghi commit/PR, checks đã chạy, gates đã đóng/còn mở và đầu vào còn thiếu.
```

## Cách tiếp tục sau một phiên

Dùng cùng repo và gửi: “Tiếp tục từ docs/COMPLETION_PLAN_2026-10-19.md và trạng thái mới
nhất trong REMAINING_GATES. Kiểm tra Git trước, giữ các ràng buộc đã xác nhận, thực hiện
gate ưu tiên cao nhất còn khả thi và commit dưới tên tôi.” Không yêu cầu chạy lại các
chặng đã PASS nếu source/tác động không thay đổi; bản release cuối vẫn cần critical QA.

Khi có blocker, chỉ cung cấp thông tin không bí mật như “SMTP đã cấu hình trên backend”,
“keystore nằm ở đường dẫn ignored này” hoặc “thiết bị đã kết nối”. Thành viên thực hiện
review/video và xác minh nội dung; không dùng prompt để tạo approval hoặc bằng chứng giả.
