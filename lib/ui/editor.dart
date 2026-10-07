import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/note.dart';
import '../domain/writing_tools.dart';
import '../state/focus_session.dart';
import '../state/app_controller.dart';
import 'design_system.dart';
import 'attachments.dart';
import 'sharing.dart';
import 'ai.dart';
import 'note_text_field.dart';
import 'writing_studio.dart';

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
  bool focusMode = false;
  final focusSession = FocusSession();
  final contentFocus = FocusNode();
  final toolsKey = GlobalKey();
  final editorScroll = ScrollController();
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
    if (!authorized || !editable || note?.locked == true) focusSession.pause();
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
    contentFocus.dispose();
    focusSession.dispose();
    editorScroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) focusSession.pause();
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

  void toggleTask(String expected, WritingTask task) {
    final note = c.notes.where((n) => n.id == widget.id).firstOrNull;
    if (!authorized || !editable || requiresReopen || note?.locked == true) {
      return;
    }
    final updated = toggleWritingTask(expected, content.text, task);
    if (updated == null) return;
    content.value = content.value.copyWith(
      text: updated,
      composing: TextRange.empty,
    );
    unawaited(input());
  }

  void jumpToHeading(int offset) {
    if (!authorized || offset > content.text.length) return;
    contentFocus.requestFocus();
    content.selection = TextSelection.collapsed(offset: offset);
    final field = contentFocus.context;
    if (field != null) Scrollable.ensureVisible(field, duration: Duration.zero);
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

  Future<void> toolAction(String action) async {
    if (!authorized) return;
    final note = c.notes.where((n) => n.id == widget.id).firstOrNull;
    if (note?.locked == true || c.accessUnavailable.contains(widget.id)) return;
    switch (action) {
      case 'outline':
        final target = toolsKey.currentContext;
        if (target != null) {
          Scrollable.ensureVisible(
            target,
            duration: PrismMotion.duration(
              context,
              const Duration(milliseconds: 240),
            ),
          );
        }
      case 'theme':
        await c.setPreferences({'dark': !c.dark});
      case 'sync':
        await flush();
        await c.synchronize();
      case 'ai':
        if (note == null ||
            dirty ||
            c.hasPending(widget.id) ||
            c.drafts.containsKey(widget.id)) {
          return;
        }
        await showDialog<void>(
          context: context,
          builder: (_) => AiSummaryDialog(controller: c, noteId: widget.id),
        );
      case 'share':
        if (note?.role != 'owner' || c.hasPending(widget.id)) return;
        await showDialog<void>(
          context: context,
          builder: (_) => ShareDialog(controller: c, noteId: widget.id),
        );
      case 'files':
        if (note == null || c.hasPending(widget.id)) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AttachmentsDialog(
            controller: c,
            noteId: widget.id,
            canEdit: editable,
          ),
        );
    }
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
    final compactTools =
        MediaQuery.sizeOf(context).width < 600 ||
        MediaQuery.textScalerOf(context).scale(18) > 24 ||
        focusMode;
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
            focusMode
                ? 'Viết tập trung'
                : editable
                ? 'Không gian viết'
                : 'Chỉ xem',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              key: const Key('focus-mode'),
              tooltip: focusMode ? 'Thoát tập trung' : 'Viết tập trung',
              icon: Icon(
                focusMode
                    ? Icons.fullscreen_exit
                    : Icons.center_focus_strong_outlined,
              ),
              onPressed: () {
                setState(() => focusMode = !focusMode);
                if (!focusMode) focusSession.pause();
                if (focusMode && editorScroll.hasClients) {
                  editorScroll.jumpTo(0);
                }
              },
            ),
            if (compactTools)
              PopupMenuButton<String>(
                key: const Key('editor-tools-menu'),
                tooltip: 'Công cụ ghi chú',
                onSelected: (action) => unawaited(toolAction(action)),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'outline',
                    child: Text('Dàn ý & checklist'),
                  ),
                  if (note != null)
                    PopupMenuItem(
                      value: 'ai',
                      enabled:
                          !dirty &&
                          !c.hasPending(widget.id) &&
                          !c.drafts.containsKey(widget.id),
                      child: const Text('Tóm tắt bằng AI'),
                    ),
                  if (note?.role == 'owner' && !c.hasPending(widget.id))
                    const PopupMenuItem(
                      value: 'share',
                      child: Text('Chia sẻ ghi chú'),
                    ),
                  if (note != null && !c.hasPending(widget.id))
                    const PopupMenuItem(
                      value: 'files',
                      child: Text('Đính kèm'),
                    ),
                  const PopupMenuItem(
                    value: 'theme',
                    child: Text('Đổi giao diện'),
                  ),
                  const PopupMenuItem(value: 'sync', child: Text('Đồng bộ')),
                ],
              ),
            if (!compactTools) ...[
              IconButton(
                tooltip: 'Dàn ý & checklist',
                onPressed: () {
                  final target = toolsKey.currentContext;
                  if (target != null) {
                    Scrollable.ensureVisible(
                      target,
                      duration: PrismMotion.duration(
                        context,
                        const Duration(milliseconds: 240),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.account_tree_outlined),
              ),
              if (!focusMode && note != null)
                IconButton(
                  tooltip: 'Tóm tắt bằng AI',
                  icon: const Icon(Icons.auto_awesome_outlined),
                  onPressed:
                      dirty ||
                          c.hasPending(widget.id) ||
                          c.drafts.containsKey(widget.id)
                      ? null
                      : () => showDialog<void>(
                          context: context,
                          builder: (_) =>
                              AiSummaryDialog(controller: c, noteId: widget.id),
                        ),
                ),
              if (!focusMode &&
                  note?.role == 'owner' &&
                  !c.hasPending(widget.id))
                IconButton(
                  tooltip: 'Chia sẻ ghi chú',
                  icon: const Icon(Icons.person_add_alt_outlined),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        ShareDialog(controller: c, noteId: widget.id),
                  ),
                ),
              if (!focusMode && note != null && !c.hasPending(widget.id))
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
          ],
        ),
        body: ReadingCanvas(
          controller: editorScroll,
          panel: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (focusMode) ...[
                FocusBar(session: focusSession),
                const SizedBox(height: 16),
              ],
              Semantics(
                liveRegion: true,
                child: SurfacePanel(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              status,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      if (c.realtime != null && c.online)
                        MetadataPill(
                          c.realtimeLive ? 'Trực tiếp' : 'Đang nối lại',
                          icon: Icons.cloud_outlined,
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
                              builder: (_) =>
                                  EditorScreen(controller: c, id: widget.id),
                            ),
                          );
                        },
                        child: const Text('Chỉnh sửa phiên bản mới'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              NoteTextField(
                key: const Key('editor-title-control'),
                fieldKey: const Key('note-title'),
                controller: title,
                titleMode: true,
                readOnly: !editable || requiresReopen,
                fontSize: c.fontSize,
                onChanged: (_) => unawaited(input()),
              ),
              const SizedBox(height: 16),
              NoteTextField(
                key: const Key('editor-content-control'),
                fieldKey: const Key('note-content'),
                focusNode: contentFocus,
                controller: content,
                titleMode: false,
                readOnly: !editable || requiresReopen,
                fontSize: c.fontSize,
                onChanged: (_) => unawaited(input()),
              ),
              if (!focusMode && note != null && note.role == 'owner') ...[
                const SizedBox(height: 16),
                NoteSection(
                  label: 'Sắp xếp',
                  icon: Icons.label_outline,
                  child: Wrap(
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
                          note.pinnedAt == null ? 'Ghim ghi chú' : 'Đã ghim',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                                      ? DateTime.now().toUtc().toIso8601String()
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
                          label: Text(
                            c.labelName(label),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                ),
              ],
              const SizedBox(height: 16),
              WritingToolsPanel(
                key: toolsKey,
                controller: content,
                readOnly: !editable || requiresReopen,
                onToggle: toggleTask,
                onHeading: jumpToHeading,
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
    );
  }
}
