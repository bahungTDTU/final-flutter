# Bảo trì, sửa lỗi, hiệu năng và cleanup — 03/10/2026

Workspace D:\flutter cuoi ki; base Git35ee9114ee6712d6589c144e61ded8c9293d3155 + working
changes. Người dùng ủy quyền sửa/dọn/push; author/committer Bahung, không AI/co-author/backdate.
Windows11, Flutter3.47.1/Dart3.13.1, Python3.12.14, Chrome154, Android API36 emulator.
Manifest ghi collected UTC thật, base commit và SHA-256 source/docs/evidence/builds cuối.
Không dùng base commit làm claim source sửa đã được commit tại lúc test.

## Nội dung

Batch list API giảm query roundtrips giữ transactional session/ACL/roles, label order và
locked minimal metadata. Sync index remote/pending IDs và tránh rebuild archive cho clean
notes; dirty edit/revoke/lock vẫn giữ recovery. API giữ HTTP status với non-JSON error, abort
JSON/binary request khi timeout. Foreground/dispose guards ngăn periodic work sau background
hoặc disposed session-load. Bỏ dependency/illustration không dùng, archive legacy teal audit,
dọn generated duplicates/old browser logs. Details: docs/PERFORMANCE_AND_MAINTENANCE.md.

## Lệnh thật / target / kết quả03/10

| Command | Result / log |
|---|---|
| `dart format lib test/maintenance_regression_test.dart` | Format final PASS; format-final.txt |
| `flutter test test/maintenance_regression_test.dart test/realtime_test.dart test/sync_durability_test.dart test/encrypted_recovery_test.dart` |37 PASS trước clean-archive refinement; targeted-flutter.txt; final source rerun full gate |
| `.venv/Scripts/python.exe -m pytest backend/tests/test_note_listing.py backend/tests/test_security.py backend/tests/test_avatar_labels.py backend/tests/test_sharing.py -q` |31 PASS; targeted-backend.txt; TestClient + pytest cache warning trên lượt này |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1` | Final format/analyze sạch, **123 Flutter/56 backend PASS**; check-final.txt; chỉ1 TestClient deprecation warning |
| `.venv/Scripts/python.exe scripts/benchmark_notes.py --output evidence/2026-10-03-maintenance/notes-before.json` rồi `notes-after.json` | Real local ASGI/SQLite measurements; benchmark-before/after.txt, notes-before/after.json;7 measured requests + warm-up |
| `.venv/Scripts/python.exe evidence/2026-10-02-ui-upgrade/api_acl_probe.py` | Direct actual HTTP8000 owner/viewer/editor/stranger read/write/sharing/protection/minimal lock PASS; api-acl.txt |
| `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/note_flow_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000 --enable-software-rendering --no-enable-impeller` | Android debug/API36 Skia software real API/Sembast/DeviceRecoveryKeys PASS;1 scenario, +2 gồm teardown; android-core.txt |
| `scripts/build.ps1 -Target web` | Web release PASS;40 static resources, worker notetogether-static-fe2154b5779bb956; build-web.txt |
| `flutter pub get` sau integration rồi `scripts/build.ps1 -Target apk` riêng | APK release55.8MB PASS; pub-get-release.txt/build-apk.txt; không sửa GeneratedPluginRegistrant |
| `npx --yes --package @playwright/cli playwright-cli -s=maintenance …` | Chrome actual UI/network/offline/reload/theme/resize; scope bên dưới |
| `.venv/Scripts/python.exe evidence/2026-10-03-maintenance/verify_browser_note.py before` rồi `after` | Real API note ID/count/content/revision assertions PASS; browser-api-before/after.txt, browser-note-before/after.json |
| `collect_manifest.py` rồi `--verify` cùng evidence folder | Source/docs/evidence/build integrity + README equality; không rerun tests hoặc browser/native |

Executables: C:/Users/LENOVO/flutter-sdk/bin/flutter.bat/dart.bat, .venv/Scripts/python.exe,
C:/Program Files/nodejs/npx.ps1, D:/Android/sdk/platform-tools/adb.exe.
Backend/Web chạy scripts/start_backend.ps1/scripts/start_web.ps1, localhost8000/7357.
Native AVD D:/Android/avd/taskflow_api36, no-window/swiftshader,720×1280/density240,
adb reverse tcp:8000 tcp:8000. Software flags chỉ QA command, không đổi renderer production.

## Hiệu năng có đo

Temporary real SQLite + TestClient ASGI,3 labels/note,5% locked, owner và shared viewer.
SELECT count gồm auth/session revalidation và list/labels; correlated COUNT vẫn làm việc
trong SQLite, không nói tổng request O(1). Không đo server internet/user production/device FPS.

|1.000 notes|Before|After|
|---|---:|---:|
|Owner SELECT statements|5.803|4|
|Viewer SELECT statements|7.753|4|
|Owner median ms|64.248|52.397|
|Viewer median ms|76.335|58.701|

Hai lượt local có nhiễu tải host;10-note latency không cải thiện ổn định. Min/max/median/raw
query counts trong JSON. Không nội suy thành benchmark jank/60fps hoặc mọi dataset.
Benchmark helper lượt đầu có Windows SQLite file-handle cleanup error; đã explicit close
connection trước temp cleanup rồi chạy before thành công. Không tính helper-error là PASS.

## Regression có ý nghĩa

5 Flutter tests mới: dispose trong session-read không revive polling/write; background31s
không requests/resume không SSE catch-up; non-JSON401 retire local session; binary502 giữ
status/không hiện HTML; JSON/binary timeout abort trigger trước retry. Những tests này dùng
HTTP/local doubles đúng phạm vi, không chứng minh server mutation bị hủy sau timeout.
Immutable op IDs và backend idempotency vẫn giữ trách nhiệm retry an toàn.

3 backend cases mới:5/150 notes bounded queries, owner/editor/viewer list so với independent
detail serializer; label order/foreign/deleted filtering, current owner identity, minimal lock
sau unlock, revoke/deleted/stranger không thấy dữ liệu. Existing ACL/SSE/draft/frozen base/
preferences/recovery suites chạy lại full final gate, không chỉ test mirrors/coverage count.

## Chrome final release / source boundary

Actual main.dart.js navigation response SHA trong browser-loaded.txt:
`4ede5c31629bf6b0c0a3f77db6db963d7ca001d281da5e6e323b72b9335f70f1`.
Đối chiếu với build artifact trong browser-artifact-match.txt/source-manifest.json.
Viewport ổn định1440×900 rồi reload, auth/login fixture thật:
ui-upgrade-owner@example.test / UiEvidence-2026!, chỉ QA local example.test.
Home labels/pinned/minimal locked card; ảnh maintenance-home.png đã xem.

Tạo note mới QA maintenance 2026-10-03 qua UI, autosave lên API revision1. Đổi theme/resize
390×844 giữ nội dung bằng focused inputValue assertion; ảnh maintenance-editor.png đã xem.
Context setOffline(true) gây actual network failures, không HTTP response doubles: thay body,
Back, reload shell offline, Home vẫn7 notes/pending1. Mở lại note và assert đúng offline text;
setOffline(false), nút Đồng bộ, API assert cùng ID/count7, revision1→2 và final content:
`Bản offline maintenance 03/10 được giữ sau reload.` Không tạo note trùng.
maintenance-reconnected.png đã xem: server ack Đã đồng bộ, SSE lúc ảnh vẫn Đang nối lại,
không báo realtime live giả. Browser-console.txt chỉ lỗi network offline đã tạo cho QA.
Exact caret/base assertions là host/native scopes; Chrome chỉ assert text/theme/resize ở lượt này.

## Android final-source core

Actual backend registration, auto-save UI, encrypted Sembast/database close/reopen,
unreachable socket offline và preference/reconnect/cross-session assertions PASS.
Debug API36 Skia software, không HTTP doubles. Reopen trong cùng process, không OS force-kill.
Raw log có IME FrameTracker warnings trên emulator; không dùng test PASS làm chứng cứ hết jank.
Đợt này không native screenshots/new full sharing/realtime/picker suite; các mốc trước giữ scope.

## Cleanup

cleanup-candidates.json và cleanup-result.json:309 old/duplicate generated files,
5.229.325 bytes.47 output files được SHA so với kept evidence trước Remove-Item;
262 dated01–02/10 Playwright snapshots/console logs, QA results đã ở evidence.
Absolute target phải nằm trong workspace/intended directory, dùng PowerShell LiteralPath.
Giữ unique fixtures/historical raw logs/images/prompts/fonts/data/keys/venv/build.
Source cleanup: unused PaperIllustration66lines, direct cupertino_icons dependency,
legacy contrast audit khỏi scripts/ vào historical evidence, bắt buộc explicit --output.
Không ghi đè historical manifests/contrast kết quả cũ thành claim current.

## Giới hạn

123/56 PASS/build/direct HTTP/local browser/debug emulator không phải full32 rubric hoặc
submission/production/physical/HTTPS/release-functional/signing/TalkBack/NVDA acceptance.
Chưa đo FPS/full device frame timing/list UI lớn. Không rerun SMTP/picker/protected editing/
all two-device stress/history/deep-link. Existing blockers giữ STATUS.
Auto permission-review lần pub-get đầu hết thời gian; retry một lần đã được chấp nhận và
hoàn tất. Không cần người dùng cấp thêm quyền; không hành động nào còn bị chặn.
