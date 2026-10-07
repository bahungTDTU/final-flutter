# Editor sections —06–07/10/2026

Base `f8ff8fa427b3d490255c0522699f1a9650a3cb73` + working changes chưa commit.
Thư mục giữ ngày bắt đầu06/10; kiểm tra browser/native tiếp tục07/10 theo giờ Asia/Saigon.

| Lệnh / target | Kết quả | Artifact |
|---|---|---|
| scripts/check.ps1 / host06/10 | Format/analyze sạch,167 Flutter/88 backend PASS;1 upstream warning | check.txt |
| flutter test test/editor_sections_test.dart +5 suite liên quan / host |65 tests PASS, gồm6 mới | targeted.txt |
| flutter test test/editor_sections_test.dart /07/10 |6 PASS với assertion section/tile bounds bổ sung | geometry-final.txt |
| qa_writing_studio.py / API8015 |Actual owner/editor/viewer/stranger, stale/revoke/lock/minimal fields PASS | http.json;http.txt |
| Flutter run web-server7364 / API8015 |Input/API ack, theme/resize/text/range, sections/checklist/protected/relock/expiry PASS | after-*.jpg;web-api.json;web-shots.json |
| Flutter drive ui_cohesion_test / emulator-5554 API36 |3 reused workflows + teardown PASS46s; không4-new-tests | android.txt;8 native PNG |
| flutter pub get; flutter analyze / source cuối |Dependency/registrant bình thường; analyzer sạch; không sửa Java generated bằng tay | pub-get.txt;analyze-final.txt |

Native exact command: `flutter drive --driver=test_driver/ui_cohesion.dart
--target=integration_test/ui_cohesion_test.dart -d emulator-5554
--dart-define=API_URL=http://127.0.0.1:8015 --enable-software-rendering --no-enable-impeller`.
UI_SCREENSHOT_DIR là output/native-editor-sections, adb reverse8015. Emulator cài sẵn
taskflow_api36, ANDROID_AVD_HOME=D:/Android/avd; không sửa dữ liệu project TaskFlow.

Backend create_app dùng tmp/ui-review/app.sqlite3, TLS SMTP sink local và explicit
FixtureProvider. Owner/editor/viewer/stranger/note/labels/files là disposable fixture;
không đụng database thật. Script HTTP là bản QA hiện có với BASE đổi8012→8015 trong
ignored tmp/ui-review/qa_editor_acl.py; assertions giữ nguyên. Không Internet mail/LLM call.

before-editor-* là ảnh nguyên byte từ bộ UI review06/10 ở commit base, không chụp mới.
Ảnh after dùng source mới, kích thước file ảnh và thời gian ghi file UTC trong web-shots.json.
web-attempt-metadata.json giữ timestamp của các lần chụp ban đầu; không dùng timestamp cũ
cho ảnh đã được chụp lại. Metadata sau được gom lại từ file cuối vì REPL giữ bản array cũ.
Nội dung fixture thêm dòng khi thử nhập; before/after không phải golden cùng dữ liệu.
Đọc kích thước file ảnh thật trước claim; gallery/artifact gốc không sửa/crop ảnh.

Lần targeted đầu sai tên fixture labelCatalogue và locator label nằm trong TextField cũ;
đã sửa fixture và dùng field key ổn định, giữ đầy đủ assertion downgrade/recovery/read-only.
targeted-first.txt không phải PASS. Sau khi đổi mode protected cần focus/đợi input connection
trước fill: DOM value lúc chưa focus rỗng, khác controller; lần nhập cuối đã đối chiếu exact API.
Phiên unlock5 phút tự hết khi chụp; ảnh expiry được đặt tên đúng và editor đã chụp lại.
Lượt Android06/10 bị giới hạn phê duyệt do hết usage, không chạy; lượt07/10 ở android.txt mới
là kết quả nghiệm thu. Không gọi review failure đó là lỗi an toàn hoặc native PASS.

Không physical/native release/NVDA/TalkBack/full keyboard/OS kill/FPS/HTTPS/Gemini/video.
Không claim browser200% từ widget geometry; release được hoãn, không push/deploy.
