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
      title: const DialogHeading('Đổi mật khẩu', icon: Icons.password_outlined),
      content: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sau khi đổi mật khẩu, hãy đăng nhập lại. Thay đổi đã lưu trên thiết bị giữ trong tài khoản này.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: current,
                obscureText: !visible,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nhập mật khẩu hiện tại' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: next,
                obscureText: !visible,
                enabled: !busy,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                validator: (v) => v == null || v.length < 10 || v.length > 128
                    ? 'Mật khẩu từ 10 đến 128 ký tự'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirm,
                obscureText: !visible,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Nhập lại mật khẩu mới',
                ),
                validator: (v) =>
                    v != next.text ? 'Hai mật khẩu chưa khớp' : null,
                onFieldSubmitted: (_) => submit(),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hiện mật khẩu'),
                value: visible,
                onChanged: busy
                    ? null
                    : (value) => setState(() => visible = value!),
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: busy ? null : submit,
          child: Text(busy ? 'Đang xử lý…' : 'Đổi mật khẩu'),
        ),
      ],
    ),
  );
}
