# Email durable queue — 06/10/2026

Base HEADaded41ec0ccdbfb46cae579b64ef3eab004f68bf + working changes. Mã AI/protection trước đó
giữ nguyên; đợt này bổ sung email outbox/status/resend. Không commit/push/deploy, không mua
dịch vụ hoặc build release; người dùng yêu cầu release để cuối. 2/4/30 liên quan theo matrix,
không full rubric/public/production acceptance.

## Hành vi

- Register/resend persist token+job trong transaction rồi trả queued; worker SMTP ngoài
  request/DB transaction. Verify/reset vẫn one-time/TTL30min/session revoke/manual login.
- Nonce32byte + HMAC-SHA256 private server key/user/kind→code43chars; DB token digest +
  nonce/metadata, no raw code/key. Disabled SMTP không tạo jobs/key. Key missing/corrupt
  sau restart giữ job/fail-closed; public reset không lộ known/unknown dù enqueue key lỗi.
- Lease120s/serialized claim/multi-worker guard, at-least-once same-code retry;15/60/180/600/
  900s backoff/max6 claim attempts, kể cả crashed final claim. Invalidated/expired/used job
  không gửi tiếp; in-flight mail có thể tới muộn nhưng code không sử dụng được.
- Authenticated own email-status; UI check trạng thái và public reset request-resend/email
  input/cooldown. Account switch bỏ late status. Unverified vẫn dùng notes.

## Lệnh / kết quả

| Command / target | Result |
|---|---|
| scripts/check.ps1 | check.txt: format/analyze sạch,146 Flutter PASS,87 backend PASS trước thêm actual TLS queue regression |
| pytest backend/tests -q --tb=short | backend-current.txt:88 PASS/1 TestClient deprecation warning, gồm9 queue cases sau lease-limit refinement |
| flutter test test/email_flow_test.dart | flutter-email-final.txt:7 PASS (3 regressions mới), actual queue-status response/generic reset-resend/late account; existing error/reset/200% cases |
| flutter analyze + format after native/pub get | analyze-current.txt sạch; no generated registrant manual edits |
| pytest backend/tests/test_email_queue.py backend/tests/test_email.py -q | queue-tls-final.txt:16 PASS sau fix fixture classification; actual STARTTLS reject→retry→receipt→verify/reset check + DB/key/restart/races |
| python scripts/qa_email_queue.py / API8011 + SMTP8025 | http-current.txt/json PASS after reload final backend: real HTTP queued/private status/TLS receipt; owner/viewer/editor/stranger direct notes ACL while unverified; one-time verify/public reset equality/session revoke/manual login |
| flutter drive --driver=test_driver/email_queue.dart --target=integration_test/email_flow_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8011 --enable-software-rendering --no-enable-impeller | android-final.txt:1 actual scenario + teardown PASS13s. Real backend/Sembast/device keys/STARTTLS sink/UI status/banner/verify/password2x/manual login; emulator API36 debug, not physical/release |
| flutter run -d web-server --web-hostname127.0.0.1 --web-port7361 --dart-define=API_URL=http://127.0.0.1:8011 | Web debug local + IAB actual login/status/verify/banner disappears/public reset-resend/cooldown. web-send-status.png/web-verified.png/web-reset-resend.png. Password-reset final submission done in native/API; Web password completion historical, not rerun here |

Window host Flutter3.47.1/Dart3.13.1/Python3.12; Android taskflow_api36 Skia software. Exact
spaced commands/fixture startup/CORS/adb reverse in README/docs/EMAIL_DELIVERY.md.
Transport is actual network SMTP STARTTLS localhost with QA certificate/sink, not Internet
provider/inbox. All accounts disposable @example.test; fixture code endpoint explicit QA flag,
no production raw-code endpoint. Smtp transport validates CA/hostname, no plaintext bypass.
Private keys/codes/session data kept under ignored tmp/state, never copied to this evidence.

## Failure history

- First analyze found1 curly-braces lint in integration polling; fixed, final clean.
- First native/emulator attempt lacked ANDROID_AVD_HOME, no device; correct existing
  D:/Android/avd used. Final hidden launcher15316, no permanent SDK flags changed.
- Async reset exposed fixture reader matching reset instructions inside old verify body:
  http-fixture-first-failure.txt/native first android-debug.txt retain400/wait failure. Reader
  now classifies Subject; regression asserts reset lookup returns none until reset mail received.
- HTTP fixture queue under concurrent load exceeded helper4s wait; http-queue-load-timeout.txt
  preserves failed probe. Bounded helper20s, final actual probe PASS. No production timeout/
  KDF/rate-limit loosened to hide a failure.
- First targeted backend pass logged Pytest cache permission warning; final outside-sandbox
  backend/current cache handled, remaining1 warning is upstream TestClient deprecation.

## Limits and integrity

No Internet SMTP receipt, Gmail/Outlook, real Gemini, production key/backup/worker operation,
public HTTPS, native release acceptance, physical/OS force-kill, screen-reader or full rubric
claim. Real library HMAC/SQLite/file + restart tests; transport/race doubles labelled in tests.
No exactly-once email guarantee or secure erase of SQLite pages/backups. Server HMAC key is
separate from existing encrypted device/account vault key; Windows folder ACL remains deployment
responsibility. Backup key lifecycle documented, not implemented as new device backup feature.

QA tab đóng; API8011/TLS sink8025/code reader8026 và Web debug7361 được dừng. Emulator
launcher15316/child25572 đã dừng đúng path D:/Android/sdk/emulator; không đụng thiết bị khác.
Git ignore của state-key/tmp và *.mail-key đã kiểm tra; known Gemini-key-pattern scan của
tracked/nonignored text không có match, không đọc private credential files, không comprehensive audit.

Source/docs/evidence hashes in source-manifest.json; collect_manifest.py --verify checks bytes/
README equality only, no tests rerun. No new release build included: artifacts from05/10 are
historical and were deliberately not rebuilt. Docs/matrix/STATUS describe this scope separately.
