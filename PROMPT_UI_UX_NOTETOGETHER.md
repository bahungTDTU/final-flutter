## BẮT ĐẦU PROMPT

Bạn là Product Designer và Flutter UI Engineer phụ trách cải tiến toàn bộ UI/UX của **NoteTogether**, ứng dụng ghi chú đa nền tảng cho dự án cuối kỳ môn 503107. Hãy tạo một trải nghiệm hiện đại, bắt mắt, có bản sắc, dễ sử dụng lâu dài và đủ chất lượng để trình bày trong buổi bảo vệ. Triển khai vào Flutter project hiện có, kiểm chứng tương tác và lưu lại bằng chứng thật.

### 1. Bối cảnh và ràng buộc phải đọc trước

Workspace: `D:/flutter cuoi ki`.

Đọc `AGENTS.md`, `PROMPT_CHO_AGENT.md`, `PHAN_TICH_DE_FINAL_PROJECT.md`, `STATUS.md`, `docs/TEAM_CONTRIBUTIONS.md`, `docs/REQUIREMENTS_MATRIX.md`, `README.md`, `Readme.txt`; đối chiếu PDF gốc `C:/Users/LENOVO/Downloads/503107-FinalProject-V1.pdf` nếu cần làm rõ yêu cầu. Sau đó đọc UI/controller/model và tests liên quan.

Stack đã chọn: **một Flutter project Web + Android, ChangeNotifier controller, FastAPI/SQLite, Sembast local**. Không mở lại lựa chọn framework/state/backend chỉ để redesign. Không thay client bằng website HTML/React, không dùng template ứng dụng hoàn chỉnh từ nguồn khác.

Tại thời điểm viết brief 01/10/2026, UI chủ yếu nằm ở `lib/ui/app.dart`, `lib/ui/home.dart`, `lib/ui/editor.dart`; `lib/state/app_controller.dart` xử lý state. Đây là vị trí để bắt đầu khảo sát, phải kiểm tra lại code hiện hành. Có thể tách component/theme/screen để dễ bảo trì, tránh rewrite toàn bộ logic.

Thông tin nhóm đã xác nhận trong TEAM_CONTRIBUTIONS; không hỏi lại repo/cloud/ngân sách khi nhóm chưa sẵn có. Đã xác nhận dùng AI toàn phần; vẫn phải giải thích code và không giả contributions. Không tự push/deploy/tạo phí/nộp bài.

UI đã có auth, editor, list/grid, preferences và một phần local sync. SMTP thật, avatar/file storage, lock UI/cache, share/realtime và AI chưa hoàn chỉnh theo STATUS hiện tại. **Đọc lại STATUS để biết tiến độ thật trước làm**. Phân biệt:

- Chức năng đã có: nối UI mới vào flow thật và regression test.
- Chức năng có API nhưng thiếu UI: kiểm tra contract/authorization rồi mới nối; không suy đoán endpoint.
- Chức năng chưa có backend: thiết kế đầy đủ trong tài liệu/component preview tách biệt; trong app không giả thành công hoặc tạo dữ liệu AI giả. Có thể hiển thị trạng thái chưa khả dụng ngắn gọn khi cần, ghi gap kỹ thuật trong tài liệu phát triển.

Không làm hỏng các invariant: base revision của editor đóng băng lúc mở; stable note ID; draft/outbox/account namespace; permissions/protection; không tạo note mới khi đổi theme hoặc resize. Lưu ý rủi ro đã ghi về lock remote khi còn pending draft: không tạo thông báo “đã bảo toàn” khi encrypted recovery chưa được triển khai và kiểm chứng.

### 2. Kết quả mong muốn

Giao diện phải tạo được ba ấn tượng: **rõ ràng, tinh tế, đáng tin cậy**. Người dùng thấy ngay nơi tạo ghi chú, tìm lại nội dung, nhận biết trạng thái lưu và hiểu ai có quyền xem/sửa.

Ưu tiên theo thứ tự:

1. Đọc/viết thoải mái, tìm note nhanh, không mất nội dung.
2. Hành vi nhất quán giữa Web và Android, thích nghi theo không gian thực.
3. Thị giác có bản sắc: màu, chữ, khoảng trắng, hình dạng và chuyển động có chủ đích.
4. Loading/error/offline/locked/read-only/conflict rõ ràng, thao tác tiếp theo cụ thể.
5. Accessibility, hiệu năng và bằng chứng phù hợp rubric.

Không chỉ đổi seed color và tăng border radius. Hãy cải thiện hierarchy, navigation, mật độ thông tin, editor, empty states, microcopy và các luồng khó. Không cần thêm dashboard thống kê, onboarding nhiều bước, feed, task manager hoặc các tính năng ngoài đề để lấp màn hình.

### 3. Định hướng thị giác: không gian ghi chú sáng và yên tĩnh

Hướng mặc định: nền giấy ấm, bề mặt sạch, xanh teal trầm tạo nhận diện, một ít pastel cho note/nhãn; dark mode dùng tông than xanh với tương phản tốt. Tạo cảm giác sản phẩm ghi chú được chăm chút, phù hợp sinh viên và làm việc nhóm.

Tham khảo nguyên tắc Material 3/Material 3 Expressive về phân cấp chữ, màu nhấn, hình dạng và phản hồi chuyển động. Chỉ dùng thành phần/API được Flutter SDK thực tế hỗ trợ hoặc triển khai đơn giản có kiểm chứng; không mặc định mọi component mới trong tài liệu đều đã có trong SDK.

Tính hiện đại được thể hiện bằng:

- Typography rõ với title nổi bật, metadata nhẹ hơn nhưng vẫn đọc được.
- Bề mặt có lớp bằng tonal contrast, viền mảnh và ít bóng đổ.
- Navigation thích nghi, nội dung là trọng tâm.
- Progressive disclosure: thao tác thường dùng dễ thấy; tùy chọn ít dùng trong menu/sheet có nhãn rõ.
- Chuyển động ngắn để giải thích thay đổi trạng thái.
- AI đặt cạnh nội dung và nguồn trích dẫn, không biến toàn ứng dụng thành màn hình chatbot.

Tránh gradient toàn màn hình, glass/blur sau văn bản dài, neon, quá nhiều màu nhấn, shadow dày cho mọi card, icon không nhãn, emoji thay cả bộ icon hoặc toàn bộ UI là card bo tròn khổng lồ. Không dùng số liệu/người dùng/testimonial giả để trang trí. Không sao chép nguyên bố cục hay tài sản thương hiệu của Notion, Google Keep hoặc ứng dụng khác.

### 4. Design system cụ thể

Tạo design tokens có tên semantic, dùng `ThemeData`, `ColorScheme`, `TextTheme` và `ThemeExtension` khi cần. Không rải magic colors/dimensions ở nhiều widget.

#### Màu khởi điểm

| Vai trò | Light | Dark |
|---|---|---|
| Canvas | `#F7F8F5` | `#111816` |
| Surface chính | `#FFFFFF` | `#1A2320` |
| Surface phụ | `#EFF3EF` | `#24312B` |
| Primary | `#176B57` | `#83D8B8` |
| Chữ chính | `#17251E` | `#E6EEE8` |
| Chữ phụ | `#52645A` | `#AFBEB4` |
| Outline nhẹ | `#D7E1D9` | `#405148` |
| Accent ấm tiết chế | `#E8C779` | `#D9BA73` |

Đây là palette đề xuất, **chưa phải bảng contrast đã kiểm định**. Tạo on-primary/on-surface/error/warning/success/focus/disabled/selected tokens phù hợp và đo từng cặp sử dụng. Không dùng outline nhẹ này làm đường biên duy nhất cho control nếu tương phản không đạt. Dark mode có màu note riêng, không đảo màu máy móc. Ưu tiên primary cho hành động chính, màu semantic cho trạng thái; không dùng một màu xanh cho mọi thứ.

Note color options: mặc định neutral, sage, sand, sky, lilac nhẹ. Màu giúp tổ chức, không thay thế text/label/status. Color swatch phải có tên đọc được và dấu chọn; kiểm tra chữ trên từng màu ở hai theme.

#### Typography

- Chọn một font có đầy đủ dấu tiếng Việt, chẳng hạn Inter hoặc Noto Sans; kiểm tra license và bundle font vào assets cho offline, không phụ thuộc font tải runtime.
- Không cần thêm dependency chỉ để tải font. Dùng family/fallback ổn định giữa Web/Android.
- Thang khởi điểm: page title 28–32; section 20–24; note title 17–20; body 15–16; metadata 12–13; button 14–15 logical px, điều chỉnh theo context.
- Editor content khoảng 16–18 với line height 1.5–1.65; dòng đọc dài khoảng 65–80 ký tự khi màn hình đủ rộng. Preferences về font size phải còn hoạt động.
- Title mạnh, body regular, metadata vừa phải; không dùng weight quá mảnh. Tôn trọng text scaling, không cố định chiều cao khiến dấu tiếng Việt/chữ lớn bị cắt.

#### Khoảng cách và hình dạng

- Spacing scale: 4, 8, 12, 16, 24, 32, 48.
- Content padding mobile 16, tablet 24, desktop 24–32; gap card 12–16.
- Radius: control 10–12, card 16, dialog/sheet 20–24; capsule dành cho chips/toggle phù hợp.
- Viền thường 1 logical px; elevation thấp, hover rất nhẹ. Tách selected/focused/hovered/pressed bằng trạng thái rõ ràng.
- Tap target mục tiêu tối thiểu 48×48 logical px; icon có thể nhỏ hơn nhưng hit area đủ rộng.

#### Motion

- Hover/focus khoảng 100–150ms; feedback/expand 150–220ms; navigation/sheet khoảng 200–280ms. Đây là ngân sách thiết kế đề xuất, không phải thời gian đã đo.
- Dùng motion giải thích mở note, chọn filter, trạng thái save hoặc panel; không animate toàn bộ danh sách mỗi lần gõ.
- Tôn trọng reduced motion/disable animations của nền tảng; loại hiệu ứng trang trí khi người dùng yêu cầu.
- Không chuyển focus, scroll lên đầu hoặc làm caret nhảy khi auto-save/realtime rebuild. Không dùng shimmer vô hạn; ưu tiên placeholder tĩnh khi giảm chuyển động.

### 5. Information architecture và responsive

Các khu vực chính: **Ghi chú**, **Được chia sẻ**, **Hỏi ghi chú**. **Nhãn**, **Hồ sơ**, **Cài đặt** là khu vực quản lý; có thể bố trí Nhãn trong sidebar/bộ lọc. Không thêm tab Ghim riêng nếu chip/filter đã giải quyết tốt.

Breakpoints đề xuất tính theo **logical width/constraints**, không theo tên thiết bị:

| Width | Bố cục đề xuất |
|---|---|
| <600 | Một cột nội dung chính; bottom navigation 3 mục; editor full-screen |
| 600–1023 | NavigationRail; list/grid co giãn; panel chỉ mở nếu đủ chỗ |
| ≥1024 | Sidebar khoảng 232–256; content workspace; panel ngữ cảnh khi cần |

Không ép một breakpoint chung cho mọi component. Editor có panel chỉ khi vùng còn lại đọc/viết thoải mái. Không dựng 3 pane trên màn hình 1024 nếu mỗi pane quá hẹp. Khi text scale lớn, giảm số cột và chuyển dialog sang full-screen nếu cần.

- Desktop home: sidebar, header title + nút “Ghi chú mới”, search/filter bar, vùng ghim rồi các note còn lại. Tránh vùng hero lớn đẩy note xuống dưới.
- Mobile home: header gọn, search dễ chạm, filter chips cuộn ngang có dấu hiệu còn nội dung, grid mặc định. Hai cột khi card còn đủ đọc; một cột trên màn hình hẹp/chữ lớn vẫn là adaptive grid hợp lệ.
- Grid dùng min extent hợp lý khoảng 250–280 desktop, điều chỉnh mobile; không fix số cột theo thiết bị. Card preview clamp để giữ scan rhythm; cân nhắc grid đều thay masonry khó giữ thứ tự đọc.
- List mode dùng hàng đầy đủ thông tin chính; không nhồi thành bảng nhiều cột trên mobile.
- Nhớ scroll/filter/view khi quay lại editor. Browser Back, Android Back và deep link phải có nghĩa rõ ràng; không coi đóng panel và rời note là một hành động tùy tiện.
- Create CTA: desktop có nút ở header; mobile FAB hoặc nút nổi có label. Tránh nhiều CTA “thêm” trùng nhau trên cùng viewport; không che bottom nav/nội dung cuối.

### 6. Thiết kế từng màn hình và flow

#### A. Đăng nhập/đăng ký/khôi phục

- Mobile form một cột; desktop form rộng khoảng 400–440 cạnh một mảng minh họa nhẹ mang chủ đề note, không ảnh stock lớn. Minh họa không làm tăng thời gian tải đáng kể.
- Logo/wordmark đơn giản, tiêu đề rõ, câu phụ hữu ích, label luôn hiện; không chỉ dùng placeholder làm tên field.
- Field có focus/error state, toggle password có semantic label, autofill phù hợp. Cho phép paste password; giữ các input không nhạy cảm khi lỗi, tránh reset toàn form.
- Registration chỉ email, display name, password và confirmation. Không yêu cầu avatar/phone/đồng bộ thiết bị trước khi bắt đầu.
- Primary submit có trạng thái loading/chặn double submit; Enter hoạt động; bàn phím Next/Done hợp lý. Thông báo lỗi không lộ raw stack trace.
- Sau đăng ký tự login. Banner chưa xác minh phải nổi bật, persist và không chặn tính năng. Dùng câu “Email của bạn chưa được xác minh” với action thật khả dụng; chỉ có “Gửi lại email” nếu dịch vụ hỗ trợ, không fake sent.
- Recovery form → hướng dẫn email/OTP → reset → xác nhận thành công → login thủ công. Thiết kế hết hạn/sai token và retry, không tạo success cho memory mailbox như email production.

#### B. Home và note cards

- Title “Ghi chú của bạn”, số lượng nếu lấy từ dữ liệu thật; search nổi bật nhưng không chiếm cả đầu trang.
- View switch list/grid có selected state, tooltip và accessibility label. Sort mặc định đúng đề; tránh đưa 8 tùy chọn sort không cần thiết.
- Pinned group xuất hiện trước; thứ tự ghim theo policy hiện hành, không đổi thành sort trang trí.
- Note card gồm title, snippet ngắn nếu được phép đọc, labels giới hạn hợp lý, thời gian, status indicators và menu overflow. Attachment thumbnail chỉ khi có quyền, dữ liệu đã có và tải được.
- Shared/pinned/locked có thể xuất hiện cùng nhau. Trạng thái quyền và sync phân biệt được; không gom thành dấu chấm không giải thích.
- Card keyboard-focusable; click/tap mở note. Overflow không kích hoạt mở note; icon/menu reachable bằng keyboard, không chỉ xuất hiện qua hover trên touch.
- Empty state ban đầu: minh họa vector đơn giản + “Bắt đầu với ghi chú đầu tiên” + CTA tạo. Search rỗng: “Không tìm thấy ghi chú phù hợp” + xóa từ khóa/bộ lọc; không dùng cùng một thông điệp cho hai trường hợp.
- Loading ban đầu giữ cấu trúc. Khi nền đang sync mà đã có dữ liệu local, vẫn hiển thị dữ liệu và feedback nhẹ, không thay cả màn hình bằng spinner.

#### C. Editor: màn hình quan trọng nhất

- Create/edit cùng một editor. Vùng viết có hierarchy rõ: title, nhãn/thông tin phụ gọn, content thoáng, attachments ở vị trí dễ hiểu.
- App bar có Back, trạng thái lưu, actions có quyền; desktop có thể mở panel share/AI ở bên phải, mobile dùng sheet hoặc route phù hợp.
- Không thêm nút Save bắt buộc. Status phân biệt “Đang lưu…”, “Đã lưu trên thiết bị”, “Đang đồng bộ…”, “Đã đồng bộ”, “Chưa thể đồng bộ”. Chỉ dùng “Đã đồng bộ” khi có xác nhận từ server.
- Hiển thị failure có action “Thử lại”; lỗi quan trọng không biến mất sau snackbar ngắn. Local failure phải nói rõ chưa lưu, không tiếp tục giả an toàn.
- Toolbar gọn: labels, attachments, pin, share, lock và AI theo trạng thái hỗ trợ/quyền. Chỉ thêm rich-text toolbar khi đã có editor engine thực, không dựng nút Bold/heading vô tác dụng.
- Mobile keyboard không che caret, file actions hoặc error; SafeArea/insets đúng. Back xử lý local draft theo flow thật, không thêm modal “Lưu?” mỗi lần rời nếu auto-save đã an toàn.
- Read-only: nội dung vẫn đọc/select/copy được theo quyền, hiện “Chỉ xem”; các action quản trị không hiện như thể khả dụng. Chuyển viewer khi đang sửa phải xử lý nội dung pending theo policy bảo toàn có thật.
- Title dài/content dài/link dài không phá layout; editor không cắt nội dung bằng ellipsis.

#### D. Nhãn, tìm kiếm và bộ lọc

- Live search khoảng 300ms như logic hiện có; có clear; giữ query khi quay về. Không đổi thành phải bấm Search.
- Highlight match chỉ trên nội dung được phép đọc; không tiết lộ snippet note khóa.
- Multi-label selector dùng checkbox/chip, có search khi cần; empty state thêm nhãn. UI giải thích filter **khớp tất cả nhãn đã chọn** theo AND policy hiện hành.
- Label CRUD có validation tên trùng/rỗng; rename/delete phản ánh kết quả thật. Xóa label giải thích note vẫn còn; không biến thành xóa note hàng loạt.

#### E. Khóa note và privacy

- Note khóa hiển thị representation trung tính và action “Mở khóa”; không lấy nội dung thật rồi blur bằng UI. Không để tooltip, semantics, snapshot hoặc preview lộ nội dung chưa được phép đọc.
- Unlock dialog: tên an toàn phù hợp policy, field password, show/hide, lỗi sai mật khẩu, loading, rate-limit message nếu backend có. Không khẳng định “mã hóa đầu cuối” khi kiến trúc không có.
- Bật khóa nhập hai lần; đổi khóa xác minh cũ và nhập mới hai lần; tắt khóa xác minh mật khẩu hiện tại.
- Grant hết hạn/remote khóa/revoke: ngừng hiển thị nội dung theo policy thật, giữ recovery draft an toàn nếu đã triển khai. Không xóa draft vì đổi route để làm UI gọn hơn.
- Khi offline unlock chưa được hỗ trợ, giải thích cần kết nối và giữ dữ liệu an toàn; không fake unlock local bằng boolean.

#### F. Chia sẻ và cộng tác

- Share dialog/sheet có email input, chọn “Chỉ xem”/“Có thể chỉnh sửa”, action gửi/cấp quyền theo backend thật; người dùng hiểu quyền trước submit.
- Danh sách người nhận: avatar mặc định, display name/email, permission, menu đổi/thu hồi của owner; lỗi riêng cho duplicate/chưa có tài khoản.
- Shared-with-me có người chia sẻ, thời điểm chia sẻ và role badge; loading/empty/revoked đầy đủ.
- Avatar presence hoặc chữ “Đang chỉnh sửa” chỉ hiển thị khi có realtime presence thật; không tạo avatar ngẫu nhiên cho đẹp.
- Cập nhật realtime không kéo scroll/caret; badge báo thay đổi khi cần. Xung đột mở UI so sánh bản local/remote, dùng từ người dùng hiểu như “Có hai phiên bản thay đổi”, không yêu cầu hiểu revision/HTTP 409.
- Options conflict phải phản ánh cơ chế đã có: giữ bản của tôi dưới dạng bản sao hoặc dùng bản từ máy chủ; chỉ có “Hợp nhất” nếu thực sự hỗ trợ. Nêu hệ quả trước hành động gây bỏ một bản.

#### G. AI Summary và Hỏi ghi chú

- Summary nằm trong panel của note hoặc sheet trên mobile. Có scope “Tóm tắt ghi chú này”, loading, kết quả, “Tạo lại”, copy nếu hợp lý. Không tự chèn thay nội dung note.
- Q&A là workspace hỗ trợ tìm hiểu ghi chú, không chatbot chung. Header giải thích ngắn phạm vi nguồn được phép truy cập.
- Empty state có câu hỏi gợi ý phù hợp dữ liệu demo đánh dấu rõ trong preview; khi chạy thật không giả định có note môn học cụ thể.
- Answer dễ đọc, có source cards/chips tên note và action mở; nếu source đã bị khóa/thu hồi phải xử lý quyền hiện tại.
- Loading và cancel chỉ có nếu hỗ trợ thật; không giả typewriter/streaming như đang nhận token khi backend trả một lần.
- “Chưa tìm thấy đủ thông tin trong các ghi chú có thể truy cập” khi nguồn thiếu. AI unavailable/quota/network lỗi rõ ràng, cho retry khi hợp lý. Không tạo câu trả lời giả khi chưa có LLM key.
- AI UI không chiếm CTA chính của ứng dụng; người dùng vẫn ghi chép dễ dàng khi AI không khả dụng.

#### H. Hồ sơ/cài đặt và thông báo

- Profile: avatar/default, tên, email, verified status; edit có feedback, avatar validate/preview khi chức năng thật sẵn có.
- Settings chia nhóm Giao diện, Ghi chú, Tài khoản. Theme system/light/dark nếu logic hỗ trợ; font size có preview; preference lưu đúng, không làm mất editor state.
- Change password yêu cầu current + new + confirm; bố trí hợp lý khi bàn phím mở.
- Logout rõ ràng. Nếu có pending operations, thể hiện đúng chính sách dữ liệu thật và cảnh báo nguy cơ nếu có, không xóa silently hoặc hứa sync sau khi session đã hết.
- Toast/snackbar dùng cho phản hồi ngắn không quan trọng; persistent banners/inline status dùng cho lỗi cần hành động, offline, chưa verify. Không chồng nhiều banner cao chiếm phần lớn màn hình nhỏ.

### 7. State matrix và microcopy

Tạo bảng screen × state × trigger × message × action × backend dependency. Mỗi flow phù hợp phải có default, hover, focus, pressed, selected, disabled, loading, empty, validation error, server error, offline, retry, success và access denied; không bắt ép mọi state vào mọi widget.

Thứ tự nổi bật: rủi ro mất dữ liệu/quyền thay đổi > lỗi thao tác > offline/pending > thông tin. Offline không phải luôn là lỗi: nếu local save thành công, nói rõ có thể tiếp tục ghi.

Microcopy tiếng Việt thống nhất; UI dùng “ghi chú”, “nhãn”, “chỉ xem”, “có thể chỉnh sửa”, “đồng bộ”. Không lộ từ backend/outbox/Argon2/revision trong flow người dùng thường. Tài liệu kỹ thuật có thể dùng đúng thuật ngữ.

Ví dụ cần điều kiện đúng:

| Tình huống | Nội dung gợi ý |
|---|---|
| Local save thành công, đang offline | “Đã lưu trên thiết bị. Sẽ đồng bộ khi có kết nối.” |
| Server xác nhận | “Đã đồng bộ” |
| Ghi local thất bại | “Chưa lưu được thay đổi trên thiết bị. Vui lòng thử lại.” |
| Share revoked | “Bạn không còn quyền truy cập ghi chú này.” |
| Delete confirm | “Xóa ghi chú này?” kèm tên an toàn và hệ quả đúng cơ chế xóa |
| AI không đủ nguồn | “Chưa có đủ thông tin trong ghi chú để trả lời câu hỏi này.” |

Không dùng câu “An toàn tuyệt đối”, “Luôn được lưu”, “Mã hóa đầu cuối” hoặc “Đã gửi email” khi không có cơ sở. Error text ngắn, cụ thể, có cách phục hồi nếu có.

### 8. Accessibility và hiệu năng

- Mục tiêu contrast: text thường 4.5:1; chữ lớn 3:1; control/focus/graphic thiết yếu 3:1 theo điều kiện phù hợp. Đo thực tế, không tuyên bố đạt chỉ vì dùng Material.
- Text scale 100%, 150%, 200%; display scaling, bàn phím và screen reader không làm mất chức năng. Cho layout mở rộng thay vì clip.
- Focus order theo thứ tự đọc, focus indicator rõ. Dialog trap focus hợp lý, đóng xong trả focus về trigger. Dùng semantics label/role/selected state, loại decorative semantics và tránh đọc lặp.
- Status quan trọng được announce phù hợp nhưng không đọc lại từng lần gõ/auto-save. Không bỏ focus khỏi editor để đọc snackbar.
- Keyboard có Tab/Shift+Tab/Enter/Space/Escape; chọn shortcut không xung đột browser. Không chặn Ctrl+N/Ctrl+L hay shortcut hệ thống một cách tùy tiện. Nếu thêm shortcut, document và test thật.
- Long press/hover/right-click chỉ là cách phụ; hành động chính luôn có đường truy cập bằng touch và keyboard.
- Virtualize list dài; thumbnail bounded/cached đúng quyền; chia rebuild bằng ListenableBuilder/Selector tương đương với ChangeNotifier khi cần, không chuyển state library.
- Bundle font/assets phục vụ offline; kiểm tra asset manifest/offline worker sau build theo script dự án. Không cache nội dung private trong static worker.
- Đánh giá scroll/typing trên thiết bị thử thật; không hứa 60/120fps khi chưa profile. Tránh blur, nhiều shadow, animation đồng loạt và ảnh kích thước lớn không cần thiết.

### 9. Quy trình thực hiện

**Bước 1 — Audit:** đọc code/status, chạy app nếu môi trường cho phép; chụp baseline thật cho auth/home/editor/settings ở mobile và desktop. Ghi vấn đề theo mức ảnh hưởng: usability, visual, accessibility, state, regression risk. Không gọi nhận xét từ đọc code là đã quan sát giao diện.

**Bước 2 — Design spec:** viết `docs/UI_UX_DESIGN.md` gồm nguyên tắc, palette/tokens, typography, navigation, responsive, screen specs, state matrix và dependency gaps. Đưa ra một hướng thiết kế nhất quán theo brief; tự quyết lựa chọn đảo ngược được, không dừng xin duyệt từng màu/radius.

**Bước 3 — Vertical slice:** triển khai design system + app shell + home/card + editor trước để kiểm tra chất lượng thực. Theme/components dùng chung; giữ stable keys/test hooks cần thiết. Tạo component preview hoặc widget harness cho state chưa thể tái hiện bằng backend, tách khỏi production navigation và ghi rõ fixture.

**Bước 4 — Các flow còn lại:** auth/profile/settings/labels trước; lock/share/AI theo mức backend sẵn có. Thiết kế đầy đủ mọi flow trong spec nhưng không dùng placeholder clickable giả để tuyên bố hoàn tất. Không mở rộng thành rewrite backend ngoài phần tối thiểu cần nối contract được phép.

**Bước 5 — Verify và refine:** chụp/render kết quả thật, kiểm tra spacing/contrast/overflow, sửa rồi kiểm tra lại; không chỉ build pass. Ghi ít nhất một vòng so sánh trước/sau tại cùng kích thước cho màn hình chính.

**Bước 6 — Handoff:** cập nhật `docs/UI_UX_QA.md`, evidence và STATUS/matrix đúng phạm vi UI. README.md/Readme.txt đồng bộ nếu hành vi/lệnh/assets thay đổi; không làm mất lịch sử evidence cũ. Ghi component map và lý do quyết định để nhóm bảo vệ được.

### 10. Kiểm thử và nghiệm thu

Viewport đề xuất, ghi rõ logical dimensions, DPR/theme/font scale thực tế:

- 360×800 và 390×844: mobile portrait.
- 844×390: landscape, keyboard/insets khi có.
- 768×1024: tablet.
- 1280×800 và 1440×900: desktop Web.
- Light/dark trên màn hình chính; font scale 200% cho các flow trọng yếu.

Không bắt buộc screenshot mọi tổ hợp vô nghĩa; ưu tiên tổ hợp gây rủi ro. Resize trình duyệt chỉ chứng minh responsive Web, không thay nghiệm thu Android.

Kiểm tra thực:

1. Đăng ký/login lỗi và thành công; banner chưa verify không chặn thao tác.
2. Tạo/sửa note → auto-save → Back/reopen; đổi theme/resize trong lúc nhập không mất chữ, đổi note ID hoặc reset base revision.
3. Grid/list, pinned order, search/AND label filters, restore scroll và browser Back.
4. Delete confirm và cancel; menu touch/keyboard không mở nhầm note.
5. Offline và pending status, sync failure/retry, conflict và account switching; message phản ánh state thật.
6. Owner/viewer/editor/stranger: UI actions phù hợp, direct API vẫn enforce quyền. Chỉ claim các flow backend đã hỗ trợ; nếu sửa authorization-related binding phải chạy negative tests.
7. Note khóa không lộ content qua visual/semantics/tooltip; protected recovery chưa có thì ghi gap rõ.
8. Attachments/share/AI: nếu tích hợp được, test upload errors/role changes/source open; nếu chưa có, đánh dấu design-only/chưa nghiệm thu integration.
9. Keyboard navigation, focus restore, text scaling, long Vietnamese content, validation, empty/loading/error states.
10. Android emulator/device thật cho các flow đã claim; browser thật cho Web. Kiểm tra TalkBack hoặc screen reader thật nếu tuyên bố hỗ trợ đã nghiệm thu; semantics test không thay kiểm tra người dùng.

Chạy format/analyze/tests theo `scripts/check.ps1` và README, build bằng `scripts/build.ps1` khi cần verify artifact. Giữ test regression có ý nghĩa, bổ sung tests cho tương tác/focus/responsive/state rủi ro; không thêm tests chỉ kiểm tra màu/radius đúng bằng hằng số. Golden tests chỉ dùng khi môi trường/font ổn định, review ảnh baseline thật, không tự cập nhật để che lỗi.

Definition of Done của đợt UI:

- Hướng thị giác thống nhất trên màn hình đã triển khai, không còn pha trộn style cũ/mới ở các flow chính.
- Không overflow/clipped content/CTA bị che ở viewports đã kiểm tra; layout không dựa device name.
- Tương tác tạo/tìm/sửa note dễ hiểu, trạng thái lưu trung thực; không phá invariant dữ liệu.
- Light/dark, text scaling, keyboard/focus và semantic labels được kiểm tra trong phạm vi ghi rõ.
- Các chức năng chưa có backend không bị trình bày thành tính năng hoạt động; mock chỉ ở preview/test.
- Checks phù hợp pass; screenshot/test evidence thực có target, ngày, lệnh, kết quả, commit nếu có. Chưa có commit ghi “chưa có”.
- Matrix không chuyển toàn bộ rubric sang hoàn thành chỉ vì redesign xong; public deploy/video/production vẫn là gate riêng.

### 11. Đầu ra bàn giao

1. Flutter UI/code/assets đã cập nhật trên project hiện có, components/tokens tái sử dụng hợp lý.
2. `docs/UI_UX_DESIGN.md`: định hướng, spec màn hình, flow/state matrix, tokens và nguồn tham khảo.
3. `docs/UI_UX_QA.md`: test matrix, checks đã chạy, lỗi đã sửa, giới hạn và backend dependencies.
4. Ảnh trước/sau và ảnh mobile/desktop/light/dark tiêu biểu trong thư mục evidence theo ngày thực tế, không chứa thông tin riêng tư.
5. Trạng thái từng màn hình: designed / implemented / integrated / verified Web / verified Android; không gộp các mức này.
6. Bản tổng kết ngắn: điều gì cải thiện, cách kiểm tra, phần chưa đủ điều kiện, cách chạy/xem kết quả.

Hãy bắt đầu bằng audit và design spec, rồi triển khai vertical slice. Tự tiến hành những thay đổi UI đảo ngược được trong phạm vi đã cho; không dừng ở danh sách gợi ý chung. Khi gặp blocker dịch vụ, hoàn tất thiết kế/component preview được tách riêng và tiếp tục các màn hình có backend, báo đúng giới hạn.

### 12. Nguồn tham khảo chính thức

Các hướng dẫn dưới đây được tham khảo khi viết brief; bảng màu, breakpoints và bố cục cụ thể là đề xuất riêng cho NoteTogether, không phải tiêu chuẩn bắt buộc của môn:

- Material 3 / Expressive: https://m3.material.io/
- Flutter adaptive approach: https://docs.flutter.dev/ui/adaptive-responsive/general
- Flutter adaptive best practices: https://docs.flutter.dev/ui/adaptive-responsive/best-practices
- Flutter input & accessibility: https://docs.flutter.dev/ui/adaptive-responsive/input
- Flutter accessibility: https://docs.flutter.dev/ui/accessibility
- Flutter accessibility testing: https://docs.flutter.dev/ui/accessibility/accessibility-testing

Khi triển khai, xác minh API/package với SDK đang có; tham khảo nguyên tắc và pattern, không sao chép nguyên ứng dụng.

## KẾT THÚC PROMPT
