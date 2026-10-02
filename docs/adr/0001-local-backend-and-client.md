# ADR 0001: Flutter + FastAPI cho nền tảng local

Status: accepted cho local; cần đánh giá lại hosting khi nhóm chọn ngân sách/cloud.
Ngày: 01/10/2026. Flutter Web + Android là target hiện tại.

| Khía cạnh | Managed: Firebase | Custom: FastAPI + SQLite |
|---|---|---|
| Auth/email | SDK hỗ trợ email verification/reset; cần project/config | Tự xây session/token; SMTP thật chưa cấu hình |
| Khóa note | Cần privileged function/grant và ngăn cache content | Một policy server cho read/write/share/sync |
| ACL/files/realtime | Rules + storage + listeners; cần test rule/privileged bypass | ACL đã có spike; files/subscriptions chưa làm |
| Offline/conflict | Firestore cache có last-write-wins; vẫn cần chiến lược riêng | Sembast/outbox/revision được thiết kế từ đầu |
| Search/AI | Function/server + authorization trước retrieval | Endpoint backend + authorized retrieval; chưa có LLM |
| Chi phí | Cần xác minh plan/region/billing, không hứa miễn phí | Cần HTTPS, persistent disk, SMTP/LLM và backup; không hứa miễn phí |
| Vận hành/hiểu code | Ít server ops, rules/function cần nhóm hiểu | Nhiều trách nhiệm security/ops, policy SQL dễ test trực tiếp |

Chọn custom cho local vì chưa có cloud account và có thể kiểm chứng ACL/revision ngay.
Đây không phải kết luận Firebase không làm được yêu cầu. Không khóa nhà cung cấp hosting.
State management: ChangeNotifier, một controller; tách UI, business/domain và sources.
SQLite serialize mutations để quyền không bị race với update. Public deployment sẽ cần
backup, monitoring, abuse limits, SMTP outbox worker, review session storage, persistent volume,
HTTPS và đánh giá concurrency. Multi-instance chưa được hỗ trợ.

Nguồn đối chiếu ngày 01/10/2026:
- https://firebase.google.com/docs/auth/flutter/start
- https://firebase.google.com/docs/firestore/manage-data/enable-offline
- https://fastapi.tiangolo.com/deployment/docker/
- https://pub.dev/packages/sembast_web
- https://pub.dev/packages/path_provider

Spikes auth/ACL/grants/revision: backend tests. Web/Android actual results xem STATUS và evidence;
không suy ra feature parity từ package metadata hoặc build pass.
