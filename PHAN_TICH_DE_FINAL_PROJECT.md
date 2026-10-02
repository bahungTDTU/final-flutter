# Phân tích đề cuối kỳ 503107

Nguồn chính: `C:/Users/LENOVO/Downloads/503107-FinalProject-V1.pdf`, 19 trang, Final Project Semester I/2026-2027. Đọc ngày 01/10/2026. Số trang dưới đây là số trang PDF. Tài liệu này phân biệt yêu cầu của đề với đề xuất triển khai; không phải báo cáo đã hoàn thành sản phẩm.

## 1. Kết luận về phạm vi

Đề tài đã được ấn định: **ứng dụng quản lý ghi chú đa nền tảng**, có tài khoản, nhãn, đính kèm, khóa từng ghi chú, chia sẻ/phân quyền, cộng tác thời gian thực, tóm tắt AI và hỏi đáp dựa trên ghi chú. Không chọn một ứng dụng khác rồi thêm vài chức năng ghi chú.

Client bắt buộc Flutter + Dart. Web và native phải sinh từ **cùng một Flutter project, dùng chung core Dart**. Backend được tự chọn. Tối thiểu phải có Web công khai và một bản native: Android APK release, gói Windows đầy đủ hoặc ZIP macOS .app (tr. 1, 6, 8, 14, 17).

Đây là đề full-stack: CRUD có giao diện đẹp chưa đủ. Phân quyền backend, dữ liệu offline, xử lý xung đột, triển khai công khai và bằng chứng kiểm thử đều nằm trong phạm vi chấm.

## 2. Cơ cấu điểm và 32 tiêu chí

| Nhóm | ID | Điểm |
|---|---|---:|
| Quản lý tài khoản | 1–8 | 2.0 |
| Quản lý ghi chú cơ bản | 9–22 | 3.5 |
| Quản lý ghi chú nâng cao | 23–28 | 2.5 |
| UI, kiến trúc/test, offline, triển khai | 29–32 | 2.0 |
| **Tổng** | **32 tiêu chí** | **10.0** |

Rubric gốc ở tr. 9–14. Không có/hoàn toàn sai: 0; chưa đầy đủ hoặc thiếu ổn định: 25–75% điểm tiêu chí; đúng trên các nền tảng nộp và không có lỗi đáng kể: đủ điểm. Đây là mức đánh giá, không phải điểm được bảo đảm.

| ID | Tiêu chí | Điểm | Bằng chứng nghiệm thu cần có |
|---:|---|---:|---|
| 1 | Đăng ký | 0.25 | Email, tên hiển thị, mật khẩu và xác nhận; tự đăng nhập sau thành công |
| 2 | Kích hoạt tài khoản | 0.25 | Email/link hoặc cơ chế tương đương; banner tồn tại đến khi xác minh |
| 3 | Đăng nhập/đăng xuất | 0.25 | Guard màn hình riêng tư; về home cá nhân; logout cô lập dữ liệu |
| 4 | Quên/reset mật khẩu | 0.25 | Email link/OTP; reset xong phải đăng nhập thủ công |
| 5 | Xem hồ sơ/avatar | 0.25 | Hiển thị hồ sơ đúng, có avatar mặc định |
| 6 | Sửa hồ sơ/avatar | 0.25 | Validate tệp, lưu tên/avatar nhất quán giữa nền tảng |
| 7 | Đổi mật khẩu | 0.25 | Mật khẩu hiện tại, mật khẩu mới hai lần, xử lý session an toàn |
| 8 | Tùy chỉnh người dùng | 0.25 | Lưu và áp dụng lại tùy chọn khi mở ứng dụng |
| 9 | List view | 0.25 | Hoạt động trên nhiều kích thước màn hình |
| 10 | Grid view | 0.25 | Mặc định là grid; nhớ lựa chọn list/grid |
| 11 | Tạo ghi chú | 0.25 | Chỉ title/content là trường nhập bắt buộc ban đầu |
| 12 | Sửa ghi chú | 0.25 | Tái sử dụng cùng màn hình/editor với tạo mới |
| 13 | Xóa ghi chú | 0.25 | Luôn có xác nhận trước khi xóa |
| 14 | Auto-save/lifecycle | 0.25 | Saving/saved/failure; giữ thay đổi hợp lệ khi pause/reopen |
| 15 | Đính kèm ảnh/video | 0.25 | Nhiều tệp, validate, xử lý hủy/từ chối quyền |
| 16 | Đính kèm tệp | 0.25 | Upload/open đúng; người không có quyền không tải được |
| 17 | Ghim và sắp xếp | 0.25 | Mới trước; ghim trước; nhiều ghim theo thời điểm ghim nhất quán |
| 18 | Chỉ báo trạng thái | 0.25 | Shared/pinned/locked đồng thời trên list và grid |
| 19 | Live search | 0.25 | Tìm trong title hoặc content khi gõ; không cần nút Search |
| 20 | Quản lý nhãn | 0.25 | Liệt kê/thêm/đổi tên/xóa; xóa nhãn không xóa ghi chú |
| 21 | Gắn nhãn | 0.25 | Một ghi chú có 0, 1 hoặc nhiều nhãn |
| 22 | Lọc nhãn | 0.25 | Lọc theo nhãn chọn; hành vi nhiều nhãn được định nghĩa |
| 23 | Bật/tắt khóa ghi chú | 0.5 | Mật khẩu riêng từng note; backend thực thi; tắt khóa xác thực lại |
| 24 | Mở khóa/đổi mật khẩu note | 0.5 | Kiểm tra mật khẩu cũ, xác nhận mật khẩu mới; không lưu plaintext |
| 25 | Chia sẻ/nhận/quản lý quyền | 0.5 | Email đã đăng ký; viewer/editor; chủ sở hữu đổi/thu hồi được |
| 26 | Cộng tác thời gian thực | 0.5 | Hai người thấy cập nhật không reload; viewer bị chặn ghi cả ở API |
| 27 | AI Summary | 0.25 | LLM tóm tắt, tạo lại; không tự ghi đè nội dung gốc |
| 28 | AI Q&A có nguồn | 0.25 | Truy xuất đúng quyền, tổng hợp bằng LLM, nguồn mở được; thiếu dữ liệu phải nói rõ |
| 29 | UI/UX/accessibility/adaptive | 0.5 | Loading/empty/error, responsive, touch/mouse/keyboard, khả năng tiếp cận |
| 30 | Kiến trúc/state/test | 0.5 | Một Flutter project; phân lớp; ≥3 unit, ≥3 widget, ≥1 integration có ý nghĩa |
| 31 | Offline/sync | 0.5 | Đọc dữ liệu đã tải, tạo/sửa offline, sync lại, trạng thái, cô lập tài khoản, xử lý conflict |
| 32 | Build và deploy | 0.5 | Web HTTPS + backend công khai + native release hợp lệ; build tái lập được |

## 3. Các yêu cầu dễ hiểu sai

1. **Chưa xác minh email vẫn được sử dụng tất cả chức năng**; chỉ hiện cảnh báo nổi bật, liên tục. Không dùng email verification làm điều kiện khóa toàn app (tr. 2).
2. Reset mật khẩu xong **không tự đăng nhập**. Luồng kích hoạt/reset đều phải hoạt động cho Web và native (tr. 2–3).
3. Auto-save phải xử lý vòng đời và lỗi; debounce đơn thuần chưa bảo đảm không mất thay đổi. Không dựa vào một request chạy lúc đóng tab (tr. 3).
4. Password của note độc lập với password tài khoản. Khi note khóa, phải mở khóa trước xem, sửa, xóa, share, summary và truy cập nội dung bằng các đường khác; khóa UI chưa đủ (tr. 4, 7).
5. File đính kèm phải kế thừa quyền của note. Link public có thể làm vô hiệu toàn bộ cơ chế khóa/chia sẻ (tr. 3–4).
6. Realtime chỉ đưa dữ liệu mới về chưa giải quyết việc hai người ghi đè nhau. Đề yêu cầu có chiến lược xung đột offline hợp lý; không mặc định mất dữ liệu là chấp nhận được (tr. 6, 8).
7. Q&A không phải chatbot chung hoặc danh sách kết quả keyword. Phải truy xuất nội dung liên quan được phép đọc, dùng LLM tổng hợp và trỏ về note nguồn. Note khóa chỉ dùng sau khi người hỏi mở khóa rõ ràng (tr. 5).
8. Offline phải có trên **cả hai nền tảng nộp**, không chỉ Android; khi đổi tài khoản không lộ cache của người trước (tr. 6).
9. Số test 3+3+1 chỉ là mức tối thiểu; test giả hoặc không kiểm tra hành vi dự án không được tính (tr. 6, 14).
10. Docker/local demo không thay thế Web và backend công khai; build native thành công chưa chứng minh các tính năng bắt buộc hoạt động (tr. 6).

## 4. Các điều kiện có thể quyết định kết quả nộp bài

### Điểm 0 hoặc không được chấm

- Thiếu source, video, Rubric.xlsx, public Flutter Web URL hoặc native release bắt buộc: cả nhóm 0 điểm (tr. 18).
- Lệch đề; tách thành các ứng dụng thay thế độc lập cho Web/native; dùng lại gần như toàn bộ ứng dụng có sẵn và chỉ thêm ít tính năng: không chấm, 0 điểm (tr. 19).
- Đề còn có quy định xử lý sao chép code giữa nhóm/nguồn khác (tr. 19).

### Video là một phần của bằng chứng chức năng

- `demo.mp4`, tối thiểu 1080p, âm thanh rõ, có tất cả thành viên.
- Giới thiệu kiến trúc Flutter, state management, backend, local persistence và nền tảng.
- Demo mọi tiêu chí đã triển khai trong 32 tiêu chí, mỗi tiêu chí ít nhất một nền tảng.
- Demo thêm trên **cả Web và native**: login; tạo và sửa note; attachments; offline sync; sharing hoặc realtime; ít nhất một AI feature.
- **Tiêu chí không xuất hiện trong video bị coi là chưa triển khai**, dù tự đánh giá có làm. Video quá lớn có thể đưa lên YouTube và nộp link (tr. 18).

### GitHub và đóng góp

- Cần 4 tuần lịch liên tiếp, từ thứ Hai đến Chủ nhật, trong thời gian làm dự án chính thức.
- **Mỗi thành viên, mỗi tuần, ít nhất 2 commit có ý nghĩa**, đã push và có trong lịch sử nộp. Không bù tuần, không bù người. Thiếu một commit ở một người/tuần cũng khiến nhóm không đạt, bị trừ 0.5.
- Ít nhất 8 commit/người qua 4 tuần là điều kiện cần, nhưng tổng 8 commit dồn một tuần không đạt.
- Commit phải phản ánh đóng góp thật; không đổi tác giả, lùi ngày hoặc chia vụn công việc để tạo số lượng.
- Dùng screenshot **GitHub Insights**, không thay bằng terminal/git log. Repo private phải cho giảng viên quyền đọc tới hết chấm.
- Source clone từ GitHub và giữ `.git`, kiểm tra cả sau giải nén. Không dùng GitHub Download ZIP thay cho clone (tr. 14–16).
- Tr. 16 cho phép nhóm không đạt yêu cầu teamwork bỏ bằng chứng Git và nhận trừ 0.5, trong khi mục output tr. 17 vẫn mô tả source có `.git`. Để tránh vướng cách diễn giải, nên luôn giữ `.git`; chỉ hỏi giảng viên nếu nhóm định áp dụng ngoại lệ này.

### Các khoản trừ khác (tr. 19)

| Tình huống | Mức trừ ghi trong đề |
|---|---:|
| Trễ từ 1 giây đến dưới 1 ngày được tính 1 ngày | 1 điểm/ngày |
| Cấu hình phức tạp, hướng dẫn không đủ/không đúng để chạy | 2 điểm |
| Không dọn build/cache/tệp thừa | 0.5 điểm |
| Thiếu thông tin chấm, URL không truy cập được, artifact sai, tên sai… | 1.0 điểm |

Không hiểu các khoản trừ này là thay thế cho điều kiện 0 điểm khi thiếu thành phần bắt buộc.

## 5. Chiến lược triển khai đề xuất

**Đề xuất, không phải yêu cầu của đề:** chọn Flutter Web + Android APK; làm một app ghi chú vừa đủ hoàn chỉnh, ưu tiên toàn bộ rubric trước tính năng ngoài đề. Không cần rich text phức tạp, OCR, thanh toán, social feed hoặc chatbot Internet.

Chốt backend sau một thử nghiệm kỹ thuật nhỏ về: email lifecycle, khóa note thực sự ở backend, offline trên Web/Android, quyền realtime và triển khai. Firebase là một ứng viên để đánh giá, không phải lựa chọn đã được kiểm chứng cho dự án này. Tài liệu Firebase có API quản lý người dùng/xác minh email; Firestore có offline persistence nhưng mặc định xử lý nhiều thay đổi cùng document theo last-write-wins. Do đó không coi bật cache là hoàn thành offline, khóa note và xử lý conflict.

Nguồn kỹ thuật chính thức đã đối chiếu ngày 01/10/2026:
- [Firebase Flutter: Manage users](https://firebase.google.com/docs/auth/flutter/manage-users)
- [Firestore: Access data offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline)

Với nhóm có kinh nghiệm SQL/backend, backend riêng cũng có thể phù hợp, nhưng phải tự chịu trách nhiệm auth, email, WebSocket, storage, sync và vận hành. Chưa có thông tin nhóm/ngân sách nên không kết luận một stack là tối ưu. Agent phải kiểm tra tài liệu chính thức hiện hành, chi phí và tương thích trước khi khóa lựa chọn.

### Thứ tự công việc

| Mốc | Sản phẩm kiểm chứng được |
|---|---|
| M0 | Ma trận 32 tiêu chí, kiến trúc, rủi ro; chạy skeleton Web/native; spike các rủi ro |
| M1 | Auth, hồ sơ, settings; email activation/reset được thử hai nền tảng |
| M2 | CRUD cùng editor, auto-save, grid/list, nhãn, search, pin; local persistence từ đầu |
| M3 | Sync/conflict + khóa note và attachments có phân quyền |
| M4 | Chia sẻ, đổi/thu hồi quyền, realtime; test API âm tính với nhiều tài khoản |
| M5 | Summary/Q&A có nguồn; kiểm tra không lộ note khóa hoặc bị thu hồi |
| M6 | Adaptive UX, kiểm thử tổng hợp, public deploy và native release |
| M7 | Video đủ 32 mục, Readme.txt, Rubric.xlsx thật, Insights, clone sạch và ZIP nộp |

Các mốc là thứ tự phụ thuộc, không phải cam kết thời gian. Deploy thử phải làm sớm, không đợi M6 mới phát hiện hosting/package không tương thích. Chưa có deadline/ngày bắt đầu chính thức, số thành viên, ngân sách hoặc quy định AI cụ thể để lập lịch thật.

## 6. Cấu trúc bộ nộp cần đạt

```text
id1_fullname1_id2_fullname2/
  Rubric.xlsx                  # Mẫu giảng viên cung cấp, đánh giá trung thực
  Readme.txt
  demo.mp4                     # Hoặc link YouTube theo phương án được đề cho phép
  Screenshot.png               # GitHub Insights nếu tuyên bố đạt teamwork
  source/
    .git/                      # Giữ lịch sử, clone thật, không giả bằng git init
    pubspec.yaml
    pubspec.lock
    lib/ test/ integration_test/
    android/ web/ ...
    ... backend/rules/migrations/config/scripts cần thiết
  release/
    web-url.txt
    app-release.apk            # Nếu chọn Android; hoặc gói Windows/macOS hợp lệ
```

Tên thư mục minh họa theo đề, phải điều chỉnh bằng MSSV/họ tên thật. Không đưa secret vào Git hoặc ZIP. Thông tin tài khoản demo phục vụ chấm phải cung cấp bằng tài khoản riêng, không dùng tài khoản cá nhân/quản trị. Dọn cache/build tái tạo được trong source, nhưng giữ native release và `.git` theo yêu cầu.

## 7. Dùng agent thế nào cho phù hợp

Đề không đưa ra một lệnh cấm tuyệt đối mọi hỗ trợ AI: tr. 17 đề cập việc dùng AI vi phạm quy định môn, tr. 19 yêu cầu nhóm chịu trách nhiệm và giải thích code có AI hỗ trợ. Không từ đó suy ra được phép giao toàn bộ bài cho agent. Cần đối chiếu quy định cụ thể của giảng viên; prompt kèm theo yêu cầu giải thích, nghiệm thu từng mốc và phân công thật, không tạo bằng chứng đóng góp giả.

Prompt triển khai đầy đủ nằm trong `PROMPT_CHO_AGENT.md`. Prompt không tuyên bố đã build/test/deploy và không tự chọn deadline hay nhóm hai người từ ví dụ tên ZIP.
