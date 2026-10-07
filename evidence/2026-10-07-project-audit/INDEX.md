# Audit evidence — 07/10/2026 Asia/Saigon

Base f8ff8fa427b3d490255c0522699f1a9650a3cb73 + existing uncommitted UI changes.
Read-only application audit; new report/probe artifacts only. No app fixes, push,
deployment, Internet SMTP or LLM calls. UTC timestamps in JSON fall on06/10 evening;
local date is07/10.

| Command / target | Observed result | Limits |
|---|---|---|
| `.venv/Scripts/python.exe evidence/2026-10-07-project-audit/probe.py` | Real Argon2/disposable SQLite/TestClient: unlock5 wrong403 +6th429; protection6 wrong403 during block, correct disable200; viewer403/stranger404. Locked list removes pinned_at/shared_count. See probe.json | Confirms findings, not a fixed regression PASS; no network/UI/production data |
| `flutter test evidence/2026-10-07-project-audit/write_amplification_test.dart --reporter expanded` |1 host probe PASS:500 notes ×1.000chars,20 draft updates →20 encrypted envelope writes/16.686.660 JSON bytes. Latest draft restored. See write-volume.json/.txt | Real AES-GCM; keys/records RAM, not Sembast/device. No disk latency/FPS measurement |
| `python evidence/2026-10-06-editor-sections/collect_manifest.py --verify` | PASS source/evidence integrity | Does not rerun167 Flutter/88 backend tests, builds or target QA |
| `git -c http.sslBackend=openssl ls-remote origin refs/heads/master` | Remote master f8ff8fa matches local HEAD | Read-only per-command override after Windows schannel default failed; Git config/history unchanged |

Probe helpers were first run from ignored tmp/audit-2026-10-07, then copied here
byte-for-byte for reproducibility; relative ROOT/import paths remain valid.
Flutter SDK bootstrap in restricted sandbox produced no output and was interrupted;
rerun with allowed SDK cache access completed in write-volume.txt. Not counted as
an app failure or a second test result. No unrelated process stopped.

Full audit: [PROJECT_AUDIT_2026-10-07.md](../../docs/PROJECT_AUDIT_2026-10-07.md).
Checksums/remote/readme identity metadata in audit-summary.json. Historical logs
and reports were preserved; stale statements are called out in the new report.
