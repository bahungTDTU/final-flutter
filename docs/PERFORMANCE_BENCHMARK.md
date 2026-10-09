# Đo performance và thử Android —09/10/2026

Đo trên working tree của `codex/ui-ux-performance`, base `ef2ece00386b879f6ebb72b4636c42911aa07ca3`.
Đây là số đo thực trong môi trường local; không phải số dự kiến hoặc FPS điện thoại thật.
Source hashes, JSON từng lượt, lệnh và ảnh nằm ở
[evidence](../evidence/2026-10-09-frame-performance/INDEX.md).

## Kết quả Android profile

Fixture qua HTTP thật:500 ghi chú không khóa,30 nhãn, nội dung khoảng1KB/ghi chú.
Emulator `taskflow_api36`, Google APIs x86_64, RAM2GB/4CPU/60Hz; màn hình override720×1280,
density240 (logical480×853). Host i7-11800H/16GB/RTX3060 Laptop GPU, Windows/WHPX.
Các lượt chạy riêng với warmup mỗi layout; ba lượt lưới và ba lượt danh sách ở mỗi cấu hình.

| Cấu hình | Layout | FPS từng lượt | Build p95, ms | Raster p95, ms |
|---|---|---|---|---|
| GPU host, Impeller/OpenGLES mặc định | Lưới |56.0 /54.4 /56.7|1.447 /1.169 /1.228|25.918 /27.042 /23.225|
| GPU host, Impeller/OpenGLES mặc định | Danh sách |54.4 /53.3 /52.6|1.248 /1.219 /1.226|28.255 /26.508 /26.267|
| SwiftShader host + Flutter Skia software | Lưới |33.8 /32.0 /34.4|1.645 /2.188 /1.661|26.601 /33.128 /25.038|
| SwiftShader host + Flutter Skia software | Danh sách |32.5 /32.9 /33.6|2.427 /1.928 /1.929|25.158 /24.792 /24.770|

GPU:2639 frames,341 raster frames vượt16.667ms (12.9%); software:1611 frames,
1347 raster frames vượt16.667ms (83.6%). Không có build frame vượt16.667ms ở12 lượt này.
**Chưa đạt60FPS ổn định trong môi trường emulator.** Benchmark thực thi PASS nghĩa là có
đủ dữ liệu và không có lỗi UI trong kịch bản; không có assertion biến mục tiêu60FPS thành PASS.

Snapshot `dumpsys meminfo` trong lượt GPU: PSS165.6MiB/RSS259.6MiB; software:
PSS160.3MiB/RSS252.4MiB. Đây là một snapshot mỗi cấu hình, không phải peak hoặc kiểm tra leak.
Host free RAM khoảng537MiB lúc lấy snapshot software và2.37GiB khi lấy snapshot GPU.
Trước lượt GPU đã dừng đúng Gradle daemon idle của build này để giảm áp lực RAM.
Renderer, GPU và RAM cùng khác nhau; không kết luận chênh lệch FPS chỉ do một yếu tố.

## Cách đo và giới hạn

`integration_test/performance_test.dart` bắt buộc `kProfileMode`, đăng nhập fixture server,
mở Sembast riêng có mã hóa và xóa DB fixture sau test. Rendering dùng widgets production,
không fixture UI. Tắt foreground polling khi cuộn để tách tải network/sync; Web phía dưới
dùng `lib/main.dart` với SSE/polling thật. Không dùng timing widget test debug để claim FPS.

Sau warmup, `ScrollPosition.animateTo` cuộn3600 logical pixels xuống/lên trong4s mỗi chiều,
linear, dưới fully-live binding. Không dùng `pumpAndSettle` để điều khiển nhịp trong đoạn đo.
`watchPerformance` flush timing cũ trước action; callback bổ sung chỉ bắt đầu sau flush.
FPS = `(N-1)/(vsyncLast-vsyncFirst)` của Flutter frames được báo về. Đây là **cadence frame
Flutter**, không phải số frame GPU thực sự trình bày lên màn hình. P95 lấy phần tử ở chỉ số
`ceil((N-1)×0.95)` của dữ liệu đã sắp xếp trong mỗi lượt. SDK summary dùng budget16ms; custom report dùng
1000/60ms và ghi riêng. Chụp ảnh bằng surface conversion chỉ **sau** toàn bộ đoạn đo.

Không đổi màu/hiệu ứng app trong đợt đo. Build nhỏ hơn nhiều budget; raster p95 vượt budget
ở cả hai cấu hình. Cần trace raster/driver và A/B trên điện thoại thật trước khi quy lỗi cho
gradient, shadow hoặc facet. Bước tối ưu hợp lý tiếp theo là đo repaint của nền/card và thử
RepaintBoundary có kiểm soát, giữ thiết kế rồi so cùng fixture/mode/thiết bị.
[Flutter khuyến nghị profile trên thiết bị thật](https://docs.flutter.dev/perf/ui-performance).

## Kiểm thử Android thực

`ui_cohesion_test.dart` chạy lại3 workflows đã có: đăng ký/nhãn/theme/editor và GET autosave;
template/checklist/focus + encrypted offline reopen; ghi chú bảo vệ/SSE/frozen base/offline
reopen/unlock revalidation/delete xác nhận. **3 workflows PASS**, ngoài teardown.
Đây là debug Skia software, socket refusal mô phỏng offline, không OS kill/Wi-Fi toggle/TalkBack.
Lượt profile với renderer mặc định chỉ nghiệm thu cuộn UI, không thay ba workflows đầy đủ.

Lượt đầu có2 failures. `ui_upgrade_test.dart` chờ cả `!busy` sau đăng ký và thêm tearDown để
không giữ controller/DB sau failure. Chạy lại cả3 workflows PASS; assertions chức năng giữ nguyên.
Không sửa code app để che kết quả hoặc hạ gate. `.gitignore` thêm cache Kotlin sinh bởi build.

## Web và API

Chrome154.0.8037.99 headless, profile `lib/main.dart`, viewport1440×960 và390×844/DPR1,
URL7357/API8020. Browser plugin không có; dùng Playwright bundled.12 đoạn cuộn đã hoàn thành,
mỗi layout/viewport có warmup +3 lượt; rAF cadence158.5–164.3Hz, interval p95 khoảng6.2ms,
0 long task trên50ms trong các cửa sổ đo. **rAF không phải Flutter/GPU FPS**; nhịp headless
này cũng không được dùng làm FPS Android hoặc claim60FPS Web.

Bước post-interaction ban đầu timeout ở locator/nhập semantics. Retry riêng bằng click vị
trí thật và key events đã kiểm chứng:5 search→1 match→clear→500, filter→17→clear→500 PASS.
Không chạy lại12 đoạn cuộn để đổi kết quả. JSON ghi rõ nguồn12 samples từ log đầu và scope
snapshot memory của retry sau. Không có app console error/warning, URL/title/content/canvas đúng.
Ảnh desktop/mobile và ảnh khi đã cuộn được kiểm tra trực tiếp.

Search sau phím cuối:334/325/325/326/325ms, đã gồm debounce300ms của app. Filter thao tác
723ms gồm mở sheet/gõ/chọn/Apply, không phải CPU time. Navigation→auth semantics7.369s là
một lượt cold context có explicit wait1s/semantics activation; không phải FCP/LCP chuẩn.
Login→500 notes752ms. JS heap sau GC28.2→33.4MiB qua5 search +1 filter flow, không gồm toàn bộ
WASM/GPU/native memory, không kết luận leak/peak. RAM của12 đoạn cuộn đầu không được giữ lại.

HTTP `GET /notes`500 rows:3 warmup +20 samples, p50=36.386ms/p95=56.351ms;
decode JSON client nằm ngoài timer. Loopback, chưa network WAN/concurrency/load production.
Direct API owner/editor/viewer/stranger PASS. Backend source không đổi,94 backend tests là
snapshot trước; không claim chạy lại94 tests.198 Flutter unit/widget tests là snapshot trước;
đợt này chạy native integration/profile và analyzer phù hợp với harness mới.

## Chạy lại Android

Chỉ dùng backend/database QA riêng; script seed tạo account mới và không lưu/in token.
API key/SMTP không cần cho benchmark. Với emulator đã boot và backend ở8020:

```powershell
$env:ANDROID_AVD_HOME='D:\Android\avd'
$env:ANDROID_USER_HOME='D:\Android\user'
$env:ANDROID_HOME='D:\Android\sdk'
$env:PERFORMANCE_OUTPUT_DIR="$PWD/output/performance"
python scripts/seed_performance.py --url http://127.0.0.1:8020 --output output/performance/fixture.json
$fixture=Get-Content output/performance/fixture.json -Raw | ConvertFrom-Json
adb -s emulator-5554 reverse tcp:8020 tcp:8020
flutter drive --profile --no-dds --driver=test_driver/performance.dart --target=integration_test/performance_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8020 "--dart-define=PERFORMANCE_EMAIL=$($fixture.email)"
```

AVD lần này dùng `-read-only -no-snapshot -no-window`, không wipe/chỉnh base userdata.
APK profile là harness benchmark, không phải artifact cài sử dụng bình thường. Sau đo,
khôi phục Web/API8000 và APK debug `lib/main.dart`, không deploy/sign release/push/merge.
Đo trên thiết bị Android thật, startup cold/warm nhiều lượt, peak memory, GPU presentation,
CPU attribution, battery/thermal và FPS Web bằng trace renderer vẫn chưa chạy.
