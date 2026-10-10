# Theme cohesion —09/10/2026

Source: `codex/ui-ux-performance`, base `717f0ab6b04b6f63ad7f921a82b91cd2f4b41319`
+ uncommitted working changes. Không gán kết quả này cho một commit theme chưa tồn tại.
Đây là bước đồng bộ widget sau dashboard màu sắc, theo yêu cầu người dùng.

## Kết quả và phạm vi

| Gate | Target / command | Kết quả |
|---|---|---|
| Format/analyze/Flutter/backend | `scripts/check.ps1` | PASS:90 files0changes, analyze sạch,198 Flutter,94 backend;1 upstream Starlette/httpx deprecation warning |
| Motion/value equality | `flutter test test/prism_motion_test.dart --reporter expanded` | PASS4; assertions giữ nguyên |
| Sau sửa tương phản auth | `flutter test --reporter expanded`, `flutter analyze` | PASS198/analyze sạch |
| Web QA | `flutter build web --release --no-web-resources-cdn --dart-define=API_URL=http://127.0.0.1:8022`, `python scripts/prepare_web_offline.py` | PASS compile/offline40static; tối ưu release build, chưa release acceptance |
| APK | `flutter build apk --debug --dart-define=API_URL=http://127.0.0.1:8000` | PASS compile; chưa chạy native UI cho source này |
| HTTP ACL/private attachments | `.venv/Scripts/python.exe scripts/qa_performance.py --url http://127.0.0.1:8022 --output <qa-folder>/acl.json` | PASS owner/editor/viewer/stranger; timestamp UTC11:57:23, chi tiết acl.json |
| Browser | Chrome154.0.8037.99 headless, bundled Playwright, `node <qa-folder>/qa.cjs` | PASS12 luồng/4viewport/24 PNG,0console errors/warnings; kết thúc UTC12:43:03 |

Web thử nghiệm phục vụ tại `http://127.0.0.1:7360`, title `NoteTogether`; database riêng,
backend local8022. Browser plugin absent nên dùng Playwright bundled. Đã khôi phục build
Web về API8000 sau QA; xem `web-normal-build.txt` và manifest cho artifact cuối.

## 12 luồng browser thực

1. Auth branded panel và đăng nhập bằng form; dashboard không lộ title ghi chú khóa.
2. Settings, avatar, upload disabled khi chưa chọn tệp; mở/cancel dialog đổi mật khẩu.
3. Catalogue nhãn, mở/cancel input thêm nhãn.
4. Sheet lọc nhãn và apply/clear.
5. Writing Studio và preview mẫu.
6. Editor autosave được GET API xác nhận; đổi theme/resize giữ nội dung.
7. Share dialog thêm recipient, GET API xác nhận quyền viewer.
8. File chooser và private attachment upload được server xác nhận.
9. Summary bằng provider fixture, regenerate và nguồn.
10. Q&A bằng provider fixture và nguồn.
11. Unlock→reader→edit→relock; aria snapshot không còn title riêng tư sau khóa.
12. Dark settings và navigation ở tablet/mobile/landscape.

Viewport:1440×960,390×844,768×1024,844×390; DPR1. Các bước không phải tất cả đều chạy
ở cả4viewport: editor ở desktop/mobile, sheets dark ở desktop/mobile, Home ở cả4.
`qa.json` chứa thứ tự bước/ảnh và environment; `qa.txt` là output lượt cuối đạt.
Provider `fixture-not-an-llm` được inject qua create_app; không đọc key, gọi Google,
khởi động SMTP worker hay gửi email. Nội dung và tài khoản example.test trong ảnh là fixture.

## Kiểm tra ảnh và đối chiếu design

Đã mở ảnh app thật để kiểm tra auth, editor, shares/files/summary/Q&A, protected reader/edit,
settings light/dark và mobile; đối chiếu concept/dashboard ở evidence dashboard09/10.

| Điểm đối chiếu | Kết quả |
|---|---|
| Header/brand | Cùng gradient tím-xanh với dashboard; chữ/icon trắng; dark gradient dịu hơn |
| Panel/dialog/sheet | Cùng cấp surface lavender/navy, radius/border chung; không thêm nền trắng đơn điệu |
| Trạng thái control | Primary indigo và selected state nhất quán; error/disabled riêng |
| Tiêu đề/nội dung | NoteSection tách khối; nhãn/counter ngoài vùng nhập, field nền đọc sáng/tối |
| Typography/spacing | NotoSans bundled, giữ ReadingCanvas800/adaptive spacing và luồng hiện có |
| Privacy | Thẻ khóa trung tính, trước unlock và sau relock không lộ title/content/labels/date |

Gallery chính: [auth](auth-desktop.png), [editor](editor-light.png), [editor mobile dark](editor-mobile-dark.png),
[settings](settings-light.png), [mobile dark](settings-mobile-dark.png), [shares](share-light.png),
[files](files-light.png), [summary](summary-light.png), [Q&A](questions-light.png),
[protected reader](protected-reader-light.png), [protected editor](protected-editor-light.png).
Danh sách đủ24 PNG nằm trong qa.json. Số note/account/nội dung khác concept vì fixture QA.

## Lỗi phát hiện và kiểm tra lại

Lượt gate đầu có1 motion regression: theme resolver tạo closure mới khiến theme cùng giá trị
bị AnimatedTheme xem là thay đổi. Sửa sang WidgetStateProperty.fromMap; test giữ nguyên rồi
chạy lại full gate đạt. Ảnh auth phát hiện body description kế thừa màu ngoài Theme; sửa
DefaultTextStyle trắng rồi chạy lại198 Flutter/analyze/build/browser trên source cuối.
Backend không đổi sau gate94tests, không chạy lặp vì sửa màu auth.

Các lần driver đầu sửa semantics locator, focus nhập liệu, layout settling, API envelope
và expectation reader readonly. Final run đạt; raw retry logs/failure PNG giữ ngoài repo ở
folder QA. Flutter semantics group có DOM hit target chồng nhau, nên driver dùng pointer theo
bounds và keyboard cho input/recipient nếu cần; không coi đây là chứng nhận screen reader.
SelectableText output kiểm tra response API + heading/source + ảnh, không giả DOM chứa toàn text.

## Chạy lại

`qa.cjs` và `qa-fixture.py` là bản helper đã dùng trên Windows này; runtime/workspace paths
được ghi rõ trong file. Copy fixture helper vào thư mục QA ngoài repo và qa.cjs vào child folder
`theme-2026-10-09` trước chạy để giữ database/output ngoài source. Cần backend dependencies,
Node/Playwright/Chrome tương ứng. Chạy helper Python để mở backend8022, build Web với API8022,
phục vụ build/web trên7360 rồi chạy node driver. Sau QA build lại API8000 và dừng2server.
Không dùng database fixture làm dữ liệu production; không chạy2 lượt driver song song.

## Giới hạn

NOT RUN trong đợt theme: native runtime/physical, FPS/peak memory mới, TalkBack/NVDA,
password-change acceptance, full keyboard/caret/history/deep-link, Gemini thật, HTTPS/signing/
release acceptance/submission. Token/reset app bars, popup/snackbar/tooltip dùng shared theme,
được compile/host-test; chưa có browser screenshot riêng cho mọi trạng thái lỗi/token route.
Benchmark Android/Web trước đây thuộc source trước theme và không xác nhận FPS của theme này.
Không commit/push/merge đợt mới. `source-hashes.json` và `manifest.json` ghi source/artifact thật.
