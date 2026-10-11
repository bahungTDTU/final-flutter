# Baseline máy mới và lộ trình nghiệm thu —12/10/2026

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

## Backlog duy nhất cho các chặng tiếp theo

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
