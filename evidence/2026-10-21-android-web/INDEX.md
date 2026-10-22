# Android emulator và Web — 21/10/2026

Source `ad21cf8` sau pull; chỉ thay test/harness, không đổi app/backend/dependencies.

- [Báo cáo](../../docs/ANDROID_WEB_QA_2026-10-21.md), [kết quả](result.json), [thiết bị](device.json).
- [Native lần đầu FAIL](native-initial.txt), [metadata](native-initial-result.json).
- [Native cuối PASS](native-final.txt), [metadata](native-final-result.json), [hash APK integration](integration-artifact.json).
- [Định nghĩa bundle 5 workflow](native_suite.dart): copy trở lại `tmp/android-web-2026-10-21/native_suite.dart` trước chạy lệnh metadata.
- [Analyze](analyze-final.txt), [Web build](build-web.txt), [APK main build](main-apk-build.txt), [install](main-install.txt), [launch](main-launch.txt).
- [Web rich text ACK](web-richtext-http.json), [recovery/newUUID/Delta](web-http-final.json), [dark mode ACK](web-preferences.json), [reload/console](web-browser-checks.json).
- [Native draft phục hồi](native/native-owner-deleted-restored-draft.png), [reopen](native/native-owner-deleted-reopened.png).
- [Native protected editor](native/protected-native-editor.png), [protected reopen](native/protected-native-reopened.png), [main sign-in startup](native/native-main-start.png).
- [Web rich draft](web/01-web-rich-draft.jpg), [recovered PC](web/02-web-recovered-pc.jpg), [phone dark](web/03-web-recovered-phone-dark.jpg), [reload](web/04-web-reloaded-phone.jpg).
- [Source hashes](source-manifest.json), [main build hashes](main-artifacts.json), [ảnh gốc và kích thước](screenshot-dimensions.json).

Năm workflow, không tính tearDownAll thành test nghiệp vụ thứ6. Native dùng API8072
qua10.0.2.2, Web7386 qua127.0.0.1; DB mới và tài khoản giả, providers tắt.
Native input do TextInputClient injection, DB reopen cùng process; không IME hoặc OS-kill.
Driver mặc định uninstall app khi kết thúc: main được cài lại mới và chỉ smoke startup;
không dùng màn login đó để kết luận mất session. Không clear hay uninstall AVD gốc.
Có warning SDK XML/Cupertino font và missed-frame debug/software emulator; không suy FPS.
Ảnh phone IAB375×811 từ viewport yêu cầu375×812; giữ byte gốc. VM-service capabilities đã che.
