# Attachments15/16 — evidence local 01/10/2026

Windows11, workspace `D:\flutter cuoi ki`; Flutter3.47.1/Dart3.13.1, Python3.12.14,
Android SDK36/JDK21; Chrome154 viewport390×844/DPR≈1, emulator API36 `emulator-5554`.
Commit: **chưa có** (local master unborn), không remote/push/deploy/video/timestamp nộp.
Các mốc UTC trong JSON/txt là thời gian thu thập thật; log test duration gồm chờ OS picker/Save,
không dùng làm latency benchmark. Đây là QA fixture local @example.test, không dữ liệu user thật.

## Commands / target / result

| Command / target | Actual result / evidence |
|---|---|
| `scripts/setup.ps1` Windows | Dependencies resolve; pinned video_player2.14.0/web1.1.1; backend runtime requirements giữ nguyên |
| `.venv/Scripts/python.exe -m pytest backend/tests/test_attachments.py -q` |11 PASS SQLite/TestClient direct ACL/grant/validation/Range/lock-race/restart; backend-tests.txt |
| `scripts/check.ps1` host | Format/analyze PASS;88 Flutter/40 backend PASS,1 StarletteDeprecationWarning; checks.txt |
| `flutter analyze` final | PASS sau native integration peer-delete/lock-confirm assertion; final-analyze.txt |
| `dart format --output=none --set-exit-if-changed lib test integration_test test_driver` final |44 files,0 changes; final-format.txt |
| `scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8000` | PASS,41 resources/worker300d8deb084e2b7e; web-build.txt; Web hash360d7709…669f85 |
| `scripts/build.ps1 -Target apk -ApiUrl http://127.0.0.1:8000` | PASS54.0MB; apk-build.txt; local URL/debug signing, không release feature acceptance |
| `flutter test integration_test/attachments_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000` |1 actual native final PASS,04:49 gồm chờ picker/Save; android-integration.txt; peer-only run07:43 ở android-integration-peer-pass.txt; first run02:35 ở android-integration-first-pass.txt |
| `npx --yes --package @playwright/cli playwright-cli -s=attachments …` | Actual Chrome local release UI flow dưới đây; không Web integration driver/physical/release Android claim |

Flutter executable `C:\Users\LENOVO\flutter-sdk\bin\flutter.bat`, Dart cùng bin;
Python `.venv\Scripts\python.exe`, ADB `D:\Android\sdk\platform-tools\adb.exe`,
Node/npx `C:\Program Files\nodejs\npx.ps1`. Scripts discover SDK như toolchain.ps1.
Backend start bằng `scripts/start_backend.ps1` port8000, Web `scripts/start_web.ps1` port7357.
Tham số/lệnh fixture server/native picker đầy đủ: [PRIVATE_ATTACHMENTS](../../docs/PRIVATE_ATTACHMENTS.md).

## API/unit/widget scope

Backend11 mới: owner/viewer/editor/stranger/anonymous; owner lock không bypass, grant của
session khác không dùng lại; revoked upload retry404; private Range206/suffix/416/no-store/
Content-Disposition; retry cùng ID/current row, payload changed409, deleted ID409, restart
SQLite, note deletion BLOBNULL; invalid SVG/PNG/MP4/PDF/NUL/path/20MiB+1 atomic; JPEG→PNG
≤2048px/no metadata/count10; thread gate lock trong normalize trả423/no BLOB trước commit.
Quota100MiB có code transaction; không claim test aggregate100MiB riêng hoặc mọi codec/file.

Flutter7 mới: late account response rejected/no persistent cache, same upload ID/payload retry
không note revision/outbox, revoke/lifecycle epoch hide, selected list giữ khi cancel/denied,
scale2 mobile no overflow, viewer không mutation, remote-lock names hide, peer-deleted image
preview hide và remote-lock open delete-confirm che tên/disable Xóa tệp. HTTP/picker/lifecycle
races dùng doubles; không gọi đó OS denial hay two-device QA.
Suites cũ crypto/recovery/frozen editor/preferences/labels chạy cùng check PASS.

## Chrome actual flow và nguồn build

Đăng nhập disposable QA account đã có từ avatar increment, note `3df559e7-7e58-488c-873c-900c892e31cf`,
content fixture/revision2. Từ editor Đính kèm → Chọn tệp → actual browser chooser → chọn PNG,
MP4,TXT → Tải tệp lên →3 files server thật. PNG canonical672 bytes, video9361, TXT42 bytes.
Ảnh preview: web-image.png. Video Phát→DOM video duration2/currentTime2/320×180, source Blob,
web-video.png (ảnh chụp khi đang phát); không dùng network token URL/public CDN.

Download thực bằng click TXT Tải xuống, Playwright download event → saveAs
`output/playwright/attachment-web.txt`; suggested filename attachment-fixture.txt, download.error=null.
Copy browser-saved.txt có SHA-256 khớp fixture, **không suy ra chỉ click là đã ghi disk**.
UI Xóa→Xóa tệp; second-session verifier xác nhận2 files, TXT404/BLOBNULL, content/revision2 giữ.
API second login bật protection password fixture: list/direct423 cả owner, preview che tên/ảnh
(web-remote-lock.png); restore protection revision4/list200. 423 console này là test intentional.

Commands assertions (ghi stage theo thứ tự, fixture đã bị thay đổi sau QA):

```powershell
& '.\.venv\Scripts\python.exe' evidence/2026-10-01-attachments/verify_web_attachments.py baseline
# UI TXT download và delete-confirm
& '.\.venv\Scripts\python.exe' evidence/2026-10-01-attachments/verify_web_attachments.py deleted
# Mở image preview trước thao tác peer lock
& '.\.venv\Scripts\python.exe' evidence/2026-10-01-attachments/verify_web_attachments.py lock
# Quan sát preview che rồi khôi phục fixture
& '.\.venv\Scripts\python.exe' evidence/2026-10-01-attachments/verify_web_attachments.py restore
# Build sau peer-delete guard/hash → mở image preview → peer delete
& '.\.venv\Scripts\python.exe' evidence/2026-10-01-attachments/verify_web_attachments.py peer-delete
# Final confirmation guard build/hash → mở xóa-confirm MP4, chưa chấp nhận
& '.\.venv\Scripts\python.exe' evidence/2026-10-01-attachments/verify_web_attachments.py confirm-lock
# Observe tên che/Xóa tệp disabled, rồi khôi phục fixture
& '.\.venv\Scripts\python.exe' evidence/2026-10-01-attachments/verify_web_attachments.py confirm-restore
```

web-baseline/deleted/lock/restore/peer-delete.json có UTC/actual assertions; không token persist/print.
Verifier gắn disposable account/local DB hiện tại, không là setup script cho clone sạch.

Luồng chooser/video/download/delete/lock ban đầu chạy worker806fe4ad809a4a28. Khi kiểm tra phát
hiện preview cần list membership để che tệp bị peer xóa; sửa guard + widget/native assertions,
check toàn bộ PASS rồi rebuild5142a450f41323ac. Cache update ban đầu vẫn trả JS cũ4c43aa8c…;
không nhận là final pass. Gỡ **chỉ registration/cache static QA**, giữ IndexedDB/session/draft,
about:blank→localhost rồi đối chiếu main.dart.js SHA-256576fa753…b18c5b2/cache5142a450f41323ac
trong web-peer-source.txt (bản giữ lại của web-final-source.txt lúc đó), bằng hash artifact build.
manifest-peer-pass.json là snapshot trước hardening confirmation,87 tests ở thời điểm đó.
Enable accessibility placeholder ngoài
viewport làm pointer timeout; dùng focus+Enter bật semantics, không lỗi auth/backend.

Final-source image đang hiện: web-final-image.png. API peer-delete tại16:09:03UTC → image404/
BLOBNULL/note content+revision4 giữ/1 video còn. Poll thật: web-peer-preview.txt tại16:09:36UTC
assert closedPreview=true/filenameAbsent=true; web-peer-delete.png đã visual inspect. Không
claim độ trễ realtime từ khoảng operator này; interval15s + request. Phần này đo bản5142….

Sau đó phát hiện delete-confirm cần che tên khi remote lock; thêm session AnimatedBuilder/
disable confirm, widget regression thứ7, rerun scripts/check88/40 và actual native/Web.
Final worker300d8deb084e2b7e/hash360d7709…669f85 khớp artifact trong web-final-source.txt.
Mở Xóa MP4-confirm trước peer lock revision5/list+direct423; web-confirm-preview.txt tại16:28:21UTC
deleteDisabled=true/filenameAbsent=true, screenshot web-confirm-lock.png đã visual inspect.
Restore fixture revision6/content giữ/list200; không xóa video. web-confirm-lock/confirm-restore.json.

## Android actual flow

AVD taskflow_api36/API36 dùng ANDROID_AVD_HOME=`D:\Android\avd`, ANDROID_USER_HOME=`D:\Android\user`,
headless/SwiftShader; không xóa data. ADB reverse8000/8013, push PNG vào Downloads. Bộ chọn
file_selector DocumentsUI thật: đọc uiautomator dump rồi tap **bounds tên PNG vừa quan sát**,
không tọa độ đoán. Lần cuối android-picker.xml có tên PNG bounds[111,1118][325,1147].
Upload/preview image qua actual UI + API; DELETE API trong khi preview đang mở, log
QA_PEER_DELETE_HIDDEN và assertion không Image/Nội dung đã được che. Peer login/API upload
MP4/TXT fixture lấy từ QA server8013; UI refresh/video Phát, actual native position>0,
QA_VIDEO_PLAYED. Không claim MP4/TXT được chọn từ OS picker Android (PNG mới actual picker).

TXT Tải xuống→ACTION_CREATE_DOCUMENT, android-save.xml filename field+SAVE bounds
[567,1172][699,1244] → tap Save; duplicate provider đặt `attachment-fixture (2).txt` trong
/sdcard/Download. Chờ test PASS/success **sau write**, ADB pull42 bytes native-saved-final.txt
hash BC410BEF2D999CCF8558CE65331D8852F6E85E09BF1C8631BCBBE87D95ACB165 khớp fixture.
UI delete TXT-confirm → chỉ video còn; note original content/revision1 giữ.
Tiếp theo final native mở Xóa MP4-confirm, peer protection lock: QA_LOCK_CONFIRM_HIDDEN,
tên không còn, FilledButton disabled; Hủy/tắt khóa giữ content/revision3 (hai protection mutations).
Native first save native-saved.txt cũng khớp; lần pull đầu khi chưa write xong0 bytes không nhận PASS và được
pull lại sau success. Không đưa zero-byte bản trung gian vào evidence chốt.

## Những lỗi đã gặp và xử lý

- Pytest default param ID chứa20MiB bytes làm PYTEST_CURRENT_TEST vượt Windows env32767,
 9 PASS/2 setup-teardown errors; không phải upload acceptance. Thêm explicit short param IDs,
 11 và full40 PASS. backend-initial-trimmed.txt lưu đúng ValueError, mỗi dòng param dài cắt300
 ký tự; file83MB gốc được bỏ để không phình repo, không gọi log đã cắt là nguyên bản.
- Initial restricted pytest cache warnings; full check approved SDK/runtime access còn1
 Starlette deprecation. Không đổi requirements sang dependency chưa kiểm chứng để im warning.
- MP4 base64 dart-define (kể cả file defines) vượt Gradle command length Windows, build chưa
 load test; android-define-before-fix.txt. Chuyển fixture nhỏ sang QA-only HTTP8013; test thật PASS.
- Preview peer-delete guard được thêm sau code review; không claim đã đo test fail trước sửa.
- Static worker cũ/semantics placeholder đã xử lý như trên, không suy ra full browser keyboard.
- QA restore verifier lần cuối đọc content trực tiếp từ protection response metadata làm
 KeyError sau mutation; web-confirm-restore-before-fix.txt. Sửa GET note để assert content và
 retry kiểm tra state đã unlock, không mutate hai lần; final confirm-restore PASS revision6.

## Fixture, hash và tái lập

PNG320×180teal606 bytes, MP4 H26415fps/2s/faststart9361 bytes, TXT42 bytes đã kèm. Các file
không ảnh/video của user. imageio-ffmpeg0.6.0 chỉ cài trong local venv tạo QA video, không runtime
requirements backend/production app. Có thể tạo fixture mới trong tmp (không ghi đè evidence):

```powershell
& '.\.venv\Scripts\python.exe' -m pip install -r evidence/2026-10-01-attachments/qa-requirements.txt
& '.\.venv\Scripts\python.exe' evidence/2026-10-01-attachments/generate_fixtures.py
& '.\.venv\Scripts\python.exe' evidence/2026-10-01-attachments/capture_manifest.py
```

FFmpeg builds có thể khác; fixture kèm/hash manifest là dữ liệu đã QA thật. Generator command
đã chạy vào tmp, tạo PNG606/MP49361/TXT42 bytes và text hash khớp. capture_manifest.py ghi thời
gian thu thập thật, SHA-256 source/docs/evidence/Web/APK và assert Web hash/README parity/
download native-Web byte equality; không rerun tests hoặc tạo commit. Xem manifest.json.

## Chưa chạy / giới hạn

Protected-reader attachment actual UI, OS denied/cancel/multi-file picker Android, mọi PDF/ZIP/
CSV/MP4 provider+codec, full accessibility/landscape, physical device/Wi-Fi toggle/force-kill,
native release functional/install đợt này, durable media outbox/resume/progress, antivirus/cloud
storage/account abuse protection/backups, public HTTPS/production signing/clean clone/video.
Server BLOB plaintext theo quyền file; Web session store chưa production hardening. Không
claim đầy đủ15/16/32/10 điểm hoặc ready-to-submit từ local API/build/widget/automation PASS.
