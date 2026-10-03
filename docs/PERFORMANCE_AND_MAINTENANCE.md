# Bảo trì và hiệu năng — 03/10/2026

Base Git35ee911; repository bahungTDTU/final-flutter, nhánh master.
Đợt này sửa lỗi và tối ưu code hiện có, không nâng trạng thái LLM/SMTP/HTTPS/submission.

## Các lỗi sửa

- HTTP error plain text/HTML trước bị jsonDecode ném FormatException, làm mất mã401/403/423.
  Api giữ status và JSON detail nếu có; fallback không hiển thị HTML. Regression401 thực sự
  làm controller logout và xóa session; binary502 giữ status với thông báo an toàn.
- Future.timeout trước chỉ dừng chờ, request socket/upload vẫn có thể chạy. JSON/binary request
  nay dùng AbortableRequest, hoàn thành abortTrigger trong finally sau timeout/settle.
  Timeout không chứng minh server đã hủy mutation; immutable operation IDs/idempotency vẫn bắt buộc.
- Periodic sync15s nay bỏ qua khi app ở nền; resume không SSE sync ngay, SSE giữ ready/refetch.
  Initialize/synchronize có disposed guards, không revive timer hoặc ghi session sau dispose
  giữa session-read. Không thay durability trước gửi hoặc Back/lifecycle flush.

## Tối ưu đã đo và phạm vi

GET /notes trước gọi access/labels/share metadata nhiều lần cho mỗi note. Bản mới validate
session trong transaction, dùng recipient join để chứng minh ACL, rồi hai truy vấn theo lô
cho notes/labels. Có4 SELECT tổng cộng bao gồm auth/revalidation. Các correlated COUNT trong
SQLite vẫn làm công việc theo note;4 statements không có nghĩa toàn request là O(1).
Label order giữ theo vị trí JSON; nhãn khác owner/deleted không vào response. Protected note
chỉ có id/locked/revision/role, kể cả sau unlock. Recipient chỉ thấy owner/own shared_at,
không all-recipient list. Query-count test đối chiếu với independent detail serializer và ACL.

Sync client dùng Map note IDs/Set pending IDs cho merge/revoke checks; clean viewer/locked
notes không dựng lại list archive nhiều lần. Dirty draft/conflict/pending vẫn đi encrypted
recovery trước merge. Các recovery paths còn chi phí riêng, không claim toàn sync O(N).

Benchmark `scripts/benchmark_notes.py`: temporary SQLite + TestClient ASGI local,3 labels/note,
5% locked,7 measured requests sau1 warm-up; owner và viewer. Fixture inserts trực tiếp phục vụ
đo, không phải thao tác người dùng hay contribution. JSON lưu UTC/result/min/median/max thật.

| 1.000 notes | Before | After |
|---|---:|---:|
| Owner SELECT statements | 5.803 | 4 |
| Viewer SELECT statements | 7.753 | 4 |
| Owner median local ms | 64.248 | 52.397 |
| Viewer median local ms | 76.335 | 58.701 |

Đây là hai lần đo local trên máy hiện tại, có nhiễu tải host; request nhỏ10 notes không có
cải thiện latency ổn định. Không claim production latency/60fps/jank/native performance.
Benchmark đo cả ASGI/serialization; không phải isolated query timer hoặc internet HTTP.

## Dọn mã/file

- Bỏ PaperIllustration66 lines không còn caller (auth đã dùng PrismArtwork).
- Bỏ direct dependency cupertino_icons không dùng; Web static resource count41→40.
- Chuyển script contrast palette teal cũ ra evidence/2026-10-01-ui/contrast_audit_legacy.py;
  script archived bắt buộc --output, không ghi đè contrast.json cũ mặc định. Current contrast
  đọc theme thật qua test/prism_motion_test.dart. Historical commands/logs giữ scope ngày cũ.
- Xóa309 generated files cũ/trùng,5.229.325 bytes.47 output files hash-identical với evidence
  giữ lại;262 browser snapshots/console logs01–02/10 đã có dated QA results. Cleanup dùng
  LiteralPath và absolute workspace/directory boundary checks, kết quả từng file trong JSON.
- Giữ evidence lịch sử, prompts nguồn, fonts/OFL, fixtures độc nhất và backend local data.
  Không xóa .venv/build/local keys/database hoặc sửa generated plugin registrant.

## Kiểm tra

scripts/check.ps1:123 Flutter/56 backend PASS, analyze sạch;5 regressions HTTP/lifecycle mới,
3 backend list/query/ACL tests mới. Existing frozen base/drafts/recovery/preferences/SSE/roles
suites giữ PASS. Direct real HTTP owner/viewer/editor/stranger PASS.
Browser/native/build results, source hashes và commands cụ thể trong
evidence/2026-10-03-maintenance/INDEX.md. Build/pass host không thay physical/release-functional.

```powershell
& '.\.venv\Scripts\python.exe' scripts/benchmark_notes.py --output tmp/notes-benchmark.json
powershell -ExecutionPolicy Bypass -File scripts/check.ps1
```

Người dùng đã ủy quyền push bản mới; author/committer tiếp tục Bahung
<523K0006@student.tdtu.edu.vn>, không GPT/Codex/Co-authored-by hoặc backdate.
