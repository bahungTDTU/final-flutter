# Writing Studio — 06/10/2026

Base commit `aded41ec0ccdbfb46cae579b64ef3eab004f68bf` + working changes chưa commit.
Source-only increment; không build release/push/deploy. Các evidence lịch sử giữ nguyên.

| Command / target | Kết quả | Evidence |
|---|---|---|
| `scripts/check.ps1` / host SDK | format74 files unchanged, analyze clean,155 Flutter/88 backend PASS;1 upstream deprecation warning | check.txt |
| `flutter test test/writing_studio_test.dart` | 9 meaningful domain/widget regressions; gate/layout rerun có kết quả cuối | flutter-targeted.txt; flutter-layout.txt; check.txt |
| `.venv/Scripts/python.exe scripts/qa_writing_studio.py` / actual API8012 | owner409/lock423/editor update/revoke404/viewer403/stranger404 + locked minimal metadata PASS | http.json; http.txt |
| `flutter run -d web-server --web-port=7362 --web-hostname=127.0.0.1 --dart-define=API_URL=http://127.0.0.1:8012` / IAB | Actual gallery/meeting draft/edit/check/focus start-pause/reload; HTTP checked content revision2; remote SSE lock hides tools/text/semantics PASS | web.json + web-*.png |
| `flutter drive --driver=test_driver/writing_studio.dart --target=integration_test/writing_studio_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8012 --enable-software-rendering --no-enable-impeller` / API36 debug | 1 scenario + teardown PASS; actual API same-ID revision2, platform keys/encrypted Sembast offline close/reopen | android-final.txt + native-studio-*.png |
| `flutter pub get` after native integration | Restore normal dependencies/registrant; no generated Java handedit | pub-get.txt |
| `python collect_manifest.py` then `--verify` | SHA256 binds source/evidence/base; README/Readme equality | source-manifest.json; manifest-verify.txt |

API process uses `NOTETOGETHER_DB=tmp/studio-qa.sqlite3`, loopback8012, `WEB_ORIGINS` permits7362;
SMTP/AI disabled. Disposable generated test users; no real mailbox/Google request. Login material
and session tokens only in ignored tmp files; not included in evidence manifest. No user note modified.

Full-gate first attempts found Home header growth/lazy-card and large text regressions; final layout
uses compact icon on mobile appbar/desktop filter toolbar, preserving existing list height. Final
gate is authoritative. Web checkbox check API initially reported immediate-state timeout while the
debounced UI updated; fresh DOM showed checked, HTTP and reload verified actual `[x]` text.

Boundaries: no FPS/animation smoothness measurement; emulator software renderer logs IME/frame
jank and is not physical-device performance evidence. Default renderer/physical/NVDA/TalkBack/
OS kill/production/HTTPS/release/video NOT RUN. Advanced tools apply to ordinary editor only;
protected reader follows its existing password/grant flow. No standalone creativity score claimed.
