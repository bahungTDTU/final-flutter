# Trung tâm bảo mật và hiệu năng xác thực —11–12/10/2026

Mở **Hồ sơ và tùy chỉnh → Trung tâm bảo mật**. Người dùng xem phiên hiện tại/các phiên
khác, trình duyệt/nền tảng tham khảo, lúc đăng nhập và hết hạn; thu hồi một phiên hoặc
toàn bộ phiên khác bằng mật khẩu tài khoản. Phiên hiện tại dùng nút Đăng xuất hiện có.
PC có thẻ ngang; điện thoại/chữ lớn dùng thẻ dọc, nội dung và hành động tách rõ. Dùng
gradient AppBar, SurfacePanel, màu sáng/tối và motion hữu hạn của theme chung.

## Ranh giới bảo mật

`GET /me/sessions` chỉ đọc phiên của account từ Bearer. Handle UUID công khai riêng biệt
với token/digest; response không chứa IP, raw User-Agent hoặc thông tin account khác.
User-Agent chỉ được rút gọn thành nhãn tham khảo, không chứng minh danh tính thiết bị.
`POST /me/sessions/revoke` chỉ nhận scope/password/session_id; không nhận user_id/owner/
permission. Target ngoài account hoặc đã xóa trả cùng `{ok:true,revoked:0}`; target phiên
hiện tại trả409. DELETE session cascade cả grant unlock và session_details.

Xác nhận mật khẩu để thu hồi phiên và đổi mật khẩu dùng chung counter bền vững theo
account:5 lỗi →60s/429/Retry-After, kể cả qua session hoặc restart. Mật khẩu đúng không
bypass cooldown; hết cooldown bắt đầu cửa sổ mới, đúng xóa counter. Login cũng reset
cửa sổ sau cooldown; scope email chuyển sang SHA256, migration giữ cooldown cũ. Hash
scope giảm email thô trong bảng attempts, không phải mã hóa email/chống enumeration.

Login email≤254/password≤128; confirmation, account/note current-password và unlock≤128;
Bearer≤512 trước digest lookup. Lỗi schema422 chỉ trả loc/msg/type, bỏ input/ctx/body để
không phản chiếu password, token hoặc nội dung. API responses có private/no-store,
nosniff/no-referrer; CORS expose Retry-After. HTTPS vẫn là gate deployment riêng.

SecuritySession thuộc route, giữ catalogue trong RAM, không lưu password/handles/timestamps
vào Sembast, workspace, draft hay outbox. Đổi account/token, background hoặc dispose che
metadata và abort HTTP đang chạy; epoch bỏ kết quả cũ. Resume tải lại một lần, không
polling/ticker riêng. Dialog xóa password khi background/đổi phiên; sai password giữ input
ẩn để retry. Timeout/network/schema lỗi bỏ danh sách và yêu cầu reload; timeout có thể
đến sau commit, retry target cũ là no-op rồi đọc lại server.401 logout xóa encrypted session,
giữ account/drafts mã hóa trên đĩa để phục hồi khi đăng nhập lại.

Thu hồi phiên bắt buộc máy kia đăng nhập lại khi gọi server; SSE online phát expired
theo kiểm tra250ms hiện có. Không xóa/thu hồi từ xa dữ liệu đã tải trên thiết bị mất mạng.
Thiết kế xác nhận thao tác nhạy cảm và quản lý phiên tham khảo
[OWASP Session Management](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html).
Không triển khai MFA/passkeys, quản lý thiết bị hệ điều hành hoặc distributed abuse limits.

## Migration và hiệu năng

Giữ bảng sessions ba cột để tương thích; thêm session_details FK/cascade và index theo
user_id/expiry, expiry. Startup dọn session hết hạn và backfill handle ổn định. Phiên cũ
không có thời điểm đăng nhập được ghi NULL/“trước khi nâng cấp”, không suy đoán timestamp.
Catalogue chỉ render tối đa20 lazy rows, kèm tổng. Account legacy vượt20 vẫn được giữ khi
startup, hiển thị20 + thông báo; all-others áp dụng cho mọi phiên của account. Mỗi login
mới dọn expired và giữ tối đa20 phiên, luôn giữ token vừa cấp dù thời điểm bằng nhau.

Authenticate dùng query-only `BEGIN` thay `BEGIN IMMEDIATE`; đọc catalogue cũng dùng
read transaction. Mutation giữ `BEGIN IMMEDIATE` và kiểm tra lại session/ACL/grant trong
cùng transaction, chống revoke xảy ra sau dependency. Các endpoints khác chưa chuyển
toàn bộ sang read transaction; SQLite vẫn phù hợp backend local một instance.
[SQLite transaction semantics](https://www.sqlite.org/lang_transaction.html) giải thích
reservation của IMMEDIATE và snapshot của transaction đọc.

Benchmark local5001 sessions/300 mẫu mỗi cách: p50 cũ0.6174ms, mới0.6672ms; p95 cũ0.9212ms,
mới0.9243ms. Không có cải thiện latency đơn lẻ đáng kể và không suy ra FPS/throughput.
Khi một writer giữ reservation, dependency thật đọc trong1.1446ms; transaction cũ timeout
50ms. Trace dependency thật xác nhận0 BEGIN IMMEDIATE/auth, query_only bật. Legacy comparator
chỉ mô phỏng transaction/query trước đây; current còn thực hiện digest/row factory/PRAGMA.
Kết quả minh họa giảm tranh chấp writer, không phải benchmark HTTP end-to-end hoặc load test.

## Nghiệm thu và giới hạn

Xem [evidence](../evidence/2026-10-11-security-center/INDEX.md): unit/widget/API thật/Chrome,
commands, hashes và bản build được đối chiếu. Snapshot bắt đầu11/10, kết thúc sau nửa đêm
12/10 Asia/Saigon. Branch `codex/security-center`, base master `35db810` sau PR#4 do người
dùng merge; source working changes, chưa commit/push. Không sửa snapshot QA trước đây.
Release/signing/public HTTPS/provider thật/native runtime/IME/FPS/screen reader của phần
mới chưa nghiệm thu; release vẫn để sau theo yêu cầu người dùng.
