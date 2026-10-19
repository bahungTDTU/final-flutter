# Nghiệm thu OS Android —19/10/2026

## Probe phục hồi core qua process death

`test_driver/os_relaunch_app.dart` là entrypoint QA riêng, không nối production navigation.
Mở AVD disposable và backend DB mới; không chạy trên app chứa tài khoản cá nhân. Đặt
API_URL trỏ HTTP backend QA local và QA_RUN_ID mới ở mỗi lần build; ID tối đa64 ký tự
ASCII chữ/số/dấu gạch. Probe từ chối URL ngoài loopback/emulator host.

Ví dụ sau khi xác minh SDK/adb/device thực:

```powershell
& $env:FLUTTER_BIN build apk --debug --target test_driver/os_relaunch_app.dart `
  --dart-define=API_URL=http://10.0.2.2:8062 --dart-define=QA_RUN_ID=oct19-os-a
& .venv/Scripts/python.exe scripts/qa_os_relaunch.py `
  --adb C:/Android/sdk/platform-tools/adb.exe --device emulator-5554 `
  --apk build/app/outputs/flutter-apk/app-debug.apk --run-id oct19-os-a `
  --output output/os-relaunch/oct19-os-a.json
```

Host cài QA APK bằng install -r, không clear/uninstall. Tuy vậy nó thay entrypoint của app
debug cùng package; chỉ dùng AVD QA. DB riêng `qa-os-<run>.db`, không mở DB app mặc định.
DeviceRecoveryKeys dùng native secure storage thật. Không in token/password/key; report
chỉ chứa assertion/metadata synthetic. Đầu ra phải là file mới; run cũ không được chấp nhận.

Pha1: đăng ký account disposable, sync baseline note, đóng baseline controller/DB; mở lại
offline qua socket bị từ chối65530, lưu rich Delta và invalid draft. Sau local writes đã
await, giữ controller/DB mở và ghi ready marker. Host so PID marker với pidof rồi dùng
`am force-stop`, xác minh không còn process; khởi chạy lại đúng APK đã cài, không rebuild.

Pha2: PID mới, mở encrypted store/session từ file, so note UUID/Delta, draft và fingerprint
toàn pending operation. Kiểm file Sembast không có plaintext synthetic content/token.
Reconnect API thật, so backend đúng một note/UUID/Delta và pending rỗng, invalid draft còn.

Scope: native storage/controller/process restart thật. Không chứng minh IME, thao tác UI
editor, Wi-Fi toggle, keystroke chưa kịp commit, physical device hoặc signed production
artifact. N02 được bổ sung bằng chứng core, không tự đóng toàn chặng C1.

## Checklist nghiệm thu thủ công còn lại

Mỗi case ghi source/artifact hash, OS/device, API, expected/actual, ảnh/log và PASS/FAIL.
Thao tác trên dữ liệu QA, không sửa timestamp/TTL hoặc dùng injection để thay OS.

| Gate | Thao tác thật | Expected |
|---|---|---|
| N01 IME | Telex/VNI gõ “Tiếng Việt”, sửa dấu khi composition, selection/paste, undo/redo, bold; mở keyboard và rotate/theme | Không mất/kép ký tự; selection/Delta/save/reopen đúng; không đổi editor UUID/base |
| N02 UI | Gõ offline, chờ local saved, force-stop và mở app offline, reconnect | Draft/format cùng UUID, đúng trạng thái pending, không duplicate; so backend |
| N03 quyền | A owner/B editor mở hai UI; B dirty, A downgrade/revoke/lock/delete từng case | B readonly/che theo quyền; local recovery giữ nội dung; original không overwritten; copy UUID mới cô lập |
| N04 TTL | Unlock note; chờ TTL thật; Home/background OS rồi resume, thao tác reader/AI/tệp | Relock đúng policy; không còn content/metadata trong visual/semantics/preview; server deny grant cũ |
| N05 picker | Protected note chọn TXT/upload/download, cancel picker, provider báo lỗi; avatar cancel/default | Cancel/error không đổi dữ liệu; đúng ACL; không giữ tên/preview sau lock |
| N05 labels | Gắn2labels, lọc AND, rename nhãn đang chọn, delete-confirm/cancel | Filter theo ID ổn định, không đổi note content/revision chỉ vì rename; cancel không mutate |
| N05 password | Đổi mật khẩu account qua UI; login thủ công mới; thử token/session cũ | Password mới dùng được; cũ thất bại; session/grant cũ401; draft account giữ an toàn |

Thực hiện các case tương ứng trên Web và Android theo phạm vi rubric. Full public release
critical flows cần chạy lại trên artifact cuối; local QA không thay provider/public acceptance.
