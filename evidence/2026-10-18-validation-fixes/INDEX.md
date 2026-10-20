# Validation fixes evidence —18/10/2026 buổi tối Asia/Saigon

Branch `codex/dashboard-motion-performance`, HEAD4a196ef33019b38c6c2812fcbd48f05bf0d7d134
cộng working changes. Windows host, Dart3.13.1. [Chi tiết](../../docs/VALIDATION_SYNC_FIXES_2026-10-18.md).

| Command / target | Result / log |
|---|---|
|Dart binary `format --output=none --set-exit-if-changed lib test integration_test test_driver`|`format-final.txt`, source formatting|
|Dart binary `analyze lib test integration_test test_driver`|`analyze-verified.txt`, final source static analysis|
|Dart binary `--packages=.dart_tool/package_config.json evidence/2026-10-18-validation-fixes/contract_probe.dart` → tmp/validation-fixes-contract.json|Actual domain execution; full synthetic content kept in tmp, not evidence|
|`.venv/Scripts/python.exe evidence/2026-10-18-validation-fixes/check_contract.py`|PASS10case against Pydantic, `contract-result.txt`|
|`.venv/Scripts/python.exe evidence/2026-10-18-project-audit/probe_handlers.py`|PASS synchronous route+SQLite4roles, `backend-handlers.txt`; no HTTP|
|Dart binary + Flutter tools snapshot `--no-version-check test --no-pub test/validation_sync_regression_test.dart`|BLOCKED SDKcache lock, `flutter-tests.txt`; not8PASS|
|`git diff --check`|`diff-check.txt`|

Dart binary: `C:/Users/LENOVO/flutter-sdk/bin/cache/dart-sdk/bin/dart.exe`.
Flutter tools snapshot: `C:/Users/LENOVO/flutter-sdk/bin/cache/flutter_tools.snapshot`.
No actual HTTP/browser/native/release/provider/CI acceptance. Source manifest includes
hashes of production code and test source; not an assertion they all executed.
Raw earlier audit evidence is preserved. No external network, mail or LLM call made
by contract/handler probes; all data synthetic in workspace tmp.
