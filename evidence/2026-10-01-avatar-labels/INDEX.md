# Avatar và nhãn server — evidence 01/10/2026

Windows11, Flutter3.47.1/Dart3.13.1, Python3.12, Android SDK36/JDK21,
Chrome154 local release, emulator-5554/API36. Commit: **chưa có** (unborn HEAD, no remote);
không push/deploy/quay/nộp. Chỉ disposable fixture accounts/data, không production credentials.
source-build-manifest.json ghi SHA256 source/build cuối với timestamp UTC lúc thu thập và commit=null;
không dùng manifest thay lịch sử Git/teamwork.

| Command / target | Kết quả thực | Evidence |
|---|---|---|
| powershell -ExecutionPolicy Bypass -File scripts/setup.ps1 | PASS dependency resolve/install; file_selector1.1.0/Pillow12.3.0 pinned | pubspec.lock, backend/requirements.txt; setup log tmp/avatar-labels (ignored) |
| powershell -ExecutionPolicy Bypass -File scripts/check.ps1 | PASS format/analyze, **81 Flutter / 29 backend**;1 Starlette deprecation warning | checks.txt |
| flutter test test/avatar_labels_test.dart --plain-name 'Uncreated conflicted label' trước guard | FAIL thật: remote lock không được nhận vì note POST422 dừng refresh; đã sửa và full check PASS | blocked-label-before-fix.txt |
| flutter test integration_test/avatar_labels_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000 | **PASS 1**, debug Android/native OS document picker/API/platform vault/Sembast reopen; final run03:15 | android-integration.txt, native-picker.json |
| scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8000 | PASS final release44.7s,41 resources, worker6acc3c3f573d01f6 | web-build.txt |
| scripts/build.ps1 -Target apk -ApiUrl http://127.0.0.1:8000 | PASS final release38.7s,52.7MB; debug signing/local HTTP chưa core release acceptance | apk-build.txt |
| Playwright CLI/Chrome390×844 + API8000 | PASS actual chooser/upload/cache offline + label CRUD/assign/filter/rename/offline reload/reconnect/peer/delete/default | web-avatar.yml, PNGs, web-baseline/reconnect/peer/final.json |
| Final worker update/reopen/hash/visible note/no deleted label checkbox | PASS final6acc worker activated; cached main.dart.js SHA256 matches local final build | web-final-release.json |

Flutter executable thật: C:/Users/LENOVO/flutter-sdk/bin/flutter.bat. Full check sau guard
bao gồm encrypted recovery/protection/preferences/frozen editor base revision regressions.
Backend7 tests mới (PNG/JPEG parameterization) là direct FastAPI TestClient/SQLite thật:
owner/viewer/editor/stranger/anonymous, CAS concurrent writers, immutable replay, migration0/1→2,
rename/delete không thay note revision/content, late note queue không resurrect nhãn,
avatar type/size/dimensions/metadata/private account/default/restart. Không claim internet/cloud.

## Android tái lập

Backend scripts/start_backend.ps1 phải chạy port8000. Emulator/device online; API_URL debug HTTP.
Fixture notetogether-avatar.png96×96/533bytes được tạo cho QA, có text metadata để backend loại;
không phải ảnh cá nhân. Dùng fixture đã kèm thư mục này:

```powershell
& 'D:\Android\sdk\platform-tools\adb.exe' -s emulator-5554 reverse tcp:8000 tcp:8000
& 'D:\Android\sdk\platform-tools\adb.exe' -s emulator-5554 push evidence/2026-10-01-avatar-labels/notetogether-avatar.png /sdcard/Download/notetogether-avatar.png
& 'D:\Android\sdk\platform-tools\adb.exe' -s emulator-5554 shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Download/notetogether-avatar.png
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' test integration_test/avatar_labels_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000
```

Khi log QA_NATIVE_PICKER_READY, DocumentsUI thật hiện ra. Chọn notetogether-avatar.png;
test không inject fake picker. Trong lượt này ADB uiautomator dump/pull đọc đúng item
content-desc/bounds[36,308][244,516], tap140/412 chọn fixture. Không hardcode tọa độ này
cho thiết bị khác; đọc UI mới hoặc chọn bằng tay. Không lưu tên file Download khác trong evidence.

Integration: UI avatar choose/upload; UI label create; controller assign note + offline port65530
rename/edit/draft; close/reopen Sembast/platform keys giữ queue op_id/avatar/draft; reconnect real
API rồi second session rename; UI delete-confirm/default avatar; note content/revision preserved.
Native create/delete/avatar là widget interaction trên emulator; offline rename/assign đi qua
controller. Native editor assign/filter interaction chưa rerun. DB reopen cùng process, không OS kill.

Build ban đầu failed Kotlin incremental do different roots Pub cache C: và project D:.
android/gradle.properties kotlin.incremental=false giải quyết; debug/release build sau sửa PASS.
android-build-before-fix.txt giữ lỗi thật; không sửa GeneratedPluginRegistrant.java bằng tay.

## Chrome luồng đã chạy

Session Playwright CLI avatar-labels, headed Chrome, localhost7357/8000, disposable account
web-avatar-20261001-1404@example.test. Thao tác UI register/autologin → profile → actual
file chooser → upload PNG; message Server đã lưu ảnh đại diện. API second login xác nhận
avatar revision1, canonical96×96/PNG không metadata, private/no-store, anonymous401.
Main SMTP chưa cấu hình nên banner unverified vẫn hiển thị đúng; không gửi email ngoài.

UI tạo Học tập Web → editor title/content auto-save → checkbox gắn nhãn. Offline thật qua
page.context().setOffline(true), reload từ app shell: note/name/cache avatar còn. Home chọn
filter → manager rename Nhãn offline Web; checkbox vẫn checked, pending1. Reload offline
lần nữa giữ name/operation queue (filter selection là route state, không claim persisted qua reload).
Online trở lại → Thử lại → API catalogue revision2/name mới và note revision2 unchanged.
Second API session rename Nhãn từ phiên khác revision3 → Chrome15s sync nhận name.
UI xóa-confirm → tombstone revision4; note count1/ID/title/content/revision2 giữ nguyên.
UI Dùng ảnh mặc định → avatar revision2/data NULL, download404. Tất cả API assertions PASS.

Verifier ghi timestamp UTC thật ở web-*.json và không lưu/print bearer tokens:

```powershell
.\.venv\Scripts\python.exe evidence/2026-10-01-avatar-labels/verify_web_avatar_labels.py baseline
.\.venv\Scripts\python.exe evidence/2026-10-01-avatar-labels/verify_web_avatar_labels.py reconnect
.\.venv\Scripts\python.exe evidence/2026-10-01-avatar-labels/verify_web_avatar_labels.py peer
.\.venv\Scripts\python.exe evidence/2026-10-01-avatar-labels/verify_web_avatar_labels.py final
```

Chạy từng stage đúng sau thao tác UI tương ứng; peer stage **mutates label của QA account**.
Đây là verifier của fixture ghi nhận, không tự chạy browser. Để rerun từ đầu dùng disposable
account mới, thay EMAIL/login fixture trong script; reset baseline evidence riêng. Account hiện
đã ở final nên baseline/reconnect không thể rerun độc lập mà vẫn giữ nguyên trạng thái.

Full UI flow ban đầu trên release779a6b7ba101ae25. Sau regression label-dependency guard,
full81/29 + native integration chạy lại; final Web6acc3c3f573d01f6 có worker update/reopen smoke.
Rời origin about:blank rồi mở lại cho waiting worker activate; confirmed chỉ final cache còn,
main.dart.js SHA256cbd0e127cd4aeaf43cb549fcf6a6b72ad2b3ff84543032144506971af04ee41f
khớp artifact. Không claim đã replay full Chrome CRUD flow lần nữa sau guard nhỏ.

Ảnh visual đã xem: web-avatar-dialog.png, web-offline-avatar.png,
web-offline-selected-filter.png, web-note-after-delete.png. Chọn ảnh/upload native thật và
Web fixture path đều là fixture PNG cùng tên. Chrome tool resize ban đầu đổi DPR1.5→1 trong
khi Flutter canvas cũ585×1266 còn; reload viewport cố định đưa flutter-view về390×844/DPR1.
Không dùng screenshot lệch cũ làm evidence visual PASS. Semantic overlay đôi khi chặn pointer
checks: force click đúng observed avatar control; Escape đóng sheet; assert UI sau thao tác.
Offline network console failures là chủ đích; không suy ra full screen-reader/keyboard pass.

## Giới hạn

Avatar upload/remove online-only, cache avatar đã tải; không media upload outbox/camera/crop/cloud.
Cancel/permission-denial/scale2 có widget doubles, chưa OS denial/cancel hay native physical QA.
Label conflict/duplicate/dependency+remote lock bao phủ controller/API tests, chưa full conflict
UI hai thiết bị. Poll/retry15s chưa realtime/backoff; operation/tombstone GC chưa có.
OS force-kill/physical/TalkBack/NVDA/quota/clean clone/public HTTPS/signing/video chưa chạy.
SMTP internet/mail outbox, private note attachments, shares/realtime/LLM còn ở STATUS/matrix.
Builds không thay full32 rubric/public deployment. Xem docs/AVATAR_AND_LABELS.md.
