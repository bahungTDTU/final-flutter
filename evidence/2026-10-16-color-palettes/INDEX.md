# Evidence —6bảng màu giao diện,16/10/2026

Base4a196ef33019b38c6c2812fcbd48f05bf0d7d134; branch codex/dashboard-motion-performance.
Working changes/no new commit/push/merge/deploy. Giữ các đợt dashboard/nav/labels/song ngữ trước.
Skill người dùng: C:/Users/LENOVO/.agents/skills/ui-ux-pro-max/SKILL.md.
Query thiết kế đầu (skill-design-query.txt) trả marketing pattern, không áp dụng. Retry explicit
color trả Notes & Writing App/Productivity Tool; UX contrast và Flutter ThemeData được đọc.
Spec thủ công đã xác minh ở design-system/notetogether-deskbook/pages/color-palettes.md;
không overwrite Master hoặc dùng output chưa xác minh làm thiết kế.
PDF gốc đọc lại phần2.4UI/UX và rubric; tính năng bổ sung cho8/29, không tự cộng điểm hay đóng32.

## PASS —mã cuối

- `scripts/check.ps1` → **check-verified.txt**:129files0changes/analyze no issues,
  **308/308Flutter,147/147backend**.6Flutter/2backend regression mới; thêm ensureVisible
  vào test Settings cũ, giữ nguyên assertions và hành vi phải đạt.
- `flutter test test/color_palette_test.dart --reporter expanded` → palette-targeted-final.txt
  6PASS. Kiểm tra12theme/cache/distinct, text/surface/action/container/error contrasts,
  outline>=3; public/default/account/offline reopen, immutable operation trong request,
  picker320×640/844×390 chữ200% VI/EN sáng/tối, keyboard selected/account change,
  editor picker giữ cùng document/source/selection/title/frozen base7.
  Log targeted dùng hasFlag cũ; final full dùng flagsCollection, logic assertion giữ nguyên.
- Normal body/muted minimum theo palette(sáng/tối): Atelier4.93/5.35,
  Ocean5.62/7.69, Iris5.51/7.73, Rose5.60/7.43, Amber5.77/7.29, Forest5.69/7.33.
  Đây là tokens và surface đã kiểm, không chứng nhận mọi user rich-text colour hoặc screen reader.
- **backend-preferences.txt**:6/6 preferences tests; merge/replay/legacy client/schema/account/reopen.
  Included in147full. SDK fonts/XML và Starlette deprecation là warning, không làm gate thất bại.
- `flutter build web --release --no-web-resources-cdn --dart-define=API_URL=http://127.0.0.1:8063
  --output=tmp/palettes-web-2026-10-16` + prepare_web_offline.py → **build-web-qa-final.txt**.
- `scripts/build.ps1 -Target web` → **build-web-default-final.txt**:local API8000/40static resources.
  `flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8000` → **build-apk-final.txt**.
  These final artifacts follow the last Home/settings edit; not release signing/deployment.
- Actual HTTP8063 fresh SQLite under ignored tmp; mail DisabledDelivery and LLM keys empty.
  **api-roles.json**:owner/editor/viewer/stranger/anonymous, attachment hash/replay,
  lock423/viewer403/revoke404. **api-palettes.json**:all6IDs/schema422/anonymous401,
  changed replay409/old replay cannot undo new choice, legacy PATCH retains palette+locale,
  account isolation, note array identical across palette requests, locked listing redacted.
- Actual IAB7382 **browser.json** + screenshots/txt:Atelier initial,5alternatives selected;
  light/dark preview and application chrome, VI/EN; PC1280×1000,tablet768×1024,
  phone375×812,landscape844×390. Phone menu opens gallery, scroll reaches last options,
  choosing Amber works. Editor draft survives palette/language/resize; HTTP accepts body/title,
  forest then amber/dark/en server ACK; query Kế hoạch retained after selecting Iris.
  Reload restores Iris/dark/en, locked fixture PALETTE_PRIVATE not in DOM.
  **browser-server-ack.json**, **browser-reopen-ack.json** prove server state and unchanged
  note array after UI palette roundtrip/reopen. **browser-errors.json** empty in last20entry scope.
  Phone images are Web; browser matrix is scoped, not every palette×viewport×locale cross product.
- README/Readme identical; STATUS/matrix/UI docs/architecture/preferences and new report/spec synced.
  git diff --check PASS. Cleanup stops only own backend/Web helpers; own tab closed/viewport reset.

## Initial FAIL / diagnostics retained

- analyze-initial.txt:1curly lint in catch; corrected. check.txt:4test lints
  (print/nested for braces/deprecated semantics API); corrected to debugPrint/braces/flagsCollection.
- palette-targeted.txt:4PASS2FAIL. Keyboard fixture lacked production scroll parent, causing
  1px overflow; selected state was on a separate semantics node. Match the real scroll parent
  and merge semantics into the native button, keep selected assertion. Editor test sampled
  document.source before the bridge processed the edit; pump edit first, preserve equality/base checks.
- check-final.txt:307PASS1FAIL; old settings test clicked dark toggle below visible area after gallery
  insertion. Move dark toggle before palette gallery for usability; ensureVisible before test tap.
  check-verified.txt confirms the final behavior and all original assertions pass.
- Build logs without final suffix predate the last settings placement edit, are intermediate only.
  Final builds and source hashes are captured separately. No sealed old evidence was overwritten.

## NOT RUN / OUT OF SCOPE

Android device inventory available to this run is empty (android-devices.txt); native UI/IME/OS
lifecycle/picker/screen reader/TalkBack/NVDA and profile GPU/FPS NOT RUN. APK debug is compile only.
Chữ200% là widget test, không browser/system scaling. SMTP/Gemini thật, hosted CI newest-head,
HTTPS/public release/video/submission NOT RUN. Không đổi schema note, permissions/protection,
AI output/email language hoặc user rich-text colours. Không push/merge/deploy; release vẫn để sau cùng.

capture_manifest.py kiểm tra bảy snapshot đã seal, ghi source/docs/build hashes và seal folder này.
Integrity chỉ chứng minh bytes, không thay tests/FPS/native/provider acceptance.
