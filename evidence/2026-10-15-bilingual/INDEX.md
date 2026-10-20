# Evidence —giao diện Việt–Anh,15–16/10/2026

Base `4a196ef33019b38c6c2812fcbd48f05bf0d7d134`, branch
`codex/dashboard-motion-performance`; working changes, no new commit/push/merge.
Bắt đầu15/10, tiếp tục16/10 theo người dùng. UTC trong JSON là thời điểm thực.
Giữ nguyên ba đợt dashboard/navigation/label-manager đang chưa commit và các evidence đã seal.

## PASS trên mã cuối

- `dart format --output=none --set-exit-if-changed lib test integration_test test_driver`,
  `flutter analyze`, `flutter test` → **frontend-verified.txt**:125files0changes,
  no issues, **302/302**.125 gồm source và tests, không phải số màn hình.
- Backend **145/145**, **check-final.txt**, lệnh `scripts/check.ps1`; cùng backend/app.py
  và backend/tests/test_preferences.py với mã cuối. Sau đó chỉ đổi UI/l10n/test Flutter;
  không chạy lại backend không đổi. Đây là các gate kết hợp, không nói check-accepted.txt PASS.
- 7 test mới trong localization_test: resource/placeholder/không dịch dữ liệu đối số,
  lỗi UI lồng nhau đổi hai chiều, public offline reopen/account queue isolation,
  mid-flight immutable locale operation, validator đổi locale giữ input, rich editor
  document/selection/title/base7, query/layout hai theme/privacy và English360px/chữ200%.
- feedback-final.txt:25test locale/avatar/attachments PASS; mobile-editor-final.txt:
  31test locale/UI redesign PASS. Các run này nằm trong full302 cuối.
- `flutter build web --release --no-web-resources-cdn --dart-define=API_URL=http://127.0.0.1:8062
  --output=tmp/bilingual-web-2026-10-16` + prepare_web_offline.py → **build-web-verified.txt**.
- `scripts/build.ps1 -Target web` → **build-web-default-verified.txt**; bản chạy thường API8000,
  40static shell resources. `flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8000`
  → **build-apk-verified.txt**. Không phải release signing/deploy/native runtime.
- Actual HTTP8062, fresh SQLite ignored tmp, DisabledDelivery/LLM keys empty:
  **api-roles.json** owner/editor/viewer/stranger/anonymous; private attachment hash/replay,
  grant423/viewer403/revoke404. **api-locale.json** anonymous401/invalid422/idempotency409,
  legacy PATCH giữ locale/old replay không đảo lựa chọn mới/account isolation,
  note array trước-sau identical, locked listing redacted.
- Actual IAB7380: **browser.json**, các screenshot/txt, **browser-server-login.json**,
  **browser-server-draft.json**. Đăng nhập English nhận ACK; reload giữ locale; gõ body tiếng Việt,
  chuyển VI→EN và resize giữ title/body, HTTP xác nhận body/revision. Settings đổi locale/theme,
  tìm “Kế hoạch” giữ qua đổi locale. PC1280×1000/phone375×812 sáng và tối,
  landscape844×390 tối. Final build xác nhận editor mobile có icon translate hoạt động,
  reading-time copy mới, home EN thẻ khóa dịch đúng/không chứa LOCK_PRIVATE trong DOM.
  browser-errors.json rỗng trong phạm vi log20entries. Phone screenshots là Web.
- docs/BILINGUAL_UI.md/PREFERENCES_SYNC/README/Readme/STATUS/matrix/architecture/UI QA/roadmap
  cập nhật. README và Readme byte-identical. git diff --check PASS (chỉ cảnh báo line endings).

## Các lỗi trung gian đã sửa / giới hạn evidence

- check.txt:8FAIL trong301Flutter; backend chưa chạy vì gate dừng. Editor initState đọc
  Localizations khi mở restored draft gây assertion; sửa giữ canonical feedback và dịch ở build.
  Auth dropdown tràn ở chữ150/200%; sửa menu icon. regression-final.txt62PASS sau sửa.
- localization-targeted.txt dùng sai fixture key search-notes; sửa đúng note-search.
  Hai localization-accessibility logs đầu dùng sai tooltip rồi pageBack với bottom sheet;
  sửa harness dùng Profile & preferences/Close preferences, không nới assertion.
- build/analyze/flutter-initial: thiếu import design_system.dart và lint trung gian đã sửa.
  backend-preferences.txt lỗi quyền TEMP sandbox; workspace --basetemp cho4test PASS.
  Cuối15/10 lệnh chưa chạy do automatic approval review hết usage;16/10 chạy lại thành công.
- Browser phát hiện helper của locked preview còn VI và menu Ghim không dấu bị scan bỏ sót;
  sửa dịch đúng cờ locked, không dịch note thường. Rerun locked-translation đầu có duplicate
  resource/mistyped test filename và test tìm widget ngoài lazy viewport; đã sửa harness,
  localization-regression-complete.txt31PASS, full302 cuối gồm regression privacy này.
- check-accepted.txt còn1FAIL/avatar do bỏ prefix thông báo cũ; đã khôi phục prefix canonical,
  dịch riêng nested friendlyError tại hai ranh giới feedback cho phép. feedback-final và full302 PASS.
- Các build/test có tên initial/final/accepted là lịch sử trung gian; **verified** là gate
  cuối sau icon editor điện thoại. File manifest/artifacts chốt các bytes tương ứng cuối.
- Khi thay build tại cùng origin, offline shell cần nhận worker mới rồi tải lại để hiện mã mới.
  QA đã xác nhận copy mới và icon mobile trong bản verified; không suy đoán từ reload đầu.

## NOT RUN / OUT OF SCOPE

Android inventory16/10 không có thiết bị. Chưa chạy Android runtime/OS relaunch/IME/picker,
TalkBack/NVDA/screen-reader thực, profile GPU/FPS, SMTP Internet/Gemini thật/HTTPS/public release,
CI latest-head/video/Rubric packaging. Chữ200% được xác minh bằng widget test, không giả
hệ thống/browser scaling. Chỉ dịch UI, không tự dịch ghi chú/nhãn/mẫu cá nhân/AI/email provider;
mẫu built-in chỉ dịch mô tả/chọn mẫu, body giữ dữ liệu gốc. Public release vẫn để sau cùng.

cleanup.json: dừng đúng hai helper QA, đóng tab riêng/reset viewport, không dừng dịch vụ người dùng.
capture_manifest.py xác minh sáu snapshot cũ, source/docs/artifacts và seal folder này.
Hash integrity chỉ chứng minh bytes, không thay thế thực thi tests hoặc FPS.
