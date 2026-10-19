# Backup/mail-key validation —19/10/2026

Base master d59fdfda46bd4a29bfa114f9781a21225f6454cc, fetched from official GitHub;
PR8 merged eaf39b4 and PR9 merged d59fdfd. Initial working tree clean. New branch
codex/backup-restore-hardening; author/committer Nguyễn Bảo Long
<523k0014@student.tdtu.edu.vn>, AI-assisted. No history/evidence rewritten.

## Reproduced problem

A different32-byte key was accepted with a database containing queued email jobs.
A valid manifest/hash only checks copied bytes, not the database/key pairing. A restore
could report PASS but later generate verification codes whose digests do not match
stored tokens. Malformed JSON root/map types also escaped CLI validation with traceback.

New regressions BEFORE fix:5failed/2passed (regression-before.txt). AFTER fix:
Full backend:148 PASS,145.54s (backend-tests.txt).
16 backup+emailqueue tests PASS (targeted-tests.txt);7 backup tests including CLI
exit2/no traceback/no source-path leakage PASS (backup-cli-tests.txt).

## Change and scope

Reuse the unchanged mail PRF in worker and offline validator. Reconstruct every job
that retains a nonce and compare its code digest to the snapshot's token_digest.
Wrong key cannot publish a completed backup manifest or create a restore destination.
Reject non-object manifest/non-map sha256 before dereferencing. Existing WAL snapshot,
private BLOB/ACL restore, pending code verification and no-overwrite tests remain.
If no job retains a nonce, key identity cannot be verified from erased nonces;32-byte
validation remains. Hashes/PRF do not authenticate an untrusted backup source.

No external email/Gemini calls, personal database/key, Docker changes, deployment,
Android/Web UI changes or full rubric claim. Email transports in tests are explicit
test doubles or local TLS sinks, not Internet inbox acceptance. Docker engine remains
unavailable (DockerDesktopLinuxEngine pipe absent); no new container PASS claim.
Native/manual/provider/signing/public-release/submission gates stay separate.

## Reproduce

From repo root with its Python3.12 venv:
- `.venv/Scripts/python.exe -m pytest backend/tests/test_backup.py backend/tests/test_email_queue.py -q`
- `.venv/Scripts/python.exe -m pytest backend/tests/test_backup.py -q`
- `.venv/Scripts/python.exe -m pytest backend/tests -q` (backend-tests.txt)
- `git diff --check`; Python compileall for backend.backup/email_queue:PASS.

CLI usage unchanged: `python -m backend.backup backup/restore ...`; see
[runbook](../../docs/RELEASE_AND_BACKUP.md). No backup/key/session data published.
README.md/Readme.txt byte-identical; previous acceptance evidence remains historical.
