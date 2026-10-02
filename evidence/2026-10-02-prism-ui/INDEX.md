# UI lăng kính, màu sắc và motion — evidence 02/10/2026

Workspace `D:\flutter cuoi ki`; Windows11, Flutter3.47.1/Dart3.13.1, Python3.12.14,
Chrome154 local release, Android API36 emulator taskflow_api36/emulator-5554.
Commit **chưa có**, master unborn, không remote/push/deploy. Timestamp UTC trong log/manifest
lấy từ máy thật; không dựng video/FPS/coverage/authorship/email/AI kết quả.

## Thay đổi

Theo yêu cầu mới của người dùng: thêm nhiều màu, hiệu ứng lăng kính, hiện đại nhưng không rối.
Palette6 tones light/dark; viền iridescent mảnh, backdrop radial/facet tĩnh, crystal hero vẽ code,
CTA gradient. Nền panel/card kín và contrast chữ riêng; màu nhấn tập trung ở icon/rim/chip/CTA.
Hover2px/180ms, reveal420ms, theme300ms và route fade/slide. Reduced motion bỏ lift/thời lượng
trang trí/ripple. Không blur/BackdropFilter/animation nền vô hạn hoặc framework/asset template mới.
Palette equality tránh theme restart khi controller notify; opaque ID chọn tone, không dùng nội
dung bí mật hoặc thêm trường màu lưu server. Thẻ khóa trung tính, không lộ title/content/labels.

Files: lib/ui/prism.dart, design_system.dart, app.dart, home.dart; test/prism_motion_test.dart.
Controller/backend/cache/schema/immutable operations/frozen editor base giữ nguyên.
Thiết kế và phạm vi QA: docs/UI_UX_DESIGN.md, docs/UI_UX_QA.md. README.md và Readme.txt byte-equal.

## Commands, target và kết quả thật

| Command / target (02/10/2026) | Result / log |
|---|---|
| `powershell -ExecutionPolicy Bypass -File scripts/check.ps1` host final | Format56files0changes, analyze sạch; **118 Flutter/53 backend PASS**; check-final.txt;1 TestClient deprecation warning |
| `flutter test test/prism_motion_test.dart` host | 4 meaningful tests PASS; motion-final.txt, cũng rerun trong full check |
| `flutter drive --driver=test_driver/ui_upgrade.dart --target=integration_test/ui_upgrade_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000 --enable-software-rendering --no-enable-impeller` | Real Android debug/API36/backend/Sembast/DeviceRecoveryKeys;1 scenario PASS; dòng+2 bao gồm teardown; android-ui-drive.txt |
| `.venv/Scripts/python.exe evidence/2026-10-02-ui-upgrade/api_acl_probe.py` HTTP8000 | Owner/viewer/editor/stranger read/write/sharing/protection/minimal locked metadata PASS; api-acl.txt, clock UTC thật |
| `flutter pub get` rồi `scripts/build.ps1 -Target web` / `-Target apk` | Web/APK release build PASS; pub-get-release.txt/build-web.txt/build-apk.txt; Web41resources, worker notetogether-static-d000707d1578e9da; APK55.9MB |
| `npx --yes --package @playwright/cli playwright-cli -s=prism-ui …` Chrome | Actual UI/API/render/screenshots; scope bên dưới; DOM/editor value assertion trong web-theme-resize.txt |
| `.venv/Scripts/python.exe evidence/2026-10-02-prism-ui/collect_manifest.py` rồi `--verify` | Current input/docs/evidence/build SHA-256, HEADnull/README equality; manifest-summary.txt/manifest-verify.txt; integrity check không rerun QA |

Flutter/Dart executable `C:/Users/LENOVO/flutter-sdk/bin`; npx `C:/Program Files/nodejs/npx.ps1`,
ADB `D:/Android/sdk/platform-tools/adb.exe`; Python `.venv/Scripts/python.exe`.
Backend chạy scripts/start_backend.ps1 localhost8000; Web scripts/start_web.ps1/static7357.
Native cần `adb reverse tcp:8000 tcp:8000`. README là setup/integration prerequisite;
không claim clean-machine rerun. Pub get sau integration, sau đó release build riêng;
không sửa GeneratedPluginRegistrant.java.

## Host assertions

Motion tests kiểm tra hover displacement2px, settle/return/no idle ticker, reduced hover giữ
geometry/reveal hiện ngay, và controller notify không khởi động lại theme/decorative animation.
Contrast test tính129 pairs:6 tones ×5 alpha0/.08/.13/.14/.22 ×2 text colors ×2 modes =120;
thêm6 semantic canvas/outline/primary pairs và3 CTA endpoints. Ngưỡng text4.5/control3 PASS.
Đây là envelope các tint được chọn, không đo mọi gradient interpolation/SDK state hoặc full WCAG.
Existing host suite giữ adaptive320/360/390/768/desktop/landscape200%, locked semantics/roles,
ID/base/text/caret, recovery/preferences/labels/sharing/realtime/durable outbox regression.
Host widgets dùng doubles đúng phạm vi; không gọi là real browser/native/screen-reader QA.

## Chrome final local release

Fixture `ui-upgrade-owner@example.test`, password công khai `UiEvidence-2026!`, chỉ local QA.
6 notes/4 labels đã seed qua API ở đợt trước, không mock production. Đợt này login bằng UI thật;
auth/home light1440×900, hover một card; đổi theme trong editor và resize390×844 giữ nội dung:
`Nội dung vẫn được giữ khi mất mạng; trạng thái kết nối được hiển thị đúng.` Không nhập sửa mới.
Dark home desktop1440×900/tablet768×1024/mobile390×844 và settings được chụp/xem thật.
Chrome test không assert caret offset chính xác; host/native đã kiểm tra selection/ID/base phù hợp.

Actual navigation response main.dart.js SHA-256 (browser-build.txt):
`047ecd2702aeeb357202773c7f0b5c475350be758412a8a89b7aafe00d6e2c06`.
Đối chiếu artifact thật ở browser-artifact-match.txt/source-manifest.json; không suy từ fetch
mới hoặc chỉ cache-update. CLI session thông thường không tự gọi đây là browser integration_test.

Auth ảnh đầu bị lệch sau DPR automation đổi1.5→1; reload ở viewport ổn định sửa capture, final
prism-auth-desktop.png đã xem. Close settings bằng semantics click bị Flutter overlay chặn;
web-top-views.txt giữ timeout, Escape đóng dialog thật rồi chụp lại trong web-top-retry.txt.
Không tính lượt automation thất bại là PASS. Home after-editor giữ scroll; ảnh suffix-top chụp
sau cuộn chủ động lên đầu. Hover screenshot được thực hiện thật; displacement2px được đo ở host,
không claim browser geometry dựa console output không được CLI ghi lại.

## Android debug / renderer boundary

Driver thực đăng ký disposable example.test, tạo nhãn/server sync, đổi preference/dark/list,
tạo note/autosave, đổi theme khi editor đang mở, assert ID/text/caret và GET API nội dung thật.
Sembast và DeviceRecoveryKeys thật. Ba PNG720×1280 physical/logical480×853.3:
android-editor-light.png, android-settings-dark.png, android-home-dark.png.
Home ảnh là list/search state; heading một phần dưới AppBar theo scroll, không kết luận overflow.

**PASS dưới Skia software**, flags chỉ trên lệnh QA, không cấu hình renderer production.
Hai lượt renderer mặc định mất VM/emulator/ADB connection; raw logs
android-ui-initial-disconnected.txt và android-ui-retry-disconnected.txt giữ nguyên.
Không tính PASS hoặc kết luận nguyên nhân GPU. Emulator retry có duplicate-AVD FATAL trong
emulator-held-stdout.txt; sửa vòng đời helper rồi chạy được. Không lỗi assertion UI được dùng
để che giấu disconnect. Debug integration không phải release-functional/physical acceptance.

## Ảnh đã xem

- before-home-desktop.png: baseline thật copy từ đợt UI-upgrade trước; không chụp mới sau sửa.
- prism-auth-desktop.png: login hero lăng kính/form,1440×900.
- prism-home-desktop.png: light home,1440×900; prism-hover.png: trạng thái hover/scroll.
- prism-home-desktop-dark-top.png, prism-home-tablet-dark.png,
  prism-home-mobile-dark-top.png: dark home ở đầu trang.
- prism-home-desktop-dark.png, prism-home-mobile-dark.png: dark retained-scroll state.
- prism-editor-mobile-dark.png: editor390×844 sau đổi theme/resize.
- prism-settings-dark.png: dark settings1440×900.
- android-editor-light.png, android-settings-dark.png, android-home-dark.png: actual native driver.

## Failures và giới hạn

analyze.txt ghi CupertinoPageTransitionsBuilder không có trong SDK, đã dùng Prism transition.
targeted.txt ghi hover reduced-motion còn InkWell ticker, đã sửa hoverDuration0.
motion-initial.txt còn theme ticker do test đổi sang MaterialApp default khác theme, đã giữ
same noteTheme; check-initial.txt import thừa, đã bỏ. Full check-final.txt PASS sau sửa cuối.
Không sửa source sau full gate; cuối lượt chỉ bổ sung docs/evidence và manifest.

Chưa đo FPS/frame timing/jank/list lớn; không hứa60fps. Chưa physical/TalkBack/NVDA,
OS force-kill/relaunch, browser history/deep-link/full keyboard/release-functional/signing/HTTPS.
Không rerun Chrome offline/reload/picker/upload/SMTP/full sharing/realtime flow trong đợt trang trí;
các mốc trước có scope riêng. Không đổi claims LLM/email internet/32 rubric/submission.
