# Evidence — rubric + label UX audit, 14–15/10/2026

Base `4a196ef33019b38c6c2812fcbd48f05bf0d7d134`, branch
`codex/dashboard-motion-performance`, working changes/no new commit.
Client date changed from14 to15/10 during browser QA. UTC capture times remain real.
Earlier dashboard/nav working changes preserved. No Git push/merge/deploy.

## Fresh PASS
- `scripts/check.ps1` → check-final.txt:121formatted0changes/analyze clean/295Flutter/143backend.
  five added meaningful regressions in label_manager_regression_test.dart.
- `flutter test test/label_manager_regression_test.dart --reporter expanded` → labels-targeted.txt:
  1000labels mounts6ListTiles,20unchanged pulses retain row widgets; compact320px/text200% conflict,
  search/rename duplicate validation/confirm-cancel/delete preserve original note and first immutable op;
  remote rename updates query; account switch removes form/private fields; two themes/keyboard insets.
- `flutter build web --release --dart-define=API_URL=http://127.0.0.1:8061 --output=tmp/rubric-ux-web-2026-10-14`
  + prepare_web_offline.py → build-web-final.txt;39static resources for QA.
- `scripts/build.ps1 -Target web` → build-web-default.txt;default API8000,40static resources.
- `flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8000` → build-apk.txt.
- Actual HTTP: qa_api.py --url http://127.0.0.1:8061 --output api-roles.json:
  owner/editor/viewer/stranger, anonymous, upload/replay/private body hash, lock423/viewer403/
  revoke404. Disabled SMTP/Gemini, new SQLite under ignored tmp; no production state.
- Actual IAB at7379: browser.json/screenshots/final-state;PC1280×1000 light/dark,375×812
  light/dark,844×390dark;fixture1000labels,search0999,rename→server revision2,
  note content/revision3 unchanged (browser-api-rename.json);no-result/clear restores1000;
  Tab/Enter opens row menu and rename form;cancel retains query;resize retains search.
  Initial arrow keys through AX-activated menu did not select an item; Tab/Enter on the focused
  controls worked. No claim for every keyboard gesture or screen reader.
- PDF original read/extracted19pages; rendered rubric14 and submission18 visually checked;
  official-reference.json keeps PDF hash, not a copied submission/modified original.
- git-refs.txt:46df286 resolves to original full SHA;46df287 does not resolve.
  STATUS/matrix typo corrected; historical evidence untouched.

## FAIL before fix / diagnostics
- label-baseline.txt:1000mounted rows, expectation FAIL. It also includes an initial
  offscreen-click harness warning in the second test; that second result is not accepted.
- layout-baseline.txt: corrected harness reaches sheet;320px/text200% conflict FAIL with
  trailing widget consuming entire tile width. No old assertion was weakened.
- labels-after.txt: first2regressions PASS after source change; labels-targeted.txt tests5final.
- analyze.txt/check-lint-diagnostic.txt:3curly-brace lint infos from intermediate source.
  Fixed, final check clean. build-web.txt is intermediate; final build is build-web-final.txt.
- First sandbox-only server instances were unreachable from host/browser. Stopped them,
  started hidden loopback QA helpers outside sandbox with fresh qa-http.sqlite; actual HTTP
  and browser PASS. Fixture preference setup initially used wrong schema and returned422,
  corrected to `{op_id,dark:false}`; no app schema changed to make the fixture pass.

## NOT RUN / OUT OF SCOPE
Android device list empty; no current native UI/IME/OS lifecycle/picker/TalkBack/NVDA,
GPU frame profile/FPS, Internet SMTP/inbox, real Gemini, CI newest-head, HTTPS signing/public
release/video/Rubric packaging. APK debug build is compile evidence. Phone screenshots are Web.
Native12/10 acceptance is historical, not erased and not substituted for current new widget.

Fixture seed inserted1000labels in the isolated DB, then real GET /labels confirmed count;
this is synthetic load setup, not a claim that1000labels were created through UI.
No token, session cookie, user password, DB, private config/key is published in this folder.
Synthetic examples/login constants in scripts are QA-only; runtime credentials remain ignored.

## Integrity
capture_manifest.py records final source/docs hashes and builds, verifies five prior immutable
evidence snapshots and seals this folder. Integrity does not rerun tests or establish FPS.
README/Readme/status/matrix/UI docs/architecture/backlog link the fresh32-ID audit.
The proposalsD1–D4 are NOT IMPLEMENTED. Public release remains deferred by the user.

