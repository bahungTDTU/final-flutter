# Encrypted recovery evidence — 01/10/2026

Workspace D:/flutter cuoi ki, Windows11; Flutter3.47.1/Dart3.13.1/Python3.12.
Local Git chưa commit/remote; không có commit ID. Fixture accounts/nội dung dùng cho test, không production.

| Command / target | Result / log |
|---|---|
| powershell -ExecutionPolicy Bypass -File scripts/check.ps1 | PASS format/analyze,60 Flutter tests +14 FastAPI/SQLite tests,1 deprecation warning; checks.txt |
| flutter test integration_test/encrypted_recovery_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000 | PASS1 real API + platform key storage + UI + DB close/reopen; android-recovery.txt |
| flutter test integration_test/note_flow_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000 | PASS1 baseline encrypted store/offline/reopen/notes/preferences; android-baseline.txt |
| powershell -ExecutionPolicy Bypass -File scripts/build.ps1 -Target web | PASS release/static worker,41 resources; web-build.txt |
| powershell -ExecutionPolicy Bypass -File scripts/build.ps1 -Target apk | PASS52.0MB; apk-build.txt; debug-signed scaffold, build ≠ release core HTTPS acceptance |

Android emulator API36, adb reverse tcp:8000 tcp:8000, debug HTTP. Reopen cùng test process;
không force-kill/physical-device/biometric/backups. Unit key/HTTP/fault adapters là doubles;
AES-GCM và Sembast file/migration/compaction trên Windows dùng thư viện thật.
Recovery integration có cả invalid draft qua GET locked và valid upsert queued khi port65530
không lắng nghe, bị real API423 sau second-session lock. Unit test bổ sung423 + list failure
và editor clear/cancel autosave; không claim network-list failure trên hai thiết bị thật.

## Chrome real browser flow

Playwright CLI session vault, Chrome local release http://localhost:7357:
register → online note acknowledged → setOffline(true) → title trống + body mới → local draft.
scripts/verify_web_recovery.py lock tạo session API thứ hai và khóa source; browser vẫn offline.
Toolbar Back → offline reload → vẫn có draft → online/sync archive → online reload → recovery1.
Phục hồi → Bản chỉnh sửa đã giữ → draft UUID mới → điền title → auto-save → server copy mới.
scripts/verify_web_recovery.py verify kiểm tra exact content/title, count2, ID khác, source GET423.

- web-lock.json / web-verify.json có actual UTC time, ID và boolean assertions, không token/key.
- web-storage.txt đọc account envelope từ IndexedDB: version1, fields envelope, plaintextLeak=false.
- web-locked.png: card neutral, recovery count, owner tab1; không title/content/labels source.
- web-restored.png: editor copy dưới ID mới, body fixture đã phục hồi.
- web-mobile-final.png:390x844 sau update/reload build cuối; banner/copy/nav vừa viewport, đã xem ảnh.
  web-mobile.png là capture ngay resize bị lệch tỷ lệ, không dùng làm bằng chứng layout PASS.
- web-final-snapshot.txt và web-verify.json xác nhận recovery/copy vẫn giữ sau reload build cuối.
- Browser offline tạo console network errors dự kiến; không dùng HTTP stubs để giả mất mạng.

Helper verify dùng fixture account local của lượt kiểm tra này; không phải end-to-end runner
tự dựng dữ liệu từ clean clone. lock mode yêu cầu account mới chỉ có1 note trước khóa.
Thông tin trong screenshot chỉ là fixture. Không log secret, không dùng production credentials.

Web key provider experimental/exportable browser storage; không chống XSS/profile reader.
Không key cloud backup/export, offline note-password unlock, public HTTPS, production signing,
submission/video hoặc full rubric acceptance. Xem docs/ENCRYPTED_RECOVERY.md.
