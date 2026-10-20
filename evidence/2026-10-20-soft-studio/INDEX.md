# Soft Studio acceptance — 20/10/2026

Source local trên base 87f9e49, branch codex/soft-studio-refresh; chưa commit/push.

- [Báo cáo](../../docs/SOFT_STUDIO_UI_2026-10-20.md), [thiết kế](../../design-system/notetogether-deskbook/pages/soft-studio.md).
- [Flutter cuối](flutter-quality.txt): 134 format (0 changes) / analyze / 324 tests PASS.
- [Backend](backend-tests.txt): 152 PASS trên mã không đổi; [provenance](backend-provenance.json).
- [Web QA](build-web-qa.txt), [Web API 8000](build-web-local.txt), [APK debug](build-apk.txt).
- [HTTP sau đổi Ocean/English](api-after.json), [HTTP cuối với Iris/tiếng Việt](api-final.json), [browser privacy/console](browser-final.json), [kết quả](result.json), [source](source-manifest.json), [build hashes](artifacts.json).
- [Dashboard PC sáng](screenshots/final-dashboard-pc-vi.jpg), [tối](screenshots/final-dashboard-pc-dark.jpg).
- [Điện thoại](screenshots/final-dashboard-phone-vi.jpg), [tablet](screenshots/final-tablet-dark.jpg), [landscape](screenshots/final-landscape-en.jpg).
- [Editor PC sáng](screenshots/final-editor-pc-vi.jpg), [tối](screenshots/final-editor-pc-dark.jpg), [phone](screenshots/final-editor-phone-vi.jpg).

Browser dùng DB mẫu mới, API 8065 / Web 7384 loopback; providers tắt. Các tài khoản/nội dung
đều giả lập. Snapshot/source hashes không chứa key, session, password hay DB.
APK compile không thay native acceptance; không đo FPS hoặc đóng release gates.
[Kích thước ảnh](screenshot-dimensions.json): viewport phone yêu cầu 375×812; IAB chụp 375×811, giữ nguyên ảnh, không resize.

Evidence cũ giữ nguyên. Không push/merge/deploy trong lượt nâng cấp này.
