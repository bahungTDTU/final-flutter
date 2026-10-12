# Editorial Atelier — nghiệm thu12/10/2026

IMPLEMENTED: UI mới theo yêu cầu “độc đáo, hiện đại, sang trọng” qua ui-ux-pro-max.
Branch `codex/ui-system-refresh`, base HEAD `f3b17a3d33e5d432320e1d8620f87d7fc33b30d3`;
working changes chưa commit/push/merge. Source cuối trong source_manifest.json;
đây là QA local, không phải hosted CI hoặc một release/submission mới.

[38 ảnh Chrome](GALLERY.md), [thiết kế](../../docs/UI_ATELIER.md),
[spec đã chọn](../../design-system/notetogether-atelier/MASTER.md).

## PASS

- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1`:
  format110files0changes, analyze0issues,267 Flutter/118 backend. `checks-accepted.txt`.
  Năm tests mới: pinned shelf/privacy hai theme, large text fallback, icon contrast,
  secondary text>=4.5:1. Existing editor/Home/private/outbox tests giữ nguyên.
- `scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8058`: Web release compile,
  QA worker `notetogether-static-0e3ad002402461f2`,40static assets. `build-web-accepted.txt`.
  Cache/main/bootstrap SHA256 khớp network build, không có auth/me/notes cache paths:
  `browser-cache-final.txt`. Chrome chỉ kết nối loopback8058/7376, DB mới trong tmp;
  Gemini/SMTP tắt và không ghi token vào evidence.
- Chrome thật:320×740,390×844,768×1024,844×390,1440×1000; dashboard cả sáng/tối.
  Auth, editor hai theme/phone, AI, chín mục workspace, planner/focus phone, profile,
  Security Center, protected gate/reader. `browser-home-final.txt`, `browser-dark-home.txt`,
  `browser-workspace.txt`, `browser-ai.txt`, `browser-profile.txt`, `browser-security.txt`.
  Không có page/console error trong kết quả QA cuối. Đây là viewport Web, không Android UI.
- Nhập title qua bàn phím, đổi theme/resize giữ draft, autosave HTTP200; API đối chiếu
  title chính xác/original content/pin/shared. `editor-accepted.txt`, `api-roundtrip.json`.
  Gate ẩn private title trước grant; khóa lại loại title/content. `browser-unlock.txt`,
  `browser-relock.txt`. Server locked projection chỉ6public fields. `api-role-check.json`:
  owner/editor đọc, viewer write403, stranger read404, locked read423.
- `contrast.py`: chín cặp token chính min4.93:1. `contrast.json`. Không full WCAG audit.
- `flutter build apk --debug --dart-define=API_URL=http://127.0.0.1:8000`:
  Android debug compile13.4s. `build-apk-debug.txt`; không cài/chạy/ký release.
- Web mặc định API8000 build lại ở `build-web-default.txt`; artifacts.json tách hashes
  mặc định khỏi cache của QA. Backend/controller/data/dependencies không có diff.

## Các lỗi đã xử lý và giới hạn

Header eyebrow tràn chữ200%: cho text co và xuống dòng theo available width. Icon “+”
phone bị chìm: explicit onPrimary/primary. Muted text/high container4.17:1: chỉnh màu
và thêm regression. Không hạ assertion hoặc sửa tests cũ để pass. Script browser đầu
gọi theme button trên mobile trong khi action nằm trong menu; script sửa dùng menu thật.
Script cache đầu dùng Request.url() thay vì .url; lỗi QA script đã sửa. Các raw log trước
acceptance giữ lại, không dùng để tuyên bố PASS.

NOT RUN: Android runtime/native keyboard/IME, screen reader, FPS/profiling, provider/
SMTP/cloud thật, HTTPS/release signing, CI/approval/merge và video/submission.
Widget tests chữ200%/keyboard/remote-lock không thay cho native hoặc assistive testing.
Cache theme/lazy/giảm painter là implementation; chưa đo mức tăng FPS hoặc RAM.
Snapshots cũ gồm ui-system-refresh giữ nguyên byte; hashes nguồn cũ chỉ thuộc source cũ.

## Tái lập và integrity

Khởi động `qa_server.py --db tmp/<fresh-name>.sqlite` chỉ chấp nhận file DB mới trong tmp;
chạy `qa_seed.py`, build Web API8058, phục vụ build/web tại loopback7376. Fixtures tổng
hợp và passwords thử có trong seed, không dùng với tài khoản thật. Các browser*.js chạy
qua `npx --yes --package @playwright/cli playwright-cli -s=atelier-ui run-code --filename ...`
tại đúng bước UI đã ghi; locator được đọc từ snapshot thật. Không trộn DB production.
Sau QA đóng browser/server thuộc lượt này. Không stage `.agents/` của người dùng.

source_manifest.json: source/normalized-LF hash và base/branch thực;
artifacts.json: QA/default build và Android compile;
SHA256SUMS.json: integrity của evidence này. Evidence snapshots lịch sử không được ghi đè.
