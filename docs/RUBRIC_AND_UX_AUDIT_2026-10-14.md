# Đối chiếu đề và sửa UX/hiệu năng — 14–15/10/2026

Đề gốc: `503107-FinalProject-V1.pdf`, 19 trang, đọc lại và xem trang rubric/đầu ra.
Source hiện tại: base `4a196ef33019b38c6c2812fcbd48f05bf0d7d134`,
branch `codex/dashboard-motion-performance` + working changes. Chưa commit/push.
Bản sửa dashboard/masthead trước lượt này được giữ, không tính thành sửa mới của audit này.
[Bằng chứng lượt này](../evidence/2026-10-14-rubric-ux-audit/INDEX.md).

## Kết luận đối chiếu

31 mục 1–31 đã có luồng triển khai trong code, gồm adapters email và Gemini; mục32 có
build/config/guard local nhưng chưa có đầu ra public HTTPS/native release đã nghiệm thu.
“Có code” không đồng nghĩa “FULL POINT”: đề trang7 và rubric trang9–14 yêu cầu chức năng
hoạt động đúng trên hai bản nộp, có lỗi/authorization/lifecycle được xử lý. Không quy đổi
295 Flutter/143 backend tests thành điểm hay bằng chứng tất cả màn hình trên Android.

Đợt này PASS format121 files/0 changes, analyze0 issues, 295 Flutter tests/143 backend tests,
Web release local và APK debug compile. Android device inventory trống. Nghiệm thu native12/10
vẫn hợp lệ trong phạm vi snapshot đó; UI LabelManager mới, OS relaunch/IME/picker/TTL/FPS,
SMTP Internet, Gemini thật, CI của working changes, public release/video vẫn NOT RUN.
Release giữ ở chặng cuối theo yêu cầu người dùng.

Đề không có một mục “sáng tạo” riêng ngoài32ID. UI/UX/accessibility/adaptive (ID29) tối đa0.5;
thêm tính năng phải phục vụ note management và không cản bắt buộc (trang1). Không thể bảo đảm
điểm tuyệt đối bằng số tính năng hoặc chỉ bằng giao diện đẹp.

## 32 tiêu chí: code và khoảng trống thực tế

IMPLEMENTED là có code/luồng; PARTIAL là đầu ra còn thiếu. PASS local là kết quả checks phù hợp
hiện tại, không phải cam kết FULL POINT. Cột “cần đóng” nêu những gate quan trọng, không liệt kê
mọi thử nghiệm giả định. Evidence Web/native chi tiết trước lượt này: matrix và
CURRENT_SOURCE_ACCEPTANCE; bảng này cập nhật các nhận định “Quill native chưa chạy” đã cũ.

| ID | Tiêu chí / điểm | Triển khai và kiểm chứng có thật | Cần đóng để chứng minh đầy đủ |
|---:|---|---|---|
|1|Đăng ký /0.25|IMPLEMENTED AuthScreen/AppController, backend register/hash/auto-login; tests local PASS|Regression hai artifact cuối; email đến inbox cùng ID2|
|2|Kích hoạt /0.25|IMPLEMENTED token UI, persistent unverified banner, SMTP queue; local TLS tests/evidence|SMTP Internet/inbox→verify trên Web/Android; banner biến mất|
|3|Đăng nhập/đăng xuất /0.25|IMPLEMENTED session encrypted/migration/tombstone/server revoke; local PASS; native migration12/10|Cold start/logout/manual login trên artifact cuối|
|4|Reset password /0.25|IMPLEMENTED generic request/token/reset/manual login/session revoke; local PASS, local TLS native evidence|Email Internet; reset/link hoặc OTP trên hai target, old token401|
|5|Xem profile/avatar /0.25|IMPLEMENTED default/canonical avatar, private GET/cache/account scope; tests PASS|Artifact cuối, native picker/avatar liên quan ID6|
|6|Sửa profile/avatar /0.25|IMPLEMENTED profile/avatar validation+sync; tests PASS|Chọn/cancel/error file bằng OS picker thật và Web cuối|
|7|Đổi mật khẩu tài khoản /0.25|IMPLEMENTED current password+new twice/session revoke; tests PASS|UI hai target, đăng nhập lại và old session401|
|8|Preferences /0.25|IMPLEMENTED account-scoped durable immutable sync, server field merge; tests PASS|Artifact cuối reopen/cross-device preferences|
|9|List /0.25|IMPLEMENTED lazy listing, private locked projections, ordering; widgets PASS|Native UI source cuối và keyboard/screen reader|
|10|Grid /0.25|IMPLEMENTED default grid+persisted view, adaptive; widgets PASS|Native/tablet/landscape trên artifact cuối|
|11|Tạo note /0.25|IMPLEMENTED chung EditorScreen, stable UUID/title/content/rich delta; tests PASS; native note_flow12/10|IME thật và artifact cuối|
|12|Sửa note /0.25|IMPLEMENTED Word editor PC/phone layout, frozen base, ACL/conflict/recovery; tests PASS; native12/10|N01/N03 trên artifact cuối; không mất selection/draft|
|13|Xóa note /0.25|IMPLEMENTED confirm + owner/ACL/grant/revision checks; tests PASS; protected native delete12/10|UI cuối với remote update/revoke trong confirm|
|14|Auto-save/lifecycle /0.25|IMPLEMENTED local durable drafts+debounce+feedback; tests PASS; DB reopen evidence|Android OS force-stop/relaunch, background/resume thật; không suy từ injected lifecycle|
|15|Ảnh/video /0.25|IMPLEMENTED private files/validation/preview/range; tests+HTTP4roles PASS; native historical picker/video|OS protected picker/cancel/denied/native artifact cuối; online-only ghi rõ|
|16|File /0.25|IMPLEMENTED authenticated upload/download/delete, platform save; tests+HTTP PASS|Native final OS picker/save/cancel và bytes/ACL|
|17|Ghim/order /0.25|IMPLEMENTED pin grouping/time order/server order for locked; ordering regressions PASS|Đối chiếu cả2artifact cuối; locked date vẫn ẩn|
|18|Shared/pinned/locked /0.25|IMPLEMENTED simultaneous public pin/shared/lock; privacy/semantics tests PASS|Native actual accessible indicators; không lộ share identities/count trước unlock|
|19|Live search /0.25|IMPLEMENTED300ms debounce/rich text projection/clear; tests PASS|Native final typing/clear, large library profile|
|20|Label CRUD /0.25|IMPLEMENTED ID-based CAS/journal; mới sửa lazy searchable manager, validator/confirm/conflicts|Native final UI; Web thực lượt này có rename→server ACK|
|21|Gắn nhiều nhãn /0.25|IMPLEMENTED IDs/server owner validation/dependencies; tests PASS|Native assignment UI cuối, rename/delete không hỏng note|
|22|Label filter /0.25|IMPLEMENTED AND filter/selected IDs/search/deleted cleanup; tests PASS|Native thao tác AND thật; theme/resize giữ lựa chọn|
|23|Bật/tắt khóa /0.5|IMPLEMENTED backend grant/current pwd/confirm+vault; tests PASS; native12/10|Actual background/TTL/relock/privacy trên artifact cuối|
|24|Unlock/đổi note pwd /0.5|IMPLEMENTED password-encrypted vault+server grant, current/new twice; tests PASS; native12/10|Artifact cuối/change/offline revalidation/TTL thực|
|25|Sharing/permissions /0.5|IMPLEMENTED batch/CAS/roles/revoke/recipient metadata; tests+HTTP roles PASS; hai WebUI12/10|Native independent UI peers và protected final sharing|
|26|Realtime /0.5|IMPLEMENTED authenticated SSE/reconnect/frozen409, không OT/CRDT; tests PASS; Web/native12/10|Independent two-UI native/remote lock-delete-downgrade; proxy SSE ở release|
|27|AI Summary /0.25|IMPLEMENTED Gemini backend adapter, regenerate/RAM/no overwrite; fixture tests PASS|Gemini thật bằng key mới, UI hai target, summary quality/error/quota|
|28|AI Q&A nguồn /0.25|IMPLEMENTED authorized retrieval+LLM/citation/open source/no-info; fixture tests PASS|Gemini thật/multi-source/unsupported/injection/ACL evaluation; retrieval synonym limits|
|29|UI/UX/adaptive /0.5|IMPLEMENTED shared tokens/NotoSans, separate desktop/phone editor, keyboard/focus/reduced motion; mới sửa label overflow|TalkBack/NVDA và native IME; native/profile frame time thực|
|30|Architecture/tests /0.5|IMPLEMENTED shared Dart core/ChangeNotifier/domain/data/UI/FastAPI/Sembast;295Flutter143backend PASS, critical integration code/native historical|Clean build/run đúng source cuối; nhóm giải thích source, CI newest head khi push|
|31|Offline/sync /0.5|IMPLEMENTED per-account encrypted persistence/outbox/conflict/recovery; tests PASS; Web reload/native DB reopen12/10|Native OS relaunch thật/airplane reconnect; artifacts cuối và failures nhìn thấy|
|32|Public Web + native release /0.5|PARTIAL: Web local/APK debug compile PASS; HTTPS/signing guard/backup tooling đã code|Public HTTPS/backend, signed APK install/run, independent network/clean production clone; để cuối|

Các tests liên quan: auth/email_flow/session_storage/avatar_labels/attachments/ai/
note_protection/protected_editing/realtime/sync_durability/note_ordering/home_experience/
deskbook_layout/document_editing và các regression mới. Backend tests enforce ACL/lock/grant
và transaction. Full suite đã chạy; không gọi tất cả test này là actual browser/native.

## Lỗi đã xác nhận và sửa trong lượt này

| Lỗi | Trước sửa | Sau sửa / giới hạn bằng chứng |
|---|---|---|
|Catalogue nhãn mở chậm khi nhiều dữ liệu|1.000 ListTile mounted ngay; shrinkWrap nằm trong scroll cha|SliverList.builder:6 mounted trong cùng fixture/viewport;20 notification không đổi catalogue không thay row widgets; đây là workload, không phải FPS|
|Compact+chữ lớn làm quản lý nhãn lỗi|320×720, text200%, conflict action chiếm toàn tile; baseline FAIL assertion|Một menu48dp riêng; conflict thành phần dưới tên, wrap;2theme/320px/landscape/PC+keyboard-inset tests PASS|
|Khó tìm nhãn/tác vụ lẫn nội dung|Mọi nhãn trải thành một danh sách dài, footer nằm cuối|Tìm Unicode, clear/no-result, số nhãn/pending/offline; danh sách cuộn riêng, footer Add/Sync/Close luôn tới được|
|Dialog có thể thao tác sau thay tài khoản|Luồng cũ dùng controller hiện tại sau await|Manager gắn account/token; rename/delete dialog bỏ input/tên riêng và disable confirm khi gate đổi; test account switch PASS|
|Tài liệu không thể đối chiếu commit|STATUS/matrix ghi46df287, ref không tồn tại|Đối chiếu Git và docs original: đúng46df286302cc88e07c98ba1b14160cc64491e2df; sửa6vị trí, không sửa sealed evidence|

Tìm/đổi tên/xóa giữ ID và các controller operations hiện có; không đổi server permission,
schema hay quy tắc sync. Test giữ immutable operation cũ và content/revision note sau rename/delete.
Mới tách LabelManager khỏi Home; lỗi ghi local giữ báo lỗi trong manager để thử lại.

Áp dụng ui-ux-pro-max: đọc Master Deskbook/Atelier; query UX đầu tiên trả Z-index không phù hợp,
retry “Truncation long content” khớp content; Flutter “lazy list rebuilds” khớp Lists/ListView.builder.
Giữ tokens, font, native controls. Lazy builder và thu hẹp rebuild phù hợp
[Flutter performance guidance](https://docs.flutter.dev/perf/best-practices).
Text200%/keyboard inset là widget QA; không thay actual TalkBack/IME theo
[Flutter accessibility guidance](https://docs.flutter.dev/ui/accessibility).

## Ưu tiên để hướng tới điểm tối đa

1. **P01/P02 trước thêm feature lớn:** cấu hình SMTP/Gemini an toàn tại backend; nhận mail
   thật và nghiệm thu AI Summary/Q&A hai target. Thêm bộ đánh giá khoảng20case có expected
   facts/source IDs (nhiều nguồn, không đủ thông tin, Vietnamese phrasing, nguồn bị khóa/revoke,
   prompt injection, timeout/quota). Ghi kết quả thật, không đặt điểm quality giả.
2. **N01–N05 trên thiết bị:** Telex/VNI/selection/paste/undo; force-stop/relaunch giữ UUID/
   rich Delta; background/TTL/relock; OS protected picker/cancel; label AND và đổi account pwd.
   Profile dashboard/list/grid + catalogue lớn trên profile mode với frame timings/DevTools;
   không suy FPS từ widget times hoặc PC screenshot.
3. **UI29:** kiểm tra keyboard tới mọi modal/action, focus không bị footer che, TalkBack/NVDA,
   hai theme/chữ200%/tablet/landscape. Giữ typography, thứ bậc Title/Content/Metadata;
   ưu tiên trạng thái offline/error/retry và không mất công việc khi mạng lỗi.
4. **T01/S01 song song:** nhóm tự xác nhận phân công/contribution thật4tuần, mỗi thành viên
   mỗi tuần≥2meaningful commits trong kỳ chính thức; Insights, khả năng giải thích/sửa code.
   Chuẩn bị kịch bản32ID và shot list hai nền tảng; không tự tạo Rubric.xlsx thay bản giảng viên
   hoặc timestamp/video/contribution giả.
5. **Release cuối:** public Web/backend HTTPS, SSE/proxy, persistent data+restore,
   signedAPK/install/run, clean clone/production setup, video≥1080p và ZIP/unpack validation.

Đề trang17–18: thiếu source/demo/Rubric.xlsx/public Web URL/native artifact dẫn tới0cả nhóm;
mục nào không demo trong video bị coi chưa làm. Các màn core và ít nhất1AI phải được demo trên
cả2nền tảng. Teamwork thiếu có thể trừ0.5, cấu hình không tái tạo được trừ2; không trì hoãn
những đầu vào này chỉ để tăng số feature. Đây là đối chiếu đề, không tự publish/nộp.

## Tính năng nên thêm/cải thiện sau khi đóng các gate bắt buộc

Đã có rich Word editor, tìm/thay, mục lục/checklist, mẫu+template riêng, nhật ký, yêu thích/
gần đây, import/export JSON, Kanban/calendar/priority, Pomodoro và Security Center.
Không đề xuất lại chúng như feature mới. Thứ tự dưới là đề xuất, chưa triển khai:

| Ưu tiên | Đề xuất | Giá trị và nghiệm thu | Phạm vi / chi phí tương đối |
|---|---|---|---|
|D1|Trung tâm đồng bộ với lỗi theo từng note/label/preference|Cho biết lưu ở thiết bị hay đã lên server; retry đúng op; liên kết editor/conflict; không lộ content note khóa; thử lost ACK/timeout/reconnect/account switch|Mở rộng UX hiện có, không thay immutable outbox; vừa|
|D2|So sánh hai bản xung đột và lịch sử phiên bản trên server|Có original/base/local/remote, xem diff rồi chọn bản sao hoặc restore tạo revision mới; ACL/grant trên history, revoke/relock purge; tránh mất nội dung|Conflict dialog đã có giữ-copy/use-remote nhưng chưa có diff/history server; lớn|
|D3|Thùng rác và hoàn tác xóa có thời hạn|Soft-delete/tombstone đồng bộ, restore explicit consent, người nhận không thấy note đã xóa; bảo vệ history/files/grants; purge có policy|Chưa có recycle bin; lớn, cần migration/retention/ACL tests|
|D4|Liên kết giữa ghi chú và backlinks|Chuyển từ note này sang note liên quan, resolve theo UUID; không trả title/preview của note bị khóa/revoke; kiểm tra deletion/rename|Giúp nghiên cứu/học tập; vừa, sau D1|

Mỗi tính năng có một luồng demo ngắn và tiêu chí an toàn. Không cần thêm CRDT, OAuth,
rich table, offline media queue hay DOCX chỉ để đủ đề; chúng tăng phạm vi nhưng không tự
cộng thêm điểm. ChọnD1 trước vì làm rõ độ tin cậy của những chức năng bắt buộc hiện có.

