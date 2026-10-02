import 'dart:async';

import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../state/share_session.dart';
import 'design_system.dart';

class ShareDialog extends StatefulWidget {
  const ShareDialog({
    super.key,
    required this.controller,
    required this.noteId,
    this.protectedGate,
    this.gateChanges,
  });
  final AppController controller;
  final String noteId;
  final bool Function()? protectedGate;
  final Listenable? gateChanges;
  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> with WidgetsBindingObserver {
  final form = GlobalKey<FormState>();
  final emails = TextEditingController();
  String role = 'viewer';
  late final session = ShareSession(
    widget.controller,
    widget.noteId,
    protectedGate: widget.protectedGate,
    gateChanges: widget.gateChanges,
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(session.refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    session.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    session.dispose();
    emails.dispose();
    super.dispose();
  }

  List<String> parsed() => emails.text
      .split(RegExp(r'[,;\s]+'))
      .where((s) => s.isNotEmpty)
      .map((s) => s.toLowerCase())
      .toList();
  Future<void> add() async {
    if (!form.currentState!.validate()) return;
    await session.submit({
      'action': 'add',
      'recipients': parsed().map((e) => {'email': e, 'role': role}).toList(),
    });
    if (mounted && session.message == 'Server đã cập nhật chia sẻ.') {
      emails.clear();
    }
  }

  Future<void> revoke(Map<String, dynamic> row) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AnimatedBuilder(
        animation: session,
        builder: (context, _) {
          final available =
              session.canManage &&
              session.recipients.any((r) => r['user_id'] == row['user_id']);
          return AlertDialog(
            title: const Text('Thu hồi quyền truy cập?'),
            content: Text(
              available
                  ? '${row['email']} sẽ không còn đọc hoặc sửa ghi chú qua server.'
                  : 'Quyền đã thay đổi. Đóng và kiểm tra lại.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: available
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Thu hồi'),
              ),
            ],
          );
        },
      ),
    );
    if (accepted == true && mounted) {
      await session.submit({'action': 'revoke', 'user_id': row['user_id']});
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) {
      final enabled =
          session.canManage && !session.busy && session.pending == null;
      return PopScope(
        canPop: !session.busy,
        child: AlertDialog(
          title: const DialogHeading(
            'Chia sẻ ghi chú',
            icon: Icons.people_outline,
          ),
          scrollable: true,
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StatusNotice(
                  message: 'Người nhận cần có tài khoản. Chia sẻ bản đã đồng bộ và quản lý quyền khi có kết nối.',
                  icon: Icons.shield_outlined,
                ),
                const SizedBox(height: 20),
                if (session.message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(session.message!),
                  ),
                if (session.canManage) ...[
                  const SectionHeading(
                    'Mời người cộng tác',
                    detail:
                        'Thêm một hoặc nhiều email, rồi chọn quyền truy cập.',
                  ),
                  Form(
                    key: form,
                    child: TextFormField(
                      key: const Key('share-emails'),
                      controller: emails,
                      enabled: enabled,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Email người nhận',
                        hintText: 'Mỗi email một dòng, hoặc ngăn bằng dấu phẩy',
                      ),
                      validator: (_) {
                        final values = parsed();
                        if (values.isEmpty || values.length > 20) {
                          return 'Nhập từ 1 đến 20 email.';
                        }
                        if (values.toSet().length != values.length) {
                          return 'Không nhập email trùng.';
                        }
                        if (values.any(
                          (e) =>
                              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(e),
                        )) {
                          return 'Email chưa hợp lệ.';
                        }
                        if (values.contains(widget.controller.user?['email'])) {
                          return 'Không chia sẻ cho chính mình.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(
                      labelText: 'Quyền khi thêm',
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'viewer', child: Text('Chỉ xem')),
                      DropdownMenuItem(
                        value: 'editor',
                        child: Text('Có thể chỉnh sửa'),
                      ),
                    ],
                    onChanged: enabled
                        ? (v) => setState(() => role = v!)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('share-add'),
                    onPressed: enabled ? add : null,
                    child: const Text('Thêm người nhận'),
                  ),
                  const SizedBox(height: 24),
                  SectionHeading(
                    'Người có quyền truy cập',
                    detail: '${session.recipients.length} người nhận',
                  ),
                  if (session.recipients.isEmpty)
                    const Text('Chưa có người nhận.'),
                  for (final row in session.recipients)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              row['name'] as String,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(row['email'] as String),
                            Text(
                              'Chia sẻ: ${sharingDate(row['shared_at'] as String)}',
                            ),
                            Semantics(
                              label: 'Quyền của ${row['email']}',
                              child: DropdownButton<String>(
                                key: ValueKey('share-role-${row['user_id']}'),
                                value: row['role'] as String,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'viewer',
                                    child: Text('Chỉ xem'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'editor',
                                    child: Text('Có thể chỉnh sửa'),
                                  ),
                                ],
                                onChanged: enabled
                                    ? (v) => session.submit({
                                        'action': 'role',
                                        'user_id': row['user_id'],
                                        'role': v,
                                      })
                                    : null,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: enabled ? () => revoke(row) : null,
                                child: const Text('Thu hồi quyền'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                if (session.pending != null)
                  TextButton(
                    onPressed: session.busy ? null : session.retry,
                    child: const Text('Thử lại thao tác'),
                  ),
                TextButton(
                  onPressed: session.busy || !session.active
                      ? null
                      : session.refresh,
                  child: const Text('Kiểm tra quyền và cập nhật'),
                ),
                if (session.busy) const LinearProgressIndicator(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: session.busy ? null : () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    },
  );
}

String sharingDate(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return 'Chưa có thời điểm';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
