# Home: bố cục, bộ lọc và phạm vi rebuild —09/10/2026

Đợt này cải thiện hệ Prism/NotoSans hiện có; một Flutter project Web/Android,
ChangeNotifier và contract dữ liệu giữ nguyên. Base Git `ef2ece00386b879f6ebb72b4636c42911aa07ca3`,
branch `codex/ui-ux-performance`, working changes chưa commit/push/merge. Release vẫn để cuối.

- Tìm kiếm, kiểu xem và nhãn có vùng riêng. Thanh công cụ có viền Prism và separator;
  thẻ ghi chú phân tách tiêu đề, preview và metadata, vẫn giới hạn preview480 units.
- Home chỉ dựng tối đa6 chip nhãn nhanh, ưu tiên nhãn đang chọn. Bộ lọc mở sheet có tìm kiếm,
  danh sách lazy và lựa chọn AND. Áp dụng mới đổi filter; đóng/hủy giữ filter/query hiện có.
  Xóa nhãn khi sheet đang mở loại bỏ lựa chọn đã mất; apply kiểm tra lại account/catalogue.
- Nút tạo mobile ở app bar, không phủ chữ/menu của thẻ. List không cần khoảng đệm cho FAB.
  Grid chuyển sang thẻ có chiều cao tự nhiên khi text scale>=150%; preference grid giữ nguyên
  khi resize trở lại. Sheet cuộn được cả heading/search và danh sách, footer Apply vẫn riêng,
  layout thu gọn khi chữ lớn/cửa sổ thấp/bàn phím mở.
- App shell chỉ nghe readiness/account ID/dark; tạo hai ThemeData một lần. Auth vẫn nghe busy/
  error; Home tự nghe controller. Home bỏ qua notification không đổi source khi route bị che.
  Khi source/account đổi, Home xóa listing cache và dựng lại cả khi bị che để bỏ widgets
  riêng tư cũ ngay sau khóa/thu hồi. Khi trở lại, dependency
  `ModalRoute.isCurrentOf` dựng Home theo state mới. Home có key theo account.
- Metadata khóa giữ policy07/10: public pin/shared flags vẫn hiện; title/content/labels/date/
  người chia sẻ/count vẫn không hiển thị. Editor giữ controller/ID/base revision/selection,
  durable drafts và encrypted recovery; không thêm debounce cho local persistence.

Probe dùng Flutter test engine trên host,500 ghi chú,20 notifications không đổi source mỗi case. Baseline là
app shell lưu ở commit base, chạy với cùng Home/fixture hiện tại để cô lập thay đổi root.
Đếm identity widget/ThemeData, không đo FPS, thời gian frame, native latency hoặc disk IO.

| Trong20 notifications | Shell cũ | Shell hiện tại |
|---|---:|---:|
| MaterialApp bị thay widget |20|0|
| Light ThemeData bị tạo lại |20|0|
| Thẻ Home bị thay widget khi editor phủ lên |20|0|

`test/home_experience_test.dart` thêm10 regression: shell notifications/theme/auth, Home bị che/
return, remote lock purge,1000 nhãn lazy/search/apply/cancel/AND, xóa nhãn, keyboard200%,4 viewport200% với hai theme.
Không sửa assertions bảo mật/editor cũ để bỏ qua lỗi. Full gate198 Flutter/94 backend PASS,
format87 files0changes và analyze sạch. Direct HTTP owner/editor/viewer/stranger PASS.
Web compile + offline shell40 static resources và APK debug compile PASS; APK không phải
native feature acceptance. Không có emulator/device kết nối trong đợt này; chưa native UI/FPS/
TalkBack/NVDA/production/release/LLM/mail Internet acceptance.

Kiểm chứng render và ảnh cuối xem [evidence](../evidence/2026-10-09-home-experience/INDEX.md).
Việc thu hẹp rebuild tuân theo [Flutter performance guidance](https://docs.flutter.dev/perf/best-practices)
và dùng [ModalRoute.isCurrentOf](https://api.flutter.dev/flutter/widgets/ModalRoute/isCurrentOf.html)
để nghe đúng thay đổi trạng thái route. Các con số ở trên là phép đo local của dự án.
