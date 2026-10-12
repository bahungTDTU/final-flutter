# Deskbook — thay đổi bố cục12/10/2026

Người dùng yêu cầu bố cục có cá tính và khác các ứng dụng ghi chú tương tự, dùng
ui-ux-pro-max tại `.agents/skills/ui-ux-pro-max/SKILL.md`. Deskbook tổ chức không gian
theo một cuốn sổ đặt trên bàn: điều hướng ở trên, thư viện ở giữa, ngăn công cụ bên phải.
Thiết kế kế thừa palette Editorial Atelier; thay đổi chính là vị trí và phân cấp thao tác.

## IMPLEMENTED

PC đủ rộng/cao có masthead với ba đích đánh số, tạo ghi chú, tìm nhanh và avatar.
Tiêu đề thư viện có bookmark dọc; ngăn bàn244dp tách mẫu, workspace, nhãn và tùy chỉnh.
Khu vực ghi chú tiếp tục lazy grid/list, ghim7:5 giữ thứ tự server. Drawer cuộn độc lập.
Không dựng hai catalog hoặc bản sao note để trang trí.

Phone giữ điều hướng dưới, tạo note trên app bar, grid/list và bộ lọc nhãn trực tiếp.
Menu `Công cụ thư viện` chứa workspace/tìm nhanh. PC hẹp hoặc cửa sổ thấp dùng rail;
chữ lớn dùng bố cục tự tăng chiều cao, không cố ép desktop. Full desk cần1180×700,
text scale<1.5. Editor PC có tab `Trang viết`, ribbon, mục lục và thông tin đóng/mở riêng;
phone vẫn là trang viết một cột. Nội dung/tab không chứa dữ liệu bảo vệ trước grant.

## Bảo toàn hành vi

Không đổi backend, controller, data, dependencies, ACL, format dữ liệu hoặc outbox.
Giữ scroll/query/label selection; editor giữ controller, selection và revision lúc mở.
Ngăn thông tin dùng Material để ListTile có phản hồi ink/focus đúng. Masthead phân
chiều rộng linh hoạt để các nhãn điều hướng xuống dòng khi cần, tránh tràn ở1180dp.
Giữ theme cache, giảm chuyển động và purge private content khi lock/revoke.

[Spec đã lựa chọn](../design-system/notetogether-deskbook/MASTER.md),
[kết quả và ảnh](../evidence/2026-10-12-deskbook-layout/INDEX.md).
Các evidence trước ngày/lượt này là snapshots của source tương ứng, không bị ghi đè.
