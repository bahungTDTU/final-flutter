# Session storage QA — 07/10/2026 Asia/Saigon

Base Git5b82996c3fd42e046a9e087471dc0f2effc156ae + existing performance working changes
+ session implementation. No commit/push/deploy/public release/provider/Internet mail in
this request. Historical audit/performance manifests and results are preserved at their
original sources/timestamps; they are not regenerated to imply final-source QA.

| Command / target | Actual result | Scope |
|---|---|---|
| `scripts/check.ps1` → check-final.txt |85files format0changes/analyze clean/188Flutter/94backend PASS | Host gate; upstream TestClient/httpx deprecation warning retained |
| `flutter test test/session_storage_test.dart --reporter expanded` |8 PASS → session-targeted.txt | Real AES/file Sembast fault/migration/durability + one memory-double UI retry case; no coverage fabricated |
| `flutter test test/encrypted_recovery_test.dart test/draft_projection_test.dart test/sync_durability_test.dart --reporter expanded` |30 PASS → existing-targeted.txt | Existing recovery/projection/sync invariants after adding session path, also in full188 gate |
| `flutter drive --driver=test_driver/ui_cohesion.dart --target=integration_test/session_storage_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8017 --enable-software-rendering --no-enable-impeller` |1 scenario + teardown PASS5s → native.txt +3PNG | API36 taskflow_api36/Android secure-storage provider/real support file + local HTTP. Deliberate legacy token fixture migrated, raw record lacks user/token and file lacks bearer. Actual failed socket65530/offline reopen; logout bearer→401; manual UI login new bearer + preserved draft. Does not mean2 functional scenarios or OS kill/physical/FPS/default renderer |
| `python scripts/qa_performance.py --url http://127.0.0.1:8017 --output evidence/2026-10-07-session-storage/http.json` |Actual owner/editor/viewer/stranger + anonymous PASS → http.json/.txt | No backend permission changes; upload/replay/private download hash, lock/grant/revoke preserved. Dedicated local QA accounts, no external mail/AI |
| IAB Web debug7366/loopback API8017, computer-use UI |Legacy previous-version QA session restored; encrypted-session reload while backend stopped→Home/cache/Offline; reconnect/logout/reload→Auth; manual login→same note; edit profile→API→offline reload with new profile |WebCrypto provider in real browser. No direct hidden browser storage/token access through automation; byte-level opacity/compaction checked by host/native. Static debug server online; no service-worker cold-first-load/Wi-Fi toggle/OS kill/XSS-immunity claim |
| `python evidence/2026-10-07-session-storage/verify_web.py` |PASS new profile/one note/same ID/revision4 + independent API token logout→401 → web-result.json/web-api.txt |Token held only in helper memory. This server401 is the helper's separate token; native verifies its actual controller token, browser verifies visible logout/reload |
| final `flutter pub get`, format/analyze; `collect_manifest.py --verify` |See format-analyze-final.txt/integrity.txt |Checksums/README byte identity do not rerun browser/native or grant public readiness |

## Storage behavior verified

- Dedicated session key/nonce/AAD, complete token/profile encrypted; ciphertext tamper or
  matching-key transplant into account namespace fails authentication. Account rotation
  leaves session ciphertext unchanged. Session key is outside Sembast and reused after logout.
- Legacy publication/readback/transaction failure keeps original record. Compact interruption
  keeps marker, refuses to release token/call API, then retries successfully. Real file
  migration removes older token + current token/name/email from journal; draft/root preserved.
- Missing session key never regenerates or overwrites ciphertext. New login with local failure
  returns false, keeps Home closed and tries revoking its newly issued bearer. No tokens printed.
- Logout interrupted after tombstone cannot revive old token on reopen; pending account data
  retained, server revoke still attempted. Local publish failure shows explicit retry notice.
- Refresh/logout/login B race keeps A queue durable, sends no A preference mutation and leaves
  B as the stored session. UI retry uses a memory failure double; file rollback tested separately.

## Recorded failures

First targeted run reached7 passed regular cases, then stalled in the widget case because
file IO/crypto ran under the widget fake clock. Stopped only the identified dedicated test
process; kept session-targeted-first.txt. UI case now uses a memory failure double; seven
regular cases retain real crypto/file transactions and the native scenario verifies real
UI/platform storage. Final8 tests passed. This was test-harness work, not an app acceptance.

Initial check.txt stopped on3 missing-brace style infos in the new race mock; fixed braces
and reran full gate in check-final.txt. Native SDK XML/IME/debug frame messages preserved;
do not use them as a performance benchmark. No core source changes after the passing gate.

First manifest collection expected a full AX file, but CUA's immediately repeated captures
are diffs. Raw files remain unchanged. web-observations.json is explicitly a manual record
of the actual full CUA response (profile button/name, Offline and same note); screenshots
and separate API profile result also retained. Manifest validates that recorded scope;
integrity-first.txt preserves the subsequent missing-manifest error from the failed collection.

## Fixture and cleanup

Backend uses the ignored previous performance QA SQLite fixture, explicitly disabled mail/AI,
worker off, bound127.0.0.1:8017. This keeps the saved browser QA bearer valid for migration;
it is not a production database. Browser account from previous QA has one revision4 note;
profile updated only for test. Native uses a unique account and DB, deletes its own QA file
after logout. App's normal local account data/keys are retained by policy.

Created tab, API/Web processes and emulator are stopped at finish; existing gallery/user tabs
remain. The performance HTTP helper's login fixture is only in ignored tmp, removed at finish.
Logs/screenshots/JSON store no bearer or key bytes. Debug VM URLs are temporary SDK diagnostics.
Web provider still does not defend against XSS/extensions/full-profile+key readers; no secure
erase, key backup, public HTTPS, production signing, real Gemini/mail or physical-device claims.

[Design and migration](../../docs/SESSION_STORAGE.md). source-manifest.json records real UTC,
base SHA, final source/evidence hashes and image dimensions; commit is base + working changes.
