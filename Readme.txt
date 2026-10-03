# NoteTogether - nền tảng triển khai local

Nhóm: 523K0006 Nguyễn Bá Hùng; 523K0014 Nguyễn Bảo Long. Deadline trước tháng 12/2026,
chưa có ngày/giờ cụ thể. Repository: https://github.com/bahungTDTU/final-flutter; cloud chờ nhóm bổ sung. Đây là source do agent hỗ trợ;
Initial import dùng danh tính Git của người dùng theo yêu cầu; không thay bằng chứng teamwork4 tuần.
Đọc STATUS.md trước claim hoàn thành.

## Công nghệ và hiện trạng

Flutter 3.47.1, Dart 3.13.1; Android SDK 36/JDK 21, Python 3.12.
Một Flutter project Web + Android, ChangeNotifier, HTTP, Sembast/IndexedDB/application-support,
FastAPI/SQLite/Argon2id. Versions chính xác: pubspec.lock + backend/requirements.txt.
Architecture/ACL/offline ở docs; ADR so sánh Firebase/custom.
Email có SMTP/TLS transport + code UI, disabled khi chưa config. Main không giữ mailbox memory;
internet inbox chưa xác minh. Private attachments và SSE realtime đã có local QA; AI chưa triển khai.
Local DB schema version2, migration0/1→2 giữ note revisions/content và operation v1.
Avatar PNG/JPEG lưu private trong SQLite; catalogue nhãn server dùng ID/revision/tombstone.
Attachment ảnh/video/file dùng private note API và BLOB SQLite, chỉ online; xem docs/PRIVATE_ATTACHMENTS.md.

## Setup trên Windows

Flutter SDK cần có trên PATH hoặc đặt FLUTTER_BIN (đường dẫn flutter.bat).
Python 3.12 cần sẵn; trên máy hiện tại setup script dùng bundled runtime Codex.
Máy khác truyền -Python đường dẫn Python thật, không dùng WindowsApps stub.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
# Máy khác:
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1 -Python C:\Python312\python.exe
powershell -ExecutionPolicy Bypass -File scripts/check.ps1
```

Chạy backend và Web ở hai terminal:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/start_backend.ps1
powershell -ExecutionPolicy Bypass -File scripts/start_web.ps1
```

Backend http://127.0.0.1:8000, /health, /docs. Web port 7357; start_web phục vụ release local,
tự build nếu chưa có worker. Sau sửa source chạy scripts/build.ps1 -Target web rồi reload.
Backend đọc NOTETOGETHER_DB và WEB_ORIGINS từ process environment. .env.example là template;
code không tự load .env. CORS cần origin chính xác. API_URL chỉ là public URL, không secret.
Tạo tài khoản test email/display name/password≥10 ký tự hai lần, tự login và giữ banner unverified.
Không có grading account/public credentials preloaded; production email/AI không được giả success.

## Exact commands đã có

Trên máy này Flutter không nằm trên PATH, dùng executable đầy đủ:

```powershell
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' analyze
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' test
& '.\.venv\Scripts\python.exe' -m pytest backend/tests -q
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' build web --release --no-web-resources-cdn
& '.\.venv\Scripts\python.exe' scripts\prepare_web_offline.py
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' build apk --release
```

Scripts tương đương và hỗ trợ cấu hình backend:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8000
powershell -ExecutionPolicy Bypass -File scripts/build.ps1 -Target apk -ApiUrl https://BACKEND_HOST_TO_CONFIGURE
```

Build output local: build/web và build/app/outputs/flutter-apk/app-release.apk.
Không gọi APK spike là final artifact: release scaffold hiện debug-signed, cần keystore production.
Release Android chỉ HTTPS; HTTP local dành debug. Web public URL/backend hosting chưa có.

Integration native cần backend running, emulator/device online, adb reverse và debug cleartext manifest:

```powershell
& 'D:\Android\sdk\platform-tools\adb.exe' reverse tcp:8000 tcp:8000
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' test integration_test\note_flow_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000
```

Kết quả lệnh này phải xem STATUS/evidence; không coi chỉ có source test là pass.
Web integration automated driver chưa chạy; browser manual automation evidence ghi riêng.

## Offline và limitations

Draft lưu transaction ngay khi input; valid notes debounce 650ms; outbox UUID/payload immutable,
revision conflict bảo toàn bản local và cho chọn remote/copy. Retry interval 15s, chưa backoff.
Account namespace + generation guard; account snapshots mã hóa AES-GCM bằng khóa device riêng,
session/profile vẫn plaintext, cần hardening. Khóa remote giữ local edit trong encrypted recovery,
Phục hồi tạo draft UUID mới rồi auto-save khi hợp lệ, không mở source. Xem docs/ENCRYPTED_RECOVERY.md.
Web key store experimental; không chống XSS/browser-profile reader. Key loss/clear storage có thể mất
recovery; chưa backup/export key/offline note unlock. Labels catalogue server với durable queue riêng;
Preferences có durable field-patch outbox/idempotency và đồng bộ theo tài khoản; xem docs/PREFERENCES_SYNC.md.
Sync ghi snapshot thành công trước gửi; session write/logout dùng cùng hàng đợi. Conflict copy giữ
draft mới nhất và lưu bản thay thế trong cùng transaction. Regression durability ở
test/sync_durability_test.dart và evidence/2026-10-01-durability; lock recovery ở evidence/2026-10-01-encrypted-recovery.
Web dùng custom static-only service worker và local CanvasKit qua scripts/build.ps1; API/private data không cache.
Cold first-load offline chưa hỗ trợ; cập nhật worker/quota/eviction cần regression riêng.
Known blockers: internet SMTP receipt/outbox, attachment offline queue/full OS/release QA, protected editing/offline unlock, protected-reader share/file/realtime UI acceptance, LLM, HTTPS hosting,
production signing, release regression, clone sạch, deadline lịch teamwork, video và Rubric.xlsx gốc.

## Deployment và nộp

backend/Dockerfile chuẩn bị một service với SQLite persistent disk cần mount/backup. Chưa build/run Docker
image và chưa public deploy. Không hứa free tier. WEB_ORIGINS/API_URL phải dùng HTTPS origin thật.
SMTP variables đã được code đọc; LLM placeholders chưa đọc. Không dán secrets vào chat hoặc commit.
source nộp phải clone GitHub và giữ .git; local git init không chứng minh teamwork.
Read docs/SUBMISSION_CHECKLIST.md; chưa tạo ZIP nộp vì thiếu repo/video/Rubric/URL/release-final.
Readme.txt được giữ cùng nội dung cốt lõi với README.md. Tài khoản chấm chỉ đưa riêng trong bộ nộp.

## Bảo trì và hiệu năng03/10/2026

GET /notes đọc theo lô giữ server ACL/locked minimal metadata; client merge dùng ID indexes,
background polling dừng khi app ở nền. HTTP error không phải JSON vẫn giữ mã lỗi, timeout
abort underlying request; encrypted draft/outbox và frozen editor base giữ regression PASS.
123 Flutter/56 backend, direct actual HTTP ACL và Android debug API36 Skia software PASS;
Chrome local release có offline/reload/reconnect + note ID/count/content assertions thật.
Web40 static resources/APK55.8MB build PASS; chưa physical/release-functional/FPS/HTTPS.

Benchmark local1.000 notes,7 measured requests: owner/viewer SELECT5.803/7.753→4,
median64/76ms→52/59ms. Không áp dụng như cam kết production hoặc UI FPS.
Đã dọn309 generated files cũ/trùng, bỏ dependency cupertino_icons/illustration không dùng;
evidence lịch sử và dữ liệu local được giữ. Legacy teal contrast script đã archive, current
theme contrast được kiểm tra trong prism_motion_test.dart. Details/commands:
docs/PERFORMANCE_AND_MAINTENANCE.md và evidence/2026-10-03-maintenance/INDEX.md.

## UI/UX mới

Giao diện hiện tại dùng sáu tông tím/xanh/cyan/hồng/amber/mint, viền chuyển sắc mảnh,
ánh sáng lăng kính và hero tinh thể vẽ bằng code. Nền đọc kín, màu nhấn có tiết chế;
hover180ms/theme300ms/reveal420ms, hỗ trợ giảm chuyển động của hệ thống.
Không blur nặng hoặc animation nền lặp; chưa benchmark FPS trên thiết bị vật lý.
Theme sáng/tối dùng Noto Sans bundled (OFL ở assets/fonts), tokens/component chung
trong design_system.dart và PrismPalette extension trong prism.dart.
Home đổi sidebar/rail/bottom navigation theo logical width; lưới/danh sách có selected state,
ghim thành nhóm, search clear/AND filters và thẻ khóa neutral. Editor giữ ID/revision/draft,
vùng viết thoáng và status local/server khác nhau; settings có preview cỡ chữ.
Password dialog có validation/loading và error giữ input. Chức năng chưa có dịch vụ thật chỉ
có spec/component fixtures; Hỏi ghi chú trong app báo chưa khả dụng, không trả AI giả.

Chạy/xem bằng scripts/start_backend.ps1 và scripts/start_web.ps1 như trên; build lại Web sau
sửa code. docs/UI_UX_DESIGN.md là spec/component map, docs/UI_UX_QA.md là phạm vi kiểm chứng,
evidence/2026-10-02-prism-ui/INDEX.md chứa ảnh, commands, hashes và phạm vi đợt prism02/10:
118 Flutter/53 backend PASS, Chrome local release và Android debug Skia software PASS,
Web/APK release build PASS. Các đợt UI trước giữ evidence riêng. scripts/check.ps1 chạy preview harness,
responsive/scaled layouts và invariant tests. lib/ui/previews.dart không nằm trong production navigation.
Chưa full browser history/deep link, screen reader thật, release HTTPS hoặc production UI acceptance.

Lệnh native UI driver đã chạy đợt lăng kính (backend/adb reverse như trên):

```powershell
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' drive --driver=test_driver/ui_upgrade.dart --target=integration_test/ui_upgrade_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000 --enable-software-rendering --no-enable-impeller
```

Hai lượt renderer mặc định mất kết nối emulator; chưa nghiệm thu renderer đó. Software rendering
chỉ là flags của lệnh QA này, không cấu hình sản phẩm. Chưa physical-device/release-functional.

## Khóa ghi chú online

Menu ghi chú của mình → Bật khóa ghi chú (mật khẩu2x, ghi chú đã đồng bộ). Chạm thẻ khóa → nhập
mật khẩu → phiên đọc tạm tối đa5 phút. Owner có đổi/tắt mật khẩu; Khóa lại chỉ hủy phiên hiện tại.
Nội dung không vào ordinary cache/search/snapshot; che khi background/expiry/lỗi quyền/kết nối.
Phiên này chỉ đọc; protected editing và offline unlock chưa có. Xem docs/NOTE_PROTECTION.md.
Integration mới (backend + adb reverse như trên):

```powershell
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' test integration_test/note_protection_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000
```

## Email xác minh và khôi phục

SMTP_HOST trống thì không gửi thư; account chưa verified vẫn dùng được ghi chú. Cấu hình
SMTP_HOST/PORT/SECURITY/FROM/USERNAME/PASSWORD trong process environment rồi restart backend;
chỉ STARTTLS hoặc TLS, verify CA/hostname. Hướng dẫn không lộ secret ở docs/EMAIL_DELIVERY.md.
Home **Xác minh** cho nhập/gửi lại mã (cooldown60s). **Quên mật khẩu** → kiểm tra mã trước →
mật khẩu mới2x → login thủ công; code30 phút/one-time. smtp_accepted là server nhận thư, chưa
chứng minh inbox delivery. Local TLS fixture/Android test có lệnh riêng trong doc; không deploy fixture.

## Avatar và nhãn server

Hồ sơ và tùy chỉnh → Đổi ảnh đại diện: chọn PNG/JPEG tối đa2 MiB rồi Tải ảnh lên; server
decode/thu nhỏ≤512px, bỏ metadata, trả ảnh riêng của tài khoản. Cancel giữ ảnh cũ; có Dùng ảnh
mặc định. Upload cần online; ảnh đã tải được cache trong snapshot mã hóa để xem khi mở lại offline.
Quản lý nhãn có thêm/đổi tên/xóa-confirm và xử lý xung đột. Nhãn giữ ID ổn định; đổi tên/xóa
không sửa nội dung hoặc revision note. Nhãn pending lưu trước request, gửi trước note operations,
giữ qua reopen offline; thiết bị khác nhận khi sync15s/nút retry. Nhiều filter là AND theo ID.
Xem docs/AVATAR_AND_LABELS.md cho API/quyền/CAS/migration và giới hạn.

81 Flutter/29 backend PASS; Chrome release390x844 offline/reload/reconnect và Android debug API36
bộ chọn file OS thật PASS trong evidence/2026-10-01-avatar-labels. Native test cần chọn fixture
notetogether-avatar.png khi hiện DocumentsUI; kiểm tra denied/cancel chỉ ở widget, chưa OS QA.

```powershell
& 'D:\Android\sdk\platform-tools\adb.exe' push evidence/2026-10-01-avatar-labels/notetogether-avatar.png /sdcard/Download/notetogether-avatar.png
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' test integration_test/avatar_labels_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000
```

Fixture PNG đã kèm trong evidence index; backend/adb reverse như phần integration trên.
Kotlin incremental compilation tắt để tránh cross-drive Pub cache C:/project D:; không chỉnh
generated plugin registrant. Web/APK build PASS vẫn chưa nghiệm thu signing/HTTPS/physical-device.

## Đính kèm ảnh/video/file riêng tư

Note đã sync → editor Đính kèm → chọn nhiều tệp → Tải tệp lên. PNG/JPEG≤10 MiB,
MP4/PDF/TXT/CSV/ZIP≤20 MiB, tối đa10 tệp/100 MiB mỗi note. Ảnh canonical PNG bỏ metadata;
ảnh/video có preview; file tải qua trình duyệt hoặc Android DocumentsUI. Owner/editor xóa-confirm,
viewer chỉ xem/tải; server kiểm tra ACL/grant khi list/read/upload/delete/retry, không có public URL.
Attachment operations giữ nguyên content/revision/base editor. Remote lock/revoke hoặc peer delete
che preview sau kiểm tra quyền/poll15s; không thể thu hồi bản đã xuất. Chọn/upload/xem cần online;
lựa chọn retry chỉ giữ RAM trong cửa sổ, chưa durable media outbox. Protected reader có nút xem
đính kèm theo grant nhưng actual UI flow này chưa nghiệm thu.

88 Flutter/40 backend PASS; actual Chrome release chooser/upload/image/video/download/delete/remote
lock và Android debug API36 OS picker/video/SAF save/delete PASS. File tải/lưu được đối chiếu SHA-256;
denied/cancel/scale2 chỉ widget doubles. Web/APK release build PASS, chưa release functional/public
HTTPS/physical-device/video. Exact integration commands/QA fixture server8013 (chỉ test), giới hạn và
evidence: docs/PRIVATE_ATTACHMENTS.md, evidence/2026-10-01-attachments/INDEX.md.

## Quản lý chia sẻ và quyền người nhận

Note owner đã sync → menu Chia sẻ hoặc editor Chia sẻ ghi chú. Thêm1–20 email đã đăng ký mỗi
lượt, viewer/editor, batch atomic; đổi quyền bằng dropdown, thu hồi-confirm. Danh sách owner có
tên/email/thời điểm/quyền; recipient tab Được chia sẻ có owner/time/role, owner có icon/số người.
API owner/grant, share revision riêng + immutable operation journal; retry không cấp lại quyền
đã thu hồi. Role/metadata refresh giữ base revision editor và content note. Khi viewer/revoked,
latest draft/upsert giữ qua encrypted recovery; UI chỉ đọc/che source, phục hồi UUID mới.
Quản lý online-only, catalogue RAM-only; che khi background/lock/account loss, không poll khi nền.

97 Flutter/48 backend PASS, actual Android debug API36 batch/role/recipient edit/viewer/revoke/
encrypted offline DB reopen/recovery UI PASS, Chrome local release actual UI/API checks và
Web/APK release build PASS. Mốc sharing này dùng poll15s; SSE mới xem phần realtime bên dưới. Protected-reader share UI/
physical/release functional/HTTPS/video chưa nghiệm thu. Xem docs/SHARING_AND_PERMISSIONS.md,
evidence/2026-10-02-sharing/INDEX.md. Integration cần backend và adb reverse theo README:

```powershell
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' test integration_test/sharing_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000
```

## Cộng tác realtime —02/10/2026

SSE `/events` authenticated theo account, thông báo chỉ counter và refetch bằng API kiểm tra
ACL/grant. Hai session thấy thay đổi trong note đang mở không cần tap Đồng bộ; editor đang
gõ giữ draft/base, stale save409 qua conflict UI. Editor sạch hiển thị mới ngay, muốn sửa tiếp
chọn “Chỉnh sửa phiên bản mới” để mở base mới rõ ràng. Lock/viewer/revoke giữ encrypted recovery.

Reconnect/backoff/foreground/account guards; HTTP15s vẫn fallback. SQLite counter polling
250ms phía server, không OT/CRDT. Host106 Flutter/53 backend PASS; Android debug API36 real
SSE/API/encrypted reopen và Chrome local release QA xem evidence/2026-10-02-realtime/INDEX.md.
Web/APK build PASS; protected-reader actual realtime/physical/release functional/load/HTTPS/video
chưa nghiệm thu. Chi tiết protocol/races/limits: docs/REALTIME_COLLABORATION.md.

```powershell
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' test integration_test/realtime_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000
```

Integration cần backend/adb reverse theo hướng dẫn trên. Sau integration chạy `flutter pub get`
rồi build APK release riêng để SDK sinh lại plugin registration; không sửa GeneratedPluginRegistrant.

## UI/UX toàn diện —02/10/2026

Home có sidebar/rail/bottom navigation, ngữ cảnh tài khoản, thẻ/metadata và hàng ghim gọn;
Ctrl+F đưa focus vào tìm kiếm. Editor có mặt giấy, trạng thái lưu thật và số ký tự; theme/resize
giữ ID/base/selection. Auth và các flow hồ sơ/nhãn/avatar/chia sẻ/tệp/bảo vệ/mã email dùng cùng
components; Material được Việt hóa cả feedback mặc định. Chữ200% và màn hình320px có regression.
AI Q&A vẫn báo chưa khả dụng. Xem docs/UI_UX_DESIGN.md, docs/UI_UX_QA.md và
evidence/2026-10-02-ui-upgrade/INDEX.md cho ảnh trước/sau và phạm vi QA thật.

Native UI integration dùng backend local và emulator như hướng dẫn trên; driver sau xuất ảnh
thật vào output/native-ui (không phải golden hoặc mock):

```powershell
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' test integration_test/ui_upgrade_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' drive --driver=test_driver/ui_upgrade.dart --target=integration_test/ui_upgrade_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000
```

NVDA/TalkBack, thiết bị vật lý và kiểm thử đầy đủ APK release vẫn chưa nghiệm thu.
