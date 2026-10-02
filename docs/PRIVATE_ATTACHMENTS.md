# Đính kèm riêng tư — 01/10/2026

Tiêu chí15/16: nhiều ảnh PNG/JPEG, video MP4, file PDF/TXT/CSV/ZIP gắn vào note đã đồng bộ.
Editor → Đính kèm → Chọn tệp → Tải tệp lên; ảnh/video có Xem trước, tất cả có Tải xuống.
Owner/editor có Xóa-confirm; viewer chỉ đọc/tải. ProtectedReader đã nối nút Xem đính kèm
với grant hiện tại, chỉ đọc. Không dùng URL công khai hoặc token trong query string.

## Giới hạn và validation

| Loại | Giới hạn / xử lý server |
|---|---|
| PNG/JPEG | Input≤10 MiB, cạnh≤8192px,≤16 triệu pixel, một frame; decode/verify, EXIF orientation, thu nhỏ≤2048px, tạo PNG RGBA mới bỏ metadata |
| MP4 | Input≤20 MiB; kiểm tra bounded ISO-BMFF boxes, ftyp đầu + moov + mdat; không validate toàn bộ codec/sample, không transcode |
| PDF/TXT/CSV/ZIP | Input≤20 MiB; extension+MIME; PDF/ZIP signature, TXT/CSV UTF-8 không NUL; không execute/extract/render inline |
| Mỗi note | Tối đa10 active files và100 MiB canonical BLOB, kiểm tra trong transaction |
| Tên | NFC, trim,1–160 ký tự, không slash/backslash/control; UI chọn tối đa10 files/100 MiB mỗi lần |

Video phát được phụ thuộc codec nền tảng; H264/yuv420p320×180/2 giây đã đo trên Chrome/Android.
PDF/ZIP signature không thay antivirus/full parser. Không claim quét malware hoặc mọi MP4 đều phát.
Ảnh tải xuống là PNG canonical; UI thêm `.png` vào tên gốc để không coi canonical PNG là JPEG.
Không đưa arbitrary HTML/SVG/executable vào allowlist. Giới hạn throughput/account quota/abuse cần
hoàn thiện trước public release; SQLite BLOB là lưu trữ local, chưa cloud/CDN/load-test.

## API, quyền và transaction

Base: `/notes/{note_id}/attachments`, Bearer session bắt buộc.

| Method | Route / body | Rule |
|---|---|---|
| GET | Base → metadata array | read ACL + unlock grant nếu locked |
| POST | `/{UUID}?name=...&kind=image\|video\|file`, raw binary/MIME | edit ACL, validate trước upload và kiểm tra lại sau normalize trước commit |
| GET | `/{UUID}` → binary | read/grant kiểm tra lại mỗi request; single Range206/416 |
| DELETE | `/{UUID}` | edit/grant; tombstone giữ fingerprint, data=NULL/size0; retry idempotent |

Owner không bypass khóa; editor không có quyền đổi owner/role/protection. Viewer POST/DELETE403,
stranger404, anonymous401; grant bind session/version/TTL, revoke/lock/session reset có hiệu lực
với request mới. Direct binary trả private/no-store, nosniff, CSP sandbox/default-src none,
Content-Disposition attachment. App worker chỉ cache static assets, không cache API/files.

ID upload tạo một lần cho lựa chọn, fingerprint note/name/kind/MIME+bytes ban đầu immutable.
Retry sau mất ack trả row hiện tại nếu cùng creator/payload, không tạo bản thứ hai. ID khác
payload hoặc đã bị xóa trả409; replay sau revoke vẫn bị từ chối trước kiểm tra ID. SQLite
BEGIN IMMEDIATE kiểm tra quyền/quota+insert/delete; soft-delete note null toàn bộ attachment
BLOB trong cùng transaction. Attachment mutation không sửa note content/revision, không nâng
frozen base revision của editor và không rewrite note outbox/preferences/labels/recovery.

Schema vẫn version2: attachments là additive CREATE TABLE IF NOT EXISTS/index trong schema.sql;
migration label0/1→2 đã có được giữ nguyên, không tự tăng PRAGMA version. Test restart thực
SQLite giữ files, tombstone không resurrect. BLOB server plaintext theo quyền file DB/backups;
không claim E2E encryption hoặc thu hồi file người dùng đã xuất hợp lệ.

## Client, cache và lỗi

AttachmentSession (ChangeNotifier) riêng theo route/account/token, metadata/bytes trong RAM;
không đưa vào account snapshot/session/Sembast/recovery/outbox. Metadata poll15s; account switch,
remote lock/revoke/lỗi mạng/lifecycle background tăng epoch và che danh sách/preview. Preview
phải còn ID trong danh sách mới nhất; peer delete che cả tên/ảnh/video và dispose player.
Hộp xác nhận xóa cũng theo session: khi lock/revoke/delete làm mất quyền/ID thì bỏ tên file,
hiện lời nhắc kiểm tra lại và vô hiệu Xóa tệp; Hủy vẫn hoạt động.
Độ trễ polling15s có thể thêm thời gian request; không phải realtime hay tức thì trên máy offline.

Web fetch binary có Bearer rồi tạo Blob URL RAM cho ảnh/video/download, revoke khi dispose;
download báo đã chuyển cho trình duyệt, không tuyên bố đã ghi disk. Android video dùng private
URL+Authorization qua video_player native, không tạo file video plaintext trong app directory.
Android export dùng MethodChannel → ACTION_CREATE_DOCUMENT → vị trí người dùng chọn, không
xin quyền toàn bộ bộ nhớ/gallery. OS save success chỉ trả sau write; cancel trả false.

Picker cancel/denied giữ lựa chọn cũ; upload tuần tự loại lựa chọn sau ack, lỗi giữ ID/payload để
retry trong cửa sổ. Đóng cửa sổ bỏ lựa chọn chưa upload; không có durable/offline media queue,
background upload/progress/resume/force-kill guarantee. Attachment CTA chờ note pending hoàn tất.
Read/upload timeout60s; không thay timeout15s của avatar/API khác. Nội dung note vẫn có draft
và encrypted recovery độc lập. Dữ liệu đã xuất hoặc đã buffer hợp lệ không thể bị thu hồi vật lý.

## Kiểm chứng và tái chạy

`scripts/setup.ps1`, `scripts/check.ps1`:88 Flutter/40 backend PASS (7/11 mới), analyze/format sạch;
1 warning deprecation Starlette TestClient. Backend dùng SQLite/TestClient owner/viewer/editor/
stranger/anonymous, grant session/revoke/replay, type/size/count, range, canonical ảnh, restart,
delete cleanup và race khóa trong normalize. Flutter account-switch/lifecycle/pending retry,
viewer controls, peer-delete preview, remote-lock delete-confirm; picker denied/cancel/scale2 dùng doubles.

Chrome local release390×844/DPR1: actual chooser3 files, upload, image/video Blob preview (2s
video position thực), download hash, delete TXT giữ content/revision2, second-session lock423
che preview. Web build sau peer-delete guard được đối chiếu hash rồi kiểm tra peer delete ảnh;
build chốt thêm confirmation guard có hash riêng và actual remote-lock xóa-confirm PASS.
Android API36 emulator debug: actual file_selector/DocumentsUI PNG upload/image, peer delete
che preview, peer MP4/TXT upload, native video position>0, ACTION_CREATE_DOCUMENT TXT save,
hash42 bytes khớp, UI delete TXT, note revision1/content giữ nguyên. Final native run còn kiểm
tra remote-lock khi xóa-confirm: tên file che/nút disabled, tắt khóa giữ content/revision3 đúng.

Logs/results/exact commands/hash/ảnh và giới hạn: [evidence index](../evidence/2026-10-01-attachments/INDEX.md).
Không nâng thành full15/16 nghiệm thu: OS denial/cancel chưa đo, protected-reader attachments
chưa chạy actual UI, physical device/release feature/HTTPS/public deployment/video chưa có.

Chạy backend8000 theo README, emulator online, fixture files đã kèm evidence. Test MP4/TXT cần
fixture server8013 **chỉ QA**, ở terminal riêng:

```powershell
& '.\.venv\Scripts\python.exe' -m http.server 8013 --bind 127.0.0.1 --directory evidence/2026-10-01-attachments
& 'D:\Android\sdk\platform-tools\adb.exe' reverse tcp:8000 tcp:8000
& 'D:\Android\sdk\platform-tools\adb.exe' reverse tcp:8013 tcp:8013
& 'D:\Android\sdk\platform-tools\adb.exe' push evidence/2026-10-01-attachments/attachment-fixture.png /sdcard/Download/attachment-fixture.png
& 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' test integration_test/attachments_test.dart -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000
```

Khi log QA_ATTACHMENT_PICKER_READY chọn PNG; QA_ATTACHMENT_SAVE_READY chọn vị trí và Save.
Không deploy fixture server. Production không fetch port8013; chỉ integration_test sử dụng.
Fixture generation tùy chọn: script ở evidence, imageio-ffmpeg0.6.0 là QA-only, không thêm
dependency runtime backend. Dùng fixture đã kèm không cần cài ffmpeg.

## Nguồn chính thức đã kiểm tra

- [file_selector1.1.0](https://pub.dev/packages/file_selector): openFiles; Android không có save dialog API từ package.
- [video_player2.14.0](https://pub.dev/packages/video_player), [Web limitations](https://pub.dev/packages/video_player_web): codec/autoplay; Web không dùng file constructor.
- [Android Storage Access Framework](https://developer.android.com/training/data-storage/shared/documents-files): ACTION_CREATE_DOCUMENT, quyền theo URI người dùng chọn.
