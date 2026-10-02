# Evidence local - 01/10/2026

Môi trường: Windows11/Flutter3.47.1/Dart3.13.1/Python3.12/JDK21/SDK36/Chrome154/API36 emulator.
Commit chưa có (repo local chưa commit/remote). Dữ liệu thử là disposable, không grading accounts.

| File | Expected / actual / scope |
|---|---|
| flutter-doctor.txt | Toolchain thật; PATH warning/license status unknown lúc kiểm tra; release Gradle sử dụng license đã có và cài SDK35/CMake thành công |
| final-check.txt | Format sạch, analyze0 issue, 9 Flutter tests +12 backend tests PASS; backend1 deprecation warning |
| backend-tests.txt / flutter-tests.txt | Lần chạy trước regression cuối; final-check là nguồn kết quả source cuối |
| android-integration.txt | Flutter test integration -d emulator-5554 --dart-define=API_URL=http://127.0.0.1:8000; real HTTP/SQLite/Sembast; 1 PASS; native debug |
| web-build.txt | scripts/build.ps1 -Target web; release + static worker39 resources; build PASS |
| apk-build.txt / apk-sha256.txt | scripts/build.ps1 -Target apk; final release build PASS/hash; debug signing, HTTPS backend chưa cấu hình |
| android-release-smoke.png | APK install + launch main login; không full native release feature evidence |
| web-offline-reload.png | Real Chrome viewport390x844, offline reload sau create offline; pending1, nội dung tồn tại; trước final route-ID fix |
| web-server-confirmation.json | Sau reconnect/nút sync: UI pending0; SQLite note offline body đúng, chứng minh operation tới server |
| emulator-stdout/stderr | Logs khởi động emulator existing API36, host GPU; không QEMU crash trong run này |

Browser workflow thật:
1. Local release http://127.0.0.1:7357, API http://127.0.0.1:8000.
2. Enable Flutter semantics; register → auto login với persistent banner → editor/create/back.
3. Reload online: note giữ được. Resize390x844: kiểm tra ảnh, không clipping đáng kể.
4. Set Chrome context offline: edit note, local save/pending. Reload ban đầu fail internet disconnected.
5. Sửa custom service worker + local CanvasKit; build/activate worker; offline reload thành công.
6. Create note “Ghi chú offline Web” / “Tạo khi mất mạng và giữ sau reload”, Back, pending1.
7. Reload khi Chrome context vẫn offline: note và pending1 giữ nguyên (screenshot).
8. Context online, sync: pending0; query SQLite exact title/content assertion PASS.
9. Phát hiện draft thừa do UUID trong route builder; cố định ID ngoài builder, widget regression/theme rebuild PASS,
   re-run final-check + Android integration + Web/APK release; status cuối xem STATUS.

Backend-unreachable native integration dùng port65530 không có service, không HTTP mock.
Database close/reopen diễn ra trong process test; không force-kill OS, không physical device,
không Wi-Fi toggle. Email transport là memory mailbox, không delivery thật. Offline errors trong
Chrome console là request/backend/font mạng không truy cập được, không được tính thành API success.
Chưa chạy public HTTPS, real SMTP/LLM, attachments/realtime/protected-cache, clean clone hoặc video.

Final route regression browser: sau update worker b8648554e06d2077, tạo note mới và Back: đúng1 server note, body đúng, không tăng draft count (2 draft cũ trước fix vẫn được giữ để recovery). web-final.png là ảnh sau fix.
