import 'dart:async';

import 'package:flutter/material.dart';

import 'ai.dart';
import 'editor.dart';
import 'rich_note_field.dart';
import 'document_workspace.dart';

import '../state/app_controller.dart';
import '../state/protected_reader.dart';
import '../data/protected_note_vault.dart';
import '../data/api.dart';
import 'app.dart';
import 'design_system.dart';
import 'attachments.dart';
import 'sharing.dart';

enum ProtectionAction { enable, change, disable }

String protectionError(Object error) {
  if (error is ApiException && error.status == 429) {
    return 'Bạn đã thử nhiều lần. Đợi một phút rồi mở khóa hoặc đổi/tắt bảo vệ lại.';
  }
  final text = '$error';
  if (text.contains('Current note password incorrect')) {
    return 'Mật khẩu ghi chú hiện tại chưa đúng.';
  }
  if (text.contains('Sync and finish')) {
    return 'Đợi đồng bộ và hoàn tất bản nháp của ghi chú trước khi đổi khóa.';
  }
  if (text.contains('Owner required') ||
      text.contains('Insufficient permission')) {
    return 'Chỉ chủ ghi chú có quyền đổi khóa.';
  }
  return friendlyError(error);
}

class NoteProtectionDialog extends StatefulWidget {
  const NoteProtectionDialog({
    super.key,
    required this.controller,
    required this.id,
    required this.action,
  });
  final AppController controller;
  final String id;
  final ProtectionAction action;
  @override
  State<NoteProtectionDialog> createState() => _NoteProtectionDialogState();
}

class _NoteProtectionDialogState extends State<NoteProtectionDialog> {
  final form = GlobalKey<FormState>();
  final current = TextEditingController(),
      next = TextEditingController(),
      confirm = TextEditingController();
  bool busy = false, visible = false;
  String? error;
  String get title => switch (widget.action) {
    ProtectionAction.enable => 'Bật khóa ghi chú',
    ProtectionAction.change => 'Đổi mật khẩu ghi chú',
    ProtectionAction.disable => 'Tắt khóa ghi chú',
  };
  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.controller.changeNoteProtection(
        widget.id,
        currentPassword: current.text,
        password: widget.action == ProtectionAction.disable ? null : next.text,
        confirmation: widget.action == ProtectionAction.disable
            ? null
            : confirm.text,
      );
      if (mounted) {
        FocusScope.of(context).unfocus();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => error = protectionError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: DialogHeading(title, icon: Icons.lock_outline),
      content: SizedBox(
        width: 400,
        child: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.action == ProtectionAction.disable
                      ? 'Sau khi tắt khóa, người có quyền đọc sẽ xem được ghi chú mà không cần mật khẩu ghi chú.'
                      : 'Mật khẩu riêng cho ghi chú. Bật hoặc đổi mật khẩu sẽ đóng các phiên mở khóa đang có.',
                ),
                const SizedBox(height: 16),
                if (widget.action != ProtectionAction.enable)
                  TextFormField(
                    key: const Key('note-current-password'),
                    controller: current,
                    enabled: !busy,
                    obscureText: !visible,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu ghi chú hiện tại',
                    ),
                    validator: (v) =>
                        (v ?? '').isEmpty ? 'Nhập mật khẩu hiện tại' : null,
                  ),
                if (widget.action != ProtectionAction.disable) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('note-new-password'),
                    controller: next,
                    enabled: !busy,
                    obscureText: !visible,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu ghi chú mới',
                    ),
                    validator: (v) =>
                        (v ?? '').length < 10 || (v ?? '').length > 128
                        ? 'Dùng 10–128 ký tự'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('note-confirm-password'),
                    controller: confirm,
                    enabled: !busy,
                    obscureText: !visible,
                    decoration: const InputDecoration(
                      labelText: 'Nhập lại mật khẩu ghi chú mới',
                    ),
                    validator: (v) =>
                        v != next.text ? 'Hai mật khẩu chưa khớp' : null,
                    onFieldSubmitted: (_) => unawaited(submit()),
                  ),
                ],
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hiện mật khẩu'),
                  value: visible,
                  onChanged: busy ? null : (v) => setState(() => visible = v!),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const Key('confirm-note-protection'),
          onPressed: busy ? null : submit,
          child: Text(busy ? 'Đang xử lý…' : title),
        ),
      ],
    ),
  );
}

class ProtectedNoteScreen extends StatefulWidget {
  const ProtectedNoteScreen({
    super.key,
    required this.controller,
    required this.id,
    this.recoveryMode = false,
    this.vault,
  });
  final AppController controller;
  final String id;
  final bool recoveryMode;
  final ProtectedNoteVault? vault;
  @override
  State<ProtectedNoteScreen> createState() => _ProtectedNoteScreenState();
}

class _ProtectedNoteScreenState extends State<ProtectedNoteScreen>
    with WidgetsBindingObserver {
  late final ProtectedReader reader;
  late final NoteDocumentController document;
  final contentFocus = FocusNode();
  final documentScroll = ScrollController();
  final password = TextEditingController(),
      title = TextEditingController(),
      content = TextEditingController();
  final form = GlobalKey<FormState>();
  bool visible = false, editing = false, allowPop = false, leaving = false;
  Timer? debounce;
  AppController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    reader = ProtectedReader(
      c,
      widget.id,
      recoveryMode: widget.recoveryMode,
      vault: widget.vault,
    )..addListener(changed);
    document = NoteDocumentController(
      source: content,
      canEdit: () =>
          reader.active &&
          !reader.obscured &&
          reader.note != null &&
          editing &&
          reader.canEdit &&
          !reader.requiresReopen,
      onChanged: () => unawaited(input()),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  void replaceText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    final selection = controller.selection;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection(
        baseOffset: selection.baseOffset.clamp(0, value.length),
        extentOffset: selection.extentOffset.clamp(0, value.length),
      ),
    );
  }

  void changed() {
    if (reader.note == null || reader.obscured) {
      debounce?.cancel();
      editing = false;
      title.clear();
      content.clear();
    } else {
      password.clear();
      replaceText(
        title,
        reader.draft?['title'] as String? ?? reader.note!.title,
      );
      replaceText(
        content,
        reader.draft?['content'] as String? ?? reader.note!.content,
      );
      if (reader.dirty && reader.canEdit) editing = true;
    }
    if (!reader.active) password.clear();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      password.clear();
      debounce?.cancel();
      if (reader.picking) {
        reader.obscureForPicker();
      } else {
        unawaited(
          reader.relock('Ứng dụng đã chuyển nền. Mở khóa lại để tiếp tục.'),
        );
      }
    }
  }

  Future<void> unlock() async {
    if (reader.busy || !reader.active || !form.currentState!.validate()) return;
    await reader.unlock(password.text);
  }

  Future<void> input() async {
    debounce?.cancel();
    try {
      await reader.edit(title.text, content.text);
    } catch (_) {
      return;
    }
    debounce = Timer(
      const Duration(milliseconds: 650),
      () => unawaited(reader.flush()),
    );
  }

  Future<void> leave() async {
    if (leaving) return;
    leaving = true;
    debounce?.cancel();
    try {
      await reader.drainWrites();
      if (reader.localWriteFailed) throw StateError('Local write failed');
      await reader.flush();
      await reader.relock();
      if (mounted) {
        setState(() => allowPop = true);
        Navigator.pop(context);
      }
    } catch (_) {
      leaving = false;
      if (mounted) {
        showMessage(
          context,
          'Bản nháp chưa ghi bền. Giữ màn hình mở và thử lại.',
        );
      }
    }
  }

  Future<void> manage(ProtectionAction action) async {
    if (reader.dirty || reader.saving) return;
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          NoteProtectionDialog(controller: c, id: widget.id, action: action),
    );
    if (changed == true) {
      await reader.relock('Khóa đã cập nhật. Các phiên mở khóa cũ đã đóng.');
      if (action == ProtectionAction.disable && mounted) {
        setState(() => allowPop = true);
        Navigator.pop(context);
      }
    }
  }

  Future<void> copy() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo ghi chú riêng từ bản nháp?'),
        content: const Text(
          'Bản chỉnh sửa sẽ trở thành ghi chú riêng trong tài khoản của bạn. Thao tác này không mở khóa hoặc sửa ghi chú nguồn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tạo bản riêng'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      final id = await reader.copyDraft();
      if (id != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EditorScreen(controller: c, id: id),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'Chưa tạo được bản riêng. Bản nháp mã hóa vẫn được giữ.',
        );
      }
    }
  }

  Future<void> delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AnimatedBuilder(
        animation: reader,
        builder: (context, _) {
          final available =
              reader.serverGate &&
              reader.note?.role == 'owner' &&
              !reader.dirty;
          return AlertDialog(
            title: const Text('Xóa ghi chú bảo vệ?'),
            content: Text(
              available
                  ? '“${reader.note!.title}” sẽ bị xóa trên máy chủ.'
                  : 'Quyền hoặc phiên mở khóa đã đổi. Không thể xóa.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                key: const Key('protected-delete-confirm'),
                onPressed: available
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Xóa'),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed == true && await reader.deleteNote() && mounted) {
      setState(() => allowPop = true);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    reader.removeListener(changed);
    reader.dispose();
    document.dispose();
    contentFocus.dispose();
    documentScroll.dispose();
    password.dispose();
    title.dispose();
    content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = reader.obscured ? null : reader.note;
    return PopScope(
      canPop: allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(leave());
      },
      child: Scaffold(
        appBar: noteAppBar(
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: leave,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            widget.recoveryMode ? 'Bản nháp bảo vệ' : 'Ghi chú bảo vệ',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (note != null)
              IconButton(
                tooltip: 'Khóa lại',
                onPressed: () => reader.relock(),
                icon: const Icon(Icons.lock_outline),
              ),
          ],
        ),
        body: note == null
            ? ReadingCanvas(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Mở khóa để tiếp tục',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.recoveryMode
                          ? 'Nhập mật khẩu từng dùng cho bản nháp cục bộ. Không cấp quyền lên máy chủ.'
                          : 'Phiên tối đa 5 phút. Offline chỉ mở được bản đã tải và mã hóa trên thiết bị này.',
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: form,
                      child: TextFormField(
                        key: const Key('unlock-note-password'),
                        controller: password,
                        enabled: !reader.busy && reader.active,
                        obscureText: !visible,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu ghi chú',
                          suffixIcon: IconButton(
                            tooltip: visible ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                            onPressed: reader.busy
                                ? null
                                : () => setState(() => visible = !visible),
                            icon: Icon(
                              visible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            (v ?? '').isEmpty ? 'Nhập mật khẩu ghi chú' : null,
                        onFieldSubmitted: (_) => unawaited(unlock()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('unlock-note'),
                      onPressed: reader.busy || !reader.active ? null : unlock,
                      child: Text(reader.busy ? 'Đang mở khóa…' : 'Mở khóa'),
                    ),
                    if (reader.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(reader.error!),
                      ),
                  ],
                ),
              )
            : DocumentWorkspace(
                title: title,
                document: document,
                contentFocus: contentFocus,
                scrollController: documentScroll,
                readOnly: !editing || !reader.canEdit || reader.requiresReopen,
                titleKey: Key(
                  editing && reader.canEdit
                      ? 'protected-title-editor'
                      : 'protected-title',
                ),
                contentKey: Key(
                  editing && reader.canEdit
                      ? 'protected-content-editor'
                      : 'protected-content',
                ),
                fontSize: c.fontSize,
                onTitleChanged: () => unawaited(input()),
                leading: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatusNotice(
                      message: widget.recoveryMode
                          ? 'Bản chỉnh sửa riêng · nguồn không được mở khóa.'
                          : reader.onlineLease
                          ? 'Đã mở khóa · nội dung không xuất hiện trong cache hoặc tìm kiếm thường.'
                          : 'Đang dùng bản cục bộ offline · chưa xác nhận quyền hiện tại trên server.',
                      icon: Icons.lock_open_outlined,
                    ),
                    const SizedBox(height: 16),
                    if (reader.error != null)
                      StatusNotice(
                        message: reader.error!,
                        icon: Icons.info_outline,
                      ),
                    if (editing)
                      Text(
                        reader.saving
                            ? 'Đang đồng bộ…'
                            : reader.dirty
                            ? 'Bản nháp mã hóa trên thiết bị · chưa đồng bộ'
                            : 'Đã đồng bộ',
                        key: const Key('protected-save-status'),
                      ),
                  ],
                ),
                organisation: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeading(
                      'Thông tin ghi chú',
                      icon: Icons.info_outline,
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (note.pinnedAt != null)
                          const Chip(
                            label: Text('Đã ghim'),
                            avatar: Icon(Icons.push_pin_outlined),
                          ),
                        if (note.sharedCount > 0 || note.role != 'owner')
                          const Chip(
                            label: Text('Đã chia sẻ'),
                            avatar: Icon(Icons.people_outline),
                          ),
                        Chip(
                          label: Text(
                            note.role == 'viewer'
                                ? 'Chỉ xem'
                                : note.role == 'editor'
                                ? 'Có thể chỉnh sửa'
                                : 'Chủ sở hữu',
                          ),
                        ),
                      ],
                    ),
                    if (note.role != 'owner')
                      Text(
                        'Từ ${note.sharedByName ?? note.sharedByEmail ?? 'Chủ sở hữu'} · ${note.sharedAt ?? ''}',
                      ),
                    if (!widget.recoveryMode && note.role == 'owner')
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(
                              Icons.push_pin_outlined,
                              size: 18,
                            ),
                            label: Text(
                              reader.effectivePin == null
                                  ? 'Ghim ghi chú'
                                  : 'Đã ghim',
                            ),
                            onPressed: reader.requiresReopen || reader.saving
                                ? null
                                : () async {
                                    final pin = reader.effectivePin;
                                    await reader.edit(
                                      title.text,
                                      content.text,
                                      updatePin: true,
                                      pinnedAt: pin == null
                                          ? DateTime.now()
                                                .toUtc()
                                                .toIso8601String()
                                          : null,
                                    );
                                    await reader.flush();
                                  },
                          ),
                          ...c.labels.map(
                            (label) => FilterChip(
                              label: Text(c.labelName(label, note)),
                              selected:
                                  (reader.draft?['labels'] as List? ??
                                          note.labels)
                                      .contains(label),
                              onSelected: reader.requiresReopen || reader.saving
                                  ? null
                                  : (selected) async {
                                      final labels =
                                          (reader.draft?['labels'] as List? ??
                                                  note.labels)
                                              .cast<String>();
                                      await reader.edit(
                                        title.text,
                                        content.text,
                                        labels: selected
                                            ? [...labels, label]
                                            : labels
                                                  .where((l) => l != label)
                                                  .toList(),
                                      );
                                      await reader.flush();
                                    },
                            ),
                          ),
                        ],
                      ),
                    if (note.role != 'owner')
                      Wrap(
                        spacing: 8,
                        children: note.labels
                            .map(
                              (label) =>
                                  Chip(label: Text(c.labelName(label, note))),
                            )
                            .toList(),
                      ),
                    if (reader.canEdit)
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: reader.saving
                                ? null
                                : () {
                                    reader.beginFreshEdit();
                                    setState(() => editing = true);
                                  },
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(
                              reader.requiresReopen
                                  ? 'Chỉnh sửa phiên bản mới'
                                  : 'Chỉnh sửa',
                            ),
                          ),
                          if (reader.dirty)
                            TextButton(
                              onPressed: reader.localWriteFailed
                                  ? () async {
                                      try {
                                        await reader.persist();
                                      } catch (_) {}
                                    }
                                  : reader.serverGate
                                  ? reader.flush
                                  : null,
                              child: Text(
                                reader.localWriteFailed
                                    ? 'Thử ghi bản nháp lại'
                                    : 'Đồng bộ bản nháp',
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                tools: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (reader.dirty &&
                        (reader.conflicted || widget.recoveryMode)) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: copy,
                        child: const Text('Giữ bản nháp thành ghi chú riêng'),
                      ),
                      if (reader.serverGate)
                        TextButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text(
                                  'Bỏ bản nháp và dùng bản máy chủ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Hủy'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Dùng bản máy chủ'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) await reader.useRemote();
                          },
                          child: const Text('Dùng bản máy chủ'),
                        ),
                    ],
                    const SizedBox(height: 24),
                    if (!widget.recoveryMode || reader.serverGate)
                      const SectionHeading(
                        'Công cụ ghi chú',
                        icon: Icons.tune_outlined,
                      ),
                    if (!widget.recoveryMode)
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: reader.canUseAi
                                ? () => showDialog<void>(
                                    context: context,
                                    builder: (_) => AiSummaryDialog(
                                      controller: c,
                                      noteId: widget.id,
                                      protectedGate: () => reader.canUseAi,
                                      gateChanges: reader,
                                    ),
                                  )
                                : null,
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('Tóm tắt AI'),
                          ),
                          OutlinedButton.icon(
                            onPressed: reader.canUseAi
                                ? () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => AiQuestionsScreen(
                                        controller: c,
                                        protectedGate: () => reader.canUseAi,
                                        gateChanges: reader,
                                      ),
                                    ),
                                  )
                                : null,
                            icon: const Icon(Icons.question_answer_outlined),
                            label: const Text('Hỏi AI'),
                          ),
                        ],
                      ),
                    if (reader.serverGate) ...[
                      TextButton.icon(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => AttachmentsDialog(
                            controller: c,
                            noteId: widget.id,
                            canEdit: reader.canEdit,
                            onPickingChanged: reader.setPicking,
                            protectedGate: () => reader.serverGate,
                            gateChanges: reader,
                          ),
                        ),
                        icon: const Icon(Icons.attach_file),
                        label: Text(
                          reader.canEdit ? 'Quản lý đính kèm' : 'Xem đính kèm',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: reader.busy ? null : reader.refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Kiểm tra quyền và cập nhật'),
                      ),
                      if (note.role == 'owner')
                        TextButton.icon(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => ShareDialog(
                              controller: c,
                              noteId: widget.id,
                              protectedGate: () =>
                                  reader.serverGate &&
                                  reader.note?.role == 'owner',
                              gateChanges: reader,
                            ),
                          ),
                          icon: const Icon(Icons.people_outline),
                          label: const Text('Quản lý chia sẻ'),
                        ),
                      if (note.role == 'owner') ...[
                        const SizedBox(height: 16),
                        const SectionHeading(
                          'Bảo vệ & quản lý',
                          icon: Icons.security_outlined,
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: reader.dirty || reader.saving
                                  ? null
                                  : () => manage(ProtectionAction.change),
                              child: const Text('Đổi mật khẩu ghi chú'),
                            ),
                            OutlinedButton(
                              onPressed: reader.dirty || reader.saving
                                  ? null
                                  : () => manage(ProtectionAction.disable),
                              child: const Text('Tắt khóa ghi chú'),
                            ),
                            TextButton.icon(
                              key: const Key('protected-delete'),
                              onPressed: reader.dirty || reader.saving
                                  ? null
                                  : delete,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Xóa ghi chú'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
