# UI đồng bộ, responsive và chi phí render —06/10/2026

Yêu cầu: thống nhất chủ đề, sửa bố cục/responsive và tối ưu performance. Giữ Prism/NotoSans
hiện có, một Flutter project; không đổi framework, state, backend hay schema. Release tiếp tục hoãn.

## Thay đổi đã nối vào production

- `ReadingCanvas` trong design_system dùng chung cho editor, AI Q&A và protected reader:
  reading width800, surface opaque/rim Prism, spacing12/16 ở mobile hoặc cửa sổ thấp;
  spacing24/28 khi rộng. Không thêm keyboard inset lần hai khi Scaffold đã resize body.
  Route vẫn sở hữu controllers/scroll/selection; protected grant/lifecycle/obscure giữ nguyên.
- Gallery bỏ backdrop vẽ lặp bên trong nền toàn app; sáu template dùng sáu tone có sẵn,
  selected border/check icon vẫn rõ ở hai theme. Hai cột chỉ khi đủ width840/height440
  và text scale<140%; cửa sổ thấp/chữ lớn dùng một cột cuộn.
- Footer compact chỉ có “Dùng mẫu” và “Xem trước mẫu”, tránh caption/footer chiếm body
  khi landscape/chữ200%. Preview dialog cuộn mở được ngay, giữ selected template;
  desktop vẫn có preview bên cạnh. Appbar gallery/protected một dòng có ellipsis.
- Preview card giới hạn480 UTF-16 units + ellipsis, không cắt đôi surrogate. Giới hạn cả
  input shaping và card semantics; editor và search vẫn đọc đầy đủ100000 ký tự.
  Locked card không đọc title/content/pin/date/labels/shared metadata để hiển thị; pinned
  section/sort cũng không dựa pin/date của note khóa dù object còn mang metadata cũ.
- `NoteListingCache` chỉ thuộc Home route: notes immutable replaced/same-list element
  replacement, account, query, role destination, selected/deleted labels đều invalidate.
  Listener xóa source cache ngay khi dữ liệu/account đổi, cả khi Home nằm sau editor;
  dispose bỏ references. Không giữ lowercase index/private text copy hoặc ghi cache mới xuống DB.
- Chỉ suffix “Xóa tìm kiếm” dựng lại ngay lúc nhập. Query/list chạy sau debounce300ms;
  clear hủy timer để query cũ không quay lại. Các refresh chỉ status/theme dùng lại kết quả
  lọc/sort khi source không đổi. PageStorage scroll/filter/ID và frozen editor base giữ nguyên.
- Literal search dùng `RegExp.escape` + Unicode case-insensitive matching, tránh nối và
  lowercase toàn bộ note dài ở mỗi query. Giữ match ở title/content và qua separator cũ
  bằng suffix/prefix có độ dài giới hạn theo query. Không đổi thành fuzzy/AI search.

## Đo hiệu năng có phạm vi

Lệnh độc lập sau nghiệm thu native (emulator dừng):

```powershell
& 'C:/Users/LENOVO/flutter-sdk/bin/flutter.bat' test test/ui_cohesion_test.dart --plain-name 'Controlled NotoSans shaping and cached-query benchmark' --reporter expanded
```

Flutter test engine trên host, NotoSans bundled, warm4/đo11 iterations, median microseconds.
TextPainter font16/maxLines4/width260/ellipsis; đổi input mỗi lần để tránh paragraph reuse.
Query500 note, mỗi note100000 ký tự, keyword “việt” nằm gần đầu; cùng filter/sort cho baseline.

| Công việc | Baseline/đầu vào đầy đủ | Sau tối ưu | Phạm vi |
|---|---:|---:|---|
| Layout đoạn chữ card |4279 µs|165 µs|100000 →481 units đầu vào; khoảng96% giảm trong case này |
| Query lần đầu |348926 µs|388 µs|Lowercase+join → literal matching, keyword gần đầu |
| Query lặp source không đổi |348926 µs|10 µs|Reuse view + source/list/label/account checks |

Kết quả trong `benchmark-isolated.txt`/`benchmark.json`; full gate khi native/Web cùng chạy
có số khác do tải hệ thống. Không áp các tỷ lệ này cho mọi query/thiết bị; suffix/missing vẫn
phải scan text. Không đo FPS, raster frame time, battery, default native renderer hoặc máy thật.
Emulator dùng Skia software có IME/jank logs, không phải bằng chứng animation đạt60 FPS.

## Kiểm chứng

- **161 Flutter/88 backend PASS**, format/analyze sạch;6 regression mới gồm cache invalidation,
  lock metadata, Unicode literal/boundary, bounded surrogate preview, debounce không rebuild card,
  full-text tail search,320×390/chữ200%/preview CTA, keyboard/selection/frozen base và benchmark.
- Suite native chỉ gom lại **3 scenario hiện có**, không tính thành3 test mới: auth/labels/
  preferences/stable editor; gallery/checklist/focus/encrypted offline reopen; protected SSE/
  offline/revalidate/delete. API36 debug real API/device keys/Sembast PASS; teardown là riêng.
  Test UI cũ được cập nhật để chọn theme qua menu compact thực, không bỏ data assertions.
- Actual IAB Web debug: mobile390×568, landscape844×390, tablet requested768×1024
  (PNG768×988), desktop1280×900 có DOM metrics xác nhận. Gallery preview, dark editor,
  AI form giữ câu hỏi khi đổi breakpoint (không submit/provider call), protected actual unlock/
  relock, full-text search cuối100000 ký tự ra1 kết quả, API content/ID sync, remote SSE lock
  che editor và cached Home PASS. Chưa full browser-history/deep-link/NVDA/TalkBack QA.
- Direct HTTP owner stale409/lock423, editor update/revoke404, viewer403, stranger404,
  locked minimal fields PASS bằng script có `--output` tách từng đợt evidence.
- [Evidence/ảnh/commands/hashes](../evidence/2026-10-06-ui-cohesion/INDEX.md).
  Không public deploy/release/physical/Gemini thật/email Internet/video claim.
