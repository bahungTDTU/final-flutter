# Submission/performance audit — 23/10/2026 Asia/Saigon

Base9003d65; branch codex/submission-performance-audit; uncommitted backend change.
UTC timestamps22/10T17:xx correspond to23/10 after midnight in Asia/Saigon.

- `github.json`: live master/PR15/checks/reviews/openPRs/releases read from GitHub API.
- `before.json`, `after.json`: `python scripts/benchmark_tenant_listing.py --output <new-path>`.
- `regression-before.txt`: `python -m pytest backend/tests/test_listing_scaling.py -q`, FAIL before fix.
- `targeted.txt`: `python -m pytest backend/tests/test_listing_scaling.py backend/tests/test_note_listing.py -q`, 6PASS after fix.
- `backend-final.txt`: `python -m pytest backend/tests -q`, 153 PASS, one Starlette/httpx deprecation warning on modified source.
- `asgi-after.json`: `python scripts/benchmark_notes.py --counts 10 1000 --repeats 7 --output <new-path>`.
- `asgi-baseline.json`: same script with backend.app.list_visible_notes loaded from `git show HEAD:backend/note_listing.py`; no working source replaced.
- `run_api.py`, `http.txt`, `http-roles.json`: actual loopback8077 API4roles, private attachments, lock/revoke/conflict; temporary server stopped and DB deleted.

Measurements use synthetic fixtures, no provider/inbox/public HTTPS or user data.
Flutter/native/FPS/browser/load/release/submission acceptance NOT RUN in this turn.
Existing source and prior evidence preserved; no new push/merge/deploy.
