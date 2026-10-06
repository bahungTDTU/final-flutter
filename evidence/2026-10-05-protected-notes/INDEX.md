# Ghi chú bảo vệ — nghiệm thu local05/10/2026

Base Git `aded41ec0ccdbfb46cae579b64ef3eab004f68bf`, master + working changes gồm AI đợt trước
và protection đợt này. Không commit/push/deploy mới. Những log01–03/10 và AI05/10 giữ phạm vi
lịch sử; manifest ở đây bind mã/tài liệu/build bytes hiện tại, không sửa hashes của mốc cũ.

## Thay đổi

ProtectedNoteVault password cache/draft AES-GCM + PBKDF2-SHA256600000, account+note AAD;
device/account encrypted snapshot field merge; no password/key persist, no ordinary content
cache/search/outbox. Reader edit/autosave/immutable op/own ack/confirmed owner delete,
offline password unlock/revalidate/recovery copy, clean SSE/frozen base/dirty409. Old-password
draft có copy bền trước khi thay cache bằng password mới; input mới không bị đánh dấu đã copy.
UI dùng NoteTextField chung, metadata chỉ sau unlock; server gate cho private files/shares/AI.
Back drains local writes; picker obscures/revalidates; ordinary background locks.

## Lệnh và kết quả

Các lệnh chạy ở `D:/flutter cuoi ki`. Runtime Windows11/Flutter3.47.1/Dart3.13.1/Python3.12.
Backend8000 FastAPI/SQLite thật; in-app browser7357 Web release localhost. Android emulator
`taskflow_api36`, API36, debug Skia software rendering, `adb reverse tcp:8000 tcp:8000`.
Ngày/timestamp real trong logs/HTTP JSON và collected_at_utc manifest; không dùng video timestamps.

| Command / target | Result / evidence |
|---|---|
| `scripts/check.ps1` | Format/analyze sạch;143 Flutter/79 backend PASS trong `check-current.txt`;1 TestClient deprecation warning |
| `flutter test test/protected_editing_test.dart` | 12 PASS `protected-final.txt`: production KDF/nonce/account/note, actual encrypted file reopen, latest draft/lost ack, old-password recovery→new unlock, delete409/revoke, field merge/account switch, picker gate |
| `python -m pytest backend/tests/test_protected_editing.py -q` | 6 PASS `targeted-backend.txt`; real FastAPI/SQLite TestClient. Owner/viewer/editor/stranger, grant expiry, payload cannot change protection, private files, revision/replay |
| `python scripts/qa_protected_notes.py` / HTTP8000 | PASS `http-api.txt/json`, disposable users/notes. Locked423/stranger404/minimal list; protected editor save/replay; viewer edit403/editor delete403; stale409; private upload/read/delete; revoke/password-change invalidation; owner delete404 |
| Existing protection/recovery/preferences/AI tests | 32 PASS `existing-targeted.txt`; preserve unlock/revoke order, encryption/recovery, prior invariant |
| `flutter drive --driver=test_driver/protected_notes.dart --target=integration_test/protected_editing_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000 --enable-software-rendering --no-enable-impeller` | PASS actual final source1scenario + teardown in43s `android-current.txt`; first scoped PASS `android-core.txt`, setup-race repair PASS `android-rerun.txt` |
| `flutter pub get` after integration | `pub-get-final.txt`; restore plugin dependencies before release, no hand-edited Java registrant |
| `scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8000` | PASS92s `web-current.txt`;40 static resources/workeraaf0baf19a213a73; static-only cache; SHA in manifest |
| `scripts/build.ps1 -Target apk -ApiUrl http://127.0.0.1:8000` | PASS85.2s/56.2MB `apk-current.txt`; local debug signing/HTTP URL, build acceptance only |
| `python evidence/2026-10-05-protected-notes/collect_manifest.py --verify` | Hash/README equality check only, no QA rerun; `manifest-verify.txt` |

Native scenario: actual unique registration/server-protected fixture→password unlock→peer HTTP
content update→real SSE reader update→explicit new-base edit→autosave/API exact content→ordinary
cache/draft/outbox no source content→port65530 actual socket refusal→offline password unlock/edit→
encrypted DB close/reopen→online grant revalidation/same-source sync→owner delete confirmation→GET404.
Production KDF/default platform key provider; no injected short work factor. Screenshots
protected-native-editor.png/protected-native-reopened.png show reader/edit/reopened draft.

## Actual Web UI

Codex in-app browser at `http://127.0.0.1:7357`, API8000, viewport1280×720 screenshots.
QA fixture users created by script; no real personal notes. Session/tokens only `tmp` ignored,
never copied to evidence. These actions use actual page controls, not hidden app-state mutations.

- Locked Home has generic card without title/labels/pin/shared detail. After password unlock,
  visible shared/pinned/owner metadata; clean peer actual HTTP update appears automatically
  (`web-peer-update.txt`, web-live-reader.png). Explicit new-version edit→autosave exact content
  confirmed by API `web-autosave.json`, web-edited.png.
- Protected TXT actual filechooser→upload success; selected picker callback revalidates before
  upload. `web-protected-files.png`, `web-file.json`: downloaded through authenticated API and
  hash/content match fixture; `private,no-store`. No browser download/export claim for this run.
- Owner share dialog renders existing viewer/editor with roles after unlock
  (`web-protected-shares.png`); mutations have API/earlier sharing evidence, no new full native
  protected sharing UI acceptance claim.
- Stop/restart owned API8000 server to induce real backend unavailability, leave static server7357
  running. Reader hides; password opens loaded cache; offline edit→Back awaits writes→reload→
  locked Home + nonsensitive recovery notice→password reopens same draft. Reconnect hides,
  asks new server unlock, then sends immutable protected change. API confirms same ID/count1,
  exact body/revision5 and locked-list only4fields (`web-offline-verified.json`). This is backend
  unreachable, not whole-browser network-offline or Wi-Fi-toggle proof.
- PNGs web-offline-draft/offline-reload-locked/offline-reopened/reconnect-revalidate/reconnected
  capture states. Final bundle smoke recorded separately after source/build refresh in
  web-final-build.json/web-final-build.png when present; earlier flow images bind tested source
  before final copy/delete refinements, with those refinements covered by host regressions.

After final build: served JS/worker SHA-256 equals build bytes (`web-served-build.json`),
IAB reload twice→locked list→unlock→edit→autosave→actual API exact content/revision6/minimal
list/count1 PASS (`web-final-build.json/png`). Browser cache executable hash was not inspected;
do not equate HTTP server byte equality with proof of exact code executed in the browser.

## Failures and repairs

Initial parser/lint errors corrected before analyze PASS. Existing test detected unlock→close→
new unlock order regression; relock now serializes revoke even if online unlock is in flight.
New widget expectation initially counted title in background and dialog; narrowed dialog scope,
then globally asserts title absent after revoke. Backend tests initially assumed upload201 and
an owner grant not yet unlocked; fixtures corrected to actual contract200 and explicit owner relock.
`backend-failure-redacted.txt` retains failure fact with disposable bearer tokens removed.

Full host KDF initially exceeded default30s while concurrent tests/build ran; retained
`full-check-kdf-timeout.txt`, added only this real600000-round test timeout2min. No weaker
production KDF. `android-final.txt` records setup race: SSE refresh started between idle observation
and controller changeProtection. New integration creates protected fixture with actual API and
waits locked metadata, preserving production guards; rerun logs show actual final outcome.

## Limits

HTTP MockClient and injectable workFactor50 only in race/widget units; actual KDF test and native/
Web production use600000. Crypto/encrypted file reopen tests use real libraries; fault/HTTP unit
adapters are doubles. Native close/reopen in same process is not OS force-kill/relaunch; failure
port65530 is not Wi-Fi toggle; emulator software rendering is not physical/default-renderer QA.
IME/frame warnings in logs are not measured FPS or a claim that jank is solved.

Đã dừng đúng hai process của emulator headless do đợt QA khởi chạy (launcher28524 và child31636,
đường dẫn D:/Android/sdk/emulator). Backend8000/Web7357 local vẫn phục vụ bản build để xem.
Known Gemini-key-pattern scan trên tracked/nonignored text không có match; không đọc các file
credential bị ignore, không phải comprehensive secret/security audit.

No E2EE: server has content. No key backup/export/transfer, multi-tab stress, secure erase,
anti-XSS/screenshot/OS recents guarantee or physical revocation of downloaded offline copies.
Session/profile storage hardening remains. Native protected OS picker/media, screen-reader,
physical-device/public HTTPS/release-functional/two-device load/video remain NOT RUN.
Gemini live NOT RUN; no key read/saved/used here. AI fixtures from previous turn are separate.
Public deployment, contributions4weeks and submission gates remain in STATUS/matrix.
