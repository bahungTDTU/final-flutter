# Tiêu chí 8 – tùy chỉnh theo tài khoản

Ba tùy chọn: theme sáng/tối, cỡ chữ note 14–24, grid/list (grid mặc định).
UI áp dụng sau khi local transaction commit, lưu trong `account:<UUID>` cùng immutable
`pending_preferences`. Logout trả theme/font/view về mặc định; hàng đợi cũ giữ trong namespace
của tài khoản cũ, không gửi bằng session tài khoản mới.

Mỗi operation chứa UUID và chỉ các trường người dùng đổi. Đồng bộ gửi tuần tự trước note queue,
server kiểm tra session rồi merge từng trường trong transaction. Bảng `preference_operations`
ghi fingerprint theo user+op_id. Retry payload cũ chỉ đọc trạng thái hiện tại, không áp lại;
op_id trùng với payload khác trả409. Endpoint không nhận owner/role hoặc trường khác.

Quy tắc hai thiết bị: các trường khác nhau được giữ; cùng một trường thì thay đổi được server
chấp nhận sau cùng thắng. Đây là tùy chỉnh hiển thị, không dùng quy tắc này cho note content.
Local changes phát sinh khi request đang chạy vẫn overlay lên server profile và còn trong outbox.
Thiết bị khác nhận trong lần sync kế tiếp (timer15s/nút sync/login); không claim realtime.
Lỗi mạng giữ pending; UI hiện số tùy chỉnh chờ và nút retry. Không gọi pending là đã sync.

Backend schema additive `CREATE TABLE IF NOT EXISTS` không thay/xóa dữ liệu hiện có;
schema version vẫn1 (initial schema được mở rộng trước first release).
Local snapshots cũ chưa có pending_preferences đọc như queue rỗng. Những preferences từ bản
best-effort cũ chưa từng tới server không được suy đoán là pending: lần sync mới nhận server.
Nên backup local/state trước upgrade nếu cần giữ tùy chỉnh cũ chưa sync.

Backend legacy PATCH `/me/preferences` còn để tương thích bản local đầu; Flutter mới dùng
POST `/me/preferences/sync`. Các client cần upgrade cùng backend để có retry idempotent.
Server trả profile khi login; Sembast giữ cache trước reopen offline, sync lấy server khi online.

Kiểm thử: backend merge/replay-after-new-change, malformed/unknown fields, account isolation,
DB reopen; controller durable queue semantics (memory double), mid-flight local edit;
widget theme/pending/logout; integration Android real HTTP+Sembast offline port65530/reopen/
reconnect và second session. Actual browser scope/result ở evidence/2026-10-01-preferences.
Native test là emulator/debug; DB reopen cùng process, chưa OS kill/physical device.
Chưa public deploy, video hoặc timestamp chấm.
