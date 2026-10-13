# Release preparation / native follow-up —12/10/2026

Base8307b4c, branch codex/current-source-acceptance; working changes recorded by
source-manifest.json and the containing Git commit. Nguyễn Bảo Long author/committer;
AI-assisted. Earlier acceptance snapshots remain unchanged. PR8 at8307b4c had3CI PASS,
no human approval, no merge. Further commits require their own CI/review.

## Executed results

- `python -m pytest backend/tests -q`:142 PASS,92.02s; backend-tests.txt.
- New backup/preflight tests:24 PASS; backup-preflight-tests.txt. Live WAL transaction
  snapshot excludes uncommitted changes, restores private BLOB/ACL/mail PRF key+queued
  job using a test-only mail transport. No SMTP Internet acceptance claimed.
- `flutter build apk --debug --dart-define=API_URL=http://127.0.0.1:8042`:PASS;
  android-debug.txt. Java Unix socket workaround process-only as prior runbook.
- `gradlew :app:assembleRelease --dry-run`:expected exit1 signing unavailable;
  android-release-no-key.txt. Release signing never falls back to debug. No group
  release key was created, imported or published; real signed APK still blocked.
- PowerShell production guards: missing explicitURL/HTTP loopback/missing key.properties
  all rejected before Flutter build; guards.json. HTTPS syntactic acceptance performs
  no DNS/TLS/network call. This is configuration validation, not public deployment.
- `docker compose config --quiet`:exit0. Docker engine pipe unavailable before/after
  launching Desktop; docker-engine*.txt. Image build/context-layer sentinel inspection,
  container recreate/volume restore not run. Compose runtime remains unverified.
- `python -m backend.backup backup --database tmp/current-source-acceptance/qa.sqlite
  --destination tmp/release-backup-http-20261012`, then restore to NEW
  tmp/release-restore-http-20261012. Private DB/session/key stay ignored. Restored backend
  on8043, original8042 kept. ActualHTTP sameUUID/revision5/rich bold Delta, protected
  owner/viewer/editor access, exact attachment bytes+SHA256, viewer delete403 and
  stranger note/file404 PASS; http-restore.json. Not a container test.
- Native API36 software-rendered emulator5554, actual backend8042:
  `flutter drive --driver=test_driver/integration_test.dart
  --target=integration_test/session_storage_test.dart -d emulator-5554
  --dart-define=API_URL=http://10.0.2.2:8042 --enable-software-rendering --no-enable-impeller`:
  PASS session encryption/migration, socket offline DB reopen, logout401, manual UI
  re-login/newtoken/draft retained. native-session-storage.txt.
- Same native command with target note_protection_test.dart:PASS enable/wrong password,
  temporary reader, injected lifecycle relock, password change old password403, disable,
  private ordinary cache check. Current Quill document selector replaces stale plainText
  lookup; no business changes. native-note-protection.txt; format/analyze PASS.

VM-service capabilities redacted before writing native logs. No auth token, DB, key or
personal data published. source-manifest hashes working-copy bytes used by tools (Git
text normalization can change bytes on checkout).

## Remaining gates and next inputs

N01 real native IME/selection/format; N02 OS process force-stop/relaunch; N03 two independent
UI peers; N04 real TTL/OS background/visual semantics; N05 actual OS picker/cancel/error,
avatar/labels and account password change. Injected lifecycle is not OS background.
P01/P02 require SMTP Internet/inbox and newly configured Gemini. R01 needs group key,
certificate inspection/install; R02 container volume recreate; R03 public HTTPS/proxy SSE
and independent network; R04 clean clone after publishing this code. S01 requires original
Rubric/video/Insights/URLs/APK; T01 requires actual group history and explanations.
Do not mark full stages complete or manufacture receipts/reviews/teamwork.

See docs/RELEASE_AND_BACKUP.md for exact private backup/restore/signing/Compose commands.
Sources: [Flutter Android signing](https://docs.flutter.dev/deployment/android),
[SQLite backup](https://sqlite.org/backup.html).
