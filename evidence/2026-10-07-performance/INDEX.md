# Performance QA — 07/10/2026 Asia/Saigon

Base `5b82996c3fd42e046a9e087471dc0f2effc156ae` + working changes. No commit/push/deploy,
release signing, real LLM or Internet mail in this request. New implementation F3/F4;
historical audit and old dated manifests/logs remain intact.

| Command / target | Observed result | Scope |
|---|---|---|
| `scripts/check.ps1` → check-complete.txt | Format83 files0changes; analyze clean;180 Flutter/94 backend PASS | Final core implementation including missing-root guard; host tests. TestClient upstream deprecation warning retained |
| `flutter test test/draft_projection_test.dart test/encrypted_recovery_test.dart test/sync_durability_test.dart test/protected_editing_test.dart --reporter expanded` |42 PASS → flutter-targeted.txt | File Sembast/AES + request doubles; early implementation, not native/provider acceptance |
| `python -m pytest backend/tests/test_attachment_projection.py backend/tests/test_attachments.py -q` |12 PASS → backend-targeted.txt | Real SQLite/ASGI/cursor observation; list/replay zero BLOB materialization, download exact byte boundary |
| `flutter test test/draft_projection_test.dart --reporter expanded` |7 PASS → flutter-final-projection.txt | After final gate, strengthened existing fold test: empty projection overrides root drafts after file reopen. Same7 cases; no new test count |
| `flutter drive --driver=test_driver/ui_cohesion.dart --target=integration_test/draft_projection_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8017 --enable-software-rendering --no-enable-impeller` |1 functional workflow + teardown PASS8s → native.txt/2PNG | Android API36 taskflow_api36, platform recovery keys + application support file; failed socket65530, latest draft restored, remote revision1→2/same ID/count1. Not2 functional cases/OS kill/Wi-Fi/physical/FPS |
| `python scripts/qa_performance.py --url http://127.0.0.1:8017 --output evidence/2026-10-07-performance/http.json` |Actual HTTP4roles PASS → http.json/.txt | Owner upload/replay/list/grant/private hash, editor upload/delete/revoke404, viewer read200/write403/locked423, stranger404/anonymous401; disposable loopback accounts |
| IAB Web debug7366 → actual API8017 |offline draft/reload/restored editor/reconnect/autosave ACK PASS; verify_web.py confirms revision3→4/same ID/one note → web-result.json/.jpg/AX/.txt | UI actions via computer-use, account registered by HTTP helper. API stopped after login, static Flutter debug server remained online. API restarted after cached Home/editor opened; restored proof screenshot shows reconnected draft, before valid title/autosave. No service-worker cold first visit/OS kill/FPS claim |
| final format/analyze + manifest verify |See format-analyze-final.txt/integrity.txt | Source/evidence integrity does not rerun targets or imply a public release |

## Measured probes

Write workload:500 notes×1000chars,20 consecutive draft updates,5 repetitions, seed excluded.
Real AES-GCM/file Sembast; memory key provider on Windows host. Every run closes/reopens
file and verifies all500 notes/latest text. Before16,886,608 encoded JSON envelope bytes /
20 full account writes; after4,848 bytes /0 full account writes; **20 durable transactions
still complete**. Median20updates2530.732→129.047ms. Bytes are envelope JSON payload volume,
not filesystem IO or file size; time is host batch duration, not keystroke/frame latency.

Attachment workload:10 stored BLOBs×5MiB, disposable SQLite + local ASGI TestClient,
one warm-up excluded then7 measured requests. Python tracemalloc peak10,536,155→52,505B;
median203.092→5.055ms. This is Python allocation, not RSS or SQLite/disk internals.
Metadata response remains10 records/exact6 fields; no BLOBs or credentials in results.
See write-before/after.json, attachments-before/after.json, comparison.json and raw logs.
Timings reflect host load at their actual UTC timestamps, not production/native/FPS claims.

Probes initially ran under ignored tmp/performance-2026-10-07. After-run helpers were
copied byte-for-byte here (write_probe_test.dart, attachment_probe.py, summarize.py,
server.py/verify_web.py). `write_probe_before_test.dart` is a later compatibility copy
without the new writeBatch override, for running the same workload against base Git;
it is not claimed to be a byte-exact archived helper from the earlier before run.
Before production code was base Git; after typing code is the small projection path.
The subsequent missing-root defensive check affects full-root initialization, excluded
from write timing. Final gate/native ran that guard, and final hashes represent final code.

```powershell
$env:PERF_OUTPUT='evidence/2026-10-07-performance/recheck-write.json'
& 'C:/Users/LENOVO/flutter-sdk/bin/flutter.bat' test evidence/2026-10-07-performance/write_probe_test.dart --reporter expanded
& ./.venv/Scripts/python.exe evidence/2026-10-07-performance/attachment_probe.py --output evidence/2026-10-07-performance/recheck-attachments.json
```

These commands generate **new** measurements, not overwrite before/after history. To measure
before again, use a separate checkout at base5b82996, copy the baseline compatibility helper
under evidence/date and run it there; attachment helper supports both implementations.
No current-branch reset is needed. Full account saves/sync still rewrite whole snapshots;
projection contains all ordinary drafts for account, not per-note shards/delta sync.

## Failures and cleanup

- Initial check.txt: ambiguous Finder import in new native harness + two missing-brace
  lints. Fixed import/braces; check-final.txt passed180/94. New same-key AAD assertion had
  an unnecessary `!` lint in check-final-root-guard.txt; removed; check-complete.txt PASS.
- First native.txt attempt missed card because center overlapped bottom navigation, then
  lacked an editor field. Preserved native-first.txt; harness scrolls card clear before tap.
  First successful native-before-root-guard.txt remains separate; final native.txt runs
  guard-enabled source. Debug SDK XML/IME/frame warnings kept, not an FPS measurement.
- write-before-uninitialized.json/.txt is an earlier exploratory uninitialized-controller
  probe, excluded from comparison. Canonical before/after both initialize same account cache.
- attachments-before-first.txt failed only temporary DB cleanup on Windows (SQLite context
  manager did not close connection). Explicit contextlib.closing fixed fixture, then canonical
  before rerun passed. No app failure hidden or fabricated run/acceptance.
- QA backend shutdown via Stop-Process first errored; actual HTTP remained reachable.
  Verified own server command then .NET Process.Kill stopped it; browser subsequently showed
  Offline. Only dedicated loopback API/Web/emulator created for this QA were stopped.
  QA login fixture lives only in ignored tmp and is removed at finish; evidence has no tokens.
  backend-restarted.txt is empty: warning-only logger emitted no lines. Artifact copy first
  found no Tee file for this empty output, then wrote an empty capture; target results are
  HTTP/Web/native logs, not the absent backend stdout.

Design: [PERFORMANCE_DRAFTS_AND_ATTACHMENTS.md](../../docs/PERFORMANCE_DRAFTS_AND_ATTACHMENTS.md).
source-manifest.json records real UTC collection time/base hash/final inputs/images. No fake
commit/teamwork, fabricated coverage, provider or physical-device claim.
