# Bước tiếp theo: M6.1 — release và backend tái lập

Người dùng yêu cầu06/10 để release sau cùng. Kế hoạch này được hoãn; ưu tiên các thiếu hụt
chức năng và kiểm chứng core trong STATUS trước. Không coi đây là hành động đã triển khai.

Chuẩn bị06/10/2026 từ [PROJECT_REVIEW](PROJECT_REVIEW_2026-10-06.md).
Đây là kế hoạch thực hiện đã đối chiếu code, chưa phải các thay đổi đã triển khai.

## Mục tiêu

Có cấu hình build rõ local/production, backend chạy tái lập với dữ liệu bền và đường nghiệm
thu Web/native release. Liên quan tiêu chí30/32 và điều kiện tái lập/nộp tr.6/9/17–18.
Không cần chọn cloud hoặc nhập secret để làm các phần guard/config/tests độc lập.

## Trình tự thực hiện

1. **Guard build và signing.** Cập nhật scripts/build.ps1 thêm production mode bắt buộc
   explicit HTTPS API URL, chặn localhost/loopback và các endpoint fixture QA trong mode này.
   Local QA vẫn có lệnh tường minh. Cấu hình signing Android đọc key.properties hoặc secret
   service; production thiếu keystore/alias/password phải fail trước build, không debug fallback.
   Không đặt signing secret/Gemini key trong dart-define, stdout hoặc Git. Keystore do người
   dùng quản lý khi sẵn sàng; chỉ scaffold cấu hình trong phần độc lập.
2. **Backend local tái lập.** Harden `.dockerignore`; Dockerfile COPY/runtime inputs rõ ràng,
   giữ Python requirements pin. Chuẩn bị Compose một backend và persistent SQLite volume,
   loopback binding mặc định, healthcheck/restart/stop runbook. Không thêm database/service
   ngoài nhu cầu. Không dùng `down -v` trong hướng dẫn restart thông thường.
3. **Volume và backup/restore.** Docker engine hiện chưa truy cập được, nên chưa gọi container
   PASS. Khi engine hoạt động, build image từ bản source sạch, kiểm tra không có state/secrets/
   caches; real HTTP role probe và note/file data survive container recreate. Backup SQLite
   theo cơ chế nhất quán, restore vào volume test riêng rồi xác nhận user/note/attachment/ACL.
   Không ghi đè DB development/production của người dùng và không thao tác destructive với
   volume gốc. Đây là backup server DB; không giải quyết backup device vault keys.
4. **Preflight và hướng dẫn.** Chuẩn bị script chỉ báo trạng thái, không in secret: API URL,
   signing metadata/file existence, Docker engine/config, volume, service/provider configured,
   artifact/source hashes. .env.example không phải auto-loaded; Compose/service cần env_file/
   secret mapping được mô tả chính xác. README và Readme cùng nội dung.
5. **Source và clone sạch.** Kiểm thử tại workspace trước; kiểm tra Git ignore của secret/state,
   bảo toàn working changes. Chỉ commit/push khi có ủy quyền và dùng danh tính đã xác nhận.
   Clone commit vừa publish vào thư mục QA riêng, không xóa checkout hiện tại; giữ .git, chạy
   setup/check/build đúng README. Không dùng remoteaded41e để chứng minh code AI/protection mới.
6. **Nối dịch vụ và nghiệm thu release.** Khi có URLs/secret do nhóm cấu hình: backend/Web HTTPS,
   signing thật, Gemini thật, SMTP inbox thật. Core login/create/edit/files/offline/share-or-SSE/
   ít nhất1AI trên cả Web/native release. Gate exact source/artifact/API environment và riêng
   thiết bị thật/OS relaunch. Cuối cùng mới quay video/cập nhật Rubric/đóng ZIP.

## Kiểm thử cần thêm khi triển khai

| Rủi ro | Kiểm chứng có giá trị |
|---|---|
| Build nộp vô tình dùng API local/fixture | Production preflight từ chối HTTP/loopback/placeholder/fixture; chấp nhận HTTPS URL cấu hình hợp lệ; local mode vẫn chạy được |
| Artifact ký debug dù tưởng production | Thiếu signing config fail; inspection certificate của APK thực khớp release alias, không in private key/password |
| Context/image chứa credentials | Sentinel secrets giả trong paths cần loại; inspect context/image layers đã build, không đưa secret thật vào test hoặc logs |
| Recreate mất SQLite/attachments | Real API create/share/file→recreate không xóa volume→IDs/content/hash/roles giữ nguyên |
| Backup không khôi phục được | Restore bản copy vào volume mới, exact data/hash/ACL probe; không chỉ file backup tồn tại |
| Tài liệu chỉ chạy trên máy hiện tại | Clean-clone setup/check/build với Python/Flutter được truyền/cấu hình, không phụ thuộc path Codex của người khác |

Chạy format/analyze/tests phù hợp thay đổi, sau đó build/inspect artifacts. Giữ các regression
frozen editor base, protected grant/cache/recovery, immutable outbox, account switch và preferences.
Ghi date/command/target/result/commit/hashes; chưa chạy ghi NOT RUN. Không thêm mirror tests,
không sửa GeneratedPluginRegistrant.java bằng tay. Sau native integration chạy flutter pub get
trước release build theo README.

## Điều kiện hoàn tất M6.1

- Build production không thể vô tình fallback localhost/debug signing.
- Backend image/config/volume/backup/restore có bằng chứng local đúng scope.
- README/Readme exact commands/config khớp; source/artifact provenance rõ.
- Clean-clone đã nghiệm thu hoặc nêu đúng blocker publishing/runtime.
- Public HTTPS/native release/provider receipts vẫn là gate riêng cho M6 hoàn chỉnh;
  không gọi Docker/local build PASS là deployed/public/full rubric PASS.

Nguồn: [Android signing](https://developer.android.com/studio/publish/app-signing),
[Docker build context](https://docs.docker.com/build/concepts/context/), PDF gốc tr.6/9/17–18.
