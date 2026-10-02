# Sharing25/18 — evidence local 02/10/2026

Workspace `D:\flutter cuoi ki`, Windows11; Flutter3.47.1/Dart3.13.1/Python3.12.14,
Android API36 `taskflow_api36`/emulator-5554 debug, Chrome local release390×844/DPR≈1.
Commit **chưa có** (master unborn), không remote/push/deploy/phí/video/timestamp nộp.
UTC timestamps trong fixtures/logs là thời gian thu thập thật, không latency benchmark.
Disposable @example.test/password fixture công khai, không lưu/print auth token.

## Command, target, actual result

| Command / target | Actual result / evidence |
|---|---|
| `.venv/Scripts/python.exe -m pytest backend/tests/test_sharing.py -q` host |8 PASS; backend-sharing.txt |
| `scripts/check.ps1` host, source cuối | Format48 files0 changes/analyze sạch/97 Flutter/48 backend PASS; check-final.txt;1 StarletteDeprecationWarning |
| `flutter test test/sharing_test.dart` host |8 PASS; flutter-sharing-final.txt; HTTP/lifecycle race doubles được ghi trong tests |
| `flutter analyze` final | No issues; analyze-final.txt; check-final.txt cũng analyze source cuối |
| `flutter test integration_test/sharing_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000` |1 PASS source cuối, test duration23s; android-integration-final-source.txt; real backend/platform key/Sembast/socket65530 |
| `scripts/build.ps1 -Target web` release API8000 | PASS/41 static resources/worker7e5e4205a9ecb007; build-web-final.txt |
| `scripts/build.ps1 -Target apk` release API8000 | PASS54.5MB; build-apk-final.txt; build không nghiệm thu release chức năng/signing/HTTPS |
| `npx --yes --package @playwright/cli playwright-cli -s=sharing …` và `-s=sharing-recipient …` | Actual headed Chrome owner/recipient contexts riêng; snapshots/screenshots và scope bên dưới |
| `.venv/Scripts/python.exe scripts/qa_sharing.py audit/final-audit/locked-audit` theo đúng stage | API actual assertions; web-api-audit.txt, web-lock.txt; không dùng HTTP doubles |

Flutter executable `C:\Users\LENOVO\flutter-sdk\bin\flutter.bat`; Dart cùng bin,
Python `.venv\Scripts\python.exe`, ADB `D:\Android\sdk\platform-tools\adb.exe`,
Node/npx `C:\Program Files\nodejs\npx.ps1`. Backend8000 `scripts/start_backend.ps1`,
Web7357 `scripts/start_web.ps1`; `adb reverse tcp:8000 tcp:8000` cho Android.
AVD taskflow_api36 ở D:/Android/avd, ANDROID_USER_HOME D:/Android/user; headless SwiftShader.
Đọc README integration setup trước chạy, không có emulator/physical device thì ghi chưa chạy.

## API và host tests

Backend8: owner catalogue private/no-store, recipient owner/time, editor/viewer/stranger ACL,
strict payload không owner injection,4 invalid batch cases rollback toàn bộ, CAS stale writer,
timestamp/content revision giữ khi role change, replay-after-revoke/restart/changed-op-ID409,
locked4-key metadata/owner grant/relock/recipient grant revoke, legacy write invalidates CAS.
Transactions dùng SQLite/TestClient thật; không claim distributed load/quota mọi edge case.

Flutter9 mới (8 sharing +1 attachment): immutable lost-ack op retry dù catalogue sau đó revoked,
late response bỏ khi đổi account, CAS current/review, real host file Sembast encrypted revoke/
reopen không plaintext secret, viewer đang gõ giữ draft/read-only server, locked owner/time
redaction, scale2 mobile share/revoke-confirm no overflow, background31s không request/poll,
attachment role downgrade che tên trong open delete-confirm/disable Xóa tệp. HTTP/account race/
lifecycle trong tests là doubles; không suy ra OS kill/screen reader. Các suites frozen editor,
theme/resize, preferences/label immutable outbox, encrypted recovery chạy cùng97 tests.

Initial check.txt phát hiện regression viewer+locked điền lại title sau clear; editor đã giới hạn
viewer refresh vào unlocked note và encrypted_recovery_test assertion rỗng PASS trong check cuối.
flutter-sharing-initial.txt là6 PASS/1 FAIL vì Home test harness thiếu production AnimatedBuilder;
đã dùng NoteTogetherApp, giữ assertion hide owner/time. acl-regression.txt có failure của chuỗi
confirmation fixture sai, đã sửa đúng text và check cuối PASS. Android first run dùng pageBack
không tìm custom Quay lại; sửa finder tooltip, final source run PASS. Không tính các logs này là PASS.

## Android actual debug integration

Đăng ký disposable owner/recipient/second viewer/stranger qua API thật. Production UI owner
editor → Chia sẻ ghi chú → batch2 viewer → recipient dropdown editor; GET assert2 recipients,
shared_at giữ, note revision1. Recipient login/app/tab Được chia sẻ có Native owner/time; catalogue
403, stranger404. Recipient editor UI lưu content → owner API thấy content/revision2.

Title rỗng + nội dung Draft before role downgrade chưa hợp lệ: peer owner API đổi viewer →
sync → readonly content server và latest draft recovery. Peer upgrade editor → UI draft mới →
peer revoke → sync → editor che/no TextField, source queue empty và recovery thứ2.
Close/reopen **database trong cùng test process**, production DeviceRecoveryKeys/Sembast/
EncryptedAccountStore; connect65530 không lắng nghe → offline, source không còn, recoveries2.
UI Phục hồi → chọn entry cuối → Editor content Draft before native revoke, UUID khác source,
draft giữ, không gửi original. Không HTTP mock, không OS force-kill/physical/release-functional claim.
Peer downgrade/revoke là direct API, không claim native owner revoke-confirm UI đã tap.

## Chrome actual UI và source boundary

Owner registered bằng UI, note `37ed00db-ae1b-4f4d-ada8-f3caa539034c`, content Original Web content,
revision1. Batch recipient+missing email bị từ chối toàn bộ, catalogue empty; sửa bằng Ctrl+A/
Backspace/type rồi batch recipient+other viewer thành công. Initial Playwright fill trên Flutter
semantics textarea nối chuỗi, validation bắt lỗi; không xem lần đó là thành công. Dropdown
recipient editor, role API match; share_at `2026-10-02T09:15:56.461341+00:00` giữ, share revision2,
content revision1. Server stranger404/recipient catalogue403. Manager screenshot mobile đã inspect.

Recipient browser context riêng login, tab Được chia sẻ có Web owner/02-10 16:15/role editor;
editor UI không owner sharing control. Title clear + Browser draft before revoke chưa sync →
owner UI Thu hồi quyền/Thu hồi → recipient sync15s → source editor hidden, recovery banner1.
API catalogue revision3/count1, recipient404, note content/revision1 giữ. Browser reload2 lần →
recovery vẫn có → UI Phục hồi/entry → draft đúng nội dung/title rỗng, không source mutation.
Screenshot sharing-recovered-final.png đã inspect, không tuyên bố Web UUID từ DOM; new UUID
được assert ở native/host tests. Shared manager/recipient screenshots có fixture email, không token.

Batch/role/metadata/revoke flow đầu chạy worker71b17977c80275dc. Sau background poll guard,
check97/48/native integration rerun + Web/APK rebuild. Final source worker7e5e4205a9ecb007:
recipient reload/recovery + owner shared-count indicator/menu và open revoke-confirm → peer API
lock → email che/Thu hồi disabled. API owner/viewer locked list chỉ id/locked/revision/role,
owner catalogue423/revoked recipient404; protection đúng tăng note revision2. Screenshot/snapshot
final locked confirmation đã inspect; protected-reader share manager UI chưa chạy.

browser-build-final.txt: fetched main.dart.js SHA-256 khớp disk, viewport390×844/DPR≈1, controller
offline_worker.js và cache7e5e4205a9ecb007. Còn cache71b từ context cũ trong phiên QA; không xóa
IndexedDB/session/recovery. Không claim các flow đầu đã rerun trên build cuối; thay đổi cuối là
foreground guard (widget polling regression), các final-source assertions đã nêu riêng.

Chrome console404 missing-email và423 khi peer lock là intentional authorization checks,
browser-console.txt; không framework overflow error. Không claim full keyboard/TalkBack/NVDA,
browser Back/deep link/OS background acceptance từ semantics automation.

## Artifacts và tái lập

- web-manager-mobile.png, web-recipient-mobile.png: initial-source form/recipient metadata.
- web-recovered-final.png, web-locked-confirm-final.png: final-source recovery/lock-confirm.
- snapshots/: selected actual CLI snapshots; web-recovered.txt/web-locked-confirm.txt cuối.
- web-api-audit.txt/web-lock.txt: actual API assertions theo stage, fixture cuối đã locked.
- source-manifest.json: UTC, code fingerprint, source/docs/test/script hashes và build hashes.

Main JS SHA-256 `8c454b838c14903021dd08dbfa62d1f926af2ffa17c0dc0b82e2f0541ea798b8`.
APK SHA-256 `bac7e615392be8e5afb7e88e3dc75a063c1464fd4464c9099c34270b8c601a8d`.
Index/manifest không thay commit/teamwork hoặc video1080p/timestamps môn học.

```powershell
& scripts/start_backend.ps1
& .venv/Scripts/python.exe scripts/qa_sharing.py prepare
# Read web-fixture.json; owner đăng ký qua Web UI với local-sharing-fixture-123 và tên Web owner.
# Owner tạo Web sharing fixture/Original Web content, batch recipient+other.
& .venv/Scripts/python.exe scripts/qa_sharing.py audit
# UI recipient role editor → audit; UI recipient draft + owner revoke → final-audit.
& .venv/Scripts/python.exe scripts/qa_sharing.py final-audit
# Owner mở confirmation nhưng chưa thu hồi other; peer lock rồi UI guard.
& .venv/Scripts/python.exe scripts/qa_sharing.py lock
& .venv/Scripts/python.exe scripts/qa_sharing.py locked-audit
```

prepare tạo fixtures mới và thay web-fixture.json; assertions gắn tên/stage/note một fixture local,
không production setup/cleanup script. Chưa nghiệm thu protected-reader share UI/full two-device
conflict races/realtime subscription/offline share queue/OS kill/physical/release-functional/signing/
public HTTPS/LLM/video/submission. Xem docs/SHARING_AND_PERMISSIONS.md, STATUS và matrix.
