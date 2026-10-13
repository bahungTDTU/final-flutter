# Clean clone and two UI acceptance —12/10/2026

Exact947802a cloned from official GitHub to C:/Temp/notetogether-clean-947802a,
.git preserved, detached HEAD, fresh Python3.12 venv, Flutter3.47.1 SDK F:.
`setup.ps1 -Python <bundledPython3.12>` PASS; `check.ps1` PASS format/analyze,
270Flutter and142backend. `build.ps1 -Target web -ApiUrl http://127.0.0.1:8042`
PASS40static resources; `flutter build apk --debug --dart-define=API_URL=http://127.0.0.1:8042`
PASS with process-only JVM Unixsocket workaround. Working tree remains clean.
See clean-clone.json/logs. This is local Web/debugAPK, not production signing/HTTPS release.

## Two independent actual UIs

Two IAB tabs/origins127.0.0.1:7364 and localhost:7364, distinct account stores and
sessions, actual Web UI login/open/edit/share/revoke/recovery. Fixture setup through
real API only; competing edits and permission changes/recovery used both UIs.
Disposable backend8042. Served Web artifact from previous46df286 acceptance; Git diff
lib/web/pubspec/lock to947802a is empty, verified in clean-clone.json. No claim that this
is newly built production artifact or two physical devices/native UI clients.

1. Owner and peer open original083c224c-236e-492c-9d8f-c774f5ccfd0e at same revision.
   Both enter different body via actual editor controls. Browser accessibility fill first
   inserted prefix before original text (visible in saved evidence); both full resulting
   strings were retained and verified, not replaced with an imagined intended value.
2. Peer autosave wins; owner shows conflict, owner local text stays in editor.
   Owner returns to library, opens conflict and chooses Giữ bản sao của tôi.
   Original server content preserved; newUUID b143305c-a60d-4d9a-b86b-b6ef3a89cd1d holds owner text.
3. Owner opens actual sharing manager, requests revoke and sees confirmation. Peer's
   first edit saves before confirmation (original revision3). Peer then types fresh text
   immediately before owner confirms revoke. SSE removes peer access/content from editor.
4. Peer library shows1 safely retained edit. Recovery opens new note; Đồng bộ uploads
   newUUID e8cc9c3d-6eb7-4231-a560-1a50e62abad7 with exact revoked draft text. Original
   remains revision3 without that draft. Peer original404; peer ownercopy404; owner peercopy404.
   See two-ui-backend.json and screenshots/AX snapshots. Initial diagnostic expected
   a Quill sentinel newline in plain storage incorrectly; corrected per plain text contract,
   exact content assertions retained. No application code changed.

N03 Web conflict/revoke/newUUID recovery now exercised on two UIs; remote lock/delete/
downgrade and native twoUI variants remain distinct. N01 realIME, N02 OS relaunch,
N04 realTTL/background, N05 OS picker/avatar/labels/accountpassword still open.
Provider/HTTPS/release key/video/Rubric/teamwork and Docker engine remain prerequisites;
see docs/REMAINING_GATES.md. No fabricated fullstage PASS, release or approval.
