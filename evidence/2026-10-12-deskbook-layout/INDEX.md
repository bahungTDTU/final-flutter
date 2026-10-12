# NoteTogether Deskbook — nghiệm thu12/10/2026

IMPLEMENTED: bố cục mới theo ui-ux-pro-max người dùng yêu cầu. PC có masthead ngang,
library/bookmark ở trung tâm và ngăn công cụ bên phải; editor có tab Trang viết và
drawer mục lục/thông tin riêng. Phone dùng toolbar một hàng ở chữ thường/menu công cụ.
[Thiết kế](../../docs/UI_DESKBOOK.md), [spec](../../design-system/notetogether-deskbook/MASTER.md),
[30 ảnh Chrome](GALLERY.md).

Branch `codex/ui-system-refresh`, base HEAD `f3b17a3d33e5d432320e1d8620f87d7fc33b30d3`.
Working changes chưa commit/push/merge. Source cuối/hash trong source_manifest.json;
QA local không thay CI hosted, native runtime, deployment hoặc submission.

## PASS

- Format112files0changes, analyze0issues,270 Flutter: `flutter-checks-accepted.txt`.
  `scripts/check.ps1` chạy full Flutter/backend tại `checks-final.txt`:118 backend PASS.
  Sau đó chỉ thêm tooltip UI/điểm kiểm tra tooltip; backend/controller/data/dependencies
  không đổi, Flutter suite chạy lại trên source cuối. Không hạ/sửa tests cũ để pass.
- Ba regression mới trong `test/deskbook_layout_test.dart`: desk/rail/phone giữ query và
  label selection; menu phone mở workspace thật; toggle editor giữ rich selection,
  draft và base_revision7, theme/resize không thay document controller. Existing tests
  privacy/revoke/recovery/order/large text tiếp tục PASS.
- Web release build cho QA API8058: `build-web-accepted.txt`. Chrome loopback7376,
  DB mới `tmp/deskbook-20261012.sqlite`, dữ liệu tổng hợp9notes/4labels/4roles. Gemini/
  email tắt, không dùng DB/tài khoản production, không lưu auth token vào evidence.
- Chrome7viewport:320×740,390×844,768×1024,844×390,1180×800,1440×600,1440×1000,
  hai theme. `browser-home-accepted.txt`, `browser-dark-home-accepted.txt`.
  Ảnh editor bình thường/mở rộng và phone; theme/resize giữ title, autosave HTTP200:
  `browser-editor-accepted.txt`. API xác nhận title chính xác/content/pin/share:
  `api-roundtrip-accepted.json`.
- Gate/reader bảo vệ: private title ẩn trước grant; relock loại title/content khỏi UI.
  `browser-unlock-accepted.txt`, `browser-relock-accepted.txt`. Role API: viewer write403,
  stranger read404, locked read423, locked list chỉ6public fields: `api-role-check.json`.
- Nút mẫu/workspace trong ngăn bàn và workspace trong menu phone mở route thật;
  đích AI có UI PC/phone, không gọi provider: `browser-navigation-accepted.txt`.
  Kết quả cuối không có page/console error trong phạm vi monitor đã bật.
- `browser-cache-accepted.txt`: worker `notetogether-static-460dba34d3053b8b`,40static
  resources, cache main/bootstrap SHA256 khớp network; không auth/me/notes cache paths.
  `contrast.json`:9cặp token đại diện min4.93:1, không full rendered WCAG audit.
- Android debug compile source cuối: `build-apk-accepted.txt`; không cài/chạy/ký release.
  Web được build lại cho API8000 tại `build-web-default.txt`. artifacts.json tách build
  mặc định khỏi hashes Web mà Chrome thực sự kiểm tra.
- Đóng Chrome/server thuộc lượt này: `cleanup.json`. README/Readme.txt đồng bộ byte.
  Snapshot ui-system-refresh và atelier-ui giữ nguyên, kiểm tra integrity riêng.

## Các lỗi đã xử lý và giới hạn

Masthead từng tràn ở1180: cấp chiều rộng linh hoạt cho các destination. Inspector cần
Material để ListTile vẽ ink đúng. Phone menu từng xuống một hàng thừa: dùng Row linh
hoạt ở chữ thường và Wrap ở chữ lớn. Tooltip quản lý nhãn được giữ cho integration cũ.

Một script QA gọi unlock khi chưa mở gate; một script tìm button Ghi chú trên phone
trong khi navigation là tab. Sửa thứ tự/locator, chạy lại accepted và ghi đè ảnh QA
hiện hành bằng ảnh đúng màn hình. Các lỗi locator là lỗi script, không được dùng làm
kết quả PASS. Log browser-navigation.txt giữ lỗi trước sửa; accepted mới là kết quả cuối.

NOT RUN: Android runtime/native keyboard/IME, FPS/profiling, screen reader, provider/
SMTP/cloud thật, HTTPS/release signing, CI/approval/merge và video/submission.
Ảnh phone là viewport Web. Theme cache/lazy/reduced-motion được giữ; không suy ra mức
tăng FPS/RAM từ widget tests hoặc compile. Không tự chấm điểm sáng tạo.

## Tái lập

Chạy `qa_server.py --db tmp/<new-file>.sqlite`, `qa_seed.py`, Web build API8058 và
http.server7376. Seed là tài khoản/password tổng hợp, tokens chỉ ở RAM. Các browser*.js
chạy bằng `npx --yes --package @playwright/cli playwright-cli -s=deskbook-ui run-code
--filename ...` tại đúng trạng thái UI được ghi. Read snapshot khi đổi route/menu/size;
phone destinations dùng tab, PC dùng button. Không dùng các fixture với tài khoản thật.

`record_manifest.py`: source/artifact/evidence hashes; `verify_manifest.py`: current
source/default build/APK và integrity ba snapshots. Không chạy lại manifest source cũ
để giả lập acceptance cho source mới; không stage `.agents/` hoặc tự push/merge.
