# UI/UX toàn diện — evidence local 02/10/2026

Workspace `D:\flutter cuoi ki`; Windows11, Flutter3.47.1/Dart3.13.1, Python3.12.14,
Chrome154 và Android API36 emulator taskflow_api36/emulator-5554. Commit **chưa có**,
master unborn, không remote/push/deploy. Thời gian UTC trong logs/manifest lấy từ máy thật.
Không gán authorship cá nhân hoặc giả coverage/video/AI/email internet.

## Thay đổi đã kiểm chứng

- Theme giấy ấm/teal, light/dark, Noto Sans bundled; thống nhất header/panel/section/status,
  dialog/share/files/avatar/protection và Material feedback tiếng Việt.
- Home có ngữ cảnh tài khoản, số ghi chú/nhãn thật, search Ctrl+F, filter AND/clear,
  sidebar/rail/bottom navigation và hàng ghim đầy đủ chiều rộng. Chiều cao thấp/chữ lớn dùng rail.
- Editor mặt giấy, count/typography, trạng thái local/server; giữ controller/ID/caret/frozen base.
  Bản nháp thiếu trường không báo đã đồng bộ; khi offline không hiển thị nhãn realtime cũ.
- Auth busy/autofill/Next/Done/validation; nhóm settings, nhãn và các dialog có hierarchy/close,
  giới hạn và empty/error states. AI production vẫn báo chưa khả dụng.
- Không thay backend schema/ACL, lock/grant/owner, immutable operations hoặc policy preferences.

## Lệnh thật, target và kết quả

| Command / target | Kết quả / log |
|---|---|
| `powershell -ExecutionPolicy Bypass -File scripts/check.ps1` host final | Format54 files0 changes/analyze sạch/**114 Flutter/53 backend PASS**; check-final.txt; một TestClient deprecation warning |
| `flutter test integration_test/ui_upgrade_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000` | Android debug/API thật PASS; android-ui-flow.txt trước guard offline cuối |
| `flutter drive --driver=test_driver/ui_upgrade.dart --target=integration_test/ui_upgrade_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000` | Final source PASS; android-ui-drive.txt, ba PNG native. Một scenario; dòng +2 bao gồm tearDownAll |
| `flutter test integration_test/sharing_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000` | Android debug sharing/recovery PASS; android-sharing.txt, ngay trước guard offline cuối; ACL/core không đổi sau đó |
| `flutter test integration_test/note_flow_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000` | Android real API/encrypted DB/offline core PASS; android-note-flow.txt ở giai đoạn UI đầu, không coi là rerun toàn flow trên source cuối |
| `.venv/Scripts/python.exe evidence/2026-10-02-ui-upgrade/api_acl_probe.py` localhost8000 | Direct HTTP owner/viewer/editor/stranger PASS; api-acl.txt, ngày UTC thật, tokens không log |
| `.venv/Scripts/python.exe evidence/2026-10-02-ui-upgrade/contrast_audit.py` tokens | 10 cặp text/outline light/dark PASS; contrast.json, ngưỡng4.5/3; không chứng nhận mọi SDK state/WCAG toàn app |
| `flutter pub get`, sau đó `scripts/build.ps1 -Target web` / `-Target apk` | Web/APK release build; pub-get-release.txt/build-web-final.txt/build-apk.txt; hash artifact trong source-manifest.json |
| `npx --yes --package @playwright/cli playwright-cli -s=ui-upgrade …` / `-s=ui-auth …` | Chrome local release actual UI/network/Sembast; phạm vi và source boundary dưới đây |
| `.venv/Scripts/python.exe evidence/2026-10-02-ui-upgrade/collect_manifest.py`, rồi `--verify` | Hash inputs/docs/evidence/builds + README equality/HEAD; manifest-summary.txt/manifest-verify.txt; integrity verification không rerun QA |

Executable: Flutter/Dart `C:/Users/LENOVO/flutter-sdk/bin`, Python `.venv/Scripts/python.exe`,
npx `C:/Program Files/nodejs/npx.ps1`, ADB `D:/Android/sdk/platform-tools/adb.exe`.
Backend local thật8000/Web static7357; `adb reverse tcp:8000 tcp:8000` cho emulator.
Không HTTP double trong native/Chrome/direct-HTTP suites; host controller/widget dùng mocks
đúng phạm vi. `scripts/setup.ps1` và README là prerequisites, không claim clean-machine rerun.

## Android thật

Native UI scenario tạo account disposable example.test qua UI; đăng ký tự login, mở hồ sơ,
đổi dark preference, tạo nhãn UI/sync, tạo note/autosave, đổi theme khi editor còn mở,
kiểm tra ID/text/caret và GET nội dung thật. Back → list mode/search → dark settings,
pending queues đã nhận server. Sembast và DeviceRecoveryKeys thật, không fixture controller.
Driver chụp `android-editor-light.png`, `android-settings-dark.png`, `android-home-dark.png`
ở720×1280 physical/logical480×853.3. Home ảnh ở scroll/search state nên heading nằm một phần
dưới AppBar; editor có nội dung cuộn bên dưới viewport. Không gọi đây là overflow.

Sharing scenario thực batch owner, recipient edit/viewer/revoke, owner/time metadata,
encrypted offline DB close/reopen và UI phục hồi note ID mới. Note-flow core test trước
đợt Việt hóa/pinned refinement vẫn có scope riêng. DB reopen trong process, chưa OS kill.
Driver helper đầu gọi API revert không có trong SDK và callback thiếu optional argument;
logs android-ui-initial-compile-error.txt/android-driver-initial-error.txt giữ lỗi và final PASS.
Không sửa GeneratedPluginRegistrant; pub get sau integration trước build release riêng.

## Chrome thật và source boundary

Fixture `ui-upgrade-owner@example.test`, password công khai `UiEvidence-2026!` chỉ cho QA local.
seed_ui.py tạo dữ liệu qua actual API, không production mock. Ảnh trước/sau có dữ liệu kiểm thử
thật và thay đổi do thao tác; không golden snapshot. Pin timestamp trong seed là dữ liệu fixture,
không timestamp nghiệm thu. Backend clock/evidence timestamp dùng giá trị thật.

Chrome đã kiểm tra desktop1440×900, tablet768×1024 và mobile390×844, light/dark:
auth validation/login thật; Ctrl+F vào search; query Flutter + AND Học tập/Nhóm → empty;
xóa filter giữ query; theme/resize khi editor nhập giữ text; share dialog + empty submit;
private attachment empty/limits; settings/avatar default/cancel và password open/cancel.
Không rerun OS chooser/upload/password-submit/SMTP internet trong đợt UI này.

Offline dùng `page.context().setOffline(true)`: nhập note → local pending → reload offline →
mở lại → reconnect. `web-api-after-offline.txt` xác nhận **đúng một server note**, title/content
nguyên vẹn, revision1. Các web-offline*.txt và ảnh tương ứng giữ bằng chứng từng bước.
Đọc inputValue từ textbox Flutter prefilled không focus đã trả rỗng ở automation; ảnh/focus
snapshot và API xác nhận dữ liệu còn. Không tính lỗi đọc DOM proxy là mất draft của ứng dụng.

QA trên source trước guard offline cuối dùng mainSHA
`e8ec33262ca6b27c16d357b3b0ef71ed39eec5a25f7a8a6eb96b203f134fccd1`, worker3066198d9ebf6460.
Rà ảnh phát hiện badge “Trực tiếp” có thể còn dù API offline; guard `c.online` sửa và regression
thứ114 kiểm tra stale realtime status + pending draft. `web-offline-final.txt`/ảnh offline cuối
kiểm tra lại trên source chốt. Flow trước không được gọi là rerun toàn bộ trên bundle cuối.

Final Web worker **a9b61a1af6b945f3**,41 static resources; navigation response main JS hash
`b0f624a8e92833540c8453b8fefc4cd45e0699301ea5fbfc910a1353bb589fef`
trong browser-executed-build-final.txt bằng hash build trong source-manifest.json.
Worker activation chưa tự reload VM: QA chờ cache/worker hết installing/waiting, reload rồi
hash bytes response thật. Hash fetch sau navigation đơn lẻ không đủ chứng minh VM đang chạy.
Chrome console lỗi mạng trong thời gian offline là expected; không coi là lỗi JavaScript UI.

Final guard/desktop được kiểm tra trong phiên ui-auth sau khi phiên ui-upgrade reload timeout;
chỉ harness CLI bị dừng, không sửa worker theo phỏng đoán. Cache main cũng đo đúng hash cuối.
Chờ bằng chuỗi status riêng bị strict match live-region hoặc status ghép; snapshot cuối và
assert badge/API là kết quả chốt. `web-offline-badge-assertion.txt` xác nhận không live/retry
label khi offline; `verify_offline_final.py`/`web-api-after-offline-final.txt` xác nhận đúng một
note và nội dung mới revision2 sau reconnect. Đây là cập nhật note fixture trước, không note mới.

| Ảnh | Source / phạm vi |
|---|---|
| before-auth/home/mobile.png | Baseline thực trước đợt nâng cấp |
| ui-final-home-desktop.png, ui-final-offline-dark.png | Chrome navigation bundle chốt b0f624…; desktop light1440×900/mobile dark390×844 |
| android-editor-light/settings-dark/home-dark.png | Android debug final-source qua driver; caption scroll state phía trên |
| ui-final-auth-*.png, home-mobile-dark/home-tablet/settings-tablet/share-mobile/attachments-mobile/avatar/password.png | Chrome e8ec33… ngay trước guard kết nối; các layout này không đổi sau guard |
| web-before-badge-fix-reopened.png | Offline reload/reopen trước guard; có nhãn reconnect cũ, giữ như evidence phát hiện lỗi |

Material semantics cần Enable accessibility sau reload. Avatar/password role click có thể bị
flt semantics overlay chặn; click tọa độ từ ảnh thật mở dialog thành công. Đây là giới hạn
automation được quan sát, chưa đủ để kết luận screen-reader acceptance. Fresh snapshot sau
navigation/resize/dialog close; stale-ref retries không tính thành successful interaction.

## Layout repair và regression

Colored Container che Ink decoration khiến surface sai; chuyển SurfacePanel sang Material.
LayoutBuilder bên trong AlertDialog lỗi intrinsic sizing; StatusNotice dùng Builder/MediaQuery,
chữ lớn/màn hẹp xếp action dưới. Auth hero chỉ ở desktop đủ cao/chữ bình thường; rail thay
sidebar khi viewport thấp. Pinned note đơn có row gọn; card grid tính font/conflict/role height.
Widget tests phải scroll đến card lazy sau layout đổi; giữ nguyên assert data/privacy/base.
Material Việt hóa làm tester.pageBack tìm English Back thất bại; test dùng BackButton thật.

ui-first-pass.txt là trích đầu/cuối, **không** full log; ui-first-pass.txt.gz lưu lossless log
ban đầu. Các lỗi intrinsic/layout/integration helper có log riêng, check cuối mới là gate PASS.
Responsive host test320×640/844×390/1280×600 ở200%, home short1440×600, và suite adaptive
cũ; chưa actual browser/native mọi kích thước200%. Frozen base/ID/selection, locked title/
content/labels khỏi visual và semantics, durable drafts và immutable sync suites vẫn PASS.

## Giới hạn nghiệm thu

Chưa NVDA/TalkBack/physical device, OS force-kill, native full keyboard-inset audit,
history/deep-link, protected editing/offline unlock/protected-reader full UI, load/performance.
Attachment OS upload/preview/download và avatar canonical APIs có evidence mốc riêng,
không claim rerun tất cả ở đợt này. AI LLM/internet SMTP/HTTPS/contribution/video/submission
vẫn theo STATUS. Native functional là debug; APK release build vẫn debug signing/local HTTP,
không thay public HTTPS hoặc release functional acceptance.

`source-manifest.json` ràng buộc mã/tài liệu/evidence/build hiện tại, commit null đúng thực tế.
Đối chiếu PROMPT/PDF/rubric qua docs/REQUIREMENTS_MATRIX.md; chưa tuyên bố đủ32 tiêu chí.
