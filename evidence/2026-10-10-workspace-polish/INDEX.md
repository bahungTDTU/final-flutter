# Tập trung và rà soát UI/UX — 10/10/2026

Source: `codex/adaptive-word-editor`, HEAD/base
`a5e5ec60568b7ee2b0c50290a3e6502a4d490110` + working changes. Các sửa ordering/workspace
từ yêu cầu trước được giữ nguyên. Đợt này chưa commit/push; CI ở HEAD cũ không đại diện
working changes. [Chức năng và giới hạn](../../docs/WORKSPACE_FOCUS_AND_UX.md).

## PASS

| Kiểm tra | Lệnh/target | Kết quả và bằng chứng |
|---|---|---|
| Gate toàn bộ | `powershell -File scripts/check.ps1` | 242 Flutter, 109 backend, analyzer sạch; [check.txt](check.txt). Backend có 1 deprecation warning của pinned Starlette/httpx. |
| Source cuối | `flutter test`; `flutter analyze`; `dart format --output=none --set-exit-if-changed lib test integration_test` | 242 PASS; no issues; 102 files/0 changes: [tests](flutter-final.txt), [analyze](analyze-final.txt), [format](format-final.txt). Rerun sau sửa checkmark navigation; format cuối chỉ đổi whitespace. |
| Web QA release | `scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8034` | PASS, 40 static resources: [build](web-qa-final.txt), [SHA256](web-qa-hashes.json). |
| Web cấu hình mặc định | `scripts/build.ps1 -Target web` | PASS; API 8000, worker `notetogether-static-a14a7beb0c2c0f4a`: [log](web-default-final.txt). |
| Android compile | `flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8000` | PASS trên source cuối; [log](apk-debug-default.txt). Chỉ compile, không chạy emulator/thiết bị. |
| HTTP ACL thật | Python requests → FastAPI/SQLite riêng tại API 8034, providers disabled | Owner/viewer/editor/stranger, stale revision, locked edit 423, revoke và six-field projection PASS: [report](http-roles.json). |
| Checklist thật | Chrome click task → GET note trên API 8034 | checked task lưu thật, revision 2/content Markdown: [task-server.json](task-server.json). Tìm `kiểm tra` 0/1; nguồn shared 0/0; clear/all 2/3 với 3 kết quả. |
| Pomodoro thật | Chrome release 7364, `playwright-cli -s=nt-polish run-code --filename=timer-final.js` | Pause 04:58 → reload giữ 04:58 và goal 6 → resume/pause 04:56: [log](chrome-timer.txt). Không inject clock/storage vào browser. |
| Form/confirmation | Chrome, `forms-final.js`, `collection.js` | Empty title hiện lỗi inline và giữ mô tả; sửa title lưu được; cancel delete giữ mẫu; collection mới được chọn ngay, 1 matching note. [form](chrome-forms.txt), [collection](chrome-collection.txt). Disk failure/retry được test bằng widget/controller, không claim đã gây disk failure thật trong Chrome. |
| Responsive/theme | Chrome, `gallery-clean.js` | Light/dark, 1440×960 / 390×844 / 844×390 / 768×1024: [result](chrome-gallery.json). Hình chụp trực tiếp, không sửa ảnh. Landscape nội dung cuộn, ảnh là viewport. |
| Cache source cuối | Chrome CacheStorage đọc static-only, `cache-proof.js` | 1 cache QA `f148882c85eb7fb8`, 40 resources; main/bootstrap SHA256 khớp build, API8034 có/API8000 không: [proof](chrome-cache.txt). Không đọc session/account storage để chụp bằng chứng. |
| Console phiên cuối | `playwright-cli -s=nt-polish console` | 0 errors/0 warnings: [summary](chrome-console-final.txt). |

8 regression mới: durable reopen/pause/resume, deadline day khi reopen muộn, completion
retry/idempotence/stale ID, concurrency với draft/account switch, legacy/malformed timer,
form durable failure/retry/delete cancel-confirm, task search/scope/remote-lock privacy và
320px/text200%/keyboard/ticker isolation. Giữ frozen editor base, encrypted vault/recovery,
immutable outbox, không thêm API thay quyền. Tổng workspace tests: 27.

QA dùng SQLite và credentials test riêng ngoài repo, email/LLM disabled. Sớm trong phiên,
import nhầm executable fixture module đã re-seed **chỉ QA DB**; đã chạy lại toggle task và
đối chiếu GET revision2 bằng helper không import fixture. Không dùng kết quả trước re-seed
để claim task roundtrip cuối. Không sao chép DB/token/session vào evidence.

## Lỗi đã sửa và phạm vi

- Dropdown goal overflow 103px tại 320px/text200%: sửa `isExpanded`; regression PASS.
- Navigation chip checkmark đè icon: tắt checkmark; gallery cuối đã chụp lại.
- Web upgrade: worker cache mới lấy HTTP-cache main.dart.js cũ, gây gọi API8000 trong QA.
  Sửa install `cache:reload`, fetch tôn trọng reload/no-store, fingerprint gồm worker template,
  register `updateViaCache:none`. Upgrade chuyển đúng mã mới trong cùng phiên, không clear
  cache thủ công. Cache source cuối xác nhận riêng bằng SHA256. Hai connection-refused lỗi
  trước sửa không được gộp vào claim zero console của **phiên cuối**.
- Form validation/storage failure giữ input; delete có confirmation; collection lưu chọn ngay.
- Mobile/text lớn dùng dropdown có label; task query/status/source/progress và rows lazy.

NOT RUN: Android UI/IME/FPS cho source mới, physical device, screen reader thật, native
background/OS alarm, cloud sync timer/workspace, Gemini/SMTP Internet, public HTTPS/signing/
release/video/teamwork. Timer dựa đồng hồ hệ thống; completion hết giờ kiểm bằng tests, không
claim đã chờ phiên 5 phút kết thúc trong Chrome. Không tuyên bố đạt FPS mới hoặc sẵn sàng nộp.

Sau QA, Web/API trở về cấu hình mặc định; APK debug compile API emulator8000. QA servers/browser
do agent mở được dừng; source/evidence vẫn ở workspace. Source và artifact hashes trong
[manifest](manifest.json), được tạo sau khi hoàn tất docs và build cuối.

## Ảnh để kiểm tra

- [PC tập trung — sáng](01-focus-desktop.png), [PC tập trung sau reload — tối](15-focus-reload-dark.png).
- [Checklist lọc — PC](02-tasks-filter-desktop.png), [toàn bộ checklist — PC](03-tasks-all-desktop.png).
- [Form giữ input khi validation lỗi](04-template-error.png), [xác nhận xóa](05-delete-confirm.png), [collection vừa lưu](06-collection-selection.png).
- [Điện thoại tập trung — sáng](07-focus-mobile-light.png), [checklist — sáng](08-tasks-mobile-light.png).
- [Điện thoại checklist — tối](09-tasks-mobile-dark.png), [tập trung — tối](10-focus-mobile-dark.png).
- [Landscape](11-focus-landscape-dark.png), [tablet](12-focus-tablet-dark.png), [editor cùng theme](13-editor-dark.png).

Scripts ở đây ghi luồng QA quan sát được, cần fixture thích hợp/semantics đã bật; không tự chạy
trên dữ liệu thật. `tasks.js`/`tasks-again.js` là bước trước gallery; `timer-final.js` giả định
đang mở panel paused; `forms-final.js` mở template rồi kết thúc tại form collection. Lệnh CLI
ưu tiên `run-code --filename=...` để giữ chính xác escaping trên PowerShell.
