# Publication Security Center —12/10/2026

Target: nhánh `codex/security-center`, PR tới `master` của bahungTDTU/final-flutter.
Người dùng ủy quyền push trong lượt này. Author/committer thay đổi bảo mật: Bahung
<523K0006@student.tdtu.edu.vn>, không co-author trailer; không tự merge PR/approve/deploy.

Snapshot gate lúc 01:05:14+07:00, Windows local/Asia-Saigon. Commit chức năng
`0fccdc8e79c30454604d5ec473040a3e06a860eb`; tích hợp master
`3eb76e5d22b4804c4607968307b378ea272708f1` sau merge PR#5. Xung đột chỉ ở sáu
tài liệu/attributes, giữ cả Security Center và baseline/setup của Long. Mã Flutter/backend
không đổi trong tích hợp; lịch sử/tác giả commit baseline được giữ nguyên.

## Local gate PASS

Lệnh thực sau tích hợp:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1
```

- Format: 108 files, 0 changes; analyzer sạch.
- Flutter: 258 PASS. Backend: 118 PASS, 1 warning Starlette/httpx đã có.
- `git diff --check` và staged diff check PASS trước commit chức năng và sau xử lý xung đột.
- 8 code hashes và 56 evidence hashes khớp QA11–12/10; README/Readme.txt bằng nhau.
- Preflight ban đầu: 77 file/3,863,136 bytes, không match các mẫu secret đã quét;
  xác minh thêm 12 document hashes và 4 build artifact hashes trước tích hợp.
- 172 file skill cài local trong `.agents/` không nằm trong phạm vi stage/publication.
  Private config/DB, credentials, build binaries và `tmp/` không được stage.

Logs và metadata: [check.txt](check.txt), [local-gate.json](local-gate.json),
[preflight-before-integration.json](preflight-before-integration.json).
Metadata ghi thời điểm gate trước merge commit/push; commit cuối/remote SHA và CI tra
[nhánh thực trên GitHub](https://github.com/bahungTDTU/final-flutter/tree/codex/security-center)
và PR có head `codex/security-center`. Không suy CI hosted PASS từ local gate.

## Phạm vi nghiệm thu

Giữ raw QA [11–12/10](../2026-10-11-security-center/INDEX.md) và manifest nguyên byte;
document hashes trong manifest đó thuộc tài liệu trước publication, không thay bằng tài liệu
đã tích hợp. Những lần thử/lỗi ban đầu giữ nguyên và tách khỏi kết quả final PASS.

Web release/API8000 và Android debug compile đã PASS trên source bảo mật không đổi;
actual Chrome/HTTP4roles và benchmark nằm trong snapshot cũ. Không chạy lại browser,
benchmark hoặc builds trong lượt publication. Native runtime/IME/FPS phần mới NOT RUN.
Benchmark chỉ chứng minh auth read không giữ writer reservation, không claim tăng FPS.
Provider/cloud/public HTTPS, release signing và submission vẫn là gates riêng.

Hosted CI và human approval chưa có tại thời điểm chụp gate local. PR chỉ được merge
khi cả ba required checks PASS trên head mới nhất, branch cập nhật với master, hết review
threads và có approval hợp lệ sau push cuối; yêu cầu push không phải yêu cầu merge.
