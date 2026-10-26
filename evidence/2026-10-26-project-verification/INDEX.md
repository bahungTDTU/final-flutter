# Verification and publication — 26/10/2026

Base9003d65, branch codex/submission-performance-audit. Before edits:
`git fetch origin`, verified ZIP backup of25pending files under ignored tmp/pre-pull-20261026,
then `git pull --ff-only origin master` returned Already up to date.
Existing local listing optimization/audit preserved; .agents and original assignment extract not published.

## Fixes

- Listing candidate IDs use existing owner/share indexes; avoids work proportional to
  unrelated accounts while preserving role/redaction/labels/order. Original regression
  and before/after data remain in ../2026-10-23-submission-performance.
- Rich JSON nesting beyond parser capacity raises a validation ValueError instead of
  unhandled RecursionError. Sync rejects with422 and no note/operation mutation;
  valid subsequent writes succeed. plain_content preserves malformed legacy text.
- Two20000-level tests failed before fix (`deep-final-before.txt`). Initial2000-level
  probes passed (`deep-json-before.txt`, `legacy-before.txt`); these are not failures.

## Commands and evidence

- `scripts/check.ps1`: PASS format137files/analyze/331Flutter/155backend in checks.txt; one Starlette/httpx deprecation warning.
- `python -m pytest backend/tests/test_note_document.py backend/tests/test_listing_scaling.py -q`:
  targeted.txt,17PASS.
- `python run_api.py`: http.txt/http-roles.json; actual loopback8077 owner/viewer/editor/stranger,
  locks, grants, immutable replay/conflict, attachment permissions, revoke and delete.
  Temporary backend stopped; private QA database and session file deleted.
- `python scripts/benchmark_tenant_listing.py --output evidence/2026-10-26-project-verification/benchmark.json`:
  49visible,0/20000unrelated;7200SQLite steps in both; median0.782/0.789ms.
  Local synthetic11runs after warmup, not HTTP/FPS/load. Timing differs from23/10;
  old measured results retained, not replaced.

No UI/client/schema/dependency changes. Fresh browser/native runtime/build/provider/
public HTTPS/signed-release/submission acceptance NOT RUN. Historical build/runtime
evidence does not establish a fresh run. No merge/deploy; hosted CI recorded on PR.
