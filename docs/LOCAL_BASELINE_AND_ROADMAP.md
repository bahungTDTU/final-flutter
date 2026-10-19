# Baseline máy mới và lộ trình nghiệm thu —12/10/2026

## Tiếp tục từ GitHub —19/10/2026

PR8 và PR9 đã merge; base hiện tại `d59fdfd` gồm sửa editor/tìm kiếm/inspector.
Lượt này trên `codex/backup-restore-hardening`, tác giả Nguyễn Bảo Long, có AI hỗ trợ.
Sửa backup/restore nhận nhầm mail key32byte: đối chiếu PRF với nonce/digest của các
mail job trong snapshot trước khi chấp nhận. Manifest sai kiểu được trả lỗi CLI gọn.
Giữ thuật toán mã email, ACL/editor/outbox và source UI hiện tại.
PASS148 backend tests,16 tests backup/emailqueue và7 backup/CLI tests; Python compile
và git diff whitespace checks PASS. Không rerun UI/native vì không sửa client.
[Evidence và phạm vi](../evidence/2026-10-19-backup-hardening/INDEX.md).
SMTP/Gemini thật, Docker engine/HTTPS/signing/native thủ công và bộ nộp vẫn là gate riêng.


## Clone sạch và hai UI độc lập —12/10/2026

Đúng947802a: setup/check PASS270Flutter/142backend, Web release local40resources và
APK debug build PASS; .git giữ nguyên, working tree sạch. Hai WebUI khác origin/account
PASS dirty409→bản sao UUID mới; owner revoke khi peer gõ→ẩn nội dung→phục hồi riêng,
backend xác nhận original không bị ghi đè và bản sao cô lập quyền.
[Evidence](../evidence/2026-10-12-clean-clone-two-ui/INDEX.md),
[gate/đầu vào còn thiếu](REMAINING_GATES.md). Chưa có approval để merge PR8, provider/HTTPS/key
release/Rubric/video thực; native IME/OS relaunch/picker/TTL còn riêng.


## Chuẩn bị release và phục hồi state —12/10/2026

Đã thêm production HTTPS origin guard và signing Android riêng, không fallback debug.
Backup SQLite nhất quán + mail key, restore vào thư mục mới có integrity/FK/hash checks.
142 backend tests PASS; HTTP restore riêng8043 giữ rich Delta/UUID/file bytes/ACL;
Android debug build PASS, release thiếu key bị từ chối đúng. Native session-storage
PASS migration mã hóa/offline DB reopen/logout401/manual re-login giữ draft.
Native protection enable/change/disable và injected lifecycle relock PASS; không thay
nghiệm thu OS background/TTL thật.
Compose persistent volume/context filtering đã cấu hình; Docker engine chưa khả dụng
sau thử khởi động Desktop, chưa nghiệm thu image/recreate. Xem
[runbook release](RELEASE_AND_BACKUP.md),
[evidence](../evidence/2026-10-12-release-preparation/INDEX.md).
R01 code guard đã kiểm tra; signing certificate thật/HTTPS/providers/video/Rubric và
IME/OS relaunch/picker/two-UI còn gate mở. PR#8 thiếu approval người khác trước merge.


## Tiến độ tiếp tục sau bàn giao —12/10/2026

PR#5 đã merge; master hiện46df286 còn chứa PR#6 security center và PR#7 Deskbook.
Ba required checks của cả ba PR đã success trên đúng head (github.json trong evidence mới).
Working tree ban đầu sạch; tiếp tục trên codex/current-source-acceptance từ origin/master.
Phần baseline bên dưới giữ nguyên source35db810 và trạng thái tại chặng1.

N01/N02 có bổ sung Web Vietnamese/bold/undo-redo/autosave/offline edit/reload/reconnect
giữ UUID/Delta; native note_flow Sembast/platform key/offline socket/reopen PASS.
N03 có native sharing/realtime/frozen-base409/viewer/revoke/recovery PASS và HTTP4roles.
N04 có native protected autosave/SSE/frozen base/encrypted offline DB reopen/revalidation/
confirmed delete PASS. N04/N05 có HTTP protected/private file/change-password/ACL PASS; không thay native
TTL/background/picker/cancel. IME thật, OS process relaunch, hai UI độc lập và các bước
native thủ công vẫn mở; chặng2 chưa đóng. Người dùng xác nhận chưa cấu hình provider,
P01/P02 vẫn blocked bởi SMTP Internet/inbox và Gemini key mới; tiếp tục local.
[Runbook hiện hành](CURRENT_SOURCE_ACCEPTANCE.md),
[kết quả/source/giới hạn](../evidence/2026-10-12-current-source-acceptance/INDEX.md).

## Nguồn chuẩn và phạm vi

Base source: master `35db810` (merge PR#4), checkout sạch trước thay đổi.
Branch làm việc: `codex/local-baseline-readiness`. Chặng1 chỉ sửa setup, tài liệu và
chạy baseline local; không thay business logic, deploy, signing, merge hoặc nộp bài.
Author theo yêu cầu Nguyễn Bảo Long, email523k0014@student.tdtu.edu.vn; GitHub Long-D176.
Có AI hỗ trợ; commit này không chứng minh độc lập/teamwork đủ4tuần.

Đọc current summary ở đây/STATUS/matrix cùng tài liệu chuyên đề. Audit/evidence theo ngày
là snapshot đúng source/target lúc chạy; không sửa raw evidence cũ để thành kết quả mới.
PDF đề gốc và Rubric.xlsx không có trong tracked checkout, cần đối chiếu bản giảng viên
trước chốt bộ nộp. Deadline trong TEAM chỉ trước12/2026, chưa có ngày/giờ chính xác.

## Môi trường và cách tái lập

CI: Flutter3.47.1/Dart3.13.1, Python3.12, Java21 cho build smoke.
Máy ban đầu: Flutter3.47.0/Dart3.13.0, Python3.13, Java17, Android SDK tại C:/Android/sdk.
Setup đầu fail Flutter dependencies vì Dart thấp hơn constraint ^3.13.1; không hạ constraint.
SDK3.47.1 được tải riêng trong work của chat, không upgrade SDK toàn máy.
Python3.12.14 dùng runtime có sẵn, tạo .venv riêng của repo. Không commit runtime/.venv.
Flutter doctor ban đầu báo Android license status unknown; không có Android device connected.
Java21 có sẵn nhưng không tự đổi Flutter global config hoặc chấp nhận license thay người dùng.

```powershell
# Dùng SDK phù hợp và Python3.12 của máy, thay các đường dẫn minh họa.
$env:FLUTTER_BIN = 'C:\Flutter3471\bin\flutter.bat'
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/setup.ps1 -Python C:\Python312\python.exe
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start_backend.ps1
# Terminal khác:
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start_web.ps1
```

Setup tự tìm Python theo -Python → PYTHON_BIN → py -3.12 → python; kiểm tra3.12
trước cài dependencies, kiểm tra .venv hiện có và không tự xóa môi trường sai phiên bản.
SDK path dài/có khoảng trắng đã làm analyze/hooks fail; QA dùng subst F: trỏ SDK riêng
và FLUTTER_BIN=F:\bin\flutter.bat sau khi xác nhận F: chưa dùng. Không đổi SDK toàn máy.
Cổng7357 đã có server khác; start_web thêm -Port, QA dùng7358 và giữ server cũ.
Đặt WEB_ORIGINS chính xác nếu chạy UI ở port khác. Browser UI chưa chạy vì IAB chặn
loopback và CUA Chrome không khả dụng; HTTP/static smoke không thay UI acceptance.
Backend mặc định8000/Web7357. Khi QA dùng DB tmp riêng; không dùng DB người dùng.
.env.example là template; secret chỉ qua process environment/file ignored.
Kết quả lệnh và giới hạn xem evidence/2026-10-12-local-baseline/INDEX.md.

## Backlog gốc tại chặng1 — snapshot lịch sử

Bảng dưới giữ trạng thái lúc lập baseline, không dùng để chọn việc hiện hành.
Bảng gate đang áp dụng nằm ở [REMAINING_GATES](REMAINING_GATES.md); trình tự C0–C5
ở [kế hoạch hoàn thiện19/10](COMPLETION_PLAN_2026-10-19.md). R01 guard và backup
đã có code; các nghiệm thu OS/provider/release còn riêng.

| ID | Chặng / việc | Điều kiện nghiệm thu | Trạng thái ở chặng1 |
|---|---|---|---|
| B01 | Baseline máy mới | Setup/check/backend/Web, exact source và giới hạn ghi rõ | Xem evidence baseline |
| N01 | Android editor hiện tại | IME tiếng Việt, selection/paste/undo/format/autosave/theme/resize trên native thật | NOT RUN |
| N02 | Lifecycle/offline | Web reload và Android OS relaunch, rich text cùng ID/format, reconnect không mất draft | NOT RUN trên source cuối |
| N03 | Conflict/recovery | Hai client dirty409; remote lock/delete/revoke giữ local copy và không vượt quyền | HTTP baseline có; UI hai client cần QA |
| N04 | Protected lifecycle | Unlock/change/disable/TTL/background/relock, không lộ visual/semantics/cache trước unlock | Native source cuối cần QA |
| N05 | Tệp/nhãn/tài khoản | Protected OS picker/TXT/cancel; native AND filters/rename; đổi password→manual login→old session401 | NOT RUN trên hai bản cuối |
| P01 | SMTP Internet | Inbox receipt→verify/reset trên Web/Android, resend/expiry/reuse/error | NOT RUN; cần nhóm cấu hình |
| P02 | Gemini thật | Summary/regenerate/no overwrite; Q&A nhiều nguồn/citations/no-info/ACL/injection evaluation | NOT RUN; thay/config key an toàn |
| R01 | Production preflight | HTTPS API explicit, từ chối loopback/fixture, signing riêng không debug fallback | Chưa triển khai |
| R02 | Backend bền | Persistent SQLite/files/mail key, recreate giữ data, backup→restore bản sao→ACL/hash đúng | Chưa nghiệm thu |
| R03 | Public release | Web/backend HTTPS, SSE qua proxy, APK install/run cùng source từ mạng độc lập | NOT RUN |
| R04 | Clean clone | Clone đúng commit giữ.git, setup/check/build theo README trên thư mục QA riêng | B01 là clone máy mới; release clean-clone vẫn cần |
| S01 | Video/Rubric/ZIP | 32ID có timestamp thật; core hai target; Rubric gốc/URLs/APK/Readme/source.git; unpack verify | Chưa có đầu ra cuối |
| T01 | Teamwork/vấn đáp song song | Phân công xác nhận, contribution thật4tuần, Insights và hai người giải thích/sửa được code | Nhóm thực hiện, không suy từ test |

## Thứ tự và chính sách hoàn tất

B01 → N01–N05; chuẩn bị P01/P02 song song → provider acceptance → R01–R04 → S01.
T01 bắt đầu ngay và duy trì theo tuần. Chuẩn bị release config sớm được, public release
để cuối sau core theo hướng dẫn nhóm. Không thêm chức năng ngoài rubric trong lúc đóng gates.
Không coi mọi NOT RUN là bắt buộc phải xây feature mới: kiểm chứng trước, sửa khi có lỗi.
Không biến key backup/media offline/CRDT/OAuth/table/exportDOCX thành yêu cầu mới của đề.

Mỗi gate ghi date/command/target/expected/actual/base SHA; phân biệt code/unit/mock/socket/
browser/native/provider/public-release. PASS local không thay CI trên PR head hoặc acceptance
trên artifact cuối. Commit/push qua branch/PR;3 required CI, up-to-date, resolved reviews và
approval người khác trước merge; không auto-merge trong yêu cầu publication này.
