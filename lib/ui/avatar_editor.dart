import 'package:flutter/material.dart';

import '../data/avatar_picker.dart';
import '../state/app_controller.dart';
import 'app.dart';
import 'design_system.dart';

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, required this.controller, this.radius = 20});
  final AppController controller;
  final double radius;
  @override
  Widget build(BuildContext context) => Semantics(
    label: controller.avatarBytes == null
        ? 'Ảnh đại diện mặc định'
        : 'Ảnh đại diện của bạn',
    image: true,
    child: CircleAvatar(
      radius: radius,
      backgroundImage: controller.avatarBytes == null
          ? null
          : MemoryImage(controller.avatarBytes!),
      child: controller.avatarBytes == null
          ? Text(
              (controller.user?['name'] as String? ?? '?')
                      .characters
                      .firstOrNull ??
                  '?',
            )
          : null,
    ),
  );
}

class AvatarEditor extends StatefulWidget {
  const AvatarEditor({
    super.key,
    required this.controller,
    this.picker = pickAvatar,
  });
  final AppController controller;
  final Future<SelectedAvatar?> Function() picker;
  @override
  State<AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends State<AvatarEditor> {
  SelectedAvatar? selected;
  bool busy = false;
  String? message;
  late final account = widget.controller.user?['id'];
  late final sessionToken = widget.controller.token;
  AppController get c => widget.controller;
  bool get active => c.user?['id'] == account && c.token == sessionToken;

  Future<void> choose() async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final file = await widget.picker();
      if (mounted && active && file != null) {
        if (file.bytes.isEmpty || file.bytes.length > 2 * 1024 * 1024) {
          throw ArgumentError('Chọn ảnh tối đa 2 MiB');
        }
        avatarContentType(file.bytes);
        setState(() => selected = file);
      }
    } on ArgumentError catch (e) {
      if (mounted) setState(() => message = e.message.toString());
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'Không mở được ảnh. Kiểm tra quyền truy cập file và thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> submit({bool remove = false}) async {
    if (busy || !active || !remove && selected == null) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (remove) {
        await c.removeAvatar();
      } else {
        await c.updateAvatar(
          selected!.bytes,
          avatarContentType(selected!.bytes),
        );
      }
      if (mounted && active) {
        setState(() {
          selected = null;
          message = remove
              ? 'Đã dùng ảnh mặc định.'
              : 'Server đã lưu ảnh đại diện.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => message = 'Chưa xác nhận lưu ảnh. ${friendlyError(e)}');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AnimatedBuilder(
      animation: c,
      builder: (context, _) => AlertDialog(
        title: const DialogHeading(
          'Ảnh đại diện',
          icon: Icons.account_circle_outlined,
        ),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: AccountAvatar(controller: c, radius: 48)),
            const SizedBox(height: 16),
            const StatusNotice(
              message: 'Chọn ảnh PNG/JPEG tối đa 2 MiB. Cần kết nối để cập nhật ảnh đại diện cho tài khoản.',
              icon: Icons.image_outlined,
            ),
            if (selected != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Đã chọn: ${selected!.name} · ${(selected!.bytes.length / 1024).ceil()} KiB',
                ),
              ),
            if (c.avatarError != null) Text(c.avatarError!),
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(message!, key: const Key('avatar-message')),
              ),
            if (!active)
              const Text('Tài khoản đã thay đổi. Đóng cửa sổ này và mở lại.'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('avatar-pick'),
                  onPressed: busy || !active ? null : choose,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Chọn ảnh'),
                ),
                if (c.user?['has_avatar'] == true)
                  TextButton(
                    key: const Key('avatar-remove'),
                    onPressed: busy || !active
                        ? null
                        : () => submit(remove: true),
                    child: const Text('Dùng ảnh mặc định'),
                  ),
                TextButton(
                  onPressed: busy || !active
                      ? null
                      : () async {
                          await c.synchronize();
                          if (mounted) {
                            setState(
                              () => message =
                                  c.avatarError ??
                                  (c.online && c.error == null
                                      ? 'Đã kiểm tra lại trạng thái trên server.'
                                      : c.error ??
                                            'Chưa kiểm tra được trạng thái trên server.'),
                            );
                          }
                        },
                  child: const Text('Kiểm tra trạng thái'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            key: const Key('avatar-upload'),
            onPressed: busy || selected == null || !active ? null : submit,
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tải ảnh lên'),
          ),
        ],
      ),
    ),
  );
}
