# Bảng kế hoạch và chuyển động UI — 10/10/2026

Bổ sung theo yêu cầu người dùng, ngoài 32 tiêu chí bắt buộc; không tự chấm điểm sáng tạo.
Kế hoạch là tổ chức cá nhân theo account trên thiết bị, dùng encrypted workspace hiện có.
Nội dung ghi chú, ACL, revision, draft, recovery/vault và immutable sync không đổi.

## Sử dụng

Mở Không gian làm việc → Kế hoạch → Thêm vào kế hoạch. Chọn một ghi chú chưa khóa và
còn quyền, đặt chặng Dự kiến / Đang làm / Hoàn thành, ưu tiên Thấp / Bình thường / Cao
và ngày hạn tùy chọn. Có lịch chọn ngày, Hôm nay, Ngày mai, +7 ngày và xóa ngày hạn.
Menu trên thẻ chuyển chặng, sửa ưu tiên/hạn hoặc bỏ khỏi kế hoạch có xác nhận. Bấm thẻ
mở note bằng luồng editor/reader hiện có, recheck quyền. Bỏ khỏi kế hoạch không xóa note.
Viewer cũng có thể tổ chức kế hoạch cá nhân nhưng không được sửa note qua thao tác này.

Tìm theo tiêu đề; lọc Quá hạn / Hôm nay / 7 ngày tới và ưu tiên cao. Tuần lọc gồm hôm nay
và 6 ngày sau. Completed không tính quá hạn hoặc thuộc bộ lọc hạn đang chờ. Sắp trong mỗi
chặng theo ưu tiên giảm, hạn sớm trước, ID ổn định; ngày trống sau ngày có hạn. Header đếm
các kế hoạch có note hiện còn khả dụng, progress hoàn thành trên tập đó; count ở cột theo
bộ lọc. Kế hoạch tối đa 500 references. Ngày hợp lệ 2000–2100, lưu calendar date yyyy-MM-dd
để không đổi ngày khi chuyển timezone. Panel cập nhật khi resume/qua nửa đêm, không tick
toàn app mỗi giây. Đây là ngày hạn trong app, chưa có nhắc OS/email/cloud sync kế hoạch.

PC >=1000px và chữ <150%: ba cột cuộn riêng, rows lazy. Mobile/tablet/chữ lớn: dropdown
chặng và một danh sách sliver lazy trong trang cuộn chung. Query/window/priority/chặng được
giữ khi đổi tab/resize/theme trong route, không claim lưu bộ lọc UI qua khởi động lại.

## Lưu và bảo vệ

`NotePlan` chỉ có noteId/stage/priority/dueDay, không title/content/owner/grant hoặc share
identity. Workspace migration đọc legacy thiếu plans, bỏ giá trị sai/duplicate và cap500.
Mọi note còn bật bảo vệ đều ẩn khỏi board; unlock trong reader không chép nội dung sang
workspace. Metadata cá nhân dùng lại khi note không còn bảo vệ và vẫn có quyền truy cập.
`_editWorkspace` đọc durable account root và serialize writes, giữ drafts/focus/vault;
RAM công bố sau write thành công và đúng generation/account. Move đọc plan mới nhất từ
durable record, giữ priority/dueDay đã được lưu trước đó. Form giữ lựa chọn sau storage
failure để retry; busy ngăn double save/back. Save/move recheck note availability trong queue.

Board/picker luôn derive content từ `workspaceNotes` hiện tại. Lock/revoke/account switch
loại widgets title/content/date và header counts tương ứng ngay, kể cả trong entrance motion.
IDs/plan metadata vẫn encrypted trong account để dùng khi note khả dụng trở lại. Dialog
form và cả lịch đang mở lắng nghe controller, bỏ nội dung khi note bị khóa/mất quyền; không
giữ date picker riêng tư để chạy exit animation. Không thêm endpoint hoặc quyền server mới.
Progress bỏ animation cũ khi tập source IDs thay đổi, nên lock/revoke không giữ tỷ lệ cũ;
picker bỏ cả từ khóa nhập của account cũ khi đổi account.

## Chuyển động và UI

- Chuyển nội dung workspace/card entrance: fade + lift 6–8px trong 220ms, chỉ entrance.
- Thẻ dùng hover nâng 2px hiện có và press scale0.985 trong180ms; vùng tap/layout giữ nguyên.
- Thanh progress của planner/checklist/daily goal chuyển giá trị trong220ms; semantics luôn
  diễn tả giá trị hiện tại, không đọc lại từng frame.
- Hỗ trợ `MediaQuery.disableAnimations`: durations0, press/hover không đổi geometry. Không
  có shimmer/blur/shader/animation nền vô hạn; animations hữu hạn, child tái dùng giữa frames.
- Navigation PC thu gọn padding/icon, vẫn padded touch target; mobile/chữ lớn giữ dropdown.
  Màu cột/thẻ tím/xanh/mint theo stage, title/preview/metadata tách cấp; cùng tokens light/dark.

Không dùng exit switcher giữ bản sao nội dung cũ. Giữ keys/editor identity/base revision và
home filter/scroll. Không suy ra FPS, TalkBack hay native IME từ widget test/Chrome compile.

## Kiểm chứng

250 Flutter/109 backend tests PASS trên gate; format105files0changes/analyzer sạch.
8 tests mới: deadline boundary/migration, durable failure/merge/draft/focus, queued lock/revoke/
account switch, form retry/move/remove, privacy trong animation/calendar, mobile200%/keyboard/
picker, lazy500rows/filter state, press/reduced-motion/settling. Test encryption file/reopen
hiện có được mở rộng với deadline/priority/plans và logout isolation.

Chrome release với FastAPI/SQLite riêng: ba plans, priority/date edit, filter/search, reload,
4viewports/light-dark và lock từ xa trong calendar PASS. Sau protection, stale form bỏ fields/
disable save, board bỏ note và counts; trước protection GET xác nhận planning giữ revision/
content notes. Cache cuối khớp SHA256 build/40static, console reload cuối0errors/warnings.
Web default API8000 và APK debug compile PASS;15 ảnh trực tiếp, native runtime/FPS chưa chạy.

[Ảnh, lệnh, target, kết quả và giới hạn nghiệm thu](../evidence/2026-10-10-planner-motion/INDEX.md).
Các nghiệm thu trước trong STATUS/matrix là snapshots lịch sử; release vẫn để cuối.
