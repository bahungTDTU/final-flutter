import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/note.dart';
import '../state/app_controller.dart';
import 'design_system.dart';
import 'attachments.dart';
import 'sharing.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.controller, required this.id});
  final AppController controller;
  final String id;
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with WidgetsBindingObserver {
  late final TextEditingController title, content;
  late final String account;
  Timer? debounce;
  String feedback = 'Sẵn sàng';
  bool canLeave = false, dirty = false;
  int baseRevision = 0;
  int editVersion = 0;
  Future<void>? flushing;
  bool saveFailed = false;
  bool existedAtOpen = false;
  bool requiresReopen = false;
  AppController get c => widget.controller;
  bool get authorized => c.user?['id'] == account;
  bool get editable =>
      !c.accessUnavailable.contains(widget.id) &&
      (!existedAtOpen || c.notes.any((n) => n.id == widget.id)) &&
      c.notes.where((n) => n.id == widget.id).firstOrNull?.role != 'viewer';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    account = c.user!['id'] as String;
    final note = c.notes.where((n) => n.id == widget.id).firstOrNull;
    existedAtOpen = note != null;
    baseRevision = note?.revision ?? 0;
    final draft = c.drafts[widget.id] as Map?;
    title = TextEditingController(
      text: draft?['title'] as String? ?? note?.title ?? '',
    );
    content = TextEditingController(
      text: draft?['content'] as String? ?? note?.content ?? '',
    );
    dirty = draft != null;
    if (dirty) {
      feedback = validNote(title.text, content.text)
          ? 'Bản nháp đã lưu trên thiết bị'
          : 'Nhập tiêu đề và nội dung để tạo ghi chú';
    }
    c.addListener(changed);
  }

  void changed() {
    final note = c.notes.where((n) => n.id == widget.id).firstOrNull;
    if (authorized &&
        (note?.locked == true || (existedAtOpen && note == null))) {
      debounce?.cancel();
      dirty = false;
      title.clear();
      content.clear();
    }
    if (authorized && note?.locked == false && note?.role == 'viewer') {
      debounce?.cancel();
      dirty = false;
      acceptRemote(title, note!.title);
      acceptRemote(content, note.content);
      requiresReopen = false;
    } else if (authorized &&
        note != null &&
        !note.locked &&
        !dirty &&
        !c.drafts.containsKey(widget.id) &&
        !c.hasPending(widget.id) &&
        !c.conflicts.containsKey(widget.id)) {
      acceptRemote(title, note.title);
      acceptRemote(content, note.content);
      // Display live updates without silently rebasing an editor opened earlier.
      requiresReopen = note.revision > baseRevision;
    }
    if (mounted) setState(() {});
  }

  void acceptRemote(TextEditingController field, String text) {
    if (field.text == text) return;
    final selection = field.selection;
    field.value = TextEditingValue(
      text: text,
      selection: selection.isValid
          ? TextSelection(
              baseOffset: selection.baseOffset.clamp(0, text.length),
              extentOffset: selection.extentOffset.clamp(0, text.length),
              affinity: selection.affinity,
              isDirectional: selection.isDirectional,
            )
          : selection,
    );
  }

  @override
  void dispose() {
    debounce?.cancel();
    c.removeListener(changed);
    WidgetsBinding.instance.removeObserver(this);
    title.dispose();
    content.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(flush());
    }
  }

  Future<void> input() async {
    saveFailed = false;
    editVersion++;
    dirty = true;
    debounce?.cancel();
    setState(() => feedback = 'Đang lưu trên thiết bị…');
    try {
      if (!authorized) return;
      await c.draft(widget.id, title.text, content.text);
      if (mounted) {
        setState(
          () => feedback = validNote(title.text, content.text)
              ? 'Bản nháp đã lưu trên thiết bị'
              : 'Nhập tiêu đề và nội dung để tạo ghi chú',
        );
      }
      debounce = Timer(
        const Duration(milliseconds: 650),
        () => unawaited(flush()),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          saveFailed = true;
          feedback = 'Chưa lưu được thay đổi trên thiết bị. Vui lòng thử lại.';
        });
      }
    }
  }

  Future<void> flush() async {
    debounce?.cancel();
    if (flushing != null) {
      await flushing;
      if (dirty && !saveFailed) await flush();
      return;
    }
    if (!authorized || !editable || requiresReopen || !dirty) return;
    flushing = flushSnapshot();
    await flushing;
    flushing = null;
    if (dirty && !saveFailed) await flush();
  }

  Future<void> flushSnapshot() async {
    final version = editVersion;
    final titleValue = title.text, contentValue = content.text;
    saveFailed = false;
    try {
      await c.draft(widget.id, titleValue, contentValue);
      if (version != editVersion || !authorized) return;
      if (validNote(titleValue, contentValue)) {
        await c.save(
          widget.id,
          titleValue,
          contentValue,
          baseRevision: baseRevision,
        );
        baseRevision =
            c.notes.where((n) => n.id == widget.id).firstOrNull?.revision ??
            baseRevision;
        if (mounted) setState(() => feedback = 'Đã lưu trên thiết bị');
      }
      dirty = version != editVersion;
    } catch (e) {
      saveFailed = true;
      if (mounted) {
        setState(() {
          saveFailed = true;
          feedback = 'Chưa lưu được thay đổi trên thiết bị. Vui lòng thử lại.';
        });
      }
    }
  }

  Future<void> leave() async {
    await flush();
    if (!mounted || saveFailed) return;
    setState(() => canLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!authorized) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Phiên tài khoản đã kết thúc.')),
      );
    }
    final note = c.notes.where((n) => n.id == widget.id).firstOrNull;
    if (note?.locked == true) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Ghi chú đã bị khóa.')),
      );
    }

    if (existedAtOpen && note == null && !c.hasPending(widget.id)) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyNotes(
          title: 'Bạn không còn quyền truy cập ghi chú này.',
          detail: 'Quay lại danh sách để tiếp tục.',
        ),
      );
    }
    final status = saveFailed
        ? feedback
        : c.conflicts.containsKey(widget.id)
        ? 'Có hai phiên bản thay đổi · xử lý trong danh sách'
        : dirty || c.drafts.containsKey(widget.id)
        ? feedback
        : c.hasPending(widget.id)
        ? c.syncing
              ? 'Đang đồng bộ…'
              : c.online
              ? 'Đã lưu trên thiết bị · chờ đồng bộ'
              : 'Đã lưu trên thiết bị. Sẽ đồng bộ khi có kết nối.'
        : note != null && note.revision > 0
        ? 'Đã đồng bộ'
        : 'Bắt đầu ghi chú mới';
    return PopScope(
      canPop: canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(leave());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: leave,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            editable ? 'Không gian viết' : 'Chỉ xem',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (note?.role == 'owner' && !c.hasPending(widget.id))
              IconButton(
                tooltip: 'Chia sẻ ghi chú',
                icon: const Icon(Icons.person_add_alt_outlined),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ShareDialog(controller: c, noteId: widget.id),
                ),
              ),
            if (note != null && !c.hasPending(widget.id))
              IconButton(
                tooltip: 'Đính kèm',
                icon: const Icon(Icons.attach_file),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AttachmentsDialog(
                    controller: c,
                    noteId: widget.id,
                    canEdit: editable,
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Đổi giao diện',
              onPressed: () => c.setPreferences({'dark': !c.dark}),
              icon: Icon(
                c.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
            ),
            IconButton(
              tooltip: 'Đồng bộ',
              onPressed: () async {
                await flush();
                await c.synchronize();
              },
              icon: const Icon(Icons.sync),
            ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Space.reading),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SurfacePanel(
                  padding: EdgeInsets.all(
                    MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeading(
                        'Một điều đáng ghi nhớ',
                        detail: 'Viết theo cách của bạn. Các thay đổi được tự động lưu.',
                        icon: Icons.edit_note_outlined,
                      ),
                      Semantics(
                        liveRegion: true,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(
                              saveFailed
                                  ? Icons.error_outline
                                  : dirty || c.drafts.containsKey(widget.id)
                                  ? Icons.edit_note_outlined
                                  : c.hasPending(widget.id)
                                  ? Icons.cloud_upload_outlined
                                  : Icons.check_circle_outline,
                              size: 20,
                              color: saveFailed
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            Text(
                              status,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (c.realtime != null && c.online)
                              Text(
                                c.realtimeLive ? 'Trực tiếp' : 'Đang nối lại',
                              ),
                            if (saveFailed)
                              TextButton(
                                onPressed: () async {
                                  saveFailed = false;
                                  await flush();
                                },
                                child: const Text('Thử lại'),
                              ),
                          ],
                        ),
                      ),
                      if (!editable)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: StatusNotice(
                            message: 'Bạn có quyền chỉ xem. Nội dung có thể chọn và sao chép.',
                            icon: Icons.visibility_outlined,
                          ),
                        ),
                      if (requiresReopen && editable)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const StatusNotice(
                                message: 'Đã nhận phiên bản mới. Bắt đầu phiên chỉnh sửa mới để tiếp tục.',
                                icon: Icons.sync_outlined,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute<void>(
                                      builder: (_) => EditorScreen(
                                        controller: c,
                                        id: widget.id,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Chỉnh sửa phiên bản mới'),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                      TextField(
                        key: const Key('note-title'),
                        controller: title,
                        readOnly: !editable || requiresReopen,
                        maxLength: 200,
                        maxLines: null,
                        style: Theme.of(context).textTheme.headlineLarge,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề',
                          hintText: 'Điều bạn muốn ghi nhớ',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: UnderlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (_) => unawaited(input()),
                      ),
                      const SizedBox(height: 8),
                      if (note != null && note.role == 'owner')
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              avatar: Icon(
                                note.pinnedAt == null
                                    ? Icons.push_pin_outlined
                                    : Icons.push_pin,
                                size: 18,
                              ),
                              label: Text(
                                note.pinnedAt == null
                                    ? 'Ghim ghi chú'
                                    : 'Đã ghim',
                              ),
                              onPressed: requiresReopen
                                  ? null
                                  : () async {
                                      await flush();
                                      await c.save(
                                        note.id,
                                        title.text,
                                        content.text,
                                        baseRevision: baseRevision,
                                        updatePin: true,
                                        pinnedAt: note.pinnedAt == null
                                            ? DateTime.now()
                                                  .toUtc()
                                                  .toIso8601String()
                                            : null,
                                      );
                                      baseRevision =
                                          c.notes
                                              .where((n) => n.id == widget.id)
                                              .firstOrNull
                                              ?.revision ??
                                          baseRevision;
                                    },
                            ),
                            ...c.labels.map(
                              (label) => FilterChip(
                                label: Text(c.labelName(label)),
                                selected: note.labels.contains(label),
                                onSelected: requiresReopen
                                    ? null
                                    : (v) async {
                                        await flush();
                                        await c.save(
                                          note.id,
                                          title.text,
                                          content.text,
                                          baseRevision: baseRevision,
                                          noteLabels: v
                                              ? [...note.labels, label]
                                              : note.labels
                                                    .where((l) => l != label)
                                                    .toList(),
                                        );
                                        baseRevision =
                                            c.notes
                                                .where((n) => n.id == widget.id)
                                                .firstOrNull
                                                ?.revision ??
                                            baseRevision;
                                      },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      TextField(
                        key: const Key('note-content'),
                        controller: content,
                        readOnly: !editable || requiresReopen,
                        minLines: 10,
                        maxLines: null,
                        maxLength: 100000,
                        style: TextStyle(fontSize: c.fontSize, height: 1.6),
                        decoration: const InputDecoration(
                          labelText: 'Nội dung',
                          alignLabelWithHint: true,
                          hintText: 'Bắt đầu viết…',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: UnderlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (_) => unawaited(input()),
                      ),
                      const SizedBox(height: 24),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: content,
                        builder: (_, value, _) => Text(
                          '${value.text.runes.length} ký tự',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tự động lưu. Nhập tiêu đề và nội dung để tạo ghi chú; bản nháp chưa hoàn chỉnh được giữ riêng.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
