# Baseline máy Nguyễn Bảo Long —12/10/2026

Base35db810, branch codex/local-baseline-readiness. Mã nghiệp vụ không đổi; sửa setup
Python discovery/version guard, start_web port, đồng bộ current docs và acceptance backlog.
Commit publication có thể tra Git log/PR; không tự ghi hash của commit chứa chính file này.

## Commands và kết quả

| Command / target | Actual result | Evidence |
|---|---|---|
| flutter doctor -v (SDK máy có sẵn3.47.0) | Android license unknown/no Android device; Dart3.13.0 thấp hơn constraint | doctor.txt |
| setup.ps1 -Python bundled3.12.14, SDK3.47.0 | FAIL tại pub get do Dart3.13.0; Python deps cài thành công | setup.txt |
| setup.ps1, SDK riêng3.47.1/Dart3.13.1 | PASS .venv3.12.14, pinned backend deps, pub get; lockfile không đổi | setup-final.txt |
| check.ps1, SDK riêng đường dẫn dài | FAIL analyze vì SDK directory path quá dài | check.txt |
| build.ps1 -Target web, SDK đường dẫn dài/có khoảng trắng | FAIL native hook quoting; run dừng sau lỗi, không gọi build PASS | web-build.txt |
| check.ps1, FLUTTER_BIN=F:\bin\flutter.bat (subst SDK riêng) | PASS format105files0changes/analyzer sạch/250 Flutter/109 backend,1 upstream warning | check-short-sdk.txt |
| pytest backend/tests -q (chạy riêng trước full check) | PASS109,1 upstream Starlette/httpx warning | backend-tests.txt |
| build.ps1 -Target web với SDK ngắn | PASS Web release107.3s/static-only40resources; có font/Cupertino warning, chưa audit icon UI | web-build-short-sdk.txt |
| setup Python3.13 trên scratch workspace mới | Expected rejection trước tạo.venv/cài deps; PASS guard | setup-version-guard.txt |
| start_backend.ps1 tương đương uvicorn factory8000; DB tmp riêng | health ok, email/AI not_configured | local-services.json |
| python scripts/qa_protected_notes.py, localhost8000 | PASS4roles/locked+grant/replay409/files/revoke/change/delete | http-acl.txt, http-api.json |
| start_web.ps1 -Port7358 | HTTP200 index/worker, bootstrap present, worker exact bytes match build | local-services.json |

SDK clone đầu gặp Windows filename too long; checkout SDK được phục hồi bằng git
-c core.longpaths=true restore trong SDK riêng, rồi subst F: giúp runtime đọc paths.
Không sửa source/package cache hoặc hạ Dart constraint để che lỗi môi trường.
Setup run đầu dùng -Python explicit tạo venv; run sau kiểm tra venv hiện có đúng3.12.
Guard probe dùng bản copy scripts trong tmp/setup-version-probe và Python3.13, không
xóa/đổi venv thật. Parser setup/start_web và git diff --check cũng PASS trước commit.

HTTP probe hiện hardcode output vào evidence05/10: sau chạy đã copy kết quả mới sang
http-api.json của đợt này và restore đúng file05/10 gốc; không sửa lịch sử evidence.
Session QA ở tmp ignored, không publish token/SQLite/mail keys hoặc thông tin auth GitHub.
QA chỉ disposable example.test users, không database người dùng; không gửi email/LLM thật.

## Giới hạn

IAB thử localhost trả ERR_BLOCKED_BY_CLIENT; CUA Chrome unavailable. Browser UI NOT RUN,
không có screenshot/UI claim. Cổng7357 có server khác (worker404); không dùng response đó
làm evidence app này, giữ server đó và xác minh worker7358 khớp build.
Android native/IME/OS relaunch/signing/public HTTPS/provider/video/teamwork chưa nghiệm thu.
SDK3.47.1/Python3.12 khớp CI minors; Java17 hiện được Flutter chọn, Java21 cũng có sẵn
nhưng không đổi global config/accept licenses. Không chạy APK build hoặc claim native PASS.
CI hosted chỉ tra trên PR head sau push; local PASS không thay CI. Không tự merge.

Current backlog: docs/LOCAL_BASELINE_AND_ROADMAP.md; giữ evidence cũ theo source/ngày.
