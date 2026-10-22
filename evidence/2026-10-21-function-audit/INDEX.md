# Functional audit — 21/10/2026

Snapshot local sau pull `26636e6` trên nhánh `codex/full-function-audit`; chưa commit/push.

- [Báo cáo](../../docs/FUNCTIONAL_AUDIT_2026-10-21.md).
- [Baseline Flutter](flutter-baseline.txt), [backend 152](backend-baseline.txt), [dependencies offline/lock](dependencies.txt).
- [Probe trước sửa: 3 FAIL / 2 PASS](regression-before.txt), [nhóm liên quan sau sửa: 39 PASS](regression-after.txt).
- [Toàn bộ Flutter cuối: 329 PASS, analyze sạch](flutter-final.txt).
- [Web QA](build-web.txt), [APK debug](build-apk.txt), [build hashes](artifacts.json).
- [HTTP 4 roles](protected-http.json), [HTTP hồ sơ/catalogue/SSE](catalogue-http.json).
- [Xóa từ phiên peer](peer-delete.json), [kiểm tra bản phục hồi trên server](browser-api-final.json), [reload/console](browser-checks.json).
- [Ảnh trước xóa](screenshots/01-draft-before-delete.jpg), [dialog phục hồi](screenshots/02-recovery-dialog.jpg), [draft phục hồi](screenshots/03-restored-draft.jpg).
- [Bản lưu PC](screenshots/04-recovered-saved-pc.jpg), [phone](screenshots/05-recovered-saved-phone.jpg), [reload phone](screenshots/06-reloaded-phone.jpg).
- [Kích thước ảnh](screenshot-dimensions.json), [source hashes](source-manifest.json), [kết quả/phạm vi](result.json).

Dùng DB mới, API8071/Web7385 loopback và tài khoản giả; không SMTP/LLM Internet.
Ảnh giữ nguyên byte; phone yêu cầu375×812 nhưng IAB chụp375×811. Logs build có cảnh báo
font Cupertino và SDK XML; build hoàn tất, không nâng cấp SDK/dependencies trong lượt này.
Backend suite có Starlette/httpx deprecation warning, không có test fail.
Build APK không phải nghiệm thu native/FPS/release. Evidence lịch sử giữ nguyên.
SHA256SUMS.json bảo toàn các payload trong snapshot này.
