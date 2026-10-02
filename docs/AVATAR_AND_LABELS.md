# Avatar và nhãn theo tài khoản

Đối chiếu đề gốc tr.2–4, tiêu chí5/6/20/21/22. Các hạn mức dưới đây là lựa chọn triển khai,
không phải hạn mức do đề quy định. Source dùng cùng controller trên Flutter Web/Android.

## Avatar

Hồ sơ và tùy chỉnh → Đổi ảnh đại diện → Chọn ảnh → Tải ảnh lên. Chọn file chưa thay avatar;
dialog ghi tên/dung lượng file, ảnh hiện tại là bản canonical server hoặc cache của tài khoản.
Cancel giữ ảnh cũ; lỗi/quyền/timeout giữ file đã chọn để thử lại. Có Dùng ảnh mặc định và
Kiểm tra trạng thái. Thay ảnh cần online; không có avatar-upload outbox. Đóng app khi chưa
upload thì file đã chọn trong RAM không còn; avatar đã tải thành công được cache mã hóa.

file_selector1.1.0 dùng file picker Web/native, không thêm quyền đọc toàn bộ gallery/storage.
Client lọc extension/signature/dung lượng; backend vẫn decode kiểm tra, không tin tên hoặc MIME.
PNG/JPEG tối đa2 MiB input; chiều tối đa8192, tối đa16 triệu pixels, không animation. Pillow12.3.0
verify/decode, áp EXIF orientation, thu nhỏ không vượt512×512, tạo PNG mới không EXIF/text/ICC
metadata, output tối đa1 MiB. Không hỗ trợ SVG/GIF/WebP/video làm avatar trong increment này.

| API | Hành vi |
|---|---|
| GET /me | avatar_revision, has_avatar, schema_version=2; không raw image/token URL |
| POST /me/avatar?base_revision=R | Raw PNG/JPEG bytes + Content-Type + Bearer; kiểm tra ảnh và CAS revision, trả profile |
| GET /me/avatar?revision=R | Chỉ avatar của session; PNG canonical, private/no-store/nosniff; revision sai409 |
| DELETE /me/avatar?base_revision=R | CAS; tăng revision, data=NULL, dùng avatar chữ cái mặc định |

Ảnh lưu BLOB trong SQLite cùng DB tài khoản. Replace/delete atomic nên không có file cũ/mồ côi
trong thư mục public. Không có endpoint tùy ý userId/public URL; account B không đọc avatar A.
Backend revalidate session sau decode, trước commit. Hai phiên thay ảnh cùng base revision chỉ
một request được chấp nhận; stale409 phải refresh/review rồi thử lại. Không tự overwrite ảnh mới
ở phiên khác. Timeout có thể xảy ra sau commit: kiểm tra trạng thái trước thử lại; chưa có upload
operation journal/tổng deadline bảo đảm. Không tuyên bố public deployment hoặc chống abuse đầy đủ.

Client fetch bằng Authorization header, không Image.network URL gắn token. Canonical bytes được
lưu trong encrypted account snapshot (base64 bên trong AES-GCM), không session plaintext.
Logout/account switch che ảnh và generation guard bỏ response muộn; profile/avatar revision guard
không áp ảnh cũ lên revision mới. Offline reopen có ảnh đã cache; khi online profile mới quyết định
fetch/clear. Không dùng static service worker để cache avatar hoặc API.

## Nhãn

Nhãn có ID cố định, name, revision, deleted tombstone và owner tài khoản. Tên mới1–60 ký tự,
trim/NFC, không control characters, không trùng casefold trong cùng tài khoản. Tài khoản khác
được dùng cùng tên. Nhãn legacy dài hơn được giữ trong migration; khi sửa phải theo hạn mức mới.

Home Quản lý nhãn có add/rename/delete-confirm, số thay đổi pending, sync và xung đột. Nhãn trên
editor/filter/card hiển thị name theo ID; nhiều filter là AND. Rename không đổi ID/filter đang chọn.
Delete bỏ nhãn khỏi display/filter/serialization, không xóa note/title/content/draft. Metadata nhãn
của note khóa vẫn không ở list/card/semantics. Catalogue của owner là danh sách nhãn độc lập;
recipient chỉ thấy tên nhãn trong note được phép đọc, không tải catalogue của owner.

| API | Hành vi |
|---|---|
| GET /labels | Catalogue của session, gồm tombstones để client biết nhãn đã xóa |
| POST /labels/sync | op_id, label_id, base_revision, kind=upsert/delete, name; owner-only/CAS/idempotent |
| POST /sync | Note labels là IDs với labels_format=ids; kiểm tra ID thuộc owner; editor không đổi pins/labels |
| GET /notes hoặc /notes/{id} | labels IDs + label_names khi được đọc; note khóa ở list không có hai trường này |

Ví dụ tạo nhãn rồi gắn vào note:

```json
{"op_id":"UUID_OPERATION","label_id":"UUID_LABEL","base_revision":0,"kind":"upsert","name":"Học tập"}
```

Rename tăng revision nhãn trong một transaction. Mọi note dùng ID nhìn tên mới khi sync; không
rewrite title/content hoặc tăng revision/updated_at note. Giữ invariant editor freeze base revision.
Delete ghi tombstone; associations raw trong notes.labels có thể còn ID, serializer lọc tombstone.
Một note-upsert đến muộn có ID đã xóa được lọc bỏ nhãn, không làm nhãn hồi sinh; nội dung vẫn
theo kiểm tra revision note. ID không tồn tại/của tài khoản khác422. Tombstone không được rename
để sống lại; dùng bản máy chủ và thêm nhãn mới nếu cần. Chưa có tombstone/operation-journal GC.

Label policy là optimistic revisions, không áp last-server-accepted của preferences vào nhãn.
Operation ID + payload immutable, queue/account catalogue/conflict được lưu trước network trong
encrypted snapshot. Labels gửi trước note-upserts để note mới không tham chiếu nhãn chưa tạo.
Request in-flight chỉ retire đúng op_id đã ack; local rename mới vẫn giữ operation/revision tiếp.
SQLite journal không replay mutation cũ sau một rename mới; retry đổi payload cùng op_id409.
Note tham chiếu ID nhãn mới chưa tạo được sẽ chờ label operation, không gửi payload lỗi hoặc đổi
operation cũ. Sync vẫn tải notes để nhận lock/revoke; lock vẫn archive latest draft vào recovery.

CAS/duplicate conflict giữ lựa chọn local và báo trong manager. Người dùng đổi tên để tạo operation
mới dựa revision server, hoặc Dùng bản máy chủ. Nếu hai thiết bị tạo cùng tên dưới hai ID,
chọn bản máy chủ remap assignments pending sang ID có sẵn. Nếu không có nhãn tương ứng thì bỏ
assignment. Note operations bị thay thế nhận op_id mới, không sửa payload cũ; giữ latest valid
content và unfinished draft. Resolution chờ sync kết thúc; local write fail rollback lựa chọn.
Race mới sau resolution vẫn có thể thành note conflict; cơ chế copy/remote hiện có giữ bản local.
Các cập nhật phiên khác được nhận khi sync/retry15s; đây chưa phải realtime subscriptions.

## Migration và khởi động

Server schema2 thêm avatars/labels/label_operations. Startup migration từ schema0/1 chuyển tên
nhãn trong notes.labels sang ID legacy ổn định UUIDv5 theo account+name. Nội dung/revision/timestamps,
sessions/preferences/protection/grants giữ nguyên. Tên trùng chuẩn hóa dùng một ID; legacy dài giữ
được. Không gán timestamp/teamwork/commit cho migration. Backup SQLite trước upgrade trên dữ liệu
quan trọng; máy này có snapshot version2 trước runtime restart trong tmp/avatar-labels (ignored).

Client migration account chưa có label_catalogue tạo catalogue/label queue và chuyển IDs trên cached
owned notes. Pending v1 note operations vẫn nguyên payload/op_id để replay theo fingerprint cũ;
backend hỗ trợ labels_format=legacy khi field chưa có và dùng alias legacy sau rename/delete.
New client sends labels_format=ids. Cần upgrade backend + Web/native cùng đợt; app cũ có thể hiện ID
nhãn khi backend đã upgrade. Legacy local duplicates/long names có thể cần người dùng xử lý conflict.
Migration không thay envelope/key/version của vault hoặc preferences outbox policy.

Start backend qua scripts/start_backend.ps1 dùng uvicorn backend.app:create_app --factory.
Không tạo DB default khi import module cho tests/fixture. Docker command cũng factory; Docker/public
deployment chưa chạy. DB/media persistent disk/backups vẫn phải cấu hình khi chọn cloud.

Kotlin incremental compilation tắt trong android/gradle.properties vì Pub cache C: và project D:
gây different-roots error khi build file_selector_android. Không sửa GeneratedPluginRegistrant.java.
Full compilation có thể chậm hơn; APK vẫn theo signing/HTTPS gates hiện có.

## Kiểm chứng và giới hạn

01/10/2026:81 Flutter/29 backend PASS; debug Android API36 integration với OS document picker thật,
API thật/second session/platform vault/Sembast close/reopen/offline queue PASS. Web evidence được
ghi riêng trong evidence/2026-10-01-avatar-labels/INDEX.md; xem index cho kết quả chốt. Build Web/APK
không đồng nghĩa physical-device/release core/public HTTPS. Picker denied/cancel/scale2 là widget
QA; native thật đã chọn file nhưng chưa thao tác permission denial/OS force-kill/TalkBack. Avatar
storage thuộc backend local thực, không claim đã dùng cloud storage hay production service.

Nguồn package nhỏ/SDK: [file_selector](https://pub.dev/packages/file_selector),
[Pillow Image](https://pillow.readthedocs.io/en/stable/reference/Image.html),
[Kotlin incremental flags](https://kotlinlang.org/docs/gradle-compilation-and-caches.html).
