# Security Center / auth security / performance —11–12/10/2026

Target: NoteTogether, Windows local; Flutter Web release/Chrome + FastAPI SQLite loopback,
widget/unit tests và APK debug compile. Bắt đầu11/10, kết thúc12/10 Asia/Saigon; CLI browser
timestamps là UTC. Base `35db8103fa762739d43af654229bda9a4f3ed545` trên
`codex/security-center` + working changes; chưa commit/push/merge/deploy. Source mới do agent
hỗ trợ; không gán contribution độc lập/approval cho thành viên. PR#4 đã merged ngoài lượt này.

## PASS và phạm vi

| Gate | Kết quả | Log |
|---|---|---|
| scripts/check.ps1 trước final additions | format108files0changes, analyze sạch,257 Flutter/117 backend | check.txt |
| Final Flutter source | 258 PASS, analyze sạch;8 Security Center tests mới | flutter-final.txt, analyze-final.txt, flutter-targeted-final.txt |
| Final backend source | 118 PASS;9 session/security regressions mới | backend-final.txt |
| Direct HTTP8055 | owner/viewer/editor/stranger, private six-field lock projection, revoke/password/retry, remote token/grant401 | http-qa.txt, qa_api.py seed |
| Direct HTTP422 final | password marker không trong response; chỉ loc/msg/type | http-validation.txt, qa_api.py validation |
| Chrome UI | profile navigation, wrong password403/retry, one + all-other revoke; current giữ nguyên | browser-revoke.txt, browser-connection.txt |
| Chrome offline | catalogue ẩn/actions disabled; reload online khôi phục | browser-connection.txt |
| Final Chrome visual/cache | 4viewport, light/dark;0 app exceptions/console errors trước deliberate remote expiry | browser-final.txt, browser-dark.txt |
| Remote actual SSE | actor thứ hai thu hồi Chrome; metadata ẩn/manual login required | http-remote-revoke.txt, browser-remote.txt |
| Auth microbenchmark | query-only dependency không reserve writer; đọc khi reserved writer đang giữ | benchmark-auth.txt, benchmark_auth.py |
| Final Web API8000 | release compile/static shell40assets PASS | build-web-default.txt |
| Final Android debug | assembleDebug PASS, chưa chạy native UI/FPS phần mới | build-apk-debug.txt |

Final tests bổ sung cancellation của HTTP AbortableRequest thật, account/same-user token switch,
late response/bg/resume/dispose, invalid/over-limit catalogue, password retry/network failure,
encrypted session logout giữ durable encrypted draft, dialog320px/200%/keyboard/resize.
Backend: scopes/strict payload/current/foreign handles, grants cascade/feed expiry, shared reauth
counter/restart/cooldown, cap20/tied clocks/expired cleanup, stable legacy handles/dateNULL,
mutation rechecks stale identity, read auth dưới writer reservation, headers và sanitized errors.
Một warning Starlette/httpx deprecation có sẵn; không phải test failure.
Build có font-family hint của Flutter và Android SDK XML-version warning hiện có; compile PASS.

## Ảnh UI cuối

- [PC sáng](desktop-light.png), [PC tối](desktop-dark.png).
- [Điện thoại390px](phone-light.png), [điện thoại tối](phone-dark.png).
- [Điện thoại320px](small-phone-light.png), [tablet900px](tablet-light.png).
- [Bị thu hồi phiên từ xa](remote-session-hidden.png).

Ảnh [retry mật khẩu](password-retry.png), [thu hồi all-others](revoked-others.png),
[offline che danh sách](offline-hidden.png) chụp lúc kiểm tra logic trước sửa AppBar;
logic/API không đổi, chrome final/source mới đối chiếu cache ở browser-final.txt. Ảnh
desktop-before-theme-fix/profile-before-scroll/profile-after-reload là diagnostic lịch sử,
không dùng đại diện UI cuối. Tất cả PNG chụp trực tiếp; không chỉnh sửa bitmap.

QA build API8055: `notetogether-static-90358c5797dcbbed`,40 assets. Main/bootstrap SHA256
cache = HTTP no-store = build disk, lưu ở browser-final.txt và qa-web-hashes.json.
Kiểm tra độc lập bằng return-value assertions; worker activation phải hoàn tất trước
reload thứ hai. Cache install gate ban đầu chạy quá sớm, giữ raw ở
browser-cache-install-inflight.txt. Không xóa cache/inject session/app state để tạo PASS.

Chrome console raw ở browser-console.txt:403 cố tình thử password sai; disconnected do
offline QA; connection-reset do restart backend để chạy final error handler;401 sau thu hồi
token (kể cả best-effort logout). browser-remote.txt có2 console401. Không gọi toàn phiên
QA là zero console errors. Các phase trước deliberate expiry có0 exceptions/errors.
Semantics sheet có overlay rỗng cản DOM hit-test; pointer click dùng tọa độ của nút thật
đã quan sát trong ảnh. Khi Playwright đổi DPR lần đầu cần reload để canvas/semantics đồng
bộ; không suy ra native/screen-reader acceptance từ automation này.

## Commands và reproduction

Các commands chạy tại D:/flutter cuoi ki, Python .venv; FlutterSDK qua scripts/toolchain.ps1:

```powershell
./scripts/check.ps1
flutter analyze
flutter test
./.venv/Scripts/python.exe -m pytest backend/tests -q
$env:PYTHONPATH = (Get-Location).Path
./.venv/Scripts/python.exe -X utf8 evidence/2026-10-11-security-center/benchmark_auth.py
./scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8055
./.venv/Scripts/python.exe -X utf8 evidence/2026-10-11-security-center/qa_api.py seed
./.venv/Scripts/python.exe -X utf8 evidence/2026-10-11-security-center/qa_api.py validation
./.venv/Scripts/python.exe -X utf8 evidence/2026-10-11-security-center/qa_api.py revoke-browser
./scripts/build.ps1 -Target web
flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8000
```

Browser dùng `npx --yes --package @playwright/cli playwright-cli -s=nt-security`, headed Chrome.
Fixture là4 synthetic accounts/example.test; passwords trong qa_api.py chỉ test fixtures,
token/session keys chỉ trong RAM/browser profile ngoài Git. QA backend riêng DisabledDelivery,
Gemini env trống, WebOrigin7372; không gửi SMTP/provider/cloud. Server wrapper đặt trong
external QA directory security-center-2026-10-11. Reusable qa_server.py mặc định ignored tmp/,
hoặc đặt NOTETOGETHER_SECURITY_QA_DIR thành directory mới; giữ DisabledDelivery/Gemini env trống
như wrapper đã chạy. Launch uvicorn qa_server:app --app-dir evidence/2026-10-11-security-center,
host127.0.0.1/port8055; static server port7372 trỏ build/web. Cần database/profile mới khi
reproduce seed. Copy scripts/đổi output paths sang snapshot mới, không ghi đè thư mục này.
Không import module fixture để chạy side effects; qa_api.py có main guard.

Benchmark5001sessions/300 samples: không giảm latency đơn lẻ đáng kể (~0.6–0.9ms); giảm
tranh chấp reservation: actual auth0BEGIN IMMEDIATE, dưới held writer đọc1.1446ms trong khi
legacy comparator timeout50ms. Không là HTTP end-to-end/throughput/FPS. Đo trước thêm error
handler422; auth/transaction/query code giữ nguyên sau handler. First attempts gặp sandbox
Temp permissions, rồi helper chưa close SQLite connection trên Windows; raw errors giữ ở
benchmark-auth-sandbox-error.txt/benchmark-auth-cleanup-error.txt, helper đã sửa closing và
benchmark-auth.txt exit0. Không dùng partial failed metrics làm PASS.

## Build, source và giới hạn

Web QA/source final: build-web-qa-final.txt. Web API8000/APK debug compile cuối có log riêng;
artifact hashes/source hashes ở snapshot.json sau completion. Không coi compile là Android
runtime/FPS/IME/screen reader. Protected drafts/cache/frozen editor base/immutable op semantics
giữ nguyên. Session revoke không xóa dữ liệu offline trên thiết bị khác. Release signing/HTTPS,
MFA/passkeys/distributed abuse controls/provider thật/cloud/submission vẫn ngoài lượt này.

Chỉ dừng QA Chrome nt-security và2port8055/7372 sau command-line checks, cleanup.txt.
Thư mục .agents/skills xuất hiện untracked trong workspace, không sửa/xóa/gộp vào feature.
Các evidence snapshots trước11/10 giữ nguyên. Failures ban đầu của targeted widget test do
row lazy ngoài viewport và lints được giữ trong flutter-targeted.txt/analyze.txt/
check-before-lint-fix.txt; kết quả cuối ở final logs phía trên.
