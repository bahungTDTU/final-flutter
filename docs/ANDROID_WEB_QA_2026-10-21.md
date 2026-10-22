# Kiểm thử Android emulator và Web — 21/10/2026

Đã fetch/pull nhánh hiện tại trước khi chạy; vẫn là `ad21cf8` trên
`codex/full-function-audit`. Các thay đổi mới chỉ là integration test và sửa harness;
không thay source production, API hoặc dependency. Không commit/push/merge lượt này.

## Kết quả

| Target | Kết quả và phạm vi |
|---|---|
| Android emulator | **5 workflow PASS**: note CRUD/autosave/offline/reopen/preferences; sharing/role/draft; realtime/reconnect/frozen409/viewer/revoke; protected editing/vault/revalidation/delete; owner peer-delete/recovery/newUUID/encrypted reopen |
| Android main | Debug APK `lib/main.dart` cài/chạy thật, mở được màn sign-in sau cài mới |
| Web | Browser IAB PC1280×900 và phone375×812: login/search1of2, rich bold autosave, invalid draft→peer delete→recovery/newUUID, exact Delta ACK, dark mode/resize/reload, console0errors |
| Static/build | Analyze sạch, format2 test files0changes; Web release/offline40staticassets và main APK debug build PASS |

Android16/API36 x86_64, AVD `taskflow_api36`, device `emulator-5580`, ảnh720×1280.
Chạy `-read-only -no-snapshot -no-snapshot-save` để dùng userdata copy-on-write tạm;
không ghi thay dữ liệu AVD gốc. Dùng debug software rendering/Impeller disabled.
Backend loopback8072 với SQLite mới, Web7386. Không gọi SMTP hoặc Gemini Internet.

## Vấn đề phát hiện trong bài test

Lần đầu4 workflow đạt nhưng realtime FAIL: khi reconnect, scroll offset của vùng
viết còn giữ, nút “Chỉnh sửa phiên bản mới” bị cắt dưới app bar. Cú tap của harness
không hit, nên assertion `readOnly == false` thất bại. Đã giữ log FAIL gốc.

Sửa integration_test/realtime_test.dart dùng Scrollable.ensureVisible alignment0.5,
đợi layout và kiểm hitTestable trước cả hai lần tap. Không bỏ assertion, không đổi
hành vi editor/quyền/frozen revision. Lượt chạy lại toàn bundle đạt cả5 workflow.
Flutter in +6 cuối do tính thêm tearDownAll; báo cáo không gọi đây là6 chức năng.

Bổ sung integration_test/owner_delete_recovery_test.dart: input title trống qua
TextInputClient→draft bền→phiên owner thứ2 xóa source→recovery UI→UUID mới→server404
cho source/đúng content copy→đóng/mở native encrypted Sembast và kiểm lại. Có ảnh
native thật; không dùng ảnh Web phone viewport làm bằng chứng Android.

## Phạm vi bằng chứng

Integration nhập bằng TextInputClient injection, không Telex/VNI/IME thật. Đóng/mở DB
trong cùng process không thay OS force-stop/relaunch. Peer mutation qua HTTP/controller,
không phải hai giao diện độc lập. Main startup chỉ kiểm cài mới/mở màn login; Flutter
drive mặc định uninstall app cuối run nên không kiểm persistence xuyên qua lần cài mới.

Web xác nhận qua HTTP rich Delta trước/sau recovery khớp chính xác, UUID mới khác source,
source404, note khác revision1 không đổi. Dark preference được ACK và reload giữ dữ liệu.
Native protected/vault/SSE dùng backend thật; không dùng unit/widget pass thay runtime.

Chưa chạy IME thật, OS picker/camera/TTL, native OS lifecycle acceptance mới, profile
FPS/GPU, Internet providers hoặc signed release. Debug/software emulator có missed-frame
warnings; không dùng để kết luận tốc độ trên máy thật. Backend/unit suite329/152 là
snapshot audit trước, không nhận là chạy lại trong lượt native/Web này.

[Bằng chứng, lệnh, hash và ảnh](../evidence/2026-10-21-android-web/INDEX.md).
