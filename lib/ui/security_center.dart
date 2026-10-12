import 'dart:async';

import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../state/security_session.dart';
import 'design_system.dart';

String sessionDate(DateTime value) {
  final d = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} · ${two(d.hour)}:${two(d.minute)}';
}

class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends State<SecurityCenterScreen> {
  late final session = SecuritySession(widget.controller);
  @override
  void initState() {
    super.initState();
    unawaited(session.refresh());
  }

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  Future<void> confirm({String? id}) async {
    if (!session.canManage) return;
    session.clearMessage();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RevokeDialog(session: session, id: id),
    );
  }

  Widget bounded(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: child,
    ),
  );

  Widget card(AccountSession s, int index, bool wide) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(s.label, style: Theme.of(context).textTheme.titleMedium),
            if (s.current)
              const MetadataPill(
                'Phiên này',
                icon: Icons.verified_user_outlined,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          s.createdAt == null
              ? 'Đăng nhập: trước khi nâng cấp'
              : 'Đăng nhập: ${sessionDate(s.createdAt!)}',
        ),
        const SizedBox(height: 4),
        Text(
          'Hết hạn: ${sessionDate(s.expiresAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
    final action = s.current
        ? const Text('Đang dùng')
        : OutlinedButton.icon(
            key: ValueKey('revoke-${s.id}'),
            onPressed: session.canManage ? () => confirm(id: s.id) : null,
            icon: const Icon(Icons.logout, size: 18),
            label: Text('Thu hồi phiên ${index + 1}'),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: bounded(
        SurfacePanel(
          padding: const EdgeInsets.all(20),
          child: wide
              ? Row(
                  children: [
                    Expanded(child: text),
                    const SizedBox(width: 24),
                    action,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [text, const SizedBox(height: 16), action],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) {
      final wide =
          MediaQuery.sizeOf(context).width >= 900 &&
          MediaQuery.textScalerOf(context).scale(1) < 1.5;
      return Scaffold(
        appBar: noteAppBar(
          title: const Text(
            'Trung tâm bảo mật',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
              ),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: bounded(
                      PrismReveal(
                        duration: PrismMotion.section,
                        child: SurfacePanel(
                          tinted: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const PageIntro(
                                title: 'Bạn kiểm soát phiên đăng nhập',
                                icon: Icons.shield_outlined,
                                detail: 'Xem các phiên đang hoạt động và kết thúc phiên bạn không còn sử dụng.',
                                eyebrow: 'TRUNG TÂM BẢO MẬT',
                                panel: false,
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  MetadataPill(
                                    session.validated
                                        ? '${session.total} phiên hoạt động'
                                        : 'Cần kết nối máy chủ',
                                    icon: Icons.devices,
                                  ),
                                  const MetadataPill(
                                    'Xác nhận bằng mật khẩu',
                                    icon: Icons.password_outlined,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tên trình duyệt chỉ mang tính tham khảo. Thu hồi phiên không xóa dữ liệu đã lưu trên thiết bị khác.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: bounded(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: session.active && !session.busy
                                      ? session.refresh
                                      : null,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Tải lại phiên'),
                                ),
                                FilledButton.icon(
                                  onPressed:
                                      session.canManage &&
                                          session.otherCount > 0
                                      ? () => confirm()
                                      : null,
                                  icon: const Icon(Icons.phonelink_erase),
                                  label: const Text('Thu hồi các phiên khác'),
                                ),
                              ],
                            ),
                            if (session.busy)
                              const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: LinearProgressIndicator(),
                              ),
                            if (session.message != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: StatusNotice(
                                  icon: Icons.info_outline,
                                  message: session.message!,
                                ),
                              ),
                            if (session.validated &&
                                session.total > session.limit)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  'Đang hiển thị ${session.limit} phiên. Thu hồi các phiên khác áp dụng cho toàn bộ tài khoản.',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (session.active && session.validated)
                    SliverList.builder(
                      itemCount: session.sessions.length,
                      itemBuilder: (_, i) => card(session.sessions[i], i, wide),
                    )
                  else if (!session.busy)
                    SliverToBoxAdapter(
                      child: bounded(
                        const SurfacePanel(
                          child: Text(
                            'Thông tin phiên chỉ hiển thị khi đã kết nối và xác thực.',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _RevokeDialog extends StatefulWidget {
  const _RevokeDialog({required this.session, this.id});
  final SecuritySession session;
  final String? id;
  @override
  State<_RevokeDialog> createState() => _RevokeDialogState();
}

class _RevokeDialogState extends State<_RevokeDialog> {
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool show = false;
  @override
  void initState() {
    super.initState();
    widget.session.addListener(checkGate);
  }

  void checkGate() {
    if (!widget.session.active) {
      password.clear();
      show = false;
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(checkGate);
    password.clear();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!widget.session.canManage || form.currentState?.validate() != true) {
      return;
    }
    final ok = await widget.session.revoke(password.text, id: widget.id);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      final s = widget.session;
      return PopScope(
        canPop: !s.busy,
        child: AlertDialog(
          scrollable: true,
          title: const DialogHeading(
            'Xác nhận thu hồi phiên',
            icon: Icons.shield_outlined,
          ),
          content: !s.active
              ? const Text('Phiên đã đóng hoặc ứng dụng đang ở nền.')
              : SizedBox(
                  width: 440,
                  child: Form(
                    key: form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.id == null
                              ? 'Các phiên khác sẽ cần đăng nhập lại. Phiên hiện tại được giữ nguyên.'
                              : 'Phiên được chọn sẽ cần đăng nhập lại.',
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: password,
                          enabled: !s.busy,
                          obscureText: !show,
                          maxLength: 128,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu tài khoản',
                            suffixIcon: IconButton(
                              tooltip: show ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                              onPressed: s.busy
                                  ? null
                                  : () => setState(() => show = !show),
                              icon: Icon(
                                show
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Nhập mật khẩu tài khoản để xác nhận.'
                              : null,
                          onFieldSubmitted: (_) => submit(),
                        ),
                        if (s.message != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(s.message!),
                          ),
                      ],
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: s.busy ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: s.active && !s.busy && s.validated ? submit : null,
              child: Text(s.busy ? 'Đang thu hồi…' : 'Xác nhận thu hồi'),
            ),
          ],
        ),
      );
    },
  );
}
