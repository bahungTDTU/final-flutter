# Chia sẻ ghi chú và thay đổi quyền — 02/10/2026

Phạm vi tiêu chí25 và phần chỉ báo18: owner quản lý người nhận, người nhận có mục Được chia sẻ,
thông tin chủ sở hữu/thời điểm/quyền. Realtime subscription của26 chưa triển khai; sync/poll15s
là kiểm tra định kỳ. Một Flutter project và backend local, chưa public deployment.

## Luồng sử dụng

Ghi chú của mình đã sync → menu Chia sẻ hoặc editor → Chia sẻ ghi chú. Nhập1–20 email mỗi lượt,
ngăn bởi dòng mới/dấu phẩy/chấm phẩy/khoảng trắng; chọn Chỉ xem hoặc Có thể chỉnh sửa. Email phải
đã đăng ký; trùng/self/không hợp lệ/chưa đăng ký khiến **toàn bộ batch không được cấp quyền**.
Tối đa100 người nhận/note. Không gửi email mời trong luồng này.

Danh sách owner hiển thị tên/email/shared_at/quyền. Dropdown đổi viewer/editor, Thu hồi quyền
có xác nhận. Đổi quyền giữ thời điểm chia sẻ ban đầu; thu hồi rồi cấp mới có thời điểm mới.
Nếu người nhận đã có, UI yêu cầu kiểm tra danh sách và dùng đổi quyền. Quản lý cần online;
không tự queue cấp quyền offline. Mất ack giữ nguyên operation trong RAM của cửa sổ để Thử lại.
Đóng/background/mất quyền bỏ retry RAM; mở lại kiểm tra catalogue server trước thao tác mới.

Thẻ owner có icon shared và số người nhận qua tooltip. Tab Được chia sẻ của recipient có
chủ sở hữu, thời điểm local, nhãn Chỉ xem/Có thể chỉnh sửa. Shared/pin/lock là các chỉ báo riêng;
note khóa chỉ hiển thị thông tin tối thiểu, không tên owner/email/time/title/content/labels/pin.
Protected reader của owner có Quản lý chia sẻ dùng grant online; actual protected-reader share
UI chưa nghiệm thu, API owner/grant/relock đã có tests.

## API và consistency

- GET `/notes/{id}/shares`: owner + grant nếu khóa; revision riêng và recipients.
- POST `/notes/{id}/shares/sync`: strict payload gồm op_id, base_revision và action.
  Add dùng recipients[{email,role}]; role dùng user_id/role; revoke dùng user_id.
- BEGIN IMMEDIATE: ACL/grant → journal fingerprint → CAS share revision → validate toàn batch
  → mutate → revoke grant recipient → tăng share revision → journal, trong cùng transaction.
- Stale CAS409 trả current catalogue; cần xem lại rồi tạo operation mới. OpID bị sửa payload409.
  Replay đã ack trả **catalogue hiện tại**, không reapply quyền đã bị thu hồi ở thao tác sau.
- List/mutation private,no-store; không có endpoint recipient đọc danh sách email người nhận khác.
  Note recipient chỉ có shared_by owner và shared_at của chính mình; owner chỉ shared_count.
- Share revision độc lập content revision; cấp/đổi/thu hồi không sửa note content/title/pin/labels.
  User IDs/role server xác định; payload note không đổi owner/ACL/protection.

Schema2 mở rộng additive `share_versions` và `share_operations`, giữ migration v1 và journals cũ.
Legacy POST `/shares` và DELETE `/shares/{user}` giữ tương thích spike, cũng tăng share revision
để CAS phát hiện writer cũ; **không có journal retry của API sync mới**. UI dùng endpoint sync mới.

ShareSession là ChangeNotifier theo route/account/token/epoch; late response không sang account
khác. Danh sách chỉ RAM, không vào account vault. Background/lock/session loss che danh sách và
cả email trong xác nhận thu hồi; UI disabled không thay ACL server. Refresh lỗi che catalogue;
poll15s không phải subscription và không bảo đảm thu hồi ngay ở máy mất mạng.

## Editor, cache và bản nháp khi mất quyền

Editor giữ base revision tại lần mở/last local save, không thay base do metadata/role refresh.
Incoming role cập nhật cả optimistic pending note nhưng giữ nội dung/base. Khi viewer/403/404
hoặc source shared note biến mất khỏi complete list, AppController chuyển **draft mới nhất**, nếu
không có thì upsert cuối, vào recovery trong encrypted account snapshot. Source draft/outbox/conflict
bị loại cùng snapshot; không archive cached server content khi không có thay đổi của người dùng.

Viewer nhận nội dung server chỉ đọc; revoked editor che cả controller và ngăn save trở lại source ID.
Recovery nằm theo account, reason viewer/permission/revoked; mở lại vẫn giữ. Phục hồi tạo UUID mới,
chưa tự gửi nếu draft chưa hợp lệ, không đổi ACL của source. Người đã nhận dữ liệu hợp lệ có thể
giữ bản sao; revoke không xóa được file đã export hoặc dữ liệu ở thiết bị chưa kết nối.

AttachmentSession đọc role hiện tại: role downgrade loại chọn/upload/delete và vô hiệu xác nhận
xóa đang mở; viewer vẫn xem/tải file được phép. Server luôn kiểm tra edit/grant cho mutations.

## Verification và giới hạn

97 Flutter/48 backend PASS, format/analyze sạch. Test mới: immutable lost-ack retry/replay,
CAS review, account-switch late response, file Sembast thật encrypted revoke/reopen, viewer draft
recovery, locked owner/time redaction, scale2 modal/confirmation, background poll blocked;
attachment open-confirm downgrade.
Direct API owner/editor/viewer/stranger, atomic batches, grant/relock, strict payload, restart,
stale/replay-after-revoke và timestamp/content revision. HTTP race doubles được ghi rõ trong tests.

Android API36 **debug emulator** `integration_test/sharing_test.dart` PASS: production UI batch2,
role dropdown, recipient owner/time/editor edit, peer API viewer/revoke, readonly/hidden editor,
encrypted platform-key/Sembast close/reopen qua socket65530 không lắng nghe, UI recovery UUID mới.
Không HTTP mocks; DB reopen trong test process, không OS force-kill hoặc physical-device claim.
Chrome local release390×844/DPR1 có actual UI/API checks; exact scenario/log/hash ở evidence index.
Web/APK release build PASS; release functional/signing/HTTPS/full screen reader/video chưa nghiệm thu.

```powershell
& scripts/check.ps1
& scripts/start_backend.ps1
& 'D:\Android\sdk\platform-tools\adb.exe' reverse tcp:8000 tcp:8000
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' test integration_test/sharing_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000
& scripts/build.ps1 -Target web
& scripts/build.ps1 -Target apk
```

Đọc README integration setup trước; `scripts/qa_sharing.py` chỉ dành disposable local fixtures,
password công khai để tái lập, không đưa tài khoản thật vào logs. Không push/deploy/commit/video.
Đợt kế tiếp: authorized realtime subscriptions; sau đó LLM/release/submission gates.
