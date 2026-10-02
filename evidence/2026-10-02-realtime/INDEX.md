# Realtime26 — evidence local02/10/2026

Workspace `D:\flutter cuoi ki`; Windows11, Flutter3.47.1/Dart3.13.1/Python3.12.14.
Android API36 taskflow_api36/emulator-5554 debug; Chrome local release editor390×844/DPR≈1,
owner1280×720 context riêng. Commit **chưa có**, master unborn/no remote. Không push/deploy/
phí/video/timestamp nộp. Fixture @example.test/password công khai trong scripts/qa_realtime.py;
API tokens của script QA chỉ RAM; app giữ session local theo policy hiện có (chưa production
hardening). Thời gian UTC/epoch/log thật, không benchmark latency hay video evidence.

## Lệnh, target, kết quả

| Command / target | Actual result / log |
|---|---|
| `.venv/Scripts/python.exe -m pytest backend/tests/test_realtime.py -q` host TCP localhost |5 PASS; backend-realtime.txt |
| `flutter test test/realtime_test.dart` host |9 PASS trước repair; cancellation expectation failure riêng; check-final.txt xác nhận9 cuối cùng |
| `scripts/check.ps1` final Flutter source |Format51 files0 changes/analyze sạch/106 Flutter/53 backend PASS; check-final.txt;1 Starlette deprecation warning |
| `.venv/Scripts/python.exe -m pytest backend/tests -q` final backend |53 PASS sau explicit closing SQLite read connections; backend-final.txt |
| `flutter test integration_test/realtime_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000` |1 PASS source cuối,21s test; android-integration-final-source.txt; real SSE/API/platform key/encrypted Sembast/socket65530 |
| `scripts/build.ps1 -Target web` release API8000 |PASS/41 static resources; build-web-final.txt; workeraf4ed9f3afad7268 |
| `flutter pub get`, rồi `scripts/build.ps1 -Target apk` release API8000 |PASS54.6MB; pub-get-release.txt/build-apk.txt; debug signing/local HTTP limitations giữ |
| `scripts/start_backend.ps1`, `scripts/start_web.ps1` |localhost8000/7357; backend thực đã stop/restart trong Chrome QA; ADB reverse8000 |
| `npx --yes --package @playwright/cli playwright-cli -s=realtime-editor …`, `-s=realtime-owner …` |Chrome app UI contexts/account riêng; actual scope/snapshots/images bên dưới |
| `.venv/Scripts/python.exe scripts/qa_realtime.py prepare/peer/reconnect/concurrent/viewer/revoke/lock/audit/locked-audit` |Direct actual fixture API; web-api*.txt; không HTTP doubles |

Flutter executable C:/Users/LENOVO/flutter-sdk/bin/flutter.bat, Dart cùng bin;
Python .venv/Scripts/python.exe, npx C:/Program Files/nodejs/npx.ps1,
ADB D:/Android/sdk/platform-tools/adb.exe. Emulator headless SwiftShader với ANDROID_AVD_HOME
D:/Android/avd, ANDROID_USER_HOME D:/Android/user. README integration prerequisites đã đọc.
Release build không thay acceptance HTTPS/signing/release-functional.

## API/host verification

SSE tests chạy uvicorn thread/socket bound port0 + httpx streaming thật. Authorized owner,
editor, viewer ready/changed only-version, editor POST được chấp nhận, viewer403/stranger404,
stranger không nhận event của note. Revoke recipient nhận changed rồi không nhận các edit
sau revoke; reconnect ready/GET notes empty. Protection lock redacts4-key metadata/read423,
logout gửi expired{} rồi EOF/401. Auth anonymous/query-token401, bad Origin403, cap3/session
429, slot released sau disconnect/reopen. Counter rollback không phát, replay/stale409 không
bumps, startup idempotent giữ counter/catchup. Không load/distributed cap/real internet claims.

Flutter9: bounded strict chunk/CRLF/comment parser, reconnect/catchup/dedup/header-only token,
late queued event/account replacement/stop/expiry, foreground reconnect/logout, event đến khi
GET notes đang chờ chạy lượt refresh mới và giữ latest draft. Widget clean update selection
giữ/base mới chỉ qua CTA; dirty invalid draft status giữ sau debounce rồi valid save frozen
base1 dù remote2. HTTP feed/controller/widget tests là doubles; native/socket suites tách riêng.
Full106 vẫn chạy crypto/local durability/preferences/labels/sharing/theme/resize/base regressions.

## Android actual final source

Disposable owner/recipient/editor/viewer/stranger qua backend8000. Recipient production UI mở
shared note; owner API edit → text tự cập nhật trong editor và CTA phiên mới, không manual sync.
Tap CTA, UI content edit → owner controller/feed tự nhận, GET revision3. Disconnect/resume
qua controller foreground đóng/mở HTTP socket thật, không claim OS background/Wi-Fi toggle;
owner edit trong khoảng disconnect → recipient catchup. Invalid draft giữ local khi owner
revision5; valid title autosave từ frozen base4 →409/conflict, source content không overwritten.
Owner role viewer→recipient readonly/recovery; source pending empty. Viewer API403/stranger404;
owner revoke→editor không TextField, source unavailable. Close/reopen encrypted Sembast trong
cùng process + DeviceRecoveryKeys, endpoint65530 không lắng nghe: original absent, latest recovery
content còn/pending empty. Hai controllers share test DB; peer disposed và recipient session
persist rõ ràng trước reopen. Không HTTP mock/native clipboard/media/new-ID UI claim đợt này.

Initial native lỗi `Connection closed while receiving data` khi stop stream (android-integration-
initial.txt). Async parser/client-close race sửa bằng transformer/captured subscription/await
cancel before close/epoch guard; final-source run PASS. flutter-realtime-cancel.txt chứa2 fails
vì fake tests kỳ vọng client.close đồng bộ, đã đổi sang chờ cancellation kết thúc; check cuối
PASS. Analyze/format initial logs failed vì braces/avoid_print, không tính là PASS.
APK initial compileRelease thiếu integration_test plugin (build-apk-initial-failed.txt);
SDK pub get sau integration rồi release riêng PASS, không sửa GeneratedPluginRegistrant.java.

## Chrome actual scope và build boundary

Fixture note `ed6b4b50-abec-4b42-89cf-2bcd45309886`; note lock riêng
`81a1c72b-4c59-47ee-8963-226e55b58418`. Editor login UI, tab Được chia sẻ, editor đang mở;
peer API edit revision2 → tự thấy Peer content arrives live in Chrome/CTA, không tap Đồng bộ/
reopen để nhìn update. UI explicit new base rồi edit→server revision3/Chrome editor save live.
Owner Chrome account/context riêng mở editor, recipient edit→revision4/Chrome second live edit
hiển thị owner/CTA trong wait cửa sổ5s; không coi thời gian này là latency benchmark.

Backend thực stop rồi restart: editor Trực tiếp→Đang nối lại, text cũ giữ; restart và peer edit
revision5→Trực tiếp/Catchup after real server restart tự hiển thị. Logs network RESET/REFUSED
trong khoảng server down là expected. Không click sync/page reload trong reconnect stage.

Đầu tiên thao tác keyboard quá nhanh chưa cập nhật Flutter fields (web-draft-initial*.txt),
không tính là draft pass. Focus/keyboard CLI từng bước tạo title rỗng + Chrome local unsent draft
thật; peer concurrent edit→local text giữ. Role viewer→server readonly content, local edit vào
recovery; revoke→no TextField/source hidden. Reload→Home1 recovery còn. API revision7/content
Concurrent owner version in Chrome giữ; viewer write403/stranger read404/editor revoked404.
Khâu nhập password fill/insertText cũng cần keyboard type, không xem thao tác bị ignore là PASS.

Các flow trên dùng worker8347afe326ab79a5/mainSHA f1b015de841a7b14451b1fe47888008bb4970a3b08e04adde41b547b0056aafb,
browser-build.txt đối chiếu actual cached script. QA này lộ draft invalid hiện Đã đồng bộ sau
debounce; sửa status branch giữ draft và thêm regression rồi check/native rerun/Web/APK rebuild.

Source cuối workeraf4ed9f3afad7268/mainSHA8601d48caa8d6a84a78992160e8dd0035d0513d17cadcd8ac8e46c090c105596:
browser-build-final.txt đối chiếu cache/fetch; browser-executed-build.txt hash response main JS
thực của navigation sau reload (không chỉ một fetch về sau). Worker activation không tự reload
VM đang mở: draft check đầu trước explicit navigation còn hiện status cũ, không tính là PASS.
Final draft/lock/recovery
checks ghi các file web-final*.txt/png. Không coi mọi flow đầu đã rerun trên source cuối; thay
đổi cuối chỉ status draft, core protocol/CAS/recovery giữ và native full scenario rerun PASS.

Navigation main hash cuối đã khớp → reopen draft còn title rỗng/content cũ → UI sửa thành
Chrome draft before live lock final, qua debounce vẫn báo Nhập tiêu đề…/Trực tiếp. Owner API
khóa note thứ2 revision2 → editor che ngay/không TextFields, không hiển thị owner/title/body.
Owner/editor/viewer GET note423 và list chỉ id/locked/revision/role (locked-audit), original
source content/revision không nhận invalid draft. Reload giữ2 recoveries; UI restore entry
lock hiển thị latest draft cùng title rỗng, không mở source khóa hay gửi original ID.

Backend cuối chỉ bổ sung `closing()` để connection SQLite được đóng tường minh sau mỗi
counter read; context manager sqlite mặc định chỉ commit/rollback. Toàn bộ53 backend rerun
PASS và backend QA restart trước final Chrome lock; không giữ read connection qua await mạng.

Screenshots trong index là actual browser, đã inspect bằng view_image, không mockup. Playwright
semantics/keyboard không thay TalkBack/NVDA/history/deep-link/OS hidden tab acceptance.
Protected-reader actual realtime, physical/many-device stress/release functional/public HTTPS/
proxy buffering/signing/SMTP ngoài/LLM/video/full32/submission chưa nghiệm thu. Counter polling
250ms là server implementation, không DB pubsub/OT/CRDT/distributed transaction claim.

Source/evidence/build hashes, commitnull và README=Readme xem source-manifest.json;
collect_manifest.py chỉ hash/read Git state, không tạo commit/authorship/history.

Final Web main SHA256 `8601d48caa8d6a84a78992160e8dd0035d0513d17cadcd8ac8e46c090c105596`,
APK SHA256 `2e5e70d2c7cec94fc25416163745f3533f7d847379717aeb09063a414d3dbaa7`;
code fingerprint `8ef69f6f812062e1405853c34381117ea539d38594386c427a99d010998e7c71`.
`.venv/Scripts/python.exe evidence/2026-10-02-realtime/collect_manifest.py --verify`
kiểm tra hashes sau khi thu thập; không rerun tests/QA. Manifest/summary/verify log của chính
collector được loại khỏi evidence hashes để tránh tự thay đổi hash khi viết output.
Chrome contexts/emulator tạo cho QA đã đóng; backend localhost10132/Web7357 vẫn chạy khi
kết thúc lượt này, không claim các services sẽ tồn tại qua app restart.
