# Sửa tiêu chí17 và đồng bộ tài liệu —10/10/2026

Source base `a5e5ec60568b7ee2b0c50290a3e6502a4d490110` + working changes trên
`codex/adaptive-word-editor`. Không commit/push/merge trong lượt sửa này.
Audit và probe FAIL trước sửa giữ ở ../2026-10-10-rubric-audit; log PASS mới lưu riêng.

## Kết quả mới

| Kiểm tra | Command/target | Kết quả |
|---|---|---|
| Full local gates | scripts/check.ps1 | PASS format96files0changes/analyze sạch/215 Flutter/109 backend; check-final.txt |
| Probe từng FAIL | flutter test --no-pub tmp/audit-2026-10-10/locked_order_probe_test.dart | PASS1case; locked-order-probe-pass.txt; không cộng vào215 full-suite |
| Flutter regressions | test/note_ordering_test.dart + locked_status/domain/durability/protected suites | Mixed date/pin/shared/filter, grid/list geometry, actual AES-GCM Sembast file reopen/account switch, immutable late pending edit/ACK PASS |
| Backend regressions | backend/tests/test_note_listing.py | Reverse insertion/date ties/ID, bounded queries, four roles, protected update và exact6fields PASS trong full-suite |
| Actual HTTP | FastAPI/Uvicorn fixture127.0.0.1:8031 + httpx | PASS owner/viewer/editor/stranger; grant-gated update/revoke; http-qa.json/api-update.json |
| Actual Chrome | HeadlessChrome154/Playwright CLI; Web release7362/API8031 | PASS grid/list, pin group, locked→ordinary→locked, offline reload/session/cache, reconnect update→locked→locked→ordinary; responsive390px scroll |
| Web builds | scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8031, rồi8000 | PASS compile/40static resources; default build8000 đã khôi phục; web-build-qa.txt/web-build-default.txt |
| Documentation consistency | Matrix32 IDs/10.0points + README/Readme byte parity + historical audit hash | PASS; docs-verification.json/manifest.json |
| Native runtime/FPS/IME/live Gemini/Internet SMTP/public release | Không chạy trong đợt này | NOT RUN; các mốc native/provider trước giữ scope riêng |

Browser mở ở1440×1000,1440×1320,1440×1440 và390×844. Desktop grid tọa độ first locked
(273,740) trước ordinary(562.75,740); list locked y752 trước ordinary y949. Nội dung/title/
date của locked rows không trong semantics. Locked cards không phân biệt hai secret IDs ở UI;
HTTP fixture và unit/geometry test xác nhận từng ID, browser xác nhận vị trí/public shape.
Không gọi snapshot semantics là screen-reader hoặc native acceptance.

Console trước offline:0errors/0warnings. Console sau fault injection có lỗi
ERR_INTERNET_DISCONNECTED do cố ý setOffline(true); raw console có14entries, CLI console
reported13errors. Không có loại console error khác trong log; không ghi là zero total errors.
Screenshot7PNG và snapshots ở thư mục này; browser-qa.json mô tả flow/phạm vi.

## Thay đổi

- Backend sắp `updated_at DESC,id ASC` trước projection; client giữ canonical array cho
  unpinned rows có hidden dates, ghim nhóm riêng theo public pinned_at.
- Cache encrypted lưu thứ tự; ordinary pending edits được ưu tiên, late refresh/ACK không
  đổi operation ID/payload/base revision. Protected draft/vault/grant protocol giữ nguyên.
- Không thêm metadata vào locked list/cache; vẫn `id/locked/revision/role/pinned_at/shared`.
  Legacy mixed cache cần một successful refresh; offline giữ thứ tự cache gần nhất.
- ARCHITECTURE, matrix, README/Readme, STATUS, UI guides, NOTE_PROTECTION và TEAM_CONTRIBUTIONS
  ghi hiện trạng: protected edit/offline unlock/realtime, email outbox và AI đã có mã. Provider
  thật/release/native rich-editor acceptance/teamwork/video vẫn là gate thiếu, không claim PASS.

[Quy tắc thứ tự](../../docs/NOTE_LIST_ORDERING.md) ·
[Kiến trúc hiện tại](../../docs/ARCHITECTURE.md) ·
[Matrix32 tiêu chí](../../docs/REQUIREMENTS_MATRIX.md).

## Fixture, dữ liệu và cleanup

DB/account/password/dates chỉ dành QA local ngoài repo user data, không phải dữ liệu người dùng.
Dates seed2024–2025 rõ ràng là fixture; timestamps evidence lấy clock thực. SMTP disabled,
Gemini env trống; không đọc credentials của người dùng hoặc lưu key/bearer vào evidence.
HTTP QA bearer chỉ giữ trong process memory.
Backend/web fixture được dừng sau xác minh PID/command line; đúng phiên Chrome QA đã đóng.
API default8000 trong build/web được khôi phục, không dừng service của người dùng.

Script QA gốc/logs nằm trong workspace visualization `ordering-docs-2026-10-10`; source hashes
và copies log/snapshot/ảnh trong manifest cho phép đối chiếu bản sửa. Các test regression
được lưu trong test/ và backend/tests/, chạy lại bằng scripts/check.ps1. Hai lần build có
font-family CupertinoIcons warning từ dependency, compile vẫn PASS; không gọi là native QA.
