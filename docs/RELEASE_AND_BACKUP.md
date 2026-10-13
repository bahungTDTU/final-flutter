# Release và phục hồi state — triển khai local 12/10/2026

Các thay đổi này chuẩn bị R01/R02. Chưa có public HTTPS, keystore release của nhóm,
SMTP Internet/Gemini hoặc nghiệm thu video; không coi local PASS là release hoàn tất.

## Build local và production

Local Web QA vẫn chạy `scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8042`.
Production phải chỉ rõ `-Production -ApiUrl https://<API-host-thật>`; không có default.
`scripts/release_preflight.py` từ chối HTTP, credentials/query/path/fragment, port khác443,
loopback/private/reserved IP, tên local/placeholder/fixture. Chỉ kiểm tra cấu hình;
DNS/TLS/health/CORS/provider/SSE và public reachability cần nghiệm thu riêng.

```powershell
$env:FLUTTER_BIN = '<SDK3.47.1>/bin/flutter.bat'
& scripts/build.ps1 -Target web -Production -ApiUrl https://<API-host-thật>
& scripts/build.ps1 -Target apk -Production -ApiUrl https://<API-host-thật>
```

Mọi APK release, kể cả gọi Flutter/Gradle trực tiếp, dùng signing config release riêng.
Không còn fallback debug. Thiếu file/keystore/alias/password thì task release thất bại;
APK debug/CI không cần secret. Nhóm quản lý keystore bền, tự chọn mật khẩu và bảo quản
ngoài repo. Tạo `android/key.properties` ignored theo Flutter; `storeFile` tuyệt đối dùng
slash `/` hoặc escape theo Java Properties, relative được resolve từ thư mục android:

```properties
storeFile=C:/private/notetogether-release.jks
storePassword=<nhập riêng trên máy>
keyAlias=<alias của nhóm>
keyPassword=<nhập riêng trên máy>
```

Không gửi nội dung file vào chat/log/Git, không đưa signing/provider secrets vào dart-define.
Sau build thật, dùng apksigner verify/print-certs đối chiếu SHA256 certificate với keystore
của nhóm và install/run APK. Guard thiếu key đã kiểm tra, certificate release thật chưa có.
Nguồn: [Flutter Android signing](https://docs.flutter.dev/deployment/android).

## Backend Compose

`docker compose up -d --build backend` dùng port loopback8000 mặc định, volume
`<compose-project>_backend-state` giữ SQLite, attachment/avatar BLOB và mail key cùng nhau.
Chọn `BACKEND_PORT` riêng để không đè dịch vụ đang chạy. `.env` chỉ được Compose dùng
để nội suy các biến đã liệt kê trong compose.yaml; uvicorn trực tiếp không tự load .env.
SMTP/Gemini trống mặc định. File-based provider secret và SMTP_CA_FILE chưa mount tự động;
nếu cần, cấu hình mount chỉ đọc và env tương ứng riêng trước khi bật provider.
Không chạy `docker compose config` có secrets ra log; chỉ dùng `config --quiet`.

Restart bằng `docker compose restart backend`, recreate bằng
`docker compose up -d --force-recreate backend`. Không dùng down -v hoặc xóa volume.
Healthcheck chỉ kiểm tra API sống, không chứng minh inbox/provider/public deployment.
Dockerfile chỉ copy Python runtime/schema/requirements; context loại state/DB/keys/tests/cache.
Không expose API Internet từ Compose này; cần reverse proxy HTTPS/CORS/SSE riêng sau core.

## Backup và restore bản sao

Attachments/avatars nằm trong SQLite, không có uploads tree riêng cần copy. Mail jobs
cần private32-byte PRF key ngoài DB; custom MAIL_OUTBOX_KEY_FILE phải truyền đúng khi backup.
`sqlite3.Connection.backup` lấy snapshot nhất quán cả committed WAL, không copy thô DB
đang chạy. Key hiện immutable; nếu vận hành có rotation, dừng worker trong lúc phối hợp
backup/key. Backup chứa toàn bộ dữ liệu riêng, sessions và key: giữ ở storage riêng có
ACL/encryption của OS, không đưa vào ZIP/evidence/Git; mode0600 không thay Windows ACL.

```powershell
& .venv/Scripts/python.exe -m backend.backup backup `
  --database backend/state/app.sqlite3 --destination <thư-mục-backup-mới>
# Nếu dùng custom key, thêm --mail-key <file-private-key>.
& .venv/Scripts/python.exe -m backend.backup restore `
  --backup <thư-mục-backup> --destination <thư-mục-restore-mới>
```

CLI không overwrite đường dẫn có sẵn; lỗi có thể để lại thư mục incomplete không có
manifest hợp lệ. Giữ để điều tra, chọn đường dẫn mới cho retry. Restore kiểm tra manifest,
SHA256, SQLite integrity/foreign keys và key trước khi tạo destination. Hash kiểm tra lỗi
truyền/lưu trữ, không xác thực nguồn backup; chỉ restore backup tin cậy do nhóm quản lý.
Restore output `app.sqlite3` + `app.sqlite3.mail-key` nếu có. Trỏ NOTETOGETHER_DB và
MAIL_OUTBOX_KEY_FILE sang output khi chạy backend thử, giữ backend/volume gốc nguyên vẹn.
Đặt SMTP_HOST/GEMINI_API_KEY trống trong drill để không gửi mail hoặc gọi provider thật.

Với container, export backup private vào volume trước rồi `docker compose cp` ra storage
private; module có sẵn trong image. Restore drill dùng volume/project riêng, không mount
volume production vào target ghi. Cần nghiệm thu recreate/restore qua HTTP thật trước R02 PASS.
ASGI tests chỉ xác minh module/DB/ACL/mail-key, không thay container/Internet.
Nguồn: [SQLite Backup API](https://sqlite.org/backup.html).
