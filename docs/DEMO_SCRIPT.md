# Kịch bản demo cần nhóm ghi hình

Chưa có video/timestamp. Nhóm phải tự tham gia, ≥1080p, rõ âm thanh, có cả Hùng và Long.
Không dùng log/screenshot thay demo chức năng; timestamp chỉ điền sau xem video thật.

| Đoạn | ID | Dữ liệu/kịch bản | Target | Người/timestamp |
|---|---|---|---|---|
| Auth | 1–4 | register tự login, banner, email activation, login/logout, reset manual login | Web + Android login; lifecycle hai target | Chưa xác định / chưa quay |
| Profile/settings | 5–8 | avatar/name/current-password/preferences restore | Ít nhất một; verify cả hai | Chưa xác định / chưa quay |
| Core | 9–14,17–22 | grid/list, create/edit auto-save, reopen, cancel/delete, pins/search/labels | Web + Android create/edit | Chưa xác định / chưa quay |
| Attachments | 15–16 | images/video/file, upload error, authorized download | Web + Android | Chưa xác định / chưa quay |
| Protection | 23–24 | incorrect/correct password, owner locked API deny, change/disable | Ít nhất một; verify cả hai | Chưa xác định / chưa quay |
| Collaboration | 25–26 | owner A, B viewer→editor, C denied, two session/revoke | Web + Android share hoặc realtime | Chưa xác định / chưa quay |
| AI | 27–28 | summary regenerate, question nhiều note, citation open, no data | Web + Android ít nhất một AI | Chưa xác định / chưa quay |
| Architecture/offline/release | 29–32 | adaptive, test explanation, offline reopen/sync, conflict, account switch, HTTPS/native release | Hai target | Chưa xác định / chưa quay |

Script này mapping đủ 32 mục nhưng không chứng minh đã làm. Khoảng timestamp từng ID sẽ bổ sung
sau ghi hình. Grading accounts riêng có dữ liệu owner/viewer/editor, labels/files/protected/AI sources;
không ghi mật khẩu thật vào repo, chỉ đưa trong tài liệu nộp riêng.

Avatar/labels đã chạy local QA (evidence/2026-10-01-avatar-labels), chưa có video. Có thể quay:
Profile → chọn PNG/JPEG → upload → đóng/mở offline xem avatar cache → online Dùng ảnh mặc định.
Quản lý nhãn → thêm → editor gắn nhãn → Home chọn filter → offline đổi tên → reload giữ pending
→ reconnect → phiên khác rename → sync → xóa nhãn-confirm; note/title/content/revision vẫn giữ.
Chỉ quay service/máy/target thật; đừng dùng QA fixture/screenshot để giả video hoặc timestamp.

Attachments15/16 đã chạy local QA (evidence/2026-10-01-attachments), chưa quay. Có thể quay note
đã sync → chọn PNG/MP4/TXT → upload → ảnh/video preview → tải TXT (Android chọn vị trí Save) →
xóa TXT-confirm, nội dung note còn → phiên khác lock hoặc xóa ảnh → preview che sau kiểm tra
quyền/poll. Chọn video H264 đã biết phát được; attachment online-only, không diễn media outbox
offline. Protected-reader file UI/OS denied-cancel vẫn cần QA thực trước claim trong video.

Sharing25/18 đã có local QA02/10/2026, chưa video: A tạo note, thêm B/C (đã đăng ký), batch có
email chưa đăng ký bị từ chối toàn bộ; B xem owner/time/role → A đổi B editor → B sửa → A hạ
viewer hoặc thu hồi lúc B có draft chưa sync → B readonly/che và Phục hồi UUID mới. A vẫn giữ
original content/revision khi chỉ đổi quyền; source locked cần grant. Đây là sync/poll15s, không
diễn subscription26 ở mốc sharing cũ. Xem SHARING_AND_PERMISSIONS.md/evidence index, chỉ điền timestamp sau quay.

Realtime26 local QA02/10: mở cùng note ở hai tài khoản được cấp quyền → B sửa → A thấy nội dung
trong editor đang mở, không tap Đồng bộ/reopen. A sạch có nút Chỉnh sửa phiên bản mới để đổi
phiên base rõ ràng; A có draft thì giữ draft, save stale409 → chọn conflict/recovery. Ngắt/nối
stream hoặc restart backend → tự catchup; owner đổi viewer/revoke/lock → API deny/UI readonly/
che/recovery. Đây là SSE invalidation + authorized refetch/revision CAS, không cursor/OT/CRDT.
Protected-reader actual realtime và public HTTPS/video chưa nghiệm thu; chỉ ghi timestamp sau quay.
