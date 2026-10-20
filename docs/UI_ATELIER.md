# NoteTogether — Editorial Atelier, 12/10/2026

Người dùng yêu cầu một bố cục mới độc đáo, hiện đại và sang trọng qua skill
`D:/flutter_cuoi_ki/.agents/skills/ui-ux-pro-max/SKILL.md`. Đây là implementation UI,
không phải mockup hoặc một landing page thay cho ứng dụng. Source trên
`codex/ui-system-refresh`, base `f3b17a3`; working changes chưa commit/push.

## Quyết định thiết kế

Tra design-system `luxury editorial notes workspace` và tra riêng `Editorial Magazine`.
Generator gợi ý showcase/Brutalism không phù hợp luồng ghi chú, nên dùng nguyên tắc
editorial: khoảng trắng, đường kẻ, nhịp lớn–nhỏ và grid bất đối xứng. Giữ NotoSans
bundled, không tải Cormorant/Montserrat hoặc thêm dependency/ảnh trang trí.
[MASTER](../design-system/notetogether-atelier/MASTER.md) là spec đã chọn.

Nền giấy #F4F1EA, mặt đọc #FCFAF5, obsidian #272B25, sage và điểm nhấn đồng. Dark mode
dùng nền #171A17/mặt #242822, ivory và brass. Đổi tokens chung cho các route/dialog/sheet,
không chỉ dashboard. Tách tiêu đề, mô tả, thao tác và metadata; focus rõ, action chính48dp.

## Bố cục thực

- Dashboard PC: thư viện đánh số01–03, title lớn/CTA bên dưới, ô số lượng tương phản,
  hai ghi chú ghim7:5; các ghi chú tiếp tục lazy. Cover khóa trung tính và chỉ public pin/shared.
- Dashboard phone: title/summary gọn, tạo note trên AppBar, navigation dưới. Chữ lớn
  trở về thẻ có chiều cao tự nhiên và giữ lựa chọn grid của tài khoản.
- Editor PC: paper vuông nhẹ, folio, title36px, outline và inspector. Phone: một cột,
  bottom toolbar và menu công cụ. Giữ document key, selection, ID/base revision.
- Auth PC: publication panel lớn bên trái/form giấy bên phải; phone chỉ form.
  AI, workspace/planner/focus, reader và quản lý tài khoản dùng semantic theme chung.

## Hiệu năng và trạng thái

ThemeData sáng/tối bất biến được cache theo Brightness, tránh tạo lại seed/typography
mỗi controller pulse và mỗi cover. Chỉ hai cover eager; catalogue/filter tiếp tục lazy.
Loại painter facet/glow trang trí, không thêm blur, animation loop hoặc network font.
Giữ chuyển động press/route hiện có và disableAnimations. Không giữ private widgets khi
lock/revoke; không đổi backend/state/schema/ACL hoặc preferences/outbox protocol.

## Nghiệm thu

Source và evidence cuối: [INDEX](../evidence/2026-10-12-atelier-ui/INDEX.md).
Các snapshot UI system refresh trước Atelier vẫn giữ nguyên evidence và hash.
Không suy native UI/FPS, provider/cloud/SMTP thật, hosted CI/approval hoặc release
từ local tests/build. Release vẫn thực hiện cuối cùng theo yêu cầu trước đó.
