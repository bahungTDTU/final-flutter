# Home UI/UX và performance —09/10/2026

Base `ef2ece00386b879f6ebb72b4636c42911aa07ca3`; branch `codex/ui-ux-performance`.
Đây là working changes, chưa commit/push/merge. `manifest.json` ghi thời điểm thực, hashes
source/bundle đã QA và artifact; không đổi các snapshots lịch sử.

| Kiểm chứng | Kết quả / artifact |
|---|---|
| Format + analyze |87files0changes; analyzer sạch, format.log/analyze-final.log |
| Full Flutter |198 PASS, gồm10 regression mới; flutter-final.log |
| Backend |94 PASS;1 Starlette/httpx deprecation warning, backend-final.log |
| Direct API |Owner/editor/viewer/stranger,423/403/404/429 và6 fields khóa PASS; acl.json |
| Rebuild probe |500notes/20pulses giữ source; root/theme/thẻ Home bị che20→0; benchmark.log |
| Build |Web/offline40static và APK debug PASS; web-final.log/android-debug.log |
| Chrome |5 viewport,0pageerror/console error; after-qa.json |

Browser plugin không có; Node REPL không resolve được bundled module (EPERM), nên dùng
Playwright bundled qua shell +Chrome headless. Local Flutter Web `http://127.0.0.1:7357`,
API `http://127.0.0.1:8020`, database/tài khoản disposable riêng. Không dùng provider AI/thư
Internet. QA compile release Web là build local, không deploy; APK chỉ debug, chưa native UI.

Luồng actual UI: đăng nhập → Home; search catalogue “Học tập” → chọn → Apply →2 ghi chú;
live search → empty →clear →9notes; list →mở note →nhập bằng keyboard →autosave →GET API
khớp nội dung. Resize390→1280 và dark giữ text, Back về Home, chủ động cuộn lên đầu để chụp
tablet/landscape. Ảnh/tablet xác nhận snippet mới; không claim native/TalkBack/NVDA/history/FPS.

Ảnh đã xem trực tiếp: typography/spacing, separator title/preview, màu/rim Prism, phân vùng
search/view/label, CTA không phủ thẻ, filter/checkbox và editor state. Search/catalogue hoạt
động thật; không blank/framework overlay. Không đổi copy marketing hay thêm asset/template.

Lệnh chính (logs đính kèm):

```powershell
& 'C:/Users/LENOVO/flutter-sdk/bin/dart.bat' format --output=none --set-exit-if-changed lib test integration_test test_driver
& 'C:/Users/LENOVO/flutter-sdk/bin/flutter.bat' analyze
& 'C:/Users/LENOVO/flutter-sdk/bin/flutter.bat' test --reporter expanded
& ./.venv/Scripts/python.exe -m pytest backend/tests -q --basetemp <QA-temp>
& 'C:/Users/LENOVO/flutter-sdk/bin/flutter.bat' build web --release --no-web-resources-cdn --dart-define=API_URL=http://127.0.0.1:8020
& ./.venv/Scripts/python.exe scripts/prepare_web_offline.py
& 'C:/Users/LENOVO/flutter-sdk/bin/flutter.bat' build apk --debug --dart-define=API_URL=http://127.0.0.1:8000
node qa.cjs after
flutter test <QA-temp>/ui-2026-10-09-benchmark.dart --reporter expanded
```

`qa.cjs` cần Playwright bundled ở path của máy QA; `<QA-temp>` là thư mục độc lập đã ghi
trong logs thực bên ngoài repo. `benchmark.dart.txt` giữ probe dưới dạng tài liệu, không thêm
source Dart cũ vào project. Probe dùng archived root cùng Home/fixture hiện tại để cô lập
root, không phải so sánh toàn bộ ứng dụng cũ/mới. File legacy ngoài repo trích từ
`git show ef2ece00386b879f6ebb72b4636c42911aa07ca3:lib/ui/app.dart`, đổi tên class
NoteTogetherApp thành LegacyNoteTogetherApp và relative imports thành package imports.
Lệnh chạy benchmark cần copy probe ra QA-temp, đặt tên legacy cạnh probe và thay import
`support.dart` theo checkout máy chạy. Root gốc luôn truy lại được từ commit, không lưu
thêm một bản app cũ trong source/evidence repository.

Các lần instrumentation ban đầu dùng locator Text exact cho merged Flutter semantics,
hoặc đợi heading ngoài viewport do Home giữ scroll, đã sửa script thành aria label/keyboard/
cuộn có chủ đích và GET thật. Không dùng lần timeout đó làm PASS; kết quả final là after-qa.json.
Test gate đầu có lỗi quyền temp Windows; chạy lại với thư mục QA riêng và quyền toolchain.
Không nới security assertions. Regression remote lock xác nhận nội dung cũ bị xóa cả ở Home
đang bị editor che. Code source cuối khớp hashes trong manifest. Sau QA, Web được build lại
bằng scripts/build.ps1 với API_URL mặc định8000; hai cấu hình/bundle được ghi riêng trong manifest.

Ảnh trước/sau: [desktop trước](before-desktop.png), [mobile trước](before-mobile.png),
[desktop sau](after-desktop.png), [mobile sau](after-mobile.png), [filter](after-label-filter.png),
[list](after-list.png), [editor dark](after-editor-dark.png), [tablet](after-tablet-dark.png),
[landscape](after-landscape.png). [Thiết kế/phạm vi](../../docs/HOME_UI_UX_PERFORMANCE.md).
