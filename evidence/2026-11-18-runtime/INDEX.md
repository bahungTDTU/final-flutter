# QA local ngày 18/11/2026 (Asia/Saigon)

Base `8782a333d099ecc532161c1ece709ec420ba46ea`. Commit chứa thư mục này
định danh bản sửa đã kiểm tra. Flutter 3.47.9, Dart 3.13.7, Python 3.12.14,
Chrome 157, Android 16/API 36 x86_64. Dùng DB mới và tài khoản QA.

| Kiểm tra | Lệnh hoặc cách xác minh | Kết quả |
|---|---|---|
| Backend key file mất | `python -m pytest backend/tests/test_ai.py -k missing_gemini_key_file -q` trước sửa. Chạy `scripts/start_backend.ps1 -Port 8090` sau sửa với đường dẫn key chưa tồn tại. | Trước sửa FAIL/FileNotFoundError. Sau sửa backend khởi động, cảnh báo AI tắt, GET /health báo AI và email chưa cấu hình. |
| Backend suite | `python -m pytest backend/tests -q` | PASS 164 tests, một cảnh báo Starlette TestClient deprecation. |
| Flutter | `dart format --output=none --set-exit-if-changed lib test integration_test test_driver` và `flutter analyze --no-pub` | PASS, 138 file, không thay đổi, không vấn đề. |
| Flutter suite | `flutter test --no-pub` | PASS 333 tests. |
| Web build và launcher | `scripts/start_web.ps1 -Port 7390 -ApiUrl http://127.0.0.1:8090` khi đã có một bundle cũ | PASS build, worker `notetogether-static-6e8a3f3d5101f1ae` với 41 tài nguyên. Web gọi đúng API 8090. |
| Web UI và lưu trữ | Playwright CLI điều khiển Chrome. Đăng ký, nhập ghi chú, chọn TXT, tắt mạng, sửa, reload, kết nối lại và Thử lại. Kiểm tra SQLite riêng. | PASS 201/200, đúng byte TXT, cùng UUID, revision 2, một bản ghi. Chrome đang mở nhận bản chỉnh Android. |
| Android main | `flutter build apk --debug --no-pub --dart-define=API_URL=http://10.0.2.2:8090`, `adb -s emulator-5562 install -r …/app-debug.apk`, `adb -s emulator-5562 shell am start -W -n vn.edu.notetogether.note_together/.MainActivity` | PASS build/cài/cold start. APK mở màn hình đăng nhập. AVD có kích thước override thực tế 1080×1920, 440 dpi. |
| Android UI/tệp | Thao tác Android qua ADB, kiểm tra UI hierarchy. Đăng nhập bằng tài khoản Chrome, mở ghi chú và danh sách tệp, chọn tệp rồi Back từ DocumentsUI. | PASS xem đúng nội dung và tệp, hủy picker giữ hàng tệp và không tạo tệp mới. |
| Android offline | Trên AVD QA tắt Wi-Fi/data, sửa tiêu đề, kiểm tra server vẫn revision 2. `am force-stop` và `am start -W`, cuộn để tìm bản sửa chờ đồng bộ. Bật lại mạng và đối chiếu SQLite. | PASS tiến trình mới, ghi chú còn sửa offline. Cùng UUID, revision 3 và một bản ghi sau reconnect. [Kết quả](android-reconnect.json). |
| HTTP phân quyền | `python scripts/qa_protected_notes.py --url http://127.0.0.1:8090 --output tmp/runtime-20261118/http-roles-final.json` | PASS nhóm kiểm tra HTTP bốn vai trò. [Kết quả](http-roles-final.json). |
| Bộ integration Android | `flutter drive --driver=test_driver/integration_test.dart --target=tmp/runtime-20261118/native_suite.dart -d emulator-5562 --dart-define=API_URL=http://10.0.2.2:8088 --enable-software-rendering --no-enable-impeller`. Chạy lại với `--no-dds --no-pub`; lần cuối dùng API 8090. Bundle năm workflow lấy từ evidence 21/10. | FAIL, hai lần kết nối VM bị ngắt. Một lần chạy đủ năm ca ở 320×640 nhưng dừng tại các assertion tìm note/control. Báo cáo không gộp với Android UI trực tiếp. |

[SHA256 và kiểm chứng Web](artifacts.json). Môi trường chỉ loopback,
không có SMTP/LLM thật, public HTTPS, APK ký phát hành hoặc thiết bị vật lý.
