# Giao diện Việt–Anh —15–16/10/2026

IMPLEMENTED: chuyển trực tiếp giữa Tiếng Việt và English, mặc định Tiếng Việt.
Bộ chọn nằm ở màn đăng nhập, Hồ sơ và tùy chỉnh → Giao diện → Ngôn ngữ,
và biểu tượng dịch trong thanh công cụ soạn thảo. Tên hai ngôn ngữ luôn dùng autonym.
Chữ lớn trên màn đăng nhập chuyển sang menu biểu tượng để tránh tràn ngang.

## Phạm vi và dữ liệu

Tài nguyên UI nằm trong `lib/l10n/strings_en.dart`; `AppStrings` cung cấp delegate
đồng bộ, placeholder và extension BuildContext. Material/Widgets/Cupertino và Quill
nhận cùng locale từ MaterialApp. Không thêm dependency hoặc gọi dịch vụ dịch trực tuyến.
Dashboard, editor, inspector, protection/recovery, AI forms, chia sẻ, đính kèm,
nhãn, workspace/planner/focus, security và các trạng thái UI dùng tài nguyên chung.
Các lỗi/validator đã hiển thị được dịch lại tại ranh giới UI khi đổi locale.

Chỉ dịch giao diện. Tiêu đề/nội dung ghi chú, tên nhãn, tên người dùng, bộ sưu tập,
mẫu do người dùng tạo, tệp đính kèm và kết quả AI giữ nguyên. Mẫu có sẵn dịch phần
mô tả/chọn mẫu; nội dung mẫu được lưu vẫn là dữ liệu gốc tiếng Việt. Không tự dịch
email của provider hoặc thay đổi prompt/đáp án Gemini theo ngôn ngữ giao diện.
Placeholder thay một lượt, không dịch hoặc nội suy đệ quy đối số có dữ liệu người dùng.
Hướng dẫn thẻ khóa được dịch theo cờ locked, không đưa excerpt note thường qua bộ dịch.

## Lưu, đồng bộ và tương thích

Trước đăng nhập: lưu `{locale: vi|en}` trong khóa không nhạy cảm `ui:locale`.
Sau đăng nhập: locale thuộc namespace tài khoản mã hóa hiện có, cùng immutable
`pending_preferences`; lưu thành công trên thiết bị trước khi đổi giao diện.
Nếu tài khoản cũ chưa từng có locale, lựa chọn English trước login được đưa vào queue;
nếu tài khoản đã có locale thì dùng tùy chọn tài khoản. Logout trở về lựa chọn công khai,
không lấy locale của tài khoản vừa thoát làm mặc định của người kế tiếp.

POST `/me/preferences/sync` nhận `{op_id, locale: "en"}` hoặc `"vi"`, có thể merge
cùng grid/dark/font_size. Chỉ nhận hai giá trị này; null/locale khác/owner_id bị từ chối.
Quy tắc last-server-accepted chỉ áp dụng preferences, replay op cũ không ghi đè thay đổi
mới và op_id cùng payload khác trả409. Thay đổi phát sinh trong request đang chạy vẫn
overlay profile trả về và nằm trong queue. Mất mạng giữ queue để retry, không gọi là đã sync.
Thiết bị khác nhận trong lần sync tiếp theo, không claim realtime preference.

Không đổi schema local/database. Tài khoản cũ thiếu locale mặc định vi.
Legacy PATCH `/me/preferences` không có locale giữ giá trị đã lưu trên server;
client mới cần backend mới để server chấp nhận locale. Không sửa generated plugin files.

## Invariants

Đổi locale cập nhật MaterialApp và các nhãn phụ thuộc Localizations, giữ Navigator,
editor ID, document/controller, title/body, selection, frozen base revision và query.
Phản hồi khôi phục draft trong initState dùng canonical message, dịch ở build;
không đọc Localizations trước initState hoàn tất. Không animation chuyển nội dung cũ.
Giữ cache preview có giới hạn, lazy list và scoped sync rebuild từ bản dashboard trước.

Ghi chú khóa vẫn không xuất hiện title/content/labels/date/share identities trong visual,
semantics hoặc cache danh sách; chỉ cho phép pin/shared boolean như người dùng xác nhận.
Không cache runtime private strings trong bộ dịch; chỉ cache regex tài nguyên cố định.

## Kiểm chứng

[INDEX bằng chứng](../evidence/2026-10-15-bilingual/INDEX.md) ghi lệnh, kết quả,
đích chạy và giới hạn. `test/localization_test.dart` kiểm tra resource/placeholder,
public reopen/account isolation, immutable operation đang chạy, validator, draft/selection/
frozen revision, hai theme/responsive/privacy và phone chữ200% bằng giao diện tiếng Anh.
Hai backend test mới kiểm tra locale merge/replay/legacy client/validation/account/DB reopen.
Web thực khác với widget test; APK debug build không xác nhận Android runtime hoặc FPS.
Các yêu cầu release/provider/native còn giữ trong ma trận, không được đóng bởi tính năng này.

Thiết kế delegate theo hướng dẫn chính thức:
https://docs.flutter.dev/ui/internationalization
