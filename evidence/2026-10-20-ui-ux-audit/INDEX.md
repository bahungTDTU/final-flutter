# UI/UX acceptance —20/10/2026

Base `6fba5a6`, branch `codex/dashboard-motion-performance`, source local chưa commit.
Đã đồng bộ GitHub trước chỉnh UI; backup và safety stash lưu dưới tmp/Git local.

- [Báo cáo/phạm vi](../../docs/UI_UX_AUDIT_2026-10-20.md).
- [Baseline FAIL trước sửa](regression-before.txt):2 lỗi;2 probe responsive PASS.
- [Format/analyze/full suites](check.txt):132files0changes,320Flutter,152backend PASS.
- [Web QA build](build-web.txt), [APK debug compile](build-apk.txt).
- [HTTP sau browser](browser-api-after.json), [kết quả](result.json), [source hashes](source-manifest.json).
- [Chia sẻ English ACK và email rỗng](screenshots/sharing-en-success.png).
- [Lỗi tiêu đề phone sáng](screenshots/editor-phone-validation.png), [tối](screenshots/editor-phone-dark-validation.png).
- [Dashboard PC sáng](screenshots/dashboard-pc.png), [tối](screenshots/dashboard-pc-dark.png), [phone tối](screenshots/dashboard-phone-dark.png).
- [Editor màn hình ngang](screenshots/editor-landscape-dark.png).

Browser IAB dùng DB mẫu mới dưới tmp, mail/LLM workers tắt; chỉ loopback.
Chữ200% được kiểm tra bằng widget runtime. Không chạy native/FPS/provider/release/CI.
Secret/session/DB/login fixtures không đưa vào evidence. Không sửa bằng chứng cũ.
