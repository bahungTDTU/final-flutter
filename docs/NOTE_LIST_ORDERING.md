# Thứ tự ghi chú và privacy của ghi chú khóa

Sửa tiêu chí17 ngày10/10/2026, base `a5e5ec6` + working changes. Audit trước sửa và probe FAIL
được giữ ở FINAL_PROJECT_AUDIT_2026-10-10.md/evidence2026-10-10-rubric-audit. Bằng chứng sau
sửa nằm riêng tại [INDEX](../evidence/2026-10-10-ordering-and-docs/INDEX.md).

## Quy tắc

| Trường hợp | Thứ tự hiển thị |
|---|---|
| Đã ghim | Đứng trước; pinned_at giảm dần, ID tăng dần nếu bằng nhau |
| Chưa ghim, server đã chấp nhận | updated_at giảm dần, ID tăng dần nếu bằng nhau |
| Ordinary note có operation pending | Tạm lên đầu phần chưa ghim; ACK + listing mới khôi phục thứ tự server |
| Filter/search/shared | Là tập con của cùng thứ tự; không tự đẩy note khóa xuống cuối |
| Protected draft chưa được server chấp nhận | Giữ vị trí listing gần nhất; nội dung chỉ trong password vault |

Backend `list_visible_notes` sắp array bằng SQL trước khi bỏ private fields. Locked listing
vẫn chính xác sáu trường `id, locked, revision, role, pinned_at, shared`; không trả updated_at,
title/content/labels/date/share identities/time/count. Array thể hiện thứ tự tương đối theo
ngày cập nhật, không cung cấp timestamp bí mật. Unlock grant không mở rộng list row.

`NoteListingCache` nhóm ghim theo public timestamp. Nếu source có unpinned locked row,
phần chưa ghim dùng vị trí array đã được server sắp; khi không có ngày bị ẩn, comparator ngày
cũ vẫn dùng cho ordinary notes. Thay thứ tự source cũng vô hiệu cache; filter không giữ một
text index riêng của nội dung bị khóa.

## Local edits, persistence và migration

Ordinary save/new note và conflict recovery copy đặt optimistic row trước source array;
operations/base revision/fingerprint không đổi. Refresh đang in-flight giữ pending edit
mới ở đầu và merge role từ server. Sau ACK, server array thay optimistic order. Lock/access
loss thay row tại vị trí hiện có trước refresh, không append row đã biết xuống cuối.

`account:<UUID>` lưu array trong encrypted snapshot hiện có; reopen/offline/account switch
không cần sort field/schema migration. Protected content/draft/operation vẫn trong vault riêng;
listing chỉ có public fields. Phần session/preferences/grant không thay giao thức.

Cache tạo bởi phiên bản cũ chưa giữ canonical order phải refresh thành công một lần để sửa
thứ tự các note khóa. Khi offline, không thể tái tạo ngày đã bị xóa khỏi projection; app giữ
thứ tự cache gần nhất thay vì đoán ngày hoặc lấy private metadata từ legacy rows.

## Kiểm chứng

- `test/note_ordering_test.dart`: mixed locked/ordinary/shared/filter/pins; order-only cache
  invalidation; AES-GCM Sembast file reopen/account switch/immutable pending; late edit khi
  listing in-flight; ACK; vị trí card thực trong widget grid và list.
- `backend/tests/test_note_listing.py`: reverse-insertion fixtures, ngày bằng nhau/ID,
  owner/viewer/editor/stranger, grant không lộ date và protected editor update đổi thứ tự.
- Probe gây FAIL trong audit được chạy lại trên bản sửa; log PASS mới lưu riêng.
- Direct HTTP và Chrome local kiểm tra source mới; phạm vi/commands/results trong INDEX.

Đây là sửa thứ tự và đồng bộ tài liệu; không thay kết luận về provider thật, native editor
runtime/FPS, public release, video hoặc teamwork trong audit lịch sử.
