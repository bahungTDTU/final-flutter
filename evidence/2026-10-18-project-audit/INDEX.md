# Evidence audit18/10/2026

Source: `codex/dashboard-motion-performance`, HEAD4a196ef33019b38c6c2812fcbd48f05bf0d7d134
+working changes. Target Windows local; ngày người dùng Asia/Saigon18/10/2026.
[Báo cáo và32tiêu chí](../../docs/PROJECT_AUDIT_2026-10-18.md).

## Lệnh và kết quả

- `scripts/check.ps1`: blocked SDK lock; `check.txt` rỗng vì launcher chưa tới format.
- `C:/Users/LENOVO/flutter-sdk/bin/cache/dart-sdk/bin/dart.exe format --output=none --set-exit-if-changed lib test integration_test test_driver`: PASS129files0changes, `format.txt`.
- Cùng Dart executable, `analyze lib test integration_test test_driver`: PASS no issues,
  `dart-analyze.txt`. Không gọi đây là flutter analyze.
- Dart executable + `C:/Users/LENOVO/flutter-sdk/bin/cache/flutter_tools.snapshot --no-version-check test --no-pub`:
  BLOCKED mở SDKcache lockfile; `flutter-tests.txt`.
- `.venv/Scripts/python.exe -m pytest backend/tests -q`: lỗi temp môi trường,
  `backend-tests.txt`; không phải kết quả full suite hợp lệ.
- Với TEMP/TMP trỏ workspace `tmp`, pytest full suite `--basetemp=tmp/pytest-audit-20261018`:
  blocked asyncio socketpair, đã dừng; `backend-final.txt` có thể rỗng do buffering.
- Pytest `backend/tests/test_preferences.py -x -vv -o faulthandler_timeout=20 --basetemp=tmp/pytest-audit-preferences-20261018`:
  stack chẩn đoán ở `preferences-diagnostic.txt`, đã dừng; không PASS.
- `.venv/Scripts/python.exe -m pytest backend/tests/test_release_preflight.py -q`:
  PASS22, `preflight-tests.txt`.
- `.venv/Scripts/python.exe -m pytest backend/tests --collect-only -q`:147collected,
  `backend-collection.txt`; không147PASS.
- `.venv/Scripts/python.exe evidence/2026-10-18-project-audit/probe_handlers.py`:
  `handler-probe.txt`, actual sync route functions + SQLite4roles/lock/unlock/revoke;
  **không HTTP/ASGI/middleware**, fixtures disposable, mail disabled, không Gemini.
- Dart executable `--packages=.dart_tool/package_config.json evidence/2026-10-18-project-audit/probe_validation.dart`:
  `validation-probe.txt`, actual Dart domain/characters; không widget test.
- `git diff --check`: `diff-check.txt`; warnings line endings nếu có không phải code error.

Loopback HTTP thử bị WinError10013; không có actual HTTP/browser/native nghiệm thu.
PDF gốc đọc bằng bundled pypdf, render trang18 bằng bundled pdftoppm; intermediates
ở tmp. Source manifest metadata ghi riêng, không chụp keys/tokens/private DB.
Không sửa source sản phẩm; chỉ thêm report/probes và current audit pointers.
