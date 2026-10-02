# Offline và revision sync

Chia sẻ02/10/2026: role/owner/time/count cập nhật qua server nhưng giữ immutable pending note
và frozen editor base. Viewer/revoke chuyển latest draft/upsert vào encrypted recovery, source
queue bỏ cùng snapshot; restore sang UUID mới. Share mutations online-only/RAM retry với
op_id+share revision riêng, không last-server-accepted preference policy. Catalogue recipients
không cache; mất mạng không thể phát hiện revoke ngay. Xem SHARING_AND_PERMISSIONS.md.

## Đã code

Sembast transaction lưu snapshot `account:<UUID>` gồm notes + immutable operations + drafts.
Web IndexedDB, native application support file. Local write chạy ngay khi gõ; debounce 650ms
chuyển draft hợp lệ thành note/outbox. Draft thiếu title/content giữ riêng; không sinh note rác.
Home có chip khôi phục draft. Editor flush trước Back và khi inactive/paused; không hứa async
dispose/beforeunload bảo đảm mọi keystroke nếu browser/OS bị kill trước database commit.

Outbox: op_id UUID, note_id UUID, kind, base_revision, immutable payload.
Note local tăng optimistic revision; nhiều operation cùng note tạo base revision liên tiếp.
Timeout giữ nguyên operation ID/payload; journal server tránh duplicate create/update.
Retry tuần tự mỗi 15s hoặc nút sync; hiện interval cố định, chưa exponential backoff.
Connectivity suy ra từ request thành công/thất bại, không dùng icon mạng làm bằng chứng sync.

Server revision khác base trả 409 + remote hoặc tombstone. Client giữ local và conflict,
dừng queue của note đó; chọn dùng remote hoặc tạo bản phục hồi mới không ghi đè remote.
403/404/423 cũng được giữ là conflict; không tự chạy operation bằng quyền mới.
Client không tự overwrite note có pending operation bằng remote refresh.

Logout xóa session và visible state ngay, generation guard bỏ response của account cũ.
Snapshot ghi với key account đã capture; không gửi queue A bằng token B. Account A vẫn giữ
local namespace để đăng nhập lại phục hồi. Auth mới offline chưa được hỗ trợ; offline reopen
chỉ với session đã lưu, quyền được kiểm tra lại khi request reconnect.

## Củng cố durability ngày 01/10/2026

Session write/remove và snapshot cùng đi qua hàng đợi ghi. Logout chờ write cũ rồi xóa session;
generation guard được kiểm tra lại sau local await trước khi gửi preference operation.
Load account chờ hàng đợi ghi trước đọc. Mỗi lần sync phải ghi snapshot thành công trước request,
kể cả sau lần save lỗi ổ đĩa. Lỗi ghi local có thông báo riêng, không báo đã lưu trên thiết bị.

Giữ bản phục hồi xung đột lấy draft mới nhất nếu có. Một transaction thay operation cũ bằng
note/outbox mới (base revision 0), hoặc draft mới nếu nội dung chưa hợp lệ. Nếu transaction lỗi,
giữ bản gốc và báo thử lại. Production snapshot nay được mã hóa; xem ENCRYPTED_RECOVERY.md cho lock recovery.

8 regression tests tại test/sync_durability_test.dart: file Sembast thật close/reopen trên host,
edit trong lúc ack/remote refresh, mất ack/replay giữ nguyên ID/payload, logout khi session write
bị chặn, disk failure không gửi network, conflict copy/draft mới nhất/reopen, write failure,
invalid draft. HTTP race dùng test doubles; không claim hai thiết bị production. File reopen
trên Windows host không phải force-kill Android/browser. Evidence: evidence/2026-10-01-durability.

## Chưa nghiệm thu

Full offline force-kill/quota hai target (reload/reopen/reconnect phạm vi đã pass xem STATUS);
mid-flight account switching/race test đầy đủ (8 regression mới chỉ bao phủ trường hợp đã liệt kê);
full conflict hai thiết bị; remote delete-vs-local draft UI; backoff; offline note unlock/key backup;
full race khi editor đang gõ (đã giữ TextEditingController và capture base revision lúc mở editor;
widget regression chứng minh không nâng base revision theo remote refresh).
Labels có catalogue server + immutable outbox riêng, CAS/conflicts/tombstones; gửi labels trước notes,
giữ local in-flight rename và không resurrect nhãn bị xóa. Avatar canonical cache mã hóa/account;
upload/remove cần online, không có media outbox. Xem AVATAR_AND_LABELS.md.
Preferences đã có outbox riêng, merge từng field và idempotency;
xem PREFERENCES_SYNC.md. Cùng field dùng last-server-accepted, nhận remote khi sync.

Attachments đã có online-only: route metadata/bytes/selected uploads chỉ RAM, không snapshot/media
outbox/offline replay. Đóng route bỏ lựa chọn chưa upload; retry trong route giữ ID/payload; lock/
revoke/lỗi mạng/account-switch che preview theo epoch/poll. Không làm đổi note revision hoặc frozen
base editor. Avatar cache khác attachment; PRIVATE_ATTACHMENTS.md ghi rõ. AI cloud không có chế độ offline. Browser có thể xóa
site storage, quota/eviction và private-mode cần test riêng; local storage không phải backup.

Online protected reader không đi vào cache/outbox và che nội dung khi mất kết nối. Mật khẩu note
chưa mở được nội dung offline. Vault recovery chỉ bảo toàn local edit đã có trước khóa, không mở
source. Xem NOTE_PROTECTION.md; protection mutation chặn khi draft/outbox nguồn chưa hoàn tất.

## App shell Web

web/flutter_bootstrap.js đăng ký offline_worker.js và dùng CanvasKit local. scripts/build.ps1 chạy
Flutter --no-web-resources-cdn rồi prepare_web_offline.py tạo hash/manifest từ release thật. Worker
chỉ cache allowlist static cùng origin; navigation fallback index.html; không cache API/note/session.
Lỗi offline reload ban đầu đã phát hiện qua browser thật và sửa; scope kết quả xem STATUS.
Worker update không tự reload khi đang gõ. Quota/eviction/cold first visit/update transitions chưa nghiệm thu.

SSE realtime chỉ online/foreground, không cache events/payload/token. Reconnect ready kích hoạt
full authorized sync; event đến giữa sync được drain lượt kế tiếp. Dirty editor giữ local text và
frozen base, không rebase theo remote; sạch tự hiển thị remote rồi explicit phiên chỉnh sửa mới.
Lock/viewer/revoke đi cùng encrypted recovery policy ở trên. HTTP15s vẫn fallback, không có
OT/CRDT hay offline realtime/merge từng ký tự. Chi tiết: REALTIME_COLLABORATION.md.
Nguồn: https://docs.flutter.dev/platform-integration/web/initialization và
https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API/Using_Service_Workers .
