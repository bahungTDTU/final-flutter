# Publication workspace/planner — 10/10/2026

Người dùng yêu cầu push. Nhánh mới `codex/workspace-planner` xuất phát từ master
`13e0ffc70b4dba97e907df7039ef7672896d4e3d`, sau merge PR#3. Tree của base này bằng
`a5e5ec6`, không đổi code app; các working changes từ ordering/workspace/focus/planner được
giữ nguyên. Không push master, force-push, bypass ruleset hoặc tự merge.

Phạm vi: sửa thứ tự unpinned locked notes bằng canonical server order, giữ six-field locked
projection; workspace encrypted gồm tìm nhanh/favorites/recent/smart views/checklist/templates/
journal/import-export; Pomodoro/goal; Kanban ưu tiên/ngày hạn; responsive/light-dark/finite
motion/privacy guards; sửa static cache upgrade và tài liệu/evidence tương ứng.

Gate local source cuối:250 Flutter/109 backend PASS; format105 files0changes và analyzer sạch.
[Gate và kiểm tra trình duyệt](../2026-10-10-planner-motion/INDEX.md) ghi lệnh thực,15ảnh,
Chrome4viewports, direct HTTP owner/viewer/editor/stranger, calendar remote-lock, encrypted
reopen/account/races và Web/APK debug compile. Backend có1 pinned deprecation warning.

Không chạy lại test chỉ để đổi Git branch/docs: preflight đối chiếu SHA256 của24 code/test/
backend/scripts/web inputs thay đổi với source đã chạy gate cuối; tất cả khớp. Base master chỉ
có merge commit, tree bằng base đã test. [Preflight](preflight.json) ghi timestamp/target/base/
file counts/bytes/secret-pattern scan. Bản scan cuối bao gồm source/docs/evidence định commit,
không môi trường riêng, SQLite, build, keystore, Playwright auth state hoặc Git credentials.
Fixture test passwords là dữ liệu QA công khai. Không thay ngày/hash/logs nghiệm thu cũ.

`.gitattributes` giữ nguyên bytes các snapshots mới để SHA256 logs/ảnh không đổi khi Git
normalize line endings. Captured CLI padding/blank EOF của raw browser scripts được giữ
nguyên theo cách repository đã dùng; code/docs vẫn kiểm whitespace. Evidence publication
PR#3 trong `2026-10-10-github-publication` giữ nguyên, đợt này ghi riêng trong thư mục hiện tại.

Author/committer dùng Git identity đã được người dùng xác nhận:
`Bahung <523K0006@student.tdtu.edu.vn>`. Không GPT/Codex/co-author trailer, không backdate hoặc
gán đóng góp cho Long. Code được agent hỗ trợ; đây không phải teamwork độc lập đủ4tuần.

Commit này ghi gate trước push; SHA/PR thực kiểm bằng remote và
[nhánh GitHub](https://github.com/bahungTDTU/final-flutter/tree/codex/workspace-planner).
PR vào master phải kích hoạt3 required checks trên head mới nhất: Flutter quality,
Backend tests, Build smoke. Tại thời điểm ghi snapshot này hosted CI chưa chạy; local PASS
không thay status GitHub. Merge cần tất cả checks PASS, base cập nhật, resolved threads và
approval hợp lệ từ người khác sau push cuối. Yêu cầu hiện tại chỉ publication branch/PR.

Release/HTTPS/signing/providers Internet/native UI/IME/FPS mới/screen reader/video vẫn giữ
giới hạn trong matrix, không được suy ra từ build compile hoặc việc upload source.
