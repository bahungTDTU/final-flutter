# Soạn thảo trực tiếp trên PC và điện thoại —09/10/2026

Người dùng chọn định dạng trực tiếp như Word. Đây là nâng cấp sáng tạo theo yêu cầu
người dùng, ngoài mức tối thiểu của đề; không thay đổi ACL, chủ sở hữu hay quyền chia sẻ.

## Trải nghiệm

PC từ1000px (chữ không quá150%) có thanh định dạng phía trên, trang viết ở giữa,
bảng sắp xếp/công cụ bên phải; từ1350px thêm mục lục bên trái. Tiêu đề và nội dung
có nhãn, khoảng cách và đường phân cách riêng. Có chế độ đọc, phóng/thu80–140% và
chế độ viết tập trung. Các cột thu gọn khi màn hình nhỏ hoặc tăng cỡ chữ hệ thống.

Điện thoại/tablet dùng một cột, trang viết rộng, thanh định dạng cố định phía dưới;
công cụ bổ sung trong menu và phần sắp xếp dưới tài liệu. Thanh định dạng cuộn ngang
khi cần, cùng bàn phím hệ thống và safe area. Không đưa ba cột PC lên điện thoại.

Định dạng thật: hoàn tác/làm lại, h1–h3, cỡ chữ, đậm/nghiêng/gạch chân/gạch ngang,
màu chữ/đánh dấu, căn lề, danh sách gạch đầu dòng/đánh số/checklist, trích dẫn,
khối mã, liên kết http/https/mailto, xóa định dạng, tìm và thay thế. Mục lục nhảy
đến tiêu đề; bộ đếm dùng văn bản hiển thị. Đính kèm riêng tư, AI, ghim/nhãn/chia sẻ
dùng chức năng server đã có. AI trong QA là fixture tường minh, không phải Gemini thật.

Không có bảng, DOCX/PDF export, bố cục trang in hay toàn bộ chức năng Microsoft Word.
Không đặt nút giả cho các chức năng này. Phần xem trước hiện là chế độ đọc trực tiếp.

## Lưu trữ và tương thích

`flutter_quill:11.6.0` và `markdown:7.3.0` được pin. Nội dung tiếp tục là một string:
plain text giữ string cũ; nội dung có định dạng dùng `NTDOC1:` + JSON Delta insert-text.
Không dùng HTML làm định dạng lưu, không nhúng URL ảnh/video. Tệp dùng attachment ACL.
Giới hạn100000 đơn vị UTF-16 cho string phía client gồm cả định dạng; backend giữ giới
hạn100000 ký tự. Khi vượt, trả lại bản được chấp nhận và báo chia nhỏ ghi chú.

Ghi chú Markdown cũ được diễn giải thành view trực tiếp khi mở, không ghi migration
chỉ vì mở/đổi theme/zoom/chọn chữ. Lần chỉnh sửa đầu giữ ý nghĩa văn bản và định dạng
được hỗ trợ; không đảm bảo roundtrip cú pháp Markdown nguyên văn sau chỉnh sửa.
Các client dùng source cũ chưa hiểu envelope sẽ thấy mã định dạng, cần cập nhật cùng
backend mới. Không đổi schema SQLite/Sembast hay các khóa outbox/encrypted recovery.

Search/card/conflict preview/AI sử dụng projection plain text; những từ bị chia bởi
span được ghép lại, không search các key JSON hoặc màu/font. Backend kiểm tra cấu trúc,
attribute và scheme link; nội dung trắng sau decode không tạo note/operation.

Controller, focus và GlobalKey thuộc phiên note, giữ khi resize/đổi theme. Revision
lúc mở vẫn freeze; peer update không tự rebase. Các thao tác chọn chữ/zoom không tạo
outbox. Format-only edit đi qua autosave/draft/outbox thật. Ghi chú bảo vệ dùng cùng
workspace sau unlock nhưng nội dung chỉ sống trong reader/vault; relock/revoke/account
change xóa controller và toàn bộ vùng editor khỏi visual/semantics.

Select All của browser có thể bao gồm newline cấu trúc của Quill. Adapter chặn xóa
newline trước mutation và chuẩn hóa phạm vi thay; regression kiểm tra render sau nhập.
Web semantics chỉ có một ô nội dung có focus/input/selection để tránh các lớp text con
chiếm focus. Checklist có controls trong bảng dàn ý; chưa nghiệm thu screen reader.
Nhập whole-value áp dụng diff nhỏ nhất để giữ định dạng span không liên quan. Plain-text
projection được cache theo document change, không quét lại nội dung chỉ vì đổi caret.

## Kiểm chứng

Xem [evidence](../evidence/2026-10-09-document-editor/INDEX.md) cho kết quả cuối,
ảnh Chrome, source hashes và phạm vi. Base717f0ab + working changes trên
`codex/ui-ux-performance`; không tạo commit hay push cho đợt này.

Native integration harness được cập nhật từ EditableText sang Quill TextInputClient.
Harness inject sự kiện qua platform channel như tester.enterText, không chứng minh
bàn phím thật/IME. APK compile và Chrome mobile viewport không thay cho native runtime.
Benchmark/FPS trước đây thuộc source cũ, không đại diện cho editor mới.

Các gate release, signing, HTTPS, video/báo cáo và CI/approval trước merge vẫn áp dụng.

## Đối chiếu thiết kế và ảnh thật

Hai concept được tạo và kiểm tra trước implementation; chỉ dùng làm tham chiếu, không
nhúng bitmap concept vào app. Ảnh actual được chụp từ build release local có backend riêng.

| Đặc điểm | Actual và chênh lệch có chủ đích |
| --- | --- |
| Header tím-xanh, nền lavender/navy | Giữ BrandGradient/Prism của app hiện tại; header ưu tiên tên chế độ, không lặp logo |
| Trang viết giữa ba cột | PC1536px có mục lục/trang/inspector; từ1000px thu hai cột, đảm bảo vùng nhập rộng |
| Title và content có phân cấp rõ | Title30px/25px, nhãn ngoài, divider và khoảng đệm36px/20px; counter không đè chữ |
| Ribbon đầy đủ và trạng thái chọn | Commands nối vào Quill thật; thêm size/color/alignment so với concept; Ctrl/Cmd F mở tìm kiếm |
| Inspector rõ vùng sắp xếp và công cụ | Dùng ghim/labels/attachment/AI/protection thật, cập nhật counters từ visible text |
| Mobile một cột và toolbar dưới | Không giữ sidebar PC; toolbar cuộn ngang và menu bổ sung, body cuộn trong phần còn lại |
| Footer có counts và zoom | Counts/caret/zoom giữ state qua theme/resize; mobile bỏ zoom để giảm mật độ |
| Icon bảng trong concept | Bỏ vì chưa có table engine; không tạo nút giả. DOCX/PDF cũng chưa hỗ trợ |

Tham chiếu API: [Flutter Quill11.6.0](https://pub.dev/packages/flutter_quill/versions/11.6.0),
[QuillEditorConfig](https://pub.dev/documentation/flutter_quill/latest/flutter_quill/QuillEditorConfig-class.html).
