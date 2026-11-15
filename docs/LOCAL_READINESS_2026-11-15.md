# Đồng bộ và kiểm tra local — 15/11/2026

## Source và phạm vi

Workspace ban đầu chỉ có `.git` rỗng, không có commit/remote hoặc thay đổi cần giữ.
Đã thêm origin `https://github.com/bahungTDTU/final-flutter.git`, fetch và checkout
`master` tại `9d00fcf`, rồi tạo branch `codex/local-readiness-update`.
Không sửa mã ứng dụng, dependency hoặc lịch sử tác giả. Không push/deploy/nộp bài.

Đã xử lý nợ tài liệu C0: README đưa quickstart/current state lên đầu, tách nhật ký
sang `README_HISTORY.md` tại root để giữ các liên kết tương đối cũ. `Readme.txt`
đồng nhất byte với README. Cập nhật STATUS, matrix và các gate còn lại theo lần kiểm tra này.

## Kết quả trên máy hiện tại

| Kiểm tra | Kết quả/phạm vi |
|---|---|
| Source | `9d00fcf`, mã ứng dụng không đổi |
| Flutter/Dart | SDK riêng 3.47.9 / 3.13.7; SDK trên PATH 3.47.0 / 3.13.0 không đủ |
| Dependencies | `flutter pub get --enforce-lockfile` PASS; không đổi pubspec.lock |
| Format | PASS 138 file, 0 thay đổi |
| Analyze | PASS, no issues, checkout ASCII riêng cùng commit |
| Flutter tests | PASS 333 tests, chạy qua junction ASCII tới workspace |
| Backend | PASS 163 tests trên Python 3.13.7; một StarletteDeprecationWarning |
| Python baseline CI | NOT RUN: cần Python 3.12; máy chỉ có 3.13.7 |
| Web release local | PASS build + offline shell 41 assets, API loopback; chưa chạy browser |
| Android / UI thực / SMTP / LLM / HTTPS | NOT RUN trong lượt này |

Raw logs và lệnh: [evidence](../evidence/2026-11-15-local-readiness/INDEX.md).
Backend tests gồm kiểm tra quyền trực tiếp qua TestClient, không gọi đó là nghiệm thu
HTTP server độc lập hoặc browser/native. Không suy unit/widget PASS thành release PASS.

## Lỗi môi trường và cách chạy lại

- Analyzer tại đường dẫn gốc có dấu/khoảng trắng lỗi LSP JSON `Unexpected end of input`.
- Flutter test tại SDK có khoảng trắng lỗi native hook: `C:\Users\Nguyen` không được nhận diện.
- Đã tạo junction `C:\Temp\notetogether-20261115\flutter` tới SDK riêng và
  `C:\Temp\notetogether-20261115\project` tới workspace. Test chạy thành công qua đó.
- Analyze qua project junction chưa kết thúc trong lượt thử, được dừng; analyze trên
  clone ASCII thật `C:\Temp\notetogether-20261115\checkout` cùng commit đã PASS.
  Clone này chỉ dùng QA, không chứa các chỉnh sửa tài liệu chưa commit.
- Lệnh tải/chạy bộ cài Python 3.12 bị hệ thống duyệt tự động chặn, không có lý do chi tiết.
  `.venv` hiện tại dùng 3.13.7 để kiểm tra tương thích. `scripts/setup.ps1` vẫn yêu cầu 3.12;
  không nới điều kiện chỉ để báo PASS. Khi có 3.12, tạo môi trường đúng baseline trong
  checkout riêng bằng `scripts/setup.ps1 -Python <đường dẫn python3.12.exe>`.

Chạy test tại máy này (đường dẫn junction chỉ có trên máy hiện tại):

```powershell
Set-Location 'C:\Temp\notetogether-20261115\project'
$env:FLUTTER_BIN = 'C:\Temp\notetogether-20261115\flutter\bin\flutter.bat'
& $env:FLUTTER_BIN test --no-pub
& .\.venv\Scripts\python.exe -m pytest backend/tests -q
```

## Phần còn thiếu để hoàn tất

Các tính năng chính đã có code; không tìm thấy TODO/FIXME/UnimplementedError trong
`lib`, `backend`, `scripts`. Điều này không chứng minh toàn bộ tính năng đúng.
Trong checkout chưa có `.env`, `android/key.properties`, release artifacts hoặc đầu vào
bộ nộp. Không khẳng định dịch vụ/tài liệu của nhóm không tồn tại ở nơi khác.

1. Cấu hình SMTP/inbox và LLM thật ở backend, nghiệm thu email và Summary/Q&A thực.
2. Chuẩn bị HTTPS Web/API và keystore, build và nghiệm thu cùng source trên hai bản cuối.
3. Chạy native IME, picker, background/TTL, offline/relaunch và hai UI thay đổi quyền;
   dùng phạm vi cụ thể trong NATIVE_OS_ACCEPTANCE, không làm lại chức năng đã có.
4. Bổ sung Rubric gốc, demo, Insights, grading accounts; đóng gói và kiểm tra giải nén.

Không có đủ đầu vào để đóng C3–C5 hoặc tự đánh dấu đạt 32 tiêu chí.
