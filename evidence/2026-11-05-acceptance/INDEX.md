# Local acceptance — 2026-11-05 (Asia/Saigon)

Target: `ee7c8366506b6ebf66ba7974b0506841c872cddd`, unchanged application source.
No GitHub/CI refresh, public deployment, provider call or submission in this run.

| Command / check | Result | Evidence |
|---|---|---|
| `scripts/check.ps1` format | PASS, 137 files, 0 changes | checks.txt |
| Same command: analyze | PASS, no issues | checks.txt |
| Same command: Flutter tests | PASS, 331 tests | checks.txt |
| `.venv/Scripts/python.exe -m pytest backend/tests -q` | PASS, 155 tests; 1 Starlette/httpx deprecation warning | backend.txt |
| `.venv/Scripts/python.exe evidence/2026-11-05-acceptance/run_api.py` | PASS, actual HTTP 4 roles and protected files/edits/revoke | http-run.txt, http-roles.json, api-server.txt |
| `.venv/Scripts/python.exe scripts/benchmark_tenant_listing.py --output evidence/2026-11-05-acceptance/benchmark.json` | PASS bounded SQLite work: 7,200 steps both 0/20,000 unrelated; 49 visible; medians 0.352/0.334 ms | benchmark.json |
| `scripts/build.ps1 -Target web` | PASS local release; 40 static resources, worker `notetogether-static-6653533e1b9d86f4` | web-build.txt |
| `adb devices -l` | No connected devices | Observed during this run; Android runtime NOT RUN |

HTTP runner used temporary SQLite and fixture email delivery; AI disabled. Server stopped
and disposable database removed by runner. Ignored private session JSON named in http-run.txt
was deleted after QA; no tokens included in evidence. The benchmark is synthetic in-memory
SQLite, not production HTTP latency/FPS/load.

Web build warns about expected CupertinoIcons font and available dependency updates.
Build succeeds; visual icon rendering NOT RUN. No dependency upgrades were made.
Python project venv has no pypdf; original PDF was read successfully using bundled runtime
Python/pypdf instead. PDF object-pointer warnings did not prevent extraction of required pages.

NOT RUN: fresh browser/UI, native UI/release, real SMTP inbox/LLM, public HTTPS,
independent-network/fresh-install acceptance, demo/Rubric/final ZIP/teamwork acceptance.
User confirmed release URLs/artifact/providers are not yet available. Automated tests do
not close these gates. See ../../docs/ACCEPTANCE_2026-11-05.md for required evidence.

Toolchain observed: Flutter 3.47.9, Dart 3.13.7, Python venv 3.12.14.
Full scripts/check.ps1 also finished exit 0 (backend 155 PASS); backend.txt was an independent run while Flutter was pending.
