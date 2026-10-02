# UI redesign evidence · 01/10/2026

Đọc docs/UI_UX_DESIGN.md và docs/UI_UX_QA.md để phân biệt design/code/integration/verification.
Commit: chưa có. Disposable local test accounts; không tài khoản chấm, token hoặc dữ liệu riêng tư.

| Artifact | Lệnh / scenario | Actual |
|---|---|---|
| checks.txt | `powershell -ExecutionPolicy Bypass -File scripts/check.ps1` | Format/analyze sạch,37 Flutter/14 backend PASS; 1 existing warning |
| android-integration.txt | Flutter native integration exact command trong UI_UX_QA | 1 PASS với HTTP và Sembast thật |
| android-debug-build.txt | Flutter debug `-t lib/main.dart --target-platform android-x64` | PASS; main app install/launch/login smoke |
| web-build.txt | `scripts/build.ps1 -Target web` | PASS,41 static resources; includes fonts, no API/private cache |
| apk-build.txt | `scripts/build.ps1 -Target apk` | PASS51.9MB; không functionality release claim |
| contrast.json | `.venv/Scripts/python.exe scripts/check_ui_contrast.py` | 14 foreground/background pairs đạt min riêng |
| before/after-*.png | Playwright CLI sessions preferences/ui-new/ui-final, real Chrome | Actual browser render, same-size auth/home/editor/settings comparisons |
| android-*.png | adb install/launch/input; screencap then pull | Actual emulator main debug,720×1280 và540×1200 physical/density240 (=480×853.3 và360×800 logical), chưa physical device |
| web-state-before/after.json | `verify_web_state.py before` / `after` | Real SQLite: ID giữ nguyên,3 notes, pin và exact offline content PASS |

Browser screenshot sizes theo tên: desktop1280×800, mobile390×844, tablet768×1024, DPR1.
Screenshot dark/light theo tên, text scale100%. Widget tests scale150/200% không được gán thành
browser screenshot scale200%. Các ảnh trước/sau là render thật; không tạo/sửa ảnh bằng AI.

Browser commands thực dùng: `npx --yes --package @playwright/cli playwright-cli -s=SESSION`
`open`, `resize`, `snapshot`, `fill`/`type`/`press Enter`, `click`, `screenshot --filename=...`.
Enable Flutter accessibility placeholder qua eval; service worker update qua run-code khi build thay;
switch trong sheet dùng force click do semantics overlay. Ref stale sau pin đã refresh và chụp lại.
Native screenshot có auth/home; integration source giữ critical editor/persistence/preference flow.

Không public HTTPS/email/AI/video/commit/contribution hay full32 completion. Logs tests-first,
responsive-first/second/final là các lượt phát hiện lỗi trước sửa; kết quả chốt ở checks.txt.
