# Thanh điều hướng PC —14/10/2026

IMPLEMENTED theo ảnh người dùng và skill ui-ux-pro-max được chỉ định. Giữ chủ đề
Deskbook/Atelier; thay phần trình bày ba mục trong DeskMasthead bằng DeskDestinationStrip.

- Nhóm ba nút có nền/viền riêng; bỏ số thứ tự trang trí và gạch dưới dài.
- Biểu tượng ghi chú/cộng tác/AI, chữ14 weight600/700. Mục chọn có nền primary tương
  phản, dấu tick và selected semantics; sáng là xanh đậm, tối là vàng đồng từ theme.
- Nút native min52dp, nhãn tự wrap, dấu tick có chỗ cố định nên vùng bấm không dịch.
  Hover/press hữu hạn180ms, viền focus2dp; reduced motion dùng duration0.
- Thứ tự và callback ba mục giữ nguyên. Không thêm route, dependency hay animation
  lặp; không đổi controller/query/filter/editor/draft/ACL. Phone/rail vẫn dùng bố cục cũ.

PASS: format119files0changes, analyze,290 Flutter/143 backend.3 test mới kiểm tra
Tab/Enter và selected semantics,12 trường hợp layout (hai theme/chữ100–140%/ba mục
chọn), cùng contrast text≥4.5/focus≥3. Regression Deskbook được mở rộng để chuyển
ghi chú cá nhân↔chia sẻ rồi giữ query/filter qua desktop/rail/phone.

PASS actual WebIAB/API8060/DB tổng hợp:1280×1000 sáng/tối,1180×800 tối; cả ba mục đổi
đúng màn, Shift+Tab/Enter mở thư viện chia sẻ; PC→375×812→844×390→PC giữ mục chia sẻ
và query “Kế hoạch”. Console error0 trong phiên đã kiểm tra. Các ảnh chỉ có dữ liệu QA.
API trực tiếp owner/editor/viewer/stranger PASS; backend không thay đổi. Web QA/API8060,
Web chạy thường/API8000 và APK debug/emulator API10.0.2.2:8000 compile PASS.

NOT RUN lượt này: screen reader thật, Android runtime/IME/FPS, provider thật, CI,
signing/release/deploy. Thông báo font CupertinoIcons/SDK XML/deprecation hiện có trong
logs; build/tests vẫn thành công, các biểu tượng trong thanh đã kiểm tra hiển thị đúng.

Source chưa commit/push: `codex/dashboard-motion-performance`, base `4a196ef`.
[Spec](../design-system/notetogether-deskbook/pages/desk-navigation.md),
[ảnh/log/source hashes](../evidence/2026-10-14-desk-navigation/INDEX.md).
