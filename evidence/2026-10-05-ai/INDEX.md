# AI implementation/local QA — 05/10/2026

## Source boundary

Base HEAD `aded41ec0ccdbfb46cae579b64ef3eab004f68bf` + working changes AI.
Không commit/push mới. Ngày dùng theo Asia/Saigon; logs/JSON có UTC timestamps.
Flutter3.47.1/Dart3.13.1, Python3.12, Windows11; Android API36 emulator5554.
Web dùng Codex in-app browser qua cua_repl, engine version chưa đo; không gọi là Chrome154.
Hash source/docs/evidence/builds được chốt trong source-manifest.json sau hoàn tất build.

## Kết quả

| Command / target | Result | Scope |
|---|---|---|
| `scripts/check.ps1` | Format62 files0 changes; analyze sạch; **131 Flutter +73 backend PASS**; check-final.txt | Host;1 Starlette TestClient deprecation warning |
| `.venv/Scripts/python.exe -m pytest backend/tests/test_ai.py -q -p no:cacheprovider` |17 PASS; targeted-backend.txt | Explicit RecordingProvider/httpx doubles; ACL/context before-after/revoke/delete/edit/lock/grant/session/citations/rate |
| `flutter test test/ai_test.dart` |8 PASS; targeted-flutter.txt | HTTP doubles; RAM-only/no-overwrite/pending/late/source/gate/background/citation UI/320×568200% |
| `scripts/ai_fixture.py --allow-test-provider`, then `scripts/qa_ai.py --url http://127.0.0.1:8012 --output evidence/2026-10-05-ai/http-fixture.json` | Actual HTTP owner/viewer/editor/stranger + locked/revoke/2sources/no-data PASS; http-fixture.txt/json | **Explicit provider test double, not LLM**; tokens only in ignored tmp/ai-qa-session.json |
| API8000 no-key probe | enabled=false; both AI routes503 AI_NOT_CONFIGURED PASS; http-disabled.txt | Main backend, no fake response |
| `flutter drive --driver=test_driver/ai.dart --target=integration_test/ai_flow_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8012 --enable-software-rendering --no-enable-impeller` | 1 scenario PASS (+2 includes teardown); android-fixture.txt | Debug API36, actual HTTP/keys/Sembast/UI; provider fixture; summary/regenerate/no-mutation/Q&A2citations/exact source open |
| Web build `scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8012`; actual IAB UI | Summary/Q&A2sources/citation source/no-data/peer lock clears result PASS | Local release + fixture; web-qa.json and PNG/DOM files |
| `flutter pub get` after integration | PASS; pub-get-release.txt | Regenerates plugin configuration, no manual GeneratedPluginRegistrant edit |
| `scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8000` | PASS41.5s/40resources/worker0b3445ebf15f821a; build-web-final.txt | Final default bundle, no fixture backend in output |
| `scripts/build.ps1 -Target apk -ApiUrl http://127.0.0.1:8000` | PASS43.4s/55.9MB; build-apk.txt | Build only; debug signing/local HTTP, not public release-functional acceptance |
| `collect_manifest.py` then `--verify` | Source/docs/evidence/final-build hash integrity | Does not rerun tests or UI/provider QA |
| Real Gemini | **NOT RUN** | Người dùng chọn hoàn tất code/local QA trước, cần thay/config key mới |

## Actual Web

IAB425×613 tại http://127.0.0.1:7357; bật Flutter semantics bằng Enter trên Enable
accessibility. Disposable QA owner từ HTTP fixture, email/password chỉ @example.test.
Home/editor → Summary hiện rõ **“Kết quả fixture kiểm thử, không phải LLM”**.
Home Hỏi ghi chú → hỏi Orion schedule/budget →2 source buttons → mở schedule editor đúng.
Q&A Astronomy không có nguồn → insufficient message/no source buttons.
HTTP peer bật khóa budget source khi Q&A đang hiển thị → response và citations cũ che;
web-remote-lock-api.txt và web-source-lock-dom.txt/png ghi phạm vi thực.

Observed static script URLs trong web-qa.json. Served fixture main.dart.js hash đã đo:
`bb13dabd76fb01fb34c2693eeb63eb50e0dea28d7a81f6077db37e27de417e47`, worker
`notetogether-static-16d82208680b957a`,40 resources. Đây là hash build phục vụ QA,
**không phải independently captured navigation-response bytes**. Final default bundle
có hash riêng trong manifest; không lấy fixture screenshots làm bằng chứng real Gemini.

Browser lượt đầu dùng bundle cache cũ nên login fixture thất bại; sau reload worker/bundle
đúng thì actual login PASS. `fill` khi text field còn nội dung có thể append trong Flutter;
dùng Ctrl+A/Backspace, snapshot xác nhận query mới trước request. Ảnh source đầu chụp
trong route transition được chụp lại sau ổn định; không dùng ảnh animation làm stable UI.
Selector chờ text LLM không match SelectableText semantics dạng textbox disabled;
snapshot/ảnh thực và API kiểm tra kết quả được dùng đúng phạm vi.

## Native / failure repair

AVD taskflow_api36, adb reverse8012, debug Skia software. Hai raw failures giữ lại:
android-fixture-failure.txt: setup thiếu confirmation; sửa test input.
android-fixture-failure-2.txt: note mục tiêu ngoài lazy viewport; đổi thứ tự fixture
để note mục tiêu mới nhất nằm trên, không thay logic sorting app. Lượt cuối PASS với
source đã sửa. Hai PNG ai-native-summary-fixture.png/ai-native-question-fixture.png
được driver tạo và đã xem; source citation/note text được integration assertions xác minh.

HTTP fixture QA lần đầu no-data fail do query astronomy chứa từ phổ biến “bao” trùng
“báo cáo”. Bổ sung interrogative stop words bao/nhieu/khi/dau; test/provider fixture
được restart, lượt sau PASS. LLM thật vẫn phải đánh giá relevance/sufficiency; BM25
false positives/synonyms không được coi đã giải quyết hoàn toàn bằng stop words.

## Credential incident and limits

Google AI Studio cho thấy existing project Free tier. Không bật billing, tạo paid
resource, đổi quyền/account hoặc gọi Google. Existing key format mới đã xuất hiện
trong tool output do redaction chỉ nhận format cũ. Đã báo người dùng; họ chọn local QA
trước. Không lưu key đó vào workspace/fixtures/screenshots/evidence và không sử dụng.
Cần thay/config key mới bằng scripts/configure_ai.ps1 trước real Gemini acceptance.
Không lặp secret trong báo cáo hoặc quét/log thông tin credential từ browser.

App adapter/requests/schema đã kiểm tra với doubles nhưng **không chứng minh Google
chấp nhận key/model/schema hoặc chất lượng summary/answer trên LLM thật**. Không full
rubric27/28, publicHTTPS, physical-device, release-functional, protected UI toàn bộ,
screen reader hoặc video claim. Offline shell/note/recovery invariants giữ host regressions;
AI online-only, không masquerade fixture thành cloud AI offline.
