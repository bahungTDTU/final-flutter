# Rà soát dự án và đối chiếu đề — 18/10/2026

Cập nhật buổi tối18/10: đã triển khai sửaF01–F04; xem
[bản sửa và giới hạn kiểm chứng](VALIDATION_SYNC_FIXES_2026-10-18.md).
Nội dung audit bên dưới mô tả snapshot trước sửa.

## Kết luận

Dự án đúng hướng một Flutter project Web/Android, ChangeNotifier, FastAPI/SQLite và
Sembast. Có đường triển khai cho các mục 1–31; mục 32 mới có cấu hình/build local và
release guards. Chưa đủ căn cứ nghiệm thu đầy đủ hoặc chấm điểm hoàn thành.

Phát hiện **4 vấn đề liên quan validation và đồng bộ**, gồm một lỗi hàng đợi và ba
đường tạo dữ liệu không được server chấp nhận. Đợt này là audit, **chưa sửa code sản phẩm**.
Không ghi đè thay đổi UI/locale/palette hiện có; không commit/push/merge/deploy.

Nguồn: PDF gốc `C:/Users/LENOVO/Downloads/503107-FinalProject-V1.pdf`, 19 trang;
đọc text toàn bộ, render và xem trang 18. SHA-256:
`63ea45a11778b4b60bd71ae79038b991cda54f90d429365345fe488cb5c6f907`.
Đối chiếu PROMPT_CHO_AGENT, STATUS, REQUIREMENTS_MATRIX, TEAM_CONTRIBUTIONS, README,
UI_UX_DESIGN/QA, audit14/10 và source hiện hành.

Source: branch `codex/dashboard-motion-performance`, HEAD
`4a196ef33019b38c6c2812fcbd48f05bf0d7d134` **cộng working changes**, không phải clean commit.
Manifest và logs: [evidence](../evidence/2026-10-18-project-audit/INDEX.md).

## Lỗi và mức ưu tiên

### F01 — P1: Một operation bị 422 chặn các note khác và lần tải danh sách mới

`lib/state/app_controller.dart:1184–1244`, đặc biệt nhánh `rethrow` dòng1240.
`synchronize()` duyệt pending theo thứ tự. Chỉ xử lý riêng423/403/404/409;422 bị ném
ra khỏi cả vòng lặp. Operations sau đó không được gửi; `GET /notes` nằm sau vòng lặp
cũng không chạy. Operation lỗi vẫn được giữ với cùng payload/ID. `save()` chỉ nối
operation mới nên sửa tiêu đề rồi retry không tự loại bỏ operation422 cũ.

Tác động: lỗi ở một note có thể làm các note khác không lên server; refresh lock/revoke
qua danh sách cũng bị chậm. Backend vẫn thực thi ACL; đây không phải bằng chứng bypass
quyền trên server. Không kết luận mất dữ liệu: bản local/outbox vẫn được giữ.

Bằng chứng: đọc control flow hiện hành; F02–F04 chứng minh có payload UI/ứng dụng tạo
ra bị schema server từ chối. **Chưa chạy end-to-end controller/browser cho chuỗi này**
do giới hạn môi trường; không gọi probe schema là full sync regression.

Hướng sửa: phân biệt lỗi validation vĩnh viễn với lỗi mạng, đưa operation bị từ chối
vào trạng thái cần sửa theo từng note, giữ draft và chặn các dependent operations của
note đó; cho note độc lập và remote refresh tiếp tục. Giữ payload/ID của operation
đã gửi bất biến; khi sửa dùng operation mới và giải quyết base revision rõ ràng.
Không đơn giản xóa outbox hoặc tự sửa payload dưới cùng op_id.

### F02 — P2: Tiêu đề Unicode hợp lệ trên UI nhưng quá dài với backend

`lib/ui/document_workspace.dart:151`: TextField `maxLength:200` đếm grapheme;
Flutter SDK hiện tại `LengthLimitingTextInputFormatter` dùng `characters.length`.
`backend/app.py:123`: Pydantic `max_length=200` đếm Unicode code points.
`lib/domain/note.dart:127`: `validNote` chỉ kiểm tra title/content không rỗng.

Tái hiện thuần bằng code thật: 50 emoji `👨‍👩‍👧‍👦` =50 graphemes nhưng350 code points;
`validNote` trảtrue, Pydantic Operation báo `title/string_too_long`.
Có thể xảy ra với chữ có dấu dạng combining; không chỉ emoji. Sau autosave vào
ordinary outbox dẫn đến F01. Protected reader cũng giữ operation bị422 để retry.

Hướng sửa: thống nhất đơn vị giới hạn client/server, có thông báo ngay trong editor
và validation trước tạo operation. Bảo toàn draft khi đầu vào chưa hợp lệ.

### F03 — P1: Bản sao phục hồi tự tạo tiêu đề vượt200 ký tự

`lib/state/app_controller.dart:1404`: `resolveConflict(keepCopy:true)` nối
` (bản phục hồi)` vào nguyên tiêu đề, không dành chỗ cho hậu tố và không validate
độ dài bản sao. Tiêu đề ASCII200 ký tự vốn hợp lệ thành215 ký tự; Operation server
từ chối `string_too_long`. Luồng này xóa trạng thái conflict cũ và đưa bản sao vào
pending, sau đó gặp F01. Đây là case không cần nhập dữ liệu bất thường.

Bằng chứng: nhánh tạo copy trong source và probe schema với payload215 ký tự;
chưa thao tác conflict UI thật trong lượt này.

Hướng sửa: tạo tiêu đề bản sao trong giới hạn server theo cùng quy tắc Unicode,
không cắt hỏng grapheme; giữ nguyên nội dung và bản phục hồi, chỉ kết thúc conflict
sau khi trạng thái thay thế đã được lưu an toàn. Test tiêu đề sát/vượt biên do hậu tố.

### F04 — P2: Cho chọn nhãn thứ31 dù server chỉ nhận tối đa30

`lib/ui/editor.dart:707–736`, nhánh thêm ở726: FilterChip tiếp tục thêm nhãn mà
không kiểm tra số lượng. `AppController.save()` không validate số labels.
Protected editor có cùng cách thêm trong `lib/ui/note_protection.dart`.
`backend/app.py:126` giới hạn30; probe Operation31 IDs bị `labels/too_long`.

Hướng sửa: hiển thị giới hạn khi đạt30, cho bỏ chọn nhưng chặn thêm; kiểm tra ở
controller và protected reader trước xếp hàng. Regression cần chứng minh note khác
vẫn sync và draft của note lỗi vẫn phục hồi được.

F01 là lỗi xử lý chung; F02–F04 là các nguyên nhân riêng kích hoạt nó, không phải
bốn lỗ hổng bảo mật độc lập. Không tăng số lỗi bằng cách đếm lại cùng stack trace.

## Kết quả kiểm tra thực tế lượt này

| Kiểm tra | Kết quả | Phạm vi |
|---|---|---|
| Dart format trực tiếp | PASS129files,0changes | lib/test/integration_test/test_driver |
| Dart analyze trực tiếp | PASS, no issues | Bốn thư mục trên; không ghi thành flutter analyze |
| Backend production-origin tests | PASS22 | `test_release_preflight.py`; không liên hệ tên miền |
| Thu thập backend tests |147 collected | Chỉ discovery, không phải147PASS |
| Synchronous backend handlers + SQLite | PASS | Owner create/edit, viewer403, stranger404, lock423, đúng6fields listing, unlock, revoke404 |
| Validation probes | Xác nhận F02/F03/F04 | Dart domain và Pydantic thật; không widget/HTTP |
| `scripts/check.ps1` | BLOCKED | SDK ngoài vùng ghi; launcher mắc ở cache lock, đã dừng |
| Flutter test qua tool snapshot | BLOCKED | Không mở được SDK `bin/cache/lockfile` |
| Full pytest | BLOCKED | Lần đầu lỗi temp; dùng workspace temp vẫn kẹt asyncio socketpair |
| Direct HTTP | BLOCKED | Loopback socket báo WinError10013; không claim HTTP rolesPASS |
| Browser/native/integration/build mới | NOT RUN | Không có nghiệm thu artifact mới trong lượt này |
| SMTP Internet/Gemini/HTTPS/signing/CI | NOT RUN | Không gửi mail, không gọi LLM, không publish |

`preferences-diagnostic.txt` có stack timeout20s tại Python `_fallback_socketpair`
→asyncio→Starlette TestClient. Đây là giới hạn socket của môi trường kiểm tra, chưa
phải lỗi ứng dụng. Đã dừng các tiến trình thử bị treo. Không đổi permissions hoặc SDK.
Kết quả308Flutter/147backendPASS16/10 chỉ là evidence lịch sử, không thay kết quả18/10.

## Đối chiếu32 tiêu chí

“Có code” không đồng nghĩa “đủ điểm”. Mọi mục vẫn cần demo theo đề trên các bản nộp;
bảng ghi khoảng trống quan trọng, không giả định tất cả thao tác đã chạy lượt này.

| ID | Tiêu chí | Code / nhận định hiện tại | Việc còn cần |
|---:|---|---|---|
|1|Đăng ký|Register/auto-login/hash; synchronous handler chạy được|Hai artifact cuối + email thật|
|2|Kích hoạt|Token/UI/banner/mail queue có code|SMTP Internet, nhận thư, verify Web/Android|
|3|Đăng nhập/đăng xuất|Session server và local encrypted có code|Cold start/logout/manual login bản cuối|
|4|Reset mật khẩu|Email token/reset/manual login có code|Inbox thật, hoàn tất hai target, session cũ401|
|5|Xem profile/avatar|Private avatar/cache có code|Regression hai artifact cuối|
|6|Sửa profile/avatar|Validation và picker có code|OS picker/cancel/error, lưu và reopen|
|7|Đổi mật khẩu tài khoản|Current/new/confirmation và session revoke có code|UI thành công hai target và oldtoken401|
|8|Preferences|Immutable account queue/merge; locale/palette mới|Reopen/cross-device và lỗi ghi local bản cuối|
|9|List|Có layout và locked projection|Native source mới/accessibility|
|10|Grid|Có mặc định grid/persist/adaptive|Native/tablet/landscape bản cuối|
|11|Tạo note|Shared editor/autosave; F02|Sửa validation/queue; Web/native regression|
|12|Sửa note|Frozen revision/conflict; F01/F02/F03|Sửa queue/copy; IME và conflict hai session|
|13|Xóa note|Owner/confirmation/revision/grant có code|Final UI confirm/remote change/cancel|
|14|Autosave/lifecycle|Draft/outbox/local persistence có code; F01|Validation failure không chặn note khác; OS relaunch|
|15|Ảnh/video|Private ACL/type/size/range/preview có code|Final OS chooser/cancel/denied/protected media|
|16|File|Authenticated upload/download/delete có code|Final native export/hash/picker|
|17|Ghim/sắp xếp|Pinned grouping/time order và locked array order có code|Hai artifact cuối/offline order|
|18|Chỉ báo đặc biệt|Shared boolean/pinned/locked; probe đúng6fields|Visual/semantics thực trên hai target|
|19|Live search|Debounce/plain projection/literal search có code|Native typing/clear trên bản cuối|
|20|CRUD nhãn|Catalogue/CAS/manager có code|Native rename/delete/conflict UI|
|21|Gắn nhãn|Có multi-label; F04|Chặn31 trước outbox, giữ note/draft|
|22|Lọc nhãn|AND filter theo ID có code|Native thao tác nhiều nhãn/rename/delete|
|23|Bật/tắt khóa|Server password/grant và vault có code; handler lockPASS|OS background/TTL/artifact cuối|
|24|Unlock/đổi mật khẩu note|Encrypted vault/password flow; handler unlockPASS|TTL/change/offline revalidation hai target|
|25|Chia sẻ/quyền|Owner/viewer/editor/stranger+revoke handlerPASS|HTTP và independent UI peers bản cuối|
|26|Realtime|SSE invalidation/counter + revision có code|Hai UI native, remote lock/delete/downgrade, HTTPS proxy|
|27|AI Summary|Gemini adapter/ACL/regenerate/no overwrite có code|LLM thật và quality/error trên hai target|
|28|AI Q&A nguồn|Authorized retrieval/synthesis/citations có code|LLM thật/multiple sources/no-data/injection/citation open|
|29|UI/UX/adaptive|Tokens/NotoSans/locale/palette/keyboard có code|TalkBack/NVDA/IME/native source mới; xử lý lỗi rõ ràng|
|30|Architecture/tests|Một core; format/analyzePASS; nhiều tests/integration code|Full suite hiện hành, clean build/run, nhóm giải thích code|
|31|Offline/sync|Encrypted per-account/outbox/conflict có code; F01/F03|Sửa queue/copy và OS force-stop/relaunch/reconnect|
|32|Public Web/native release|PARTIAL: build/config/guards local|Public HTTPS/backend, signedAPK install/run, clean reproducibility|

Các luồng đã rà: auth/session, preferences, note/editor/outbox/conflict, locked listing,
encrypted account store, protected reader, labels, attachments ACL, shares/realtime,
AI authorization/context recheck, UI mới, Android signing/manifest, Compose/scripts/CI.
Không có cơ sở kết luận “không còn lỗi” từ static review và các probes hạn chế này.

## Điều kiện nộp bài và rủi ro điểm

- Đề trang17–18 yêu cầu source, demo, Rubric.xlsx, public Web URL và native release.
  Thiếu một trong các đầu ra bắt buộc được liệt kê dẫn đến0điểm cả nhóm. Đây là điều
  kiện **lúc nộp**, không phải chấm0 cho trạng thái đang phát triển hiện nay.
- Video tối thiểu1080p, có cả thành viên; mỗi mục phải được demo ít nhất một nền tảng.
  Login/create/edit/attachments/offline/sharing-or-realtime/ít nhất1AI phải có cả Web/native.
  Mục không demo bị xem là chưa làm. Matrix không thay Rubric.xlsx của giảng viên.
- Git local hiện chỉ thể hiện ba tuần lịch bắt đầu28/09,05/10,12/10; Long xuất hiện
  từ12/10 trong refs đang có. Chưa chứng minh4tuần liên tiếp mỗi người≥2commit có ý nghĩa.
  Không kiểm tra remote mới, không coi số commit hoặc tác giả trong log là xác nhận
  đóng góp độc lập. Đề yêu cầu evidence thật; không tạo/backdate history để bù.
- Tài liệu `REMAINING_GATES.md` là snapshot12/10; trạng thái PR8/working tree trong đó
  không phải trạng thái mới nhất. Không dùng để kết luận merge approval/CI hôm nay.
- Source chưa commit hiện nay chưa được CI hosted kiểm chứng. Build smoke CI là
  Web local + APKdebug, không thay public Web và APKrelease ký thật.

## Thứ tự xử lý đề xuất

1. SửaF01–F04 cùng regression meaningful: rejected op không chặn note khác; giữ draft;
   Unicode boundary; copy200ký tự;30/31labels; retry/reopen; remote lock khi có validation error.
2. Chạy full check, HTTP4roles và browser/native trên môi trường cho phép; không đổi
   immutable operation/frozen revision hoặc dùng last-server-accepted cho note conflicts.
3. Đóng SMTP Internet và Gemini thật, rồi native IME/OS relaunch/TTL/picker/accessibility.
4. Hoàn thiện public HTTPS, ký/chạy release, clean clone, Rubric/video/submission thật
   theo các quyết định và quyền đã có; không tự triển khai hoặc nộp bài từ audit này.
