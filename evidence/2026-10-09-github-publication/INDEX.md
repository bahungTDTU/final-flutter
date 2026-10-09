# Local gate trước publication UI/performance —09/10/2026

Thời điểm ghi: `2026-10-09T11:43:24.444427+00:00`. Target Windows local, branch `codex/ui-ux-performance`,
base mới nhất `285af64da90f6dc65bced38c4912ccbea072c95a` (merge PR ruleset).
Fast-forward từ `ef2ece0`; tree của base không đổi code app, các thay đổi UI được giữ nguyên.
Commit chứa evidence này ghi lại gate trước push; head/PR thực tra
[nhánh GitHub](https://github.com/bahungTDTU/final-flutter/tree/codex/ui-ux-performance).

Lệnh thật: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1`.
Exit0: format90files0changes, analyze sạch,198 Flutter tests và94 backend tests PASS.
Backend có1 upstream Starlette/httpx deprecation warning; không có test fail.
Đã đối chiếu95 source hashes với snapshot benchmark; không sửa số đo, ngày hay manifest
trong các đợt Home/dashboard/native/profile trước. JSON local-checks ghi riêng kết quả mới.

Rà soát81 file trước publication (~8.3MB), không phát hiện các mẫu Google/GitHub token,
JWT literal, private key, AWS key hoặc VM-service auth URL. Không đưa database/private env,
build artifact hoặc credential helper vào Git. Fixture example.test dùng credential QA công khai.

CI hosted chưa chạy ở thời điểm gate local; cần PR kích hoạt Flutter quality/Backend tests/
Build smoke và kiểm tra kết quả ở head mới nhất. Người dùng chỉ yêu cầu push branch/PR,
không merge. Approval hợp lệ từ người khác sau push cuối vẫn cần theo ruleset.
Author/committer commit publication: Bahung theo cấu hình được người dùng xác nhận.
Release/deploy/signing/submission tiếp tục để cuối.

Whitespace check đạt trên các file staged trừ hai raw `android-gpu-meminfo.txt` và
`android-meminfo-during-profile.txt`: chúng giữ nguyên padding cột/trailing spaces của dumpsys.
Không sửa raw capture để đổi kết quả kiểm tra; không có whitespace error trong code/docs/JSON.
