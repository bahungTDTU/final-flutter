# UI/UX QA – cập nhật 03/10/2026

## Maintenance03/10/2026

Giao diện prism giữ nguyên; chỉ bỏ illustration/dependency không dùng. Full host123 Flutter/
56 backend PASS gồm responsive200%/privacy/frozen base/draft/recovery/motion/contrast.
Chrome final Web auth/home và mobile editor theme-resize giữ nội dung; offline edit→reload→
reconnect với real API ID/count/content assertions. Android API36 debug Skia software core
register/autosave/offline/encrypted DB reopen PASS. Web40resources/APK55.8MB build PASS.
Evidence/commands/limits: evidence/2026-10-03-maintenance/INDEX.md. Local SQLite/ASGI benchmark
không phải đo animation FPS; emulator log có IME frame warnings, không kết luận jank đã hết.
Các flow/picker/sharing/SMTP/history/physical/release-functional giữ scope các mốc dưới.

## Đợt lăng kính và motion 02/10/2026

Evidence: `evidence/2026-10-02-prism-ui/INDEX.md`; source/build/evidence SHA-256 trong
manifest. Git tại lúc snapshot02/10 chưa commit/remote. Các đợt bên dưới giữ phạm vi lịch sử của chúng.

| Kiểm tra hiện tại | Kết quả và phạm vi |
|---|---|
| Format/analyze/tests | Format56 files0 changes, analyze sạch; **118 Flutter/53 backend PASS**; một TestClient deprecation warning |
| Motion host | Hover2px/settle/no idle loop; reduced motion giữ geometry và reveal ngay; controller notify không restart theme; 4 test mới trong prism_motion_test.dart |
| Contrast host | 129 cặp tính từ token/tint envelope hai theme đạt ngưỡng text4.5/control3; chỉ các cặp đã chọn, không chứng nhận WCAG toàn ứng dụng/gradient interpolation/mọi SDK state |
| Regression host | Adaptive320/360/390/768/desktop/landscape200%, locked metadata/roles, frozen base/editor ID/caret và durable recovery/preferences/outbox suites PASS |
| Chrome local release | Auth/login API thật, light/dark home, hover; editor đổi theme→390×844 giữ nguyên nội dung; desktop1440×900/tablet768×1024/mobile390×844, dark settings; ảnh thực đã xem |
| Android API36 debug | UI register/labels/preferences/autosave/theme/editor ID/text/caret + GET thật PASS; driver chụp3 PNG; **Skia software** với --enable-software-rendering --no-enable-impeller |
| Actual HTTP ACL | Owner/viewer/editor/stranger read/write/sharing/protection/locked minimal metadata PASS; không chỉ mock |
| Build | Web release41resources/workerd000707d1578e9da; APK release55.9MB PASS sau pub get; build không phải release-functional acceptance |

Hai lần native renderer mặc định bị mất emulator/VM/ADB connection; giữ raw logs,
không tính là PASS hoặc kết luận nguyên nhân GPU. Không đổi renderer flag production.
Chrome auth screenshot đầu bị lệch sau thay DPR của cửa sổ automation; reload ở viewport
ổn định trước chụp final. Navigation response main.dart.js SHA được đối chiếu artifact thật.
Ảnh Home sau quay lại editor giữ scroll; ảnh suffix -top được cuộn chủ động lên đầu.

Không đo FPS/jank/device performance, không claim60fps. Chưa physical/TalkBack/NVDA,
OS kill/relaunch, release-functional/HTTPS/signing. Không rerun Chrome offline/reload,
picker/upload, SMTP hoặc mọi sharing/realtime interaction trong đợt trang trí này;
bằng chứng các flow đó vẫn có phạm vi riêng ở các mốc trước. Controller/API/cache/schema
không sửa, host regression toàn bộ vẫn PASS.

## Đợt nâng cấp toàn diện 02/10/2026

Evidence mới: `evidence/2026-10-02-ui-upgrade/INDEX.md`. Windows11, Flutter3.47.1/Dart3.13.1,
Python3.12.14, Chrome154 local release và Android API36 emulator debug. Commit chưa có.
Các mục 01/10 bên dưới là lịch sử kiểm chứng; không tự nâng thành nghiệm thu mọi flow ở bản mới.

| Screen / trạng thái | Kiểm chứng đợt nâng cấp |
|---|---|
| Auth | Chrome desktop/mobile validation, đăng nhập API thật; Android UI đăng ký thật; form320px/landscape/chữ200% qua widget |
| Home/search/labels | Chrome Ctrl+F, query + AND filter/empty/clear giữ query; light/dark mobile/tablet/desktop; Android tạo nhãn và đồng bộ thật; số lượng lấy từ controller |
| Editor | Chrome theme/resize khi nhập; offline → reload → mở lại → reconnect giữ đúng nội dung và một note trên API; Android autosave/theme giữ ID/text/caret + GET thật; host giữ frozen base |
| Trạng thái kết nối | Khi controller offline, editor ẩn nhãn realtime dù transport còn báo live; regression giữ bản nháp/pending; Chrome offline kiểm tra lại trên bundle cuối |
| Hồ sơ/tùy chỉnh | Chrome mở settings, avatar mặc định/cancel và password/cancel; Android dark/list preferences đồng bộ thật; OS file chooser/upload/password submit không rerun đợt này |
| Chia sẻ | Chrome owner dialog mobile/empty email validation; Android real batch/editor/viewer/revoke/encrypted DB reopen/recovery UI; ACL owner/viewer/editor/stranger direct HTTP PASS |
| Tệp/bảo vệ | Chrome private attachment empty state và giới hạn; host layout/locked metadata/role guards; direct API locked423/minimal metadata; picker/upload/protected-reader full flow không rerun |
| Mã email | Material tiếng Việt và form/token320px/landscape200% qua widget; SMTP/inbox ngoài không nghiệm thu mới |
| AI | Production Q&A báo chưa khả dụng; không có kết quả hoặc submit giả |

`scripts/check.ps1`: format/analyze sạch, **114 Flutter/53 backend PASS**, một deprecation warning
TestClient. Responsive regression320/360/390/768/desktop/landscape và200%; kiểm thử hành vi
query/frozen base/privacy/durable draft, không dùng test mirror để tăng số lượng.
Driver native xuất PNG thật; Web/APK release build PASS, chi tiết/hash nằm trong evidence.
Contrast đo10 cặp text/outline được chọn trong theme (light/dark), PASS ngưỡng4.5/3;
không thay audit mọi trạng thái hoặc chứng nhận WCAG toàn app.

NVDA/TalkBack, thiết bị vật lý, OS force-kill/relaunch, keyboard insets toàn editor,
browser history/deep-link, protected editing/offline unlock và toàn bộ release-functional
chưa nghiệm thu. Chrome offline dùng browser context network failure thật; native DB reopen
là trong cùng process. APK release vẫn debug signing/local HTTP; chưa public HTTPS.

## Lịch sử QA 01/10/2026

## Phạm vi và evidence

Windows 11, Flutter3.47.1/Dart3.13.1, Chrome154, Python3.12, Android API36 emulator.
Native smoke ở logical480×853.3 và360×800 (density240/DPR1.5); đã trả wm size về720×1280.
Không có commit. Code do agent hỗ trợ; không gán authorship cho nhóm. Backend local thật
127.0.0.1:8000; browser Web release 127.0.0.1:7357, không public deployment.
Ảnh/log/contrast: evidence/2026-10-01-ui. README.md/Readme.txt giữ cùng nội dung.

| Screen | Designed | Implemented | Integrated | Web verified | Android verified |
|---|---|---|---|---|---|
| Auth login/register | Có | Có, responsive/toggle/loading/error | API thật | Validation + login Enter thật; register mới chưa browser regression trong lượt này | Integration register tự login; main debug login smoke |
| Recovery/activation/reset | Có | Form mã/resend/reset2 bước, busy/error/input giữ lại | SMTP TLS + code API | Chrome390x844 PASS TLS fixture verify/reset/manual login | Debug API36 integration PASS cùng fixture; email ngoài chưa chạy |
| Home/cards/list/grid/search/pin | Có | Sidebar/rail/bottom nav, group ghim, clear/empty, metadata/privacy | Controller/API thật | Real account, pin/group, list/grid, search-clear; ảnh mobile/tablet/desktop | Integration note flow; main debug smoke |
| Editor | Có | Canvas, typography, local/server status, retry, read-only | Draft/save thật, frozen revision/ID | Edit/theme/resize/Back và dữ liệu server | Real HTTP/Sembast integration |
| Profile/settings | Có | Name/email/avatar picker/upload/default/pending/password | Preferences/profile/password/private avatar APIs | Avatar actual chooser/upload/offline reload/default PASS; password success chưa browser | Avatar OS picker/upload/cache/default integration PASS debug |
| Labels | Có | Empty/AND IDs/validation/CRUD/pending/conflict | Server catalogue/CAS/idempotent/account outbox | Actual create/assign/offline rename/reload/reconnect/peer/delete PASS | Real API + durable close/reopen/offline/peer/delete PASS debug |
| Conflict/read-only/locked | Có | Safe card + role guards; copy/remote choice | Existing contract | Widget semantics không lộ secret/menu viewer; direct API negative PASS | Chưa native conflict/revoke interaction |
| Lock manager/sharing manager/files/AI | Có | Component fixtures + Q&A unavailable | Chưa integrated | Preview/test riêng, không production success | Chưa |

## Checks đã chạy

- `scripts/check.ps1`: format/analyze sạch; 37 Flutter tests, 14 backend tests PASS.
  Backend gồm owner/viewer/editor/stranger, session/protection và negative API; một Starlette
  deprecation warning còn nguyên, không đổi dependency chỉ để bỏ warning.
- Responsive test: 360×800,390×844,844×390,768×1024,1280×800,1440×900 logical/DPR1,
  text scale1/1.5/2 trên home/auth/editor/settings, Vietnamese long title. Flutter widget binding
  dùng test font metrics; ảnh browser/native dùng bundled Noto Sans thật.
- Meaningful regressions: frozen base revision, theme/resize giữ text/selection/ID;
  secret title/content/label không trong visual/semantics; viewer không owner menu;
  AND filters/search clear; password confirmation và persistent error giữ input;
  initial home labeled touch targets + Android48 guideline. Đây không thay screen reader thật.
- `.venv/Scripts/python.exe scripts/check_ui_contrast.py`: 14 cặp token text/control/focus PASS.
  Có ratio/minimum ở contrast.json. Chỉ các cặp được đo; không chứng nhận WCAG toàn app/hover/disabled.
- `.venv/Scripts/python.exe evidence/2026-10-01-ui/verify_web_state.py before` rồi `after`:
  SQLite assertions PASS, cùng note ID/pinned và account3 notes; nội dung offline được nhận thật.
- Android `flutter test integration_test/note_flow_test.dart -d emulator-5554
  --dart-define=API_URL=http://127.0.0.1:8000`: 1 PASS; register/editor/local save/native DB reopen,
  unreachable socket→offline notes/preferences→reconnect/cross-session. Native functional test debug.
- `scripts/build.ps1 -Target web`: PASS, font assets trong 41-resource static-only worker.
- `scripts/build.ps1 -Target apk`: PASS, release51.9MB, debug signing; chưa release core HTTP/HTTPS regression.
- `flutter build apk --debug --target-platform android-x64 -t lib/main.dart
  --dart-define=API_URL=http://127.0.0.1:8000`: PASS; adb install/launch/login thật để chụp native UI.

## Audit → refine thực hiện

1. Baseline browser trước sửa ở cùng kích thước: desktop1280×800, mobile390×844.
   Auth/light, home/editor/settings dark. So sánh before/after file name; dữ liệu kiểm thử thật
   có thể thay đổi khi edit/pin, không golden snapshot cố định.
2. Wordmark overflow + auth illustration ở desktop scale200%: Flexible wordmark, bỏ illustration
   khi chữ lớn; kiểm thử lại pass. Clear-results CTA cần scroll/pump trong widget test, không bỏ assertion.
3. Card khóa: loại title/content/labels khỏi view và semantics thay vì blur. Search/filter không
   match metadata khóa. Owner/viewer menu được kiểm tra cùng API negative tests.
4. Profile email trước bị chia cột hẹp; chuyển khỏi ListTile subtitle sang dòng đầy đủ. Bundled font
   áp lại cả các TextStyle thay thế. View mode dùng segmented selected state rõ.
5. Password error trước chỉ snackbar sau dialog; nay validation/loading/inline persistent error.
6. Browser worker cũ cần update/reload khi thay release; Playwright click semantics bị overlay chặn
   ở switch, dùng force click ở vị trí UI thật và keyboard. Không coi retry automation là pass ban đầu.
7. Android360 thật: dù không overflow, header/banner/filter còn quá cao. Rút banner xác minh,
   nút nhãn có tooltip48 và giảm bottom padding header mobile; rebuild + kiểm tra lại.
8. Chrome offline: edit thật → thông báo lưu trên thiết bị → Back → reload offline giữ pending1;
   online sync → SQLite xác nhận nội dung/ID và account vẫn3 ghi chú. Worker có bundled font.

9. Test font24 +2 nhãn dài + conflict phát hiện RenderFlex overflow180px; card extent nay
   tính thêm font/status, nhãn preview1 dòng (nội dung nhãn gốc vẫn giữ). Regression bổ sung
   trong ui_redesign_test.dart; log trước sửa ở large-font-before-fix.txt, kết quả chốt checks.txt.

## Giới hạn còn cần nghiệm thu

Browser toolbar Back đã thử; browser history Back/deep-link/refresh khi đang editor chưa nghiệm thu.
Android OS force-kill/relaunch draft, physical device/Wi-Fi toggle chưa chạy. DB reopen integration
cùng process. Landscape/200% là widget QA; keyboard insets native mới auth smoke, chưa toàn editor.
Focus restore quan sát Escape settings về trigger; keyboard Tab/Enter mới phạm vi auth và widget,
không full application audit/TalkBack/NVDA. Không profile FPS/performance list lớn, không hứa60fps.
Lock remote với draft/upsert nay có encrypted recovery (ENCRYPTED_RECOVERY.md và evidence đợt riêng).
Revoke/delete-vs-draft UI, offline note unlock và key backup vẫn chưa nghiệm thu đầy đủ.
Internet SMTP receipt/outbox/attachment full OS/release QA/protected-reader realtime/LLM/HTTPS/video vẫn theo STATUS.

## Online note protection — 01/10/2026

67 Flutter/15 backend tests và Android protection integration PASS; Chrome release menu bật khóa,
wrong/retry/read/relock/change/disable PASS, API exact-content/revision/grant assertions ở evidence/
2026-10-01-note-protection. Nội dung đọc không đi vào list/search/cache; owner controls theo role
server, viewer controls/unit lifecycle và dialog error giữ input đã test. Native integration dùng
real backend/key store, lifecycle notifications mô phỏng; chưa physical-device/OS kill.
Automation cần click-focus rồi gõ/phát lại input connection sau field disabled; không coi fill bỏ
ô xác nhận hoặc reuse test input cũ là lỗi backend. Chrome 403 console do wrong-password có chủ đích.
Tab-select headless giữ document.visibilityState=visible ở cả hai tab, chưa đo browser hidden event.
Screen-reader protected SelectableText/full keyboard audit chưa chạy. Phiên chỉ đọc và cần online.

## SMTP code UI — 01/10/2026

Home Xác minh mở form thay vì chỉ sync; Gửi lại báo trạng thái service/cooldown thật. Quên mật khẩu
public mở form kiểm tra mã trước khi hiện password2x; code read-only sau check, nút đổi mã quay lại.
Reset success trở về login; lỗi mã giữ input, busy chặn lặp. Widget mobile390x844/scale2 PASS.
71 Flutter/22 backend toàn bộ PASS; Chrome release390x844 + Android debug emulator API36 verify/reset
qua TLS SMTP local PASS, manual login thực. Có ảnh Home verified và login sau reset; không chụp mã.
Semantic overlay chặn Playwright click Đăng xuất: force click đúng control rồi xác nhận auth screen;
không suy ra full keyboard/screen reader pass. Font scale2 chỉ widget, không đo browser/native scale2.
Evidence/2026-10-01-email; external mailbox/OS kill/physical-device/history/video chưa nghiệm thu.

## Avatar và nhãn server — 01/10/2026

AvatarEditor là production dialog choose/upload/default/status; picker thật Web/Android, ảnh
canonical/private API và encrypted cache. Web390x844 đã xem ảnh dialog/profile/cache offline;
81 Flutter/29 backend toàn bộ PASS, scale2/denied/cancel là widget QA. Labels stable IDs, pending/
conflict/rename/delete-confirm; Web actual UI rename giữ selected filter, reload offline giữ queue,
reconnect/peer rename/delete giữ note content/revision. Android actual native picker + real API/
platform vault/file reopen PASS; label assign/offline rename bằng controller, create/delete/avatar UI.
Chrome resize tool đổi DPR1.5→1 gây canvas cũ lớn hơn viewport; reload viewport cố định đưa
flutter-view về390×844/DPR1 rồi visual checks. Không dùng screenshot lệch để claim UI PASS.
Semantic overlay vẫn chặn một số Playwright pointer checks; force click đúng avatar control và
Escape đóng sheet rồi assert dialog/Home. Không suy ra full keyboard/TalkBack/NVDA pass.
Evidence/2026-10-01-avatar-labels/INDEX.md ghi luồng/câu lệnh/giới hạn.

## Private attachments — 01/10/2026

Production editor/protected reader mở AttachmentsDialog; owner/editor chọn/upload/xóa-confirm,
viewer xem/tải. Scrollable dialog/Wrap actions và scale2 mobile390×844 widget PASS; cancel/denied
giữ lựa chọn, busy chặn duplicate. Private image/video preview chỉ RAM, late-response/account/
lock/revoke/lifecycle guards, peer delete che tên/ảnh và dispose video. Metadata không gắn thẻ locked.
88 Flutter/40 backend PASS; actual Chrome390×844 fixed DPR1 chooser3 files/image/video Blob2s,
download/delete/remote-lock PASS. Native debug API36 actual OS PNG picker/native video position/
DocumentsUI export42 bytes hash/delete/peer-delete preview PASS. Web final worker/hash đối chiếu
riêng sau rebuild. Xóa-confirm cũng nghe session để che tên/vô hiệu Xóa tệp khi remote lock;
widget, Chrome final release và Android actual integration PASS. Screenshot/video fixture là
evidence local, không thay video nộp.
Protected-reader attachment flow/OS cancel-denied/full keyboard/screen reader/physical/release
functional/HTTPS chưa nghiệm thu. Evidence/2026-10-01-attachments/INDEX.md, PRIVATE_ATTACHMENTS.md.

## Sharing manager — 02/10/2026

ShareDialog scrollable: batch email validation, default/recipient role dropdown, revoke-confirm,
CAS review/current list, immutable retry/status. Owner icon/count, recipient owner/time/role.
Viewer downgrade hiển thị server readonly; revoke/lock che editor/catalogue/confirmation metadata,
latest typed edit có recovery banner/new-ID draft. Locked card không owner/time trong semantics.
Background bỏ catalogue và không poll đến foreground; chưa actual screen-reader acceptance.
97 Flutter/48 backend PASS; mobile scale2/no overflow qua widget doubles, Chrome local release
390×844/DPR1 actual form/role/recipient/revoke/reload recovery + Android debug API36 real-server
batch/dropdown/recipient edit/viewer/revoke/reopen recovery UI PASS. Không physical/release/public/
full keyboard/history/video. Exact screenshots/source hashes/scenarios ở sharing evidence index.

## Realtime —02/10/2026

Home/editor chỉ báo Trực tiếp/Đang nối lại; giữ pending/offline/conflict riêng. Sạch nhận remote
text trong editor, caret/clamp và frozen base giữ; CTA “Chỉnh sửa phiên bản mới” rõ ràng để sửa
tiếp. Dirty draft không bị thay; status draft vẫn giữ sau debounce, không gọi synced khi thiếu
title. Viewer readonly, revoked/locked che TextFields; recovery banner/dialog cho local edit.
Host106 Flutter/53 backend PASS; actual Chrome owner/editor contexts và Android API36 debug
SSE/API/reconnect/conflict/viewer/revoke/reopen đã chạy. Exact Web build boundary, final-source
draft/lock/recovery checks và screenshots ở evidence/2026-10-02-realtime/INDEX.md. Browser
keyboard semantics cần focus/keyboard từng bước; không suy ra NVDA/TalkBack/OS hidden tabs.
Protected-reader realtime/physical/release functional/load/public HTTPS/video chưa nghiệm thu.
