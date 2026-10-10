# Không gian làm việc cá nhân —10/10/2026

Nâng cấp sáng tạo theo yêu cầu người dùng, bổ sung ngoài 32 tiêu chí gốc. Vào **Không gian
làm việc** từ dashboard/thanh bên. PC dùng Ctrl+K (hoặc Cmd+K) trên Home/workspace để tìm
nhanh và mở ghi chú; Ctrl+K trong editor vẫn dành cho chèn liên kết.

| Chức năng | Hành vi thực tế |
|---|---|
| Tìm nhanh | Tìm tên/nội dung hiển thị của ghi chú chưa khóa, tối đa 30 kết quả; Enter mở kết quả đầu, có lệnh mở workspace/nhật ký |
| Yêu thích | Ngôi sao trong Tìm nhanh/bộ sưu tập/danh sách cá nhân; độc lập với ghim, tối đa 500 ID |
| Gần đây | 20 ID ghi chú đã mở từ Home/workspace; không lưu tiêu đề, nội dung hay thời điểm mở |
| Bộ sưu tập thông minh | Lưu điều kiện từ khóa + AND nhãn + nguồn của bạn/được chia sẻ; kết quả cập nhật theo notes hiện tại; tối đa 20 bộ, 30 nhãn/bộ |
| Bảng công việc | Gom checklist Markdown và Quill thành Cần làm/Hoàn thành; tối đa 200 ghi chú chưa khóa, 100 mục/ghi chú |
| Mẫu riêng | Tạo/sửa/xóa tối đa 30 cấu trúc Markdown cá nhân; dùng mẫu tạo bản nháp bền với UUID mới |
| Nhật ký hôm nay | Tên theo ngày thực tế của thiết bị; mỗi lần tạo một bản nháp mới, không ghi đè nhật ký cùng ngày |
| Nhập/xuất | JSON giữ tiêu đề và chuỗi nội dung/định dạng; giới hạn 1–50 ghi chú, 5 MiB; có xem trước/xác nhận |

Yêu thích, lịch sử, điều kiện tìm kiếm và mẫu riêng nằm trong `workspace` của account vault
AES-GCM hiện có. Đây là tổ chức cá nhân **trên thiết bị**, chưa đồng bộ workspace giữa nhiều
thiết bị. Nội dung ghi chú tạo từ mẫu/nhật ký/import và checklist sửa dùng server sync hiện có.
Mẫu riêng được nhập thủ công, không tự sao chép nội dung từ reader của ghi chú bảo vệ.

## Dữ liệu và quyền

Home/account listing vẫn chỉ lưu đúng sáu trường công khai khi khóa. Yêu thích/lịch sử chỉ
giữ ID; mọi màn hình workspace, palette và hộp xuất lọc lại quyền/locked state. Khóa hoặc
thu hồi quyền làm nội dung biến mất ngay khi controller nhận trạng thái mới. Cache phân
tích checklist chỉ sống trong route, purge khi source bị ẩn hoặc account đổi. Chưa nhận
được thay đổi server khi offline thì chỉ có thể áp dụng trạng thái server gần nhất, như Home.

Checklist sử dụng snapshot đã hiển thị: revision, tiêu đề và nội dung phải còn khớp, không
có draft/outbox/conflict và role phải được sửa. Operation giữ base revision, pin và label IDs;
server vẫn quyết định ACL/CAS/grant. Viewer được xem công việc nhưng checkbox không cho sửa.
Không tự rebase, ghi đè xung đột hay biến bảng công việc thành một bản lưu nội dung khác.

Workspace write được serialize cùng queue local; đọc root bền trước khi sửa riêng trường
`workspace`. Ordinary snapshot merge trường này ở thời điểm commit, giữ workspace mới hơn,
draft projection và password vault. Account/generation guards ngăn kết quả của account A
xuất hiện trong account B. Logout xóa state RAM, giữ account vault bền.

## Chuyển ghi chú

File `.notetogether.json` có đúng ba trường gốc và mỗi ghi chú có đúng hai trường:

```json
{"format":"notetogether-notes","version":1,"notes":[{"title":"Kế hoạch","content":"- [ ] Một việc"}]}
```

Chuỗi `NTDOC1:` hợp lệ giữ nguyên rich formatting; chuỗi sai schema bị từ chối. Tiêu đề
tối đa 200 ký tự, nội dung tối đa 100.000 ký tự và phải có văn bản. File không được mang
ID, owner, role, grant, revision, protection hoặc labels. Import từ chối trường thừa, payload
quyền, malformed document, sai version, file quá lớn và quá 50 ghi chú.

Import tạo fresh UUID/base revision 0 và immutable operation IDs, lưu một account transaction
trước gửi; reconnect dùng chính các operations đó. Storage failure rollback batch trong RAM,
không gửi batch chưa được publish. Đây là một transaction **local**; server chấp nhận từng
operation, không phải một transaction batch trên server. Không ghi đè note hiện có.

Export chỉ cho ghi chú owner chưa khóa. Đọc lại source sau xác nhận; selection bị khóa/thu hồi
sẽ hủy lượt xuất. File xuất **không mã hóa**, không có attachments hoặc danh sách người nhận.
UI giải thích điều này trước tải. Web dispatch Blob download; Android dùng trình lưu SAF hiện
có. Dispatch thành công không đồng nghĩa người dùng đã hoàn tất lưu file trên ổ đĩa.

## UI và hiệu năng

Palette/theme dùng cùng design_system light lavender/indigo và dark navy. Tabs/chips wrap
trên màn hình nhỏ; form, palette và export dialog cuộn khi chữ lớn hoặc bàn phím thu hẹp viewport. Danh sách notes/tasks/export dùng
slivers; không dựng toàn bộ 20.000 task rows. Parser checklist cache theo content, dùng note
snapshot mới cho metadata/revision; chuyển tab khác chỉ purge cache, không parse lại nguồn.
Chọn nhãn dùng sheet có tìm kiếm và lazy rows, không dựng hàng nghìn chip trong form.
Home giữ scroll/filter và editor giữ ID/base/selection khi đổi theme/resize.

## Nghiệm thu

Xem [evidence và ảnh](../evidence/2026-10-10-productivity-workspace/INDEX.md). Gate cuối:
format99files0changes/analyze sạch, **234 Flutter + 109 backend PASS**, trong đó 19 kiểm thử
workspace mới. Kiểm tra real Sembast file/encryption/reopen, concurrent workspace/draft/vault
writes, storage failure/account switch, immutable imports, frozen checklist revision, denied
roles, rich codec, UI320px/200%, lazy 20.000 rows và labeled tap targets.

Chrome + backend loopback kiểm tra Ctrl+K, yêu thích, bộ sưu tập, mẫu/draft/server save, hai
nhật ký ID khác nhau, export download thật, import offline/reload/reconnect và exact server
roundtrip. HTTP owner/viewer/editor/stranger giữ ACL; locked projection đúng sáu fields.
Web release compile/static-only worker và APK debug compile PASS. Offline HTTP console errors
có chủ đích được tách khỏi lỗi UI. Native runtime/SAF interaction/IME, multi-device workspace
sync, screen reader thực tế/FPS mới, public release/provider thật không được đóng gate ở đây.
Source là base a5e5ec6 + working changes, chưa commit/push; CI cũ không nghiệm thu source này.
