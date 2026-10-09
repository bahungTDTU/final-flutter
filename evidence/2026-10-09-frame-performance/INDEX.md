# FPS/performance và Android thực —09/10/2026

Source: working tree `codex/ui-ux-performance`, base HEAD
`ef2ece00386b879f6ebb72b4636c42911aa07ca3`; chưa commit/push/merge.
[Source hashes](source-hashes.txt), [APK hash](artifact-hashes.txt),
[phương pháp và giới hạn](../../docs/PERFORMANCE_BENCHMARK.md).

## Kết quả

| Target/command | Result | Phạm vi |
|---|---|---|
| Android `ui_cohesion_test`, API36 debug/software |PASS sau sửa test wait/cleanup|3 workflows +teardown,8 PNG ngoài repo|
| Android `performance_test`, profile software |PASS đo|6 samples/1611 frames;32.0–34.4FPS|
| Cùng APK, GPU host/default Impeller OpenGLES |PASS đo|6 samples/2639 frames;52.6–56.7FPS|
| Target60FPS ổn định trên emulator |NOT MET|GPU raster p95=23–28ms; build p95<1.5ms|
| Chrome profile/Playwright |PASS12 scroll samples|1440×960 và390×844/DPR1; rAF scheduler,0 long task>50ms|
| Chrome search/filter retry riêng |PASS|5 query→1→clear500; filter→17→clear500; errors/warnings0|
| HTTP4roles |PASS|owner/editor/viewer/stranger, private attachment ACL|
| HTTP GET500notes |MEASURED|3 warmup +20 samples; p50/p95=36.386/56.351ms|
| Dart format |PASS|90 files/0changes|
| Flutter analyze |PASS|No issues found, sau sửa harness grid getter|
| Restore `pub get`, Web release/API8000, APK debug `lib/main.dart`/API8000 |PASS|compile, không release signing/deploy|
| Flutter198/backend94 suites |PREVIOUS SNAPSHOT|không chạy lại vì app/backend code không đổi trong đợt đo|
| Điện thoại thật/TalkBack/GPU presented FPS/peak memory/thermal |NOT RUN|Không suy diễn từ emulator hoặc rAF|

Tất cả đo/render/HTTP ngày09/10/2026. Web post-interaction JSON ghi UTC
`2026-10-09T07:10:24.559Z` tại thời điểm script hoàn tất; sample summaries đầu giữ số liệu log gốc.
Các lượt native test/phép đo có excerpt [native-checks.txt](native-checks.txt),
raw đầy đủ ở thư mục QA ngoài repo bên dưới. Lượt đầu2 failures được giữ trong excerpt;
UI registration chờ `!busy` và tearDown dọn controller/DB.3 workflows rerun PASS.
Post-interaction Web có timeout automation trước retry thành công bằng click/key events.
Không sửa code UI để tạo kết quả PASS; không bỏ assertions hoặc sửa số liệu.

## Môi trường đo

Flutter3.47.1/Dart3.13.1, Chrome154.0.8037.99, Windows host i7-11800H/16GB/RTX3060 Laptop.
AVD `taskflow_api36`: system image android-36/google_apis/x86_64, RAM2GB/4cores/60Hz;
physical1080×2400/density420, inherited override720×1280/density240.
Boot với `ANDROID_AVD_HOME=D:/Android/avd`, `ANDROID_USER_HOME=D:/Android/user`,
`-read-only -no-snapshot -no-window -no-audio`. Không wipe hay thay base AVD userdata.
Software: `-gpu swiftshader` và Flutter software/Skia. GPU: `-gpu host`, renderer log
Impeller/OpenGLES; [GPU host](gpu-host.txt). Cùng APK profile SHA256 ở artifact manifest.
Free RAM host khác nhau giữa hai cấu hình; không coi đây là A/B chỉ thay một biến.

Backend127.0.0.1:8020, SQLite QA riêng ngoài repo; GEMINI_API_KEY/GEMINI_API_KEY_FILE/
SMTP_HOST trống. Fixture500notes/30labels tạo qua API, không in/lưu token. Native render
benchmark tắt foreground polling; Web benchmark chạy production main/SSE. Browser plugin
không có; Playwright bundled fallback. Chỉ số rAF158.5–164.3Hz không phải FPS GPU/Flutter.

## Lệnh đã chạy

```powershell
python scripts/seed_performance.py --url http://127.0.0.1:8020 --output <QA>/fixture.json
adb -s emulator-5554 reverse tcp:8020 tcp:8020
flutter drive --driver=test_driver/ui_cohesion.dart --target=integration_test/ui_cohesion_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8020 --enable-software-rendering --no-enable-impeller
flutter drive --profile --no-dds --driver=test_driver/performance.dart --target=integration_test/performance_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8020 --dart-define=PERFORMANCE_EMAIL=<fixture-email> --enable-software-rendering --no-enable-impeller
flutter drive --profile --no-dds --driver=test_driver/performance.dart --target=integration_test/performance_test.dart --use-application-binary=build/app/outputs/flutter-apk/app-profile.apk -d emulator-5554
flutter build web --profile --dart-define=API_URL=http://127.0.0.1:8020
node <QA>/web-performance.cjs
node <QA>/web-performance.cjs --interaction-only
python scripts/qa_performance.py --url http://127.0.0.1:8020 --output <QA>/api-acl.json
python <QA>/api-latency.py
dart format --output=none --set-exit-if-changed lib test integration_test test_driver
flutter analyze
flutter pub get
flutter build web --release --dart-define=API_URL=http://127.0.0.1:8000
flutter build apk --debug --target=lib/main.dart --dart-define=API_URL=http://127.0.0.1:8000
```

`<QA>` là
`C:/Users/LENOVO/.codex/visualizations/2026/10/01/01a0f5e8-00e9-7261-9755-6f8d56861ace/performance-2026-10-09`.
Các lệnh dùng Python `.venv/Scripts/python.exe`, Flutter `C:/Users/LENOVO/flutter-sdk/bin/flutter.bat`,
adb `D:/Android/sdk/platform-tools/adb.exe`, Node runtime bundled của Codex.
Script Web/traces/logs giữ ngoài source; JSON và ảnh chọn lọc ở snapshot này không chứa token/key.
Build profile APK là test harness, không dùng làm bản cài bình thường. Web restore có cảnh báo
font Cupertino không bundled; APK restore có cảnh báo SDK XML version3/4, cả hai compile PASS.

## Dữ liệu và ảnh đã xem

- [Android GPU FrameTiming](android-gpu-frames.json) và [software FrameTiming](android-software-frames.json).
- [Web rAF/long tasks/search/memory](web-performance.json), [API latency](api-latency.json), [ACL](api-acl.json).
- [Android GPU memory snapshot](android-gpu-meminfo.txt), [software memory snapshot](android-meminfo-during-profile.txt).
- [Android editor](android-editor-light.png), [Home dark](android-home-dark.png),
  [checklist](native-studio-checklist.png), [protected reopen](protected-native-reopened.png).
- [Web desktop](web-profile-1440.png), [mobile](web-profile-390.png), [đã cuộn](web-profile-scrolled.png).

Native snapshots là debug; profile screenshot chụp sau đo ở `<QA>/gpu/android-profile-home.png`.
Native FPS đo trên cùng fixture/layout, không lấy từ screenshot/HWUI `dumpsys gfxinfo` hoặc widget tests.
Web heap28.2→33.4MiB chỉ5 searches +1filter flow ở context retry riêng, không phải12 đoạn cuộn,
không native/WASM/GPU total/peak/leak proof. Không có claim production mail/LLM/public release.
