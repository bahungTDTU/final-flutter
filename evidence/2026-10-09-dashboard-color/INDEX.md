# Dashboard màu sắc —09/10/2026

Base ef2ece00386b879f6ebb72b4636c42911aa07ca3, branch codex/ui-ux-performance;
working changes có cả đợt Home trước, chưa commit/push/merge. manifest.json ghi date thực,
source/artifact/bundle hashes; không cập nhật snapshot Home đã ghi trước đó.

| Kiểm chứng | Kết quả |
|---|---|
| Format/analyze |88 files0changes, no issues; format.log/analyze.log |
| Flutter |198 PASS, gồm responsive200%/editor/recovery/locked semantics/filter; flutter.log |
| Direct API |Owner/editor/viewer/stranger PASS,423/403/404/429; acl.json |
| Web compile |Release local +40static offline shell; web.log |
| Page identity/blank/overlay |NoteTogether tại7357, meaningful Home, không overlay; qa.json/ảnh |
| Console |Pageerror/error=[]; warnings ghi riêng trong qa.json |
| Interactions |Filter→2notes, search→empty→clear9, edit→autosave→GET khớp, resize/theme giữ text |
| Native/FPS |Chưa chạy trong đợt màu sắc |

Browser plugin absent; dùng bundled Playwright qua shell/Chrome headless, API8020 với SQLite/
tài khoản disposable. Không dùng API key/cloud/email Internet. Chromium context mới mỗi run,
bật Flutter semantics để thao tác controls; thông tin xác thực fixture không đưa vào artifacts.
Backend source không đổi,94 tests PASS đã có ở đợt Home trước; không claim backend rerun mới.

Ảnh reference1440×960 do người dùng cung cấp. concept.png là preview do built-in ImageGen
dựng từ reference; không phải ảnh app hay asset shipping. Xem trực tiếp concept và latest
render ở cả1440×960 và native concept1536×1024, cộng390×844/1280×900/768×1024/844×390.

| Điểm đối chiếu | Concept / lỗi thấy ở render | Chỉnh sửa / quyết định |
|---|---|---|
| Sidebar |Indigo/navy, menu chọn lavender; render đầu ink bị gradient che |Material transparent trong local Theme; selected background + Brand rõ ở ảnh final |
| Header |Vùng tím-xanh, chữ trắng, CTA sáng, notice amber |DashboardHeader dựng đúng phân cấp; gradient đậm hơn concept để đọc chữ nhỏ |
| Toolbar |Vùng lavender-blue riêng, search đọc sáng |Background opt-in; giữ six chips/search/filter/copy và segmentation |
| Cards |Mint/lavender đầy thẻ, title/preview/footer rõ |Rich tint/facet từ opaque ID, divider/chip/footer giữ; locked tone=null |
| Typography/density |NotoSans, note-first, CTA không chèn chữ |Giữ font/control size thực; sidebar248, count2/7 giữ từ app; CTA icon ở width<900/chữ>=150% |
| Responsive/state |Mobile chưa có concept riêng; desktop direction |Layout thật390px + widget320px/chữ200%; filter/query/editor text/selection/revision giữ |
| Motion/performance |Facet tĩnh, nhẹ |CustomPainter có shouldRepaint, no blur/ticker; hover/reduced motion cũ giữ |

Above-fold copy diff: không thêm/đổi/nav/marketing eyebrow. Notice chuyển vào hero, account
counts/nav labels vẫn từ app. CTA compact có tooltip Ghi chú mới. Tone của label IDs khác
giữa fixture và concept là có chủ đích; không ánh xạ màu theo nội dung/private metadata.
Hướng màu, phân cấp và state được đối chiếu với concept; khác biệt có chủ đích ở bảng trên.

Regression đầu phát hiện CTA overflow ở768px/chữ200%, đã thu gọn. Một số test cũ thao tác
trước khi thẻ lazy xuất hiện: helper revealHome cuộn thật tới target, giữ nguyên mọi assertion
bảo mật/owner/viewer/editor/filter/recovery; kiểm tra khóa còn cuộn tới locked card trước
semantics assertions. Không dùng lần FAIL làm PASS. palette-contrast.json là sampling sRGB
palette (hero phụ>=4.76, card phụ>=4.55), không phải pixel measurement/accessibility claim.

Lệnh chính (chạy từ D:/flutter cuoi ki, QA-temp ngoài source):

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test test_driver
flutter analyze
flutter test --reporter expanded
scripts/build.ps1 -Target web -ApiUrl http://127.0.0.1:8020
node <QA-temp>/dashboard-qa.cjs after
python <QA-temp>/dashboard-acl.py --url http://127.0.0.1:8020 --output <QA-temp>/dashboard-acl.json
scripts/build.ps1 -Target web
```

Flutter SDK C:/Users/LENOVO/flutter-sdk; Node/Playwright bundled Codex runtime, Python .venv.
QA script giữ outside source; bản lưuqa.cjs dùng bundled path máy QA. Sau QA build Web mặc
định8000 để checkout chạy scripts/start_web.ps1 bình thường; hai bundle/config ghi riêng.
Các server QA riêng được dừng sau kiểm tra. Chưa deploy/Android UI/APK/FPS/physical/release.

Ảnh: [reference](reference.png), [concept](concept.png), [desktop](desktop.png),
[native size](native.png), [mobile](mobile.png), [dark](desktop-dark.png),
[filter](label-filter.png), [tablet](tablet-dark.png), [landscape](landscape.png).
[Phạm vi thiết kế](../../docs/DASHBOARD_COLOR_REFRESH.md).
