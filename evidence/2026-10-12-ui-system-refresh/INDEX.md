# Nghiệm thu UI system refresh —12/10/2026

Target: Flutter Web/Chrome thật trên Windows; Android debug compile. Branch
`codex/ui-system-refresh`, base HEAD `f3b17a3d33e5d432320e1d8620f87d7fc33b30d3` + working
changes trong `source_manifest.json`. Chưa commit/push/merge. Không sửa evidence cũ.
[Quyết định thiết kế](../../docs/UI_SYSTEM_REFRESH.md), [45 ảnh UI](GALLERY.md).

## Kết quả source cuối

| Kiểm tra | Lệnh/target | Kết quả và evidence |
|---|---|---|
| Format/analyze/Flutter/backend | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1` | PASS109files0changes/analyzer sạch/262 Flutter/118 backend; `check-final-accepted.txt` |
| Geometry mới | `flutter test test/ui_system_refresh_test.dart` | PASS4 tests, `compact-accepted.txt`; tests cũ giữ nguyên |
| Web cho QA | `scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8058` | PASS53.4s, `build-web-final-qa.txt` |
| Cache Chrome | `browser-cache-final.js` via Playwright CLI | PASS worker309b295fab4ba3aa/40static; hash cache/network/disk khớp |
| Android | `flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8000` | PASS13.3s, `build-apk-final-debug.txt`; runtime NOT RUN |
| API bốn vai trò | `.venv/Scripts/python.exe .../qa_seed.py` | PASS owner/editor read, viewer write403, stranger read404, locked read423; `http-qa.txt` |
| Draft roundtrip | `browser-edit-exact.js`, `qa_roundtrip.py` | PASS exact title, content/pin/two shares giữ nguyên; `http-roundtrip.txt` |
| Relock | `browser-protected-open.js`, UI unlock/relock, `browser-relock-final.js` | PASS trước unlock ẩn title, sau relock không còn textbox title/content |
| Tương phản | `.venv/Scripts/python.exe .../contrast.py` | PASS13 cặp token chính/min5.03; không full rendered WCAG audit |

Backend có một warning Starlette/httpx đã tồn tại, không test failure. Web có font-family
hint/tree-shaking thông thường. Bản dev Web cuối build lại với API8000;
`build-web-default.txt`/`artifacts.json` ghi kết quả/hash, không đồng nhất fingerprint của
bản API8000 với Chrome QA/API8058. APK/build outputs giữ ngoài Git theo `.gitignore`.

## Chrome và dữ liệu

Web `http://127.0.0.1:7376`, API8058, SQLite riêng `tmp/ui-system-qa/qa.sqlite3`, SMTP
DisabledDelivery/worker off và Gemini keys rỗng. 4 account `example.test`,9 notes/4 labels,
2 pinned,1 shared to viewer/editor,1 protected; dữ liệu tổng hợp, không tài khoản thật.
Token giữ RAM, không lưu vào evidence. Server/browser QA riêng đã được đóng sau kiểm tra.

Playwright CLI: `npx.cmd --yes --package @playwright/cli playwright-cli -s=ui-system ...`
với `open ... --browser chrome`, snapshot/ref → click/keyboard/resize/screenshot và
`run-code --filename evidence/2026-10-12-ui-system-refresh/<script>.js`. Chrome có Flutter
semantics được bật; một số sheet semantics intercept pointer nên keyboard Space được dùng
để đổi theme, eval chỉ cho kích hoạt semantics/đóng hoặc mở UI đã được đọc. Không NVDA claim.

Home5viewport1440×1000,390×844,320×740,844×390,768×1024; sáng/tối. Editor title thay bằng
Control+A/typing, autosave thật; theme/resize không mất title, API xác nhận. `.fill()` của
proxy title ban đầu append thay vì replace, đã thay bằng keyboard và kiểm tra giá trị chính
xác; không suy đó là lỗi dữ liệu ứng dụng. Nội dung Markdown cũ vẫn giữ nguyên trên server.
Workspace9 mục, auth/login/register/recovery/token, template gallery, labels/profile,
security, AI form, sharing, attachments và protected gate/reader được chụp. Các trạng thái
rỗng và form/provider không submit được ghi đúng phạm vi; chưa nghiệm thu provider mới.
Tooltip/keyboard focus trong một số ảnh là trạng thái tương tác Chrome đang mở.

Các ghi nhận thành công cache/resize/workspace/relock có0pageerror/consoleerror; snapshot
cuối hợp lệ ở `browser-relock-final.txt`. `browser-complete.txt` giữ lỗi parse của lệnh CLI
inline cuối; không coi là PASS của ứng dụng hoặc thay kết quả ghi nhận hợp lệ trước đó.

## Các vòng sửa và giới hạn

`check.txt` giữ8 UI regressions đầu tiên do intro/header cao đẩy controls dưới viewport.
Đã sửa mô tả toàn chiều rộng, header cửa sổ thấp và intro workspace chỉ PC đủ cao;
`targeted.txt`63PASS, `check-final.txt`261Flutter/118backend PASS trước mobile polish.
Các log `check-final-mobile.txt`, `check-accepted.txt`, `compact-targeted.txt` giữ quá trình
chỉnh geometry test mới: Scaffold tight height844 rồi font kiểm thử wrap190. Header có
natural sizing, test banner giới hạn220 và xác nhận chỉ nội dung thiết yếu; final4tests/
262fullsuite PASS. Không sửa assertion của tests cũ.

Một chuỗi click relock bị automatic approval review chặn vì ref cũ có thể nhầm thao tác.
Đã đọc snapshot mới: f2e263=Khóa lại, f2e315=Tắt khóa ghi chú, rồi chỉ đóng grant reader.
Kiểm tra sau đó PASS; protection/server policy không bị tắt. CLI sandbox Chrome launch
failure được xử lý bằng phiên QA ngoài sandbox, không thay policy trình duyệt/OS.

NOT RUN: Android UI/IME/FPS source mới, screen reader thật, Gemini/SMTP/provider, HTTPS,
signing/release/video/clean-machine và hosted CI. Không tuyên bố FPS tăng hoặc rubric/teamwork
hoàn thành từ UI/build/widgets. Motion vẫn ngắn, reduced motion được regression hiện có
kiểm tra; không thêm animation loop/blur/ticker hoặc giữ private content khi exit.

## Tái chạy độc lập

Dùng `qa_server.py --db tmp/<tên-mới>/qa.sqlite3` để có DB mới; script chặn DB đã tồn tại
và đường dẫn ngoài tmp. Sau đó chạy `qa_seed.py`, build Web API8058 và Python http.server7376
trỏ `build/web`. Chạy các browser scripts theo trạng thái UI được mô tả, cập nhật expected
worker khi compiler/source khác và lưu đợt evidence mới. Không chạy lại seed trên DB có fixture.
`source_manifest.json` lưu raw/LF SHA256 source; `artifacts.json` ghi artifacts không commit;
`SHA256SUMS.json` chỉ kiểm tra tính toàn vẹn bộ evidence này, không chứng nhận độc lập.
