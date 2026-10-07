# Performance bản nháp và đính kèm — 07/10/2026

Đợt này xử lý F3/F4 trong audit: nhập bản nháp thường không còn mã hóa/ghi lại toàn bộ
ghi chú của tài khoản; danh sách đính kèm và upload replay chỉ đọc metadata từ SQLite.
Base Git `5b82996c3fd42e046a9e087471dc0f2effc156ae` + working changes; chưa commit/push.
Audit cũ và các kết quả theo ngày được giữ nguyên như snapshots lịch sử.

## Lưu bản nháp nhỏ, vẫn đợi transaction

`account:<UUID>` giữ envelope AES-GCM v1 hiện có. Khi tài khoản đã có snapshot bền,
`AppController.draft()` capture account và toàn bộ map bản nháp thường hiện tại rồi ghi
record nhỏ `drafts:account:<UUID>`. Record dùng cùng device key ID, nonce mới và AAD riêng
gắn namespace bản nháp. Không copy notes/avatar/outbox khi gõ. Mỗi lần vẫn đợi transaction
Sembast; debounce 650ms để chuyển thành note/outbox hợp lệ giữ nguyên.

`EncryptedAccountStore.read()` xác thực cả hai envelope và trả snapshot đã thay field
drafts bằng bản mới nhất. Save/sync/recovery/metadata và password vault vẫn dùng snapshot
đầy đủ; publish root và xóa projection trong **cùng transaction**. Transaction thất bại
giữ cả root lẫn projection cũ. Controller giữ hàng đợi, immutable operations và frozen
editor base; không gửi khi local persist lỗi. Protected content tiếp tục nằm trong vault
dẫn xuất từ mật khẩu, không chuyển sang bản nháp thường.

`AtomicLocalStore.writeBatch()` là capability mới của Sembast. Store không hỗ trợ atomic
batch giữ đường ghi snapshot cũ; lần đầu chưa có account snapshot cũng tạo root trước.
Migration legacy/compaction v1 giữ nguyên; không tăng version envelope hay backend schema.
Rotate gộp bản nháp mới nhất trước đổi generation; remove account xóa hai record nguyên tử.
Thiếu root/key, sai AAD/key ID hoặc projection hỏng: báo lỗi và giữ ciphertext, không tự
tạo khóa thay thế rồi xóa dữ liệu còn sót. Logout không xóa kho account.

Giới hạn: projection chứa **mọi bản nháp thường của account**, chưa phải per-note shards.
Nhiều bản nháp lớn vẫn làm ghi tốn hơn; full saves/sync còn mã hóa snapshot đầy đủ, chưa có
delta sync. Nhiều tab cùng account, OS kill trước commit, quota/eviction/key backup chưa
được nghiệm thu thêm trong đợt này. Độ bền được xác nhận ở boundary transaction đã hoàn tất.

## Đính kèm chỉ đọc byte tại download

List SELECT sáu field `id/name/kind/media_type/size/created_at`. Upload replay thêm
note_id/created_by/fingerprint và `data IS NOT NULL AS present`, không đưa BLOB vào Python.
Response sau upload mới cũng SELECT metadata. Download vẫn đọc byte và giữ range/private
no-store. ACL owner/editor/viewer/stranger, grant của note bảo vệ, quota và idempotency
không đổi. Upload vẫn phải nhận/validate/hash payload; download vẫn có chi phí binary.

## Đo trước/sau trên cùng workload

| Workload | Trước | Sau |
|---|---:|---:|
| 500 notes × 1.000 chars; 20 draft updates: encoded envelope JSON bytes | 16.886.608 | 4.848 |
| Cùng workload: full account writes | 20 | 0 |
| Cùng workload: median thời gian 20 durable updates, 5 lần, host | 2.530,732 ms | 129,047 ms |
| List 10 attachments × 5 MiB: peak Python allocations | 10.536.155 B | 52.505 B |
| Cùng list: median 7 warm requests, ASGI local | 203,092 ms | 5,055 ms |

Write probe dùng AES-GCM + file Sembast thật, memory key provider, seed ngoài vùng đo,
20 transaction vẫn hoàn tất và close/reopen xác minh bản nháp cuối + đủ 500 notes.
Bytes là tổng JSON envelope được publish, **không phải bytes filesystem/disk IO đã đo**.
Attachment probe dùng SQLite tạm, TestClient, một warm-up loại khỏi 7 lần đo và tracemalloc;
peak là allocation của Python, không phải RSS/SQLite internal memory hay lượng đọc đĩa.
Timings chịu nhiễu tải host; không suy ra FPS, độ trễ gõ Web/Android hoặc production latency.

## Kiểm tra

- `scripts/check.ps1`: 180 Flutter / 94 backend PASS, format/analyze sạch.
- 7 regressions mới dùng file Sembast/AES thật: durable draft/reopen, rollback khi fold,
  lỗi ghi draft, rotate/remove/AAD, thiếu root/key, account switch, lost ACK và remote lock.
  Một backend regression quan sát cursor thực: list/replay zero BLOB materialization;
  download trả byte chính xác. Existing recovery/preferences/protected/sync suites giữ PASS.
- Actual loopback HTTP: owner/editor/viewer/stranger, replay, download hash/private headers,
  lock/grant/revoke và anonymous đều đúng. Không gọi LLM/mail Internet.
- Android API36 debug: 1 workflow + teardown PASS, platform keys, encrypted file reopen,
  actual failed socket, restored editor, reconnect revision 1→2/cùng ID/không duplicate.
  Render software/Skia emulator; chưa đo physical/FPS/default renderer.
- IAB Web debug: cache reload khi API đã dừng, khôi phục blank-title draft/nội dung;
  reconnect và hoàn thiện tiêu đề, autosave có ACK. Actual API xác nhận revision 3→4,
  đúng body/cùng ID, chỉ một remote note. Static debug server vẫn online; không Wi-Fi toggle.

Web và log chi tiết, thời điểm/commands/ảnh/hashes ở
[evidence/2026-10-07-performance/INDEX.md](../evidence/2026-10-07-performance/INDEX.md).
Release/HTTPS/signing tiếp tục để cuối theo người dùng; kết quả này không nâng toàn bộ rubric
hay provider acceptance thành hoàn tất.
