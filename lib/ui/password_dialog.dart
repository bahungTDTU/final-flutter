import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'app.dart';
import 'design_system.dart';

class PasswordChangeDialog extends StatefulWidget {
  const PasswordChangeDialog({super.key, required this.controller});
  final AppController controller;
  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  final form = GlobalKey<FormState>();
  final current = TextEditingController(),
      next = TextEditingController(),
      confirm = TextEditingController();
  bool busy = false, visible = false;
  String? error;
  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.controller.api.call(
        'POST',
        '/auth/password',
        token: widget.controller.token,
        body: {
          'current_password': current.text,
          'password': next.text,
          'confirmation': confirm.text,
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      await widget.controller.logout();
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: DialogHeading(
        context.tr("Đổi mật khẩu"),
        icon: Icons.password_outlined,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr(
                  "Sau khi đổi mật khẩu, hãy đăng nhập lại. Thay đổi đã lưu trên thiết bị giữ trong tài khoản này.",
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                errorBuilder: (context, message) =>
                    Text(context.trMessage(message)),
                controller: current,
                obscureText: !visible,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: context.tr("Mật khẩu hiện tại"),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? context.tr("Nhập mật khẩu hiện tại")
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                errorBuilder: (context, message) =>
                    Text(context.trMessage(message)),
                controller: next,
                obscureText: !visible,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: context.tr("Mật khẩu mới"),
                ),
                validator: (v) => v == null || v.length < 10 || v.length > 128
                    ? context.tr("Mật khẩu từ 10 đến 128 ký tự")
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                errorBuilder: (context, message) =>
                    Text(context.trMessage(message)),
                controller: confirm,
                obscureText: !visible,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: context.tr("Nhập lại mật khẩu mới"),
                ),
                validator: (v) => v != next.text
                    ? context.tr("Hai mật khẩu chưa khớp")
                    : null,
                onFieldSubmitted: (_) => submit(),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr("Hiện mật khẩu")),
                value: visible,
                onChanged: busy
                    ? null
                    : (value) => setState(() => visible = value!),
              ),
              if (error != null)
                Text(
                  context.trMessage(error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: Text(context.tr("Hủy")),
        ),
        FilledButton(
          onPressed: busy ? null : submit,
          child: Text(
            busy ? context.tr("Đang xử lý…") : context.tr("Đổi mật khẩu"),
          ),
        ),
      ],
    ),
  );
}
