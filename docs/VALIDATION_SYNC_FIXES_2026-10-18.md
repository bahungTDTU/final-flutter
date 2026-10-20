# Sửa validation và đồng bộ —18/10/2026

Tiếp tục [audit32tiêu chí](PROJECT_AUDIT_2026-10-18.md) theo yêu cầu người dùng.
F01–F04 đã sửa trong code; nghiệm thu runtime Flutter/Web/Android còn chờ môi trường
cho phép chạy. Source HEAD4a196ef33019b38c6c2812fcbd48f05bf0d7d134 + working changes,
branch `codex/dashboard-motion-performance`. Không commit/push/merge/deploy.

## Hành vi mới

| Lỗi | Thay đổi |
|---|---|
|F01:422 chặn cả queue|Đánh dấu conflict status422 cho riêng note bị từ chối. Giữ nguyên operation/ID/payload và các operation phụ thuộc, bỏ qua note đó ở các lần sync sau. Note khác và GET/notes tiếp tục; remote lock/revoke vẫn đi qua cơ chế archive hiện có. UI phân biệt validation rejection với revision conflict.|
|F02:Unicode title|Validation chung theo Unicode code points giống Pydantic: title200, serialized content100000. Emoji/combining được kiểm tra trước outbox; input không hợp lệ vẫn là draft. Editor hiện số lượng và thông báo, không âm thầm cắt input.|
|F03:copy quá dài|Dành chỗ cho hậu tố trước khi tạo tiêu đề bản sao; cắt theo grapheme hoàn chỉnh, tổng không quá200codepoints. Giữ nội dung, UUID/op_id mới và base_revision0. Bản nháp chưa hợp lệ tiếp tục ở dạng draft.|
|F04:31labels|Editor thường/bảo vệ chặn thêm khi đã30 nhưng vẫn cho bỏ chọn, hiện giới hạn. Controller từ chối trước thay đổi note/outbox; protected reader giữ draft cũ và báo lỗi.|

Protected reader khi server trả422 giữ operation bất biến và mở hành động phục hồi
bản sao như conflict. Việc sửa draft không thay payload của operation đã gửi.
Không tự retry vô hạn operation lỗi từ vòng sync chung, không tự bỏ dữ liệu người dùng.
Phục hồi theo UI có sẵn: Giữ bản sao của tôi / Dùng bản máy chủ / Để sau.
Với validation rejection, bản sao dùng note ID mới và không mang labels gây lỗi.

Giữ nguyên frozen editor base revision, permission/grant, encrypted recovery, preferences
merge/idempotency. Không áp dụng last-server-accepted cho ghi chú. Thư viện `characters1.4.1`
vốn đã có trong lockfile, nay khai báo trực tiếp để cắt tiêu đề theo grapheme; không nâng
phiên bản hoặc thêm package mới vào dependency closure.

Đính chính số học trong audit: hậu tố ` (bản phục hồi)` dài15 code points; title200 thành215,
không phải214. Tái hiện server từ chối và kết luận lỗi không đổi.

## Kiểm chứng

- Direct Dart format:130files,0changes sau format.
- Direct Dart analyze: xem log cuối trong evidence; không đổi tên lệnh thành Flutter analyze.
-10case chạy **Dart domain thật → Pydantic Operation thật** PASS: emoji ghép,200astral,
  combining200/202, whitespace vượt biên, content100000/100001 và3loại copy title.
  Hai phía thống nhất accept/reject; kiểm tra copy không cắt giữa grapheme.
- Hàm backend đồng bộ + SQLite4roles chạy PASS: owner/editor, viewer403, stranger404,
  lock423, đúng6fields listing, unlock và revoke404. Đây không phải HTTP/middleware QA.
- Thêm8regressions (7unit/controller +1widget) trong `test/validation_sync_regression_test.dart`:
  input/draft UI, Unicode domain/persistence,422quarantine/reopen/dependent ops,
  remote lock sau422, copy title200/new identity, ordinary31labels và protected
  draft31labels/immutable422copy. **Chưa chạy được**, không tính8PASS.
- Lệnh Flutter test thử thật bị chặn mở `C:/Users/LENOVO/flutter-sdk/bin/cache/lockfile`.
  Full Flutter/backend suite, actual HTTP/browser/native, build, providers và CI mới
  NOT RUN. Giới hạn socket/SDK đã được ghi trong audit; không đổi quyền hoặc giả testpass.

Probe contract ban đầu phát hiện kỳ vọng test sai về độ dài hậu tố (93 cặp combining);
sửa expectation thành92 cặp, không thay thuật toán để chiều theo test.
Kết quả10case cuối nằm trong `contract-result.txt`. Báo cáo/analyze ban đầu được giữ
riêng với log cuối để không trình bày lỗi chẩn đoán như kết quả hiện hành.

## Cần chạy tiếp khi môi trường khả dụng

```powershell
./scripts/check.ps1
flutter test test/validation_sync_regression_test.dart test/sync_durability_test.dart test/protected_editing_test.dart
```

Browser/native: tạo title50emoji ghép→thông báo/draft/reopen→rút gọn→ACK;30/31labels;
hai session gây409 với title200→giữcopy→ACK; queue422 cũ→note khác ACK→remote lock
archive latest draft; account switch không dùng queue cũ. Theo README phải có backend
và thiết bị thật/emulator trước chạy integration. Chưa claim các kịch bản này PASS.

[Evidence và source manifest](../evidence/2026-10-18-validation-fixes/INDEX.md).
