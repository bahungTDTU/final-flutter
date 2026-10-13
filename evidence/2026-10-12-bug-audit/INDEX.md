# Bug audit —12/10/2026

[Báo cáo 7 nhóm lỗi và phạm vi](../../docs/BUG_AUDIT_2026-10-12.md).
Branch `codex/bug-audit-fixes`, baseline `46df286`; source là working changes chưa commit/push.

## Nghiệm thu source cuối

- [Format](format-accepted.txt), [analyze](analyze-accepted.txt),
  [275 Flutter](flutter-accepted.txt), [full gate/backend 119](check-accepted.txt).
- [API roles/ranges](api-roles-ranges-accepted.json): HTTP thật, fixture tổng hợp 4 vai trò.
- [Chrome layout](browser-layout-final.txt), [find/realtime](browser-find-final.txt),
  [remote lock và DOM input purge](browser-hide-final.txt), [static cache](browser-cache-final.txt).
- [Web QA build](build-web-accepted-final.txt), [Android debug compile](build-apk-debug.txt).
- [Ảnh](GALLERY.md), [hash artifact QA](qa-artifacts.json), [source](source_manifest.json),
  [SHA256 evidence](SHA256SUMS.json). `verify_manifest.py` kiểm tra snapshot và 3 UI snapshots cũ.

## Tái hiện

Chạy `scripts/check.ps1`; với pytest dùng basetemp mới dưới workspace nếu temp Windows bị
hạn chế. Tests mới: `test/bug_audit_regression_test.dart`, `backend/tests/test_attachment_ranges.py`.
Browser QA: build Web với API 8058, `qa_server.py --db tmp/<fresh-file>.sqlite3`, phục vụ
build/web tại loopback 7376, chạy `qa_seed.py`, `qa_api.py setup`, rồi các `browser-*.js`
bằng Playwright CLI `run-code --filename`. Bật Flutter accessibility, login fixture,
mở note “Thiết kế NoteTogether” trước layout/find/hide. Token chỉ trong RAM.

Failures giữ nguyên: `flutter-before.txt`, `backend-before.txt`, `flutter-role-before.txt`,
`flutter-private-before.txt`, `browser-private-dom-before.txt`. Files `*harness*`/
`browser-cli-invocation-error.txt` là lỗi locator/cú pháp QA, không tính là bug ứng dụng.
Các logs/source giữa đợt được giữ để phân biệt với `*-final`/`*-accepted`.

Đã dùng server/DB tổng hợp riêng. Chưa chạy native UI/IME/FPS, screen reader, provider,
release/deploy/submission hoặc CI mới; không suy các kết quả đó từ widget/build/ảnh Web.
