# Deploy NoteTogether Web lên Azure

Một VM Ubuntu chạy Caddy và FastAPI qua Docker Compose. Caddy lấy chứng chỉ
HTTPS cho tên DNS công khai của Azure, phục vụ Flutter ở `/` và chuyển các
đường dẫn API sang FastAPI. Web dùng chính origin này làm `API_URL`. SQLite,
tệp đính kèm và khóa hàng đợi mail ở volume `backend-state`. Chứng chỉ ở
volume `tls-data`. Compose dùng project name `notetogether` cố định khi cập nhật.

## Chuẩn bị VM

- Trong subscription **Azure for Students**, chọn VM Ubuntu 24.04 cỡ nhỏ trong
  hạn mức tín dụng, ổ đĩa OS lưu bền, IP công khai và một DNS name label.
  Giữ spending limit. Tên DNS phải trỏ tới VM và các cổng TCP 80, 443 phải
  đến được Caddy để cấp chứng chỉ. Backend cổng 8000 chỉ bind loopback.
- Cài Docker Engine và Compose v2.33.1 trở lên để hỗ trợ `up --wait` và
  mạng riêng cho kết nối IPv6. Tài khoản SSH dành cho
  môi trường deploy cần chạy được `docker compose` và có Python 3, curl, tar,
  flock. Mở SSH cho runner triển khai và dùng đăng nhập bằng khóa. Lấy khóa
  host SSH từ VM qua kênh Azure xác thực để ghim trong GitHub.
  Nếu tạo VM với user `notedeploy`, dùng `deploy/azure/cloud-init.yml`
  làm custom data để chuẩn bị các gói này trong lần boot đầu.
- Tạo `~/.config/notetogether/backend.env` trên VM bằng mẫu `.env.example`.
  Đặt quyền đọc cho chủ file. Điền `SMTP_USERNAME`, `SMTP_PASSWORD` và
  `GEMINI_API_KEY` trực tiếp ở VM. Compose thiết lập sẵn origin và đường
  dẫn dữ liệu. Bản chấm mới khởi động với database riêng.

Nếu Gemini trả lỗi vị trí với IPv4, kiểm tra một yêu cầu mẫu trực tiếp qua
IPv6 của VM trước khi đặt `GEMINI_IPV6=1` trong `backend.env`. Backend Azure
có thêm mạng Docker chỉ IPv6 cho kết nối này. Cờ chỉ tác động đến Gemini
và giữ kết nối trực tiếp tới API Google.

## Kết nối GitHub Actions

Tạo environment `azure-production`, giới hạn deployment vào `master`. Điền
các tên dưới đây trong Settings của repository.

| Loại | Tên | Giá trị |
|---|---|---|
| Repository variable | `AZURE_DEPLOY_HOST` | FQDN của VM, chỉ hostname |
| Repository variable | `AZURE_DEPLOY_USER` | Tài khoản SSH deploy |
| Environment secret | `AZURE_DEPLOY_SSH_KEY` | Private key riêng của CI |
| Environment secret | `AZURE_DEPLOY_KNOWN_HOSTS` | Một dòng `hostname ssh-ed25519 …` đã xác minh qua Azure |

Workflow **Deploy Web to Azure** chạy sau một lượt **Quality** thành công
trên push vào `master`. Cũng có thể chạy thủ công từ `master` khi cần chạy
lại. GitHub cần workflow nằm trên nhánh mặc định để hiện nút chạy thủ công.
Runner nén bộ Web đã build và các file backend cần thiết. VM cài phiên bản
mới rồi đối chiếu commit qua HTTPS và kiểm tra `/health`. Khi bước kiểm tra
thất bại và có bản đang chạy, script khởi động lại dịch vụ từ bản trước.

## Nghiệm thu URL công khai

Từ mạng khác, mở trang HTTPS và kiểm tra `/health`. Dùng tài khoản mẫu để
thử lưu và tải lại note, upload/download tệp, OTP nhận qua Gmail, cập nhật
realtime giữa hai trình duyệt, AI Summary và Q&A có nguồn. Kiểm tra offline
sau lần tải online thành công. Sau khi khởi động lại VM, xác nhận dữ liệu
cũ và chứng chỉ vẫn hoạt động. Sao lưu SQLite và khóa mail cùng nhau trước
khi triển khai thay đổi schema. [Hướng dẫn sao lưu](RELEASE_AND_BACKUP.md).

## Kiểm tra cấu hình ngày 20/11/2026

Trên base `e88535a`, đã build Web release với API origin HTTPS kiểm thử.
`deploy/azure/package.sh` tạo archive 80 mục và offline manifest 42 tài nguyên.
Archive chứa Web và mã backend, cùng marker revision trả về qua HTTPS khi
triển khai. Kiểm tra archive xác nhận phần SQLite và cấu hình private ở ngoài.
`docker compose … config --quiet`, `bash -n` và kiểm tra service worker chạy đạt.
Ca same-origin xác nhận API không đi qua cache/offline fallback của Web.
