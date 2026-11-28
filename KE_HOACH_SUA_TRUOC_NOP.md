# Kế hoạch sửa trước khi nộp — giao cho Codex

Ngày lập: 28/11/2026. Nền: `master` tại `68bf97b`.
Phạm vi: 4 hạng mục bên dưới. **Không** làm video, Rubric.xlsx, Screenshot.png trong lượt này.

Đọc toàn bộ file này trước khi sửa. Làm tuần tự theo thứ tự P1 → P2 → P3 → P4 → P5 (dọn cuối).
Mỗi hạng mục là một nhánh và một PR riêng; không gộp.

---

## 0. Quy tắc chung (bắt buộc)

1. **Git identity:** mọi commit dùng đúng tác giả
   `Nguyễn Bảo Long <523k0014@student.tdtu.edu.vn>`.
   Trước commit đầu tiên chạy:
   ```powershell
   git config user.name "Nguyễn Bảo Long"
   git config user.email "523k0014@student.tdtu.edu.vn"
   ```
   **Không** thêm dòng `Co-authored-by:` hay bất kỳ trailer nào ghi nhận AI/agent.
   Không sửa tác giả/ngày của commit cũ, không rebase/force-push lịch sử đã push.
2. **Nhánh:** đặt tên theo nội dung, không chứa chữ `codex`
   (ví dụ `docs/readme-submission`, `build/sdk-constraint`, `feat/share-notification`,
   `refactor/split-app-controller`, `chore/repo-cleanup`). Không push thẳng `master`.
3. **Commit nhỏ, có nghĩa:** mỗi commit là một thay đổi hoàn chỉnh, thông điệp tiếng Việt
   mô tả rõ việc làm (ví dụ "Thêm thông báo ghi chú mới được chia sẻ cho người nhận").
   Không tạo commit rỗng, commit chỉ đổi khoảng trắng, hay chia nhỏ giả tạo.
4. **Kiểm tra sau mỗi hạng mục** (phải PASS trước khi mở PR):
   ```powershell
   flutter pub get --enforce-lockfile
   dart format --output=none --set-exit-if-changed lib test integration_test test_driver
   flutter analyze
   flutter test
   .\.venv\Scripts\python.exe -m pytest backend/tests -q
   ```
   Nếu một lệnh không chạy được trên máy, ghi rõ lý do trong mô tả PR; **không** ghi PASS
   khi chưa chạy. Không xóa/skip test để cho qua.
5. Không đổi hợp đồng bảo mật hiện có: ACL owner/editor/viewer, khóa ghi chú (argon2,
   grant theo session), cách ly dữ liệu theo tài khoản, AI chỉ đọc bản server.
6. Không thêm secret vào repo. **Repo đang PUBLIC** → không ghi mật khẩu tài khoản chấm vào
   bất kỳ file nào được commit.

---

## P1 — Viết lại `Readme.txt` đúng mục VII của đề (nhánh `docs/readme-submission`)

### Vấn đề hiện tại
- Không có lệnh trực tiếp `flutter test`, `flutter build web --release`,
  `flutter build apk --release`; chỉ trỏ tới script `.ps1`.
- Không có URL repo GitHub, không có danh sách thành viên.
- Không mô tả kiến trúc + state management ngay trong Readme (đề bắt buộc "documented in Readme.txt").
- Không liệt kê package quan trọng, không có mục giới hạn đã biết.
- Có đường dẫn gắn cứng máy cá nhân: `C:\Users\LENOVO\flutter-sdk\...`, `D:\Android\sdk\...`.
- Nội dung lặp (hai lần "Setup trên Windows"), lẫn nhật ký ngày tháng và viết tắt nội bộ
  ("C0–C5", "N02", "gate", "SOL"...), số dính chữ ("Flutter3.47.1", "port7357").

### Việc cần làm
Viết lại `Readme.txt` là văn bản thuần (không phụ thuộc render Markdown, dùng tiêu đề dạng
`1. ...`, `====`). `README.md` sao chép cùng nội dung (giữ hai file giống nhau byte như quy ước cũ).
Bố cục bắt buộc, theo đúng thứ tự:

1. **Thông tin dự án**: tên app, mã môn 503107, thành viên (MSSV – họ tên – GitHub username):
   `523K0006 – <họ tên Bahung> – bahungTDTU`, `523K0014 – Nguyễn Bảo Long – Long-D176`
   (hỏi lại người dùng họ tên đầy đủ của 523K0006 nếu không tìm thấy trong
   `docs/TEAM_CONTRIBUTIONS.md`), URL repo `https://github.com/bahungTDTU/final-flutter`.
2. **Phiên bản SDK**: Flutter, Dart (khớp kết quả P2), Python 3.12, Android SDK/JDK dùng để build APK.
3. **Nền tảng hỗ trợ**: Flutter Web (Chrome/Edge) + Android (APK release). Ghi rõ không nộp iOS/Windows/macOS.
4. **Công nghệ backend & hosting**: FastAPI + SQLite, SSE realtime, SMTP Gmail, Gemini (chỉ gọi từ backend),
   Docker Compose, Azure VM + Caddy HTTPS, GitHub Actions deploy.
5. **Kiến trúc & state management** (10–20 dòng, viết bằng lời của nhóm):
   lớp `ui/` → `state/` (ChangeNotifier) → `data/` (Api, LocalStore Sembast) → `domain/` (model thuần);
   giải thích controller nào giữ state gì (cập nhật đúng theo kết quả P4); conditional import
   Web/native ở `open_database_*.dart`, `attachment_platform_*.dart`.
   Kèm sơ đồ ASCII đơn giản các thành phần Flutter ↔ FastAPI ↔ SQLite/Gemini/SMTP.
6. **Lưu trữ offline & đồng bộ**: Sembast (IndexedDB trên Web, file trên Android), mã hóa theo tài khoản,
   hàng đợi thao tác chờ, retry khi có mạng, chiến lược xung đột (bản sao UUID mới, không ghi đè bản server mới hơn),
   trạng thái UI (Offline / chờ đồng bộ / lỗi đồng bộ). Tóm tắt từ `docs/OFFLINE_SYNC.md`.
7. **Package quan trọng**: bảng tên – phiên bản – mục đích (http, sembast, sembast_web, path_provider,
   cryptography, flutter_secure_storage, file_selector, video_player, flutter_quill, uuid,
   integration_test; backend: fastapi, uvicorn, argon2-cffi, pillow, pydantic, python-dotenv, httpx —
   lấy đúng phiên bản từ `pubspec.lock` và `backend/requirements.txt`).
8. **Cài đặt** — lệnh chính xác, chạy từ thư mục gốc repo, **không có đường dẫn máy cá nhân**:
   ```powershell
   flutter pub get
   py -3.12 -m venv .venv
   .\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt
   Copy-Item .env.example .env   # rồi điền SMTP_USERNAME/SMTP_PASSWORD/GEMINI_API_KEY nếu cần
   ```
   Ghi chú: script tiện lợi `scripts/setup.ps1` làm các bước trên (tùy chọn).
9. **Chạy dự án local**:
   ```powershell
   .\.venv\Scripts\python.exe -m uvicorn backend.app:create_app --factory --host 127.0.0.1 --port 8000 --env-file .env
   flutter run -d chrome --web-port 7357 --dart-define=API_URL=http://127.0.0.1:8000
   flutter run -d <android-device-id> --dart-define=API_URL=http://10.0.2.2:8000
   ```
   (Đã đối chiếu: `scripts/start_backend.ps1` dùng `backend.app:create_app --factory`; biến `API_URL` đọc ở
   `lib/main.dart`.) Kiểm tra lại `WEB_ORIGINS` và cách Android emulator gọi backend (`10.0.2.2` hay
   `adb reverse`) bằng cách đọc `scripts/start_web.ps1`, `android/app/src/main/AndroidManifest.xml`
   (cleartext HTTP) trước khi ghi.
   Ghi chú `WEB_ORIGINS` phải chứa origin của `flutter run -d chrome` (cổng cố định bằng `--web-port 7357`).
10. **Chạy test** — liệt kê riêng:
    - Unit + widget: `flutter test`
    - Một integration test luồng quan trọng (đăng nhập → tạo → sửa → tự lưu): ghi đúng lệnh
      `flutter test integration_test/note_flow_test.dart -d <device>` hoặc `flutter drive ...`
      theo cách file đó thực sự chạy (đọc file + `test_driver/` để xác định, kèm điều kiện cần backend).
    - Backend: `.\.venv\Scripts\python.exe -m pytest backend/tests -q`
    - Chỉ rõ 3 unit test, 3 widget test, 1 integration test tiêu biểu (tên file + tên test) để thầy dễ chấm tiêu chí #30.
11. **Build release**:
    ```powershell
    flutter build web --release --no-web-resources-cdn --dart-define=API_URL=https://notetogether-029218.malaysiawest.cloudapp.azure.com
    flutter build apk --release --dart-define=API_URL=https://notetogether-029218.malaysiawest.cloudapp.azure.com
    ```
    (Đã đối chiếu: workflow `azure-web-deploy.yml` build với `API_URL=https://$DEPLOY_HOST`, tức chính domain Azure ở trên.) Nêu cách tạo `android/key.properties`
    + keystore (không commit), đường ra `build/web`, `build/app/outputs/flutter-apk/app-release.apk`.
12. **Cấu hình & biến môi trường**: bảng từng biến trong `.env.example` – ý nghĩa – bắt buộc hay không.
13. **Triển khai công khai**: URL Web Azure, cách deploy (workflow), kiểm tra `/health`.
14. **Artifact native**: tên file `release/app-release.apk`, versionName/versionCode, Android tối thiểu (minSdk).
15. **Tài khoản chấm**: bảng có cột Email/Mật khẩu để trống dạng `<điền khi đóng gói>` + mô tả dữ liệu mẫu
    (Minh An chủ ghi chú, Khánh Linh cộng tác viên, ghi chú chung). Thêm câu: "Bản Readme.txt trong
    thư mục nộp có đầy đủ mật khẩu; repo công khai nên không ghi mật khẩu ở đây."
16. **Giới hạn đã biết**: Gemini Free Tier có quota/rate-limit; chưa có camera trực tiếp (chọn file/thư viện);
    Web không có secure storage tương đương Android; realtime dùng SSE invalidate + tải lại; v.v. — chỉ ghi
    điều đúng, kiểm tra trong code.
17. **Liên kết tài liệu chi tiết**: chỉ trỏ tới các file trong `docs/` được giữ ở P5.

### Tiêu chí xong
- `grep -nE "LENOVO|D:\\\\Android|C:\\\\Users" Readme.txt README.md` không ra kết quả.
- Mọi lệnh trong Readme đã được chạy thử ít nhất một lần trên máy (ghi lại kết quả trong mô tả PR);
  lệnh nào không chạy được phải ghi rõ trong PR.
- `Readme.txt` và `README.md` giống nhau (`fc /b Readme.txt README.md` không khác).
- Mọi link tương đối trong Readme trỏ tới file tồn tại.

---

## P2 — Ràng buộc SDK để thầy build được (nhánh `build/sdk-constraint`)

### Vấn đề
`pubspec.yaml` đòi `sdk: ^3.13.1`; Flutter 3.47.0 (Dart 3.13.0, bản stable phổ biến) **không `pub get` được**.
Đã xác nhận trên máy người dùng: "Because note_together requires SDK version ^3.13.1, version solving failed."

### Việc cần làm
1. Đổi `environment: sdk: ^3.13.0` trong `pubspec.yaml`.
2. Chạy `flutter pub get` bằng Flutter 3.47.0 để cập nhật `pubspec.lock` (mục `sdks:`).
   Nếu một package trong lock đòi Dart ≥3.13.1, hạ đúng package đó về phiên bản tương thích gần nhất
   (ghi rõ trong PR), không nâng/hạ package khác.
3. Chạy toàn bộ kiểm tra ở mục 0 bằng **Flutter 3.47.0**. Nếu có lỗi do API chỉ có từ 3.47.1, sửa code cho tương thích.
4. CI `.github/workflows/quality.yml`: giữ job hiện tại, thêm matrix hoặc job phụ chạy
   `flutter pub get --enforce-lockfile` + `flutter analyze` + `flutter test` với Flutter **3.47.0**
   để bảo đảm phiên bản tối thiểu luôn build được. Không đổi workflow deploy.
5. Cập nhật mục "Phiên bản SDK" trong Readme (P1) thành: tối thiểu Flutter 3.47.0 / Dart 3.13.0,
   CI kiểm 3.47.0 và 3.47.1.
6. Build thử `flutter build web --release` và `flutter build apk --release` (hoặc `--debug` nếu thiếu keystore) bằng 3.47.0.

### Tiêu chí xong
- Với Flutter 3.47.0: `pub get`, `analyze` (0 error), `test` đều PASS; build web PASS; build apk PASS.
- CI trên PR xanh cả hai phiên bản.

---

## P3 — Thông báo cho người nhận khi được chia sẻ (nhánh `feat/share-notification`)

### Vấn đề
Đề mục 2.5 "Better Approach" yêu cầu *notifying the recipient*. Hiện backend chỉ thêm dòng `shares`
và SSE gửi tín hiệu invalidate; người nhận không biết có ghi chú mới.

### Thiết kế (thông báo trong app là chính, email là phụ, không chặn việc chia sẻ)

**Backend**
1. Migration không phá dữ liệu (theo mẫu `PRAGMA table_info` + `ALTER TABLE` như
   `backend/email_queue.py::migrate_email_tokens`): thêm cột `seen_at TEXT NULL` vào bảng `shares`;
   cập nhật `backend/schema.sql` cho DB mới. Dòng share cũ: đặt `seen_at = shared_at` khi migrate
   (để không bắn hàng loạt thông báo cũ).
2. Khi owner thêm người nhận mới (`backend/sharing.py`, đoạn insert trong `install_share_routes`):
   `seen_at = NULL`. Đổi quyền viewer↔editor: **giữ nguyên** `seen_at` nhưng nếu đổi sang quyền khác thì
   đặt lại `NULL` để người nhận biết quyền đã đổi (ghi quyết định này trong docs/SHARING_AND_PERMISSIONS.md).
   Thu hồi: xóa dòng như hiện tại.
3. Trả thêm trong metadata ghi chú được chia sẻ (`shared_metadata`): `"share_seen": bool` — **chỉ**
   trả cho chính người nhận; owner và người khác không thấy trường này.
4. Endpoint mới `POST /notes/{note_id}/shares/seen`: chỉ người nhận hiện có quyền với ghi chú mới gọi được;
   đặt `seen_at = now()` cho dòng `(note_id, current_user)`. Owner/người lạ → 404 (giống chính sách ACL hiện có,
   không lộ sự tồn tại ghi chú). Idempotent.
5. Thêm đường dẫn mới vào `deploy/azure/Caddyfile` nếu matcher hiện tại chưa bao phủ (`/notes/*` đã có — kiểm tra lại).
6. Email (tùy chọn, best-effort): nếu SMTP đã cấu hình, gửi email ngắn cho người nhận:
   "<Tên chủ> đã chia sẻ một ghi chú với bạn (quyền: xem/chỉnh sửa). Mở NoteTogether để xem."
   **Không** đưa tiêu đề/nội dung ghi chú vào email (ghi chú có thể bị khóa). Gửi ngoài transaction,
   lỗi SMTP chỉ ghi log, không làm hỏng request chia sẻ. Tái sử dụng `SmtpDelivery` trong
   `backend/email_delivery.py`; nếu khó tích hợp an toàn với hàng đợi OTP hiện tại thì bỏ phần email và
   ghi rõ trong PR (thông báo trong app vẫn là bắt buộc).
7. Test pytest mới (ví dụ `backend/tests/test_share_notification.py`):
   - share mới → người nhận thấy `share_seen=false`; owner không thấy trường.
   - người nhận gọi `/shares/seen` → `share_seen=true`; gọi lại vẫn 200.
   - owner và người lạ gọi `/shares/seen` → 404.
   - migrate DB cũ (không có cột) → không lỗi, dòng cũ có `seen_at` khác NULL.
   - đổi quyền → `share_seen=false` trở lại (nếu áp dụng quyết định ở bước 2).

**Flutter**
1. `lib/domain/note.dart`: thêm `shareSeen` (nullable, chỉ có ý nghĩa với ghi chú được chia sẻ),
   parse/serialize như các trường share khác, giữ tương thích cache cũ (thiếu trường → coi như đã xem).
2. `lib/data/api.dart`: thêm `markShareSeen(noteId)`.
3. State: getter `unseenSharedCount`; hàm `markShareSeen(id)` cập nhật lạc quan cục bộ rồi gọi API;
   offline thì giữ cờ cục bộ và thử lại ở lần đồng bộ sau (không cần durable outbox, mất cũng chỉ hiện lại badge).
4. UI:
   - Badge số lượng trên mục điều hướng "Được chia sẻ" (`lib/ui/home.dart`, `destinations`) — cả NavigationBar
     (mobile) lẫn NavigationRail/side panel (tablet/desktop). Có `Semantics(label: "N ghi chú mới được chia sẻ")`.
   - Chip "Mới" trên thẻ ghi chú ở cả grid và list, cạnh các chỉ báo đã có (ghim/khóa/chia sẻ).
   - Khi realtime/sync nhận về ghi chú chia sẻ mới trong phiên đang mở: SnackBar
     "<Tên chủ> vừa chia sẻ một ghi chú với bạn" + nút "Mở".
   - Mở ghi chú → gọi `markShareSeen`.
   - Chuỗi mới thêm cả tiếng Việt và `lib/l10n/strings_en.dart`.
5. Test Flutter:
   - Unit: parse `share_seen`, `unseenSharedCount` đúng, cache cũ thiếu trường không crash.
   - Widget: badge hiển thị số đúng và biến mất sau khi mở ghi chú; chip "Mới" có trong grid và list.
6. Cập nhật `docs/SHARING_AND_PERMISSIONS.md` (mục thông báo) và dòng tiêu chí #25 trong `docs/REQUIREMENTS_MATRIX.md`.

### Tiêu chí xong
- Kiểm tra thủ công hai trình duyệt (hai tài khoản): A chia sẻ cho B → B thấy badge + SnackBar không cần reload;
  B mở ghi chú → badge mất; reload B → badge vẫn mất. Ghi kết quả vào mô tả PR.
- Toàn bộ test cũ + mới PASS.

---

## P4 — Tách `AppController` (nhánh `refactor/split-app-controller`)

### Vấn đề
`lib/state/app_controller.dart` dài ~2.024 dòng, gom auth, sync, nhãn, preferences, hồ sơ/avatar, workspace/planner/focus.
Rubric #30 phạt "weak separation of concerns". Mục tiêu: tách trách nhiệm **mà không đổi hành vi**.

### Nguyên tắc
- Refactor thuần: không đổi API HTTP, schema, định dạng lưu Sembast, thứ tự sync, invariant editor
  (freeze base revision lúc mở), pending_preferences, pending labels.
- Giữ `AppController` làm **facade**: các method public cũ vẫn tồn tại và ủy quyền sang controller mới,
  để UI và 333 test hiện có không phải sửa đồng loạt. Chỉ chuyển UI sang dùng controller mới khi thật cần.
- Mỗi bước tách = **một commit**, chạy `flutter analyze` + `flutter test` sau từng commit; fail thì sửa trước khi đi tiếp.
- Controller con nhận phụ thuộc qua constructor (Api, LocalStore, callback `persist`/`notify`), không dùng biến global.

### Thứ tự tách (theo nhóm method hiện có, số dòng tham khảo ở `68bf97b`)
1. `lib/state/label_catalogue.dart` — `labelName`, `noteLabelIds`, `labelNameExists`, `labelsPending`,
   `_migrateLocalLabels`, `_rebuildLabels`, `_syncLabels`, `validateLabelName`, `_labelChange`,
   `addLabel`, `renameLabel`, `removeLabel`, `useRemoteLabel` (≈ dòng 128–138, 1697–1925).
2. `lib/state/preferences_controller.dart` — `grid`, `language`/`setLanguage`, `palette`, `dark`, `fontSize`,
   `setPreferences`, pending preferences (≈ 176–201, 1663–1696).
3. `lib/state/profile_controller.dart` — `_acceptProfile`, `refreshAvatar`, `updateAvatar`, `removeAvatar` (≈ 1925–2015).
4. `lib/state/workspace_controller.dart` — `_editWorkspace`, `workspaceNotes`, `saveNotePlan`, `moveNotePlan`,
   `removeNotePlan`, `startFocus`, `changeFocus`, `setFocusGoal`, `recordRecent`, `toggleFavorite`,
   `saveWorkspaceView`, `deleteWorkspaceView`, `savePersonalTemplate`, `deletePersonalTemplate`,
   `toggleWorkspaceTask` (≈ 726–985).
5. `lib/state/realtime_link.dart` — `_startRealtime`, `_scheduleRealtimeRefresh`, `realtimeStatus`, `realtimeLive` (≈ 26–100).
6. (Chỉ làm nếu 1–5 xong gọn và test xanh) `lib/state/sync_engine.dart` — `synchronize`, `_archiveLocked`,
   `_archiveAccessLoss`, `resolveConflict`, `restoreRecovery` (≈ 1285–1662). Phần này rủi ro cao nhất;
   nếu phải đổi hành vi để tách được thì **dừng**, giữ trong AppController và ghi lý do vào PR.

### Test bổ sung
- Mỗi controller mới có ít nhất 1 unit test riêng chạy được không cần widget tree
  (ví dụ: `LabelCatalogue` đổi tên nhãn cập nhật tên hiển thị cho mọi ghi chú gắn nhãn đó;
  `PreferencesController` lưu `grid=false` và đọc lại sau khi khởi tạo lại store).

### Tài liệu
- Viết lại `docs/ARCHITECTURE.md` ngắn gọn (≤150 dòng): sơ đồ lớp, trách nhiệm từng controller, luồng dữ liệu,
  bỏ các đoạn nhật ký theo ngày. Cập nhật mục 5 của Readme (P1) cho khớp.

### Tiêu chí xong
- `app_controller.dart` ≤ ~1.000 dòng (nếu làm cả bước 6 thì ≤ ~700).
- Toàn bộ test cũ PASS không sửa logic assert (chỉ được sửa import/khởi tạo nếu bắt buộc, ghi rõ trong PR).
- Chạy thử Web: đăng nhập, tạo/sửa ghi chú, thêm/đổi tên/xóa nhãn, đổi theme + grid/list, đổi avatar, offline → online.

---

## P5 — Dọn repo, bỏ file thừa (nhánh `chore/repo-cleanup`) — làm **cuối cùng**

### Vấn đề
2.248/2.519 file tracked thuộc `evidence/` (≈89 MB) và `docs/` (~80 file nhật ký/audit theo ngày), cùng
`STATUS.md` (91 KB), `README_HISTORY.md`, các file prompt/agent. Đề trừ 0,5 điểm nếu nộp kèm file không cần thiết.

### Việc cần làm
1. Xóa khỏi cây làm việc (`git rm -r`; **không** viết lại lịch sử):
   - `evidence/` toàn bộ.
   - `STATUS.md`, `README_HISTORY.md`, `PHAN_TICH_DE_FINAL_PROJECT.md`,
     `PROMPT_CHO_AGENT.md`, `PROMPT_UI_UX_NOTETOGETHER.md`, `docs/PROMPT_6_1_SOL_COMPLETION.md`.
   - Trong `docs/`: mọi file nhật ký/audit có ngày trong tên (`*_2026-*.md`) và các tài liệu lịch sử UI
     (UI_ATELIER, UI_DESKBOOK, SOFT_STUDIO_UI…, DASHBOARD_*, PRISM…, COMPLETION_PLAN…, NEXT_STEP…, REMAINING_GATES,
     LOCAL_BASELINE…, GITHUB_PUBLISH, BRANCH_WORKFLOW nếu không còn cần).
   - `design-system/` nếu không có code/asset nào trong `lib/`, `web/`, `pubspec.yaml` tham chiếu tới (kiểm tra bằng grep).
2. **Giữ** (và rút gọn, bỏ đoạn nhật ký theo ngày) các tài liệu kỹ thuật thật sự:
   `docs/ARCHITECTURE.md`, `OFFLINE_SYNC.md`, `SECURITY_AND_PERMISSIONS.md`, `SHARING_AND_PERMISSIONS.md`,
   `NOTE_PROTECTION.md`, `REALTIME_COLLABORATION.md`, `AI_FEATURES.md`, `EMAIL_DELIVERY.md`,
   `PRIVATE_ATTACHMENTS.md`, `AZURE_WEB_DEPLOYMENT.md`, `TEST_PLAN.md`, `REQUIREMENTS_MATRIX.md`,
   `TEAM_CONTRIBUTIONS.md`, `docs/adr/`.
3. Sửa các script đang ghi/đọc vào `evidence/...` (`scripts/qa_email_queue.py`, `qa_realtime.py`, `qa_sharing.py`,
   `qa_writing_studio.py`, `verify_note_protection.py`, …) để mặc định ghi vào `output/` (đã gitignore),
   đọc fixture từ tham số dòng lệnh thay vì file evidence cố định. Sửa `scripts/start_backend_gmail.ps1`
   nếu link tài liệu bị xóa.
4. `grep -rn "evidence/\|README_HISTORY\|STATUS.md\|PROMPT_" -- . ':!*.lock'` (bỏ qua `.git`) phải không còn
   tham chiếu tới file đã xóa; mọi link Markdown trong Readme/docs còn lại phải trỏ tới file tồn tại.
5. `.gitignore`: bảo đảm có `/output/`, `/build/`, `.dart_tool/`, `.venv/`, `backend/state/`, `release/`,
   `*.apk`, `*.jks`, `*.keystore`, `android/key.properties`.
6. **Bước cuối của toàn bộ kế hoạch** (commit riêng, sau khi P1–P4 đã merge): xóa `AGENTS.md` và chính file
   `KE_HOACH_SUA_TRUOC_NOP.md` này khỏi repo vì là tài liệu điều phối công việc, không thuộc sản phẩm nộp.
7. Chạy lại toàn bộ kiểm tra mục 0 + `flutter build web --release` sau khi dọn.

### Tiêu chí xong
- `git ls-files | Measure-Object` còn khoảng vài trăm file; `git ls-files evidence` rỗng.
- Không còn link gãy; CI xanh.

---

## Checklist bàn giao cho người dùng (sau P1–P5)

- [ ] 5 PR (P1–P5) đã mở, CI xanh, mỗi PR có mục "Đã chạy / Chưa chạy được" trung thực.
- [ ] Mọi commit tác giả `Nguyễn Bảo Long <523k0014@student.tdtu.edu.vn>`, không có trailer `Co-authored-by`.
      Kiểm: `git log master..HEAD --format="%an <%ae>%n%b" | Select-String "Co-authored"` → rỗng.
- [ ] Readme.txt đủ 17 mục, không có đường dẫn máy cá nhân, mật khẩu chấm để trống trong repo.
- [ ] Build được bằng Flutter 3.47.0.
- [ ] Thông báo chia sẻ hoạt động trên Web và APK.
- [ ] `app_controller.dart` đã tách, kiến trúc được mô tả trong Readme + docs/ARCHITECTURE.md.
- [ ] Repo đã dọn; nhớ khi đóng gói thư mục `source` phải `git clone` lại (giữ `.git`) và không chép `output/`, `.venv/`, `build/`.
- [ ] Việc còn lại (ngoài phạm vi): video demo, Rubric.xlsx, Screenshot.png Insights, điền mật khẩu vào Readme.txt bản nộp.
