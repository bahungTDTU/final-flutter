import '../l10n/app_strings.dart';

import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/attachment_platform.dart';
import '../domain/note.dart';
import '../domain/workspace.dart';
import '../domain/writing_tools.dart';
import '../state/app_controller.dart';
import 'design_system.dart';
import 'app.dart' show showMessage;
import 'editor.dart';
import 'note_filters.dart';
import 'focus_panel.dart';
import 'planner.dart';

Future<void> openWorkspaceNote(
  BuildContext context,
  AppController c,
  String id,
) async {
  final account = c.user?['id'];
  try {
    await c.recordRecent(id);
    if (!context.mounted ||
        account != c.user?['id'] ||
        !c.workspaceNotes.any((n) => n.id == id)) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EditorScreen(controller: c, id: id),
      ),
    );
  } catch (_) {
    if (context.mounted) {
      showMessage(context, context.tr("Chưa thể mở ghi chú. Hãy thử lại."));
    }
  }
}

Future<void> createWorkspaceDraft(
  BuildContext context,
  AppController c,
  NoteTemplate template,
) async {
  final account = c.user?['id'];
  final id = c.uuid.v4();
  try {
    await c.draft(id, template.title, template.content);
    if (!context.mounted || account == null || account != c.user?['id']) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EditorScreen(controller: c, id: id),
      ),
    );
  } catch (_) {
    if (context.mounted) {
      showMessage(context, context.tr("Chưa lưu được bản nháp. Hãy thử lại."));
    }
  }
}

Future<void> showQuickFind(BuildContext context, AppController c) =>
    showDialog<void>(
      context: context,
      builder: (_) => _QuickFind(controller: c),
    );

class _QuickFind extends StatefulWidget {
  const _QuickFind({required this.controller});
  final AppController controller;
  @override
  State<_QuickFind> createState() => _QuickFindState();
}

class _QuickFindState extends State<_QuickFind> {
  final query = TextEditingController();
  late final account = widget.controller.user?['id'];
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      if (account == null || c.user?['id'] != account) {
        return AlertDialog(
          content: Text(context.tr("Phiên đăng nhập đã thay đổi.")),
        );
      }
      final q = query.text.trim().toLowerCase();
      final notes = c.workspaceNotes
          .where(
            (n) =>
                q.isEmpty ||
                n.title.toLowerCase().contains(q) ||
                n.plainContent.toLowerCase().contains(q),
          )
          .take(30)
          .toList();
      void open(String id) {
        final parent = Navigator.of(context);
        parent.pop();
        // Use the navigator's surviving context after closing the dialog.
        unawaited(openWorkspaceNote(parent.context, c, id));
      }

      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              shrinkWrap: true,
              children: [
                SectionHeading(
                  context.tr("Tìm nhanh"),
                  detail: context.tr(
                    "Tối đa 30 kết quả. Chỉ tìm trong ghi chú chưa khóa.",
                  ),
                  icon: Icons.search,
                ),
                TextField(
                  key: const Key('workspace-quick-query'),
                  controller: query,
                  autofocus: true,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: context.tr("Tên hoặc nội dung ghi chú"),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (notes.isNotEmpty) open(notes.first.id);
                  },
                ),

                if (q.isEmpty) ...[
                  ListTile(
                    leading: const Icon(Icons.space_dashboard_outlined),
                    title: Text(context.tr("Mở không gian làm việc")),
                    onTap: () {
                      final nav = Navigator.of(context);
                      nav.pop();
                      nav.push<void>(
                        MaterialPageRoute(
                          builder: (_) => WorkspaceScreen(controller: c),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.today_outlined),
                    title: Text(context.tr("Viết nhật ký hôm nay")),
                    onTap: () {
                      final nav = Navigator.of(context);
                      nav.pop();
                      unawaited(
                        createWorkspaceDraft(
                          nav.context,
                          c,
                          journalTemplate(DateTime.now()),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ],
                if (notes.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(context.tr("Không tìm thấy ghi chú phù hợp.")),
                  ),
                for (final n in notes)
                  ListTile(
                    leading: Icon(
                      c.workspace.favorites.contains(n.id)
                          ? Icons.star
                          : Icons.description_outlined,
                    ),
                    title: Text(
                      n.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      n.role == 'owner'
                          ? context.tr("Ghi chú của bạn")
                          : context.tr("Được chia sẻ"),
                    ),
                    onTap: () => open(n.id),
                    trailing: IconButton(
                      tooltip: c.workspace.favorites.contains(n.id)
                          ? context.tr("Bỏ yêu thích")
                          : context.tr("Yêu thích"),
                      icon: Icon(
                        c.workspace.favorites.contains(n.id)
                            ? Icons.star
                            : Icons.star_border,
                      ),
                      onPressed: () async {
                        try {
                          await c.toggleFavorite(n.id);
                        } catch (_) {
                          if (context.mounted) {
                            showMessage(
                              context,
                              context.tr("Chưa lưu được yêu thích."),
                            );
                          }
                        }
                      },
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr("Đóng")),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Await the durable write before closing, preserving user input on failure.
class _WorkspaceSaveDialog extends StatefulWidget {
  const _WorkspaceSaveDialog({
    required this.title,
    required this.content,
    required this.saveLabel,
    required this.onSave,
  });
  final Widget title, content;
  final String saveLabel;
  final Future<void> Function() onSave;
  @override
  State<_WorkspaceSaveDialog> createState() => _WorkspaceSaveDialogState();
}

class _WorkspaceSaveDialogState extends State<_WorkspaceSaveDialog> {
  bool saving = false;
  String? error;
  Future<void> save() async {
    if (saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.onSave();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = e is StateError
              ? e.message.toString()
              : context.tr("Chưa lưu được. Dữ liệu vẫn ở đây; hãy thử lại.");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: widget.title,
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AbsorbPointer(absorbing: saving, child: widget.content),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: StatusNotice(message: error!, error: true),
            ),
          if (saving)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: Text(context.tr("Hủy")),
        ),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(saving ? context.tr("Đang lưu…") : widget.saveLabel),
        ),
      ],
    ),
  );
}

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  late final account = c.user?['id'];
  AppController get c => widget.controller;
  final tasks = WorkspaceTaskCache();
  int tab = 0;
  String? viewId;
  bool done = false, busy = false;
  final taskQuery = TextEditingController();
  final plannerView = PlannerViewState();
  int taskScope = 0;
  bool allStatuses = false;
  final inFlight = <String>{};
  Future<void> run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted && account == c.user?['id']) {
        showMessage(
          context,
          e is StateError
              ? e.message.toString()
              : context.tr("Thao tác chưa hoàn tất. Hãy thử lại."),
        );
      }
    }
  }

  @override
  void dispose() {
    tasks.clear();
    taskQuery.dispose();
    plannerView.dispose();
    super.dispose();
  }

  Future<T?> accountDialog<T>({required WidgetBuilder builder}) =>
      showDialog<T>(
        context: context,
        builder: (_) => AnimatedBuilder(
          animation: c,
          builder: (context, _) => account == c.user?['id']
              ? builder(context)
              : AlertDialog(
                  content: Text(context.tr("Phiên đăng nhập đã thay đổi.")),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.tr("Đóng")),
                    ),
                  ],
                ),
        ),
      );

  Future<void> editView([WorkspaceView? value]) async {
    final name = TextEditingController(
      text: value?.name ?? context.tr("Bộ sưu tập mới"),
    );
    final query = TextEditingController(text: value?.query ?? '');
    final selected = {...?value?.labels};
    bool shared = value?.shared ?? false;
    final save = await accountDialog<bool>(
      builder: (_) => StatefulBuilder(
        builder: (context, update) => _WorkspaceSaveDialog(
          title: Text(
            value == null
                ? context.tr("Tạo bộ sưu tập thông minh")
                : context.tr("Sửa bộ sưu tập"),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: name,
                    maxLength: 60,
                    decoration: InputDecoration(
                      labelText: context.tr("Tên bộ sưu tập"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: query,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: context.tr("Từ khóa trong tên hoặc nội dung"),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.tr("Ghi chú được chia sẻ")),
                    subtitle: Text(
                      context.tr("Tắt để tìm trong ghi chú của bạn."),
                    ),
                    value: shared,
                    onChanged: (v) => update(() => shared = v),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: Text(
                      context.tr("Chọn nhãn ({0}/30)", [selected.length]),
                    ),
                    onPressed: () async {
                      final result = await showModalBottomSheet<Set<String>>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        constraints: const BoxConstraints(maxWidth: 600),
                        builder: (_) =>
                            NoteLabelFilter(controller: c, selected: selected),
                      );
                      if (!context.mounted ||
                          account != c.user?['id'] ||
                          result == null) {
                        return;
                      }
                      if (result.length > 30) {
                        if (context.mounted) {
                          showMessage(
                            context,
                            context.tr(
                              "Chọn tối đa 30 nhãn cho một bộ sưu tập.",
                            ),
                          );
                        }
                        return;
                      }
                      update(() {
                        selected
                          ..clear()
                          ..addAll(result.where(c.labels.contains));
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id in selected)
                        InputChip(
                          label: Text(c.labelName(id)),
                          onDeleted: () => update(() => selected.remove(id)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          saveLabel: context.tr("Lưu bộ sưu tập"),
          onSave: () async {
            if (account != c.user?['id']) {
              throw StateError(context.tr("Tài khoản đã thay đổi."));
            }
            await c.saveWorkspaceView(
              name.text,
              query.text,
              selected,
              shared: shared,
              id: value?.id,
            );
          },
        ),
      ),
    );
    if (save == true && mounted && account == c.user?['id']) {
      setState(() => viewId = c.workspace.views.firstOrNull?.id);
      showMessage(context, context.tr("Đã lưu bộ sưu tập."));
    }
    // Dialog controllers live until its exit animation has completed.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    query.dispose();
  }

  Future<void> editTemplate([NoteTemplate? value]) async {
    final title = TextEditingController(
      text: value?.title ?? context.tr("Mẫu mới"),
    );
    final description = TextEditingController(text: value?.description ?? '');
    final body = TextEditingController(
      text: value?.content ?? context.tr("## Mục tiêu\n\n- [ ] Việc cần làm"),
    );
    final saved = await accountDialog<bool>(
      builder: (_) => _WorkspaceSaveDialog(
        title: Text(
          value == null
              ? context.tr("Tạo mẫu riêng")
              : context.tr("Sửa mẫu riêng"),
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  maxLength: 200,
                  decoration: InputDecoration(labelText: context.tr("Tên mẫu")),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLength: 140,
                  decoration: InputDecoration(
                    labelText: context.tr("Mô tả ngắn"),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: body,
                  minLines: 6,
                  maxLines: 12,
                  maxLength: 100000,
                  decoration: InputDecoration(
                    labelText: context.tr("Nội dung khởi đầu (Markdown)"),
                  ),
                ),
              ],
            ),
          ),
        ),
        saveLabel: context.tr("Lưu mẫu"),
        onSave: () async {
          if (account != c.user?['id']) {
            throw StateError(context.tr("Tài khoản đã thay đổi."));
          }
          await c.savePersonalTemplate(
            title.text,
            description.text,
            body.text,
            id: value?.id,
          );
        },
      ),
    );
    if (saved == true && mounted && account == c.user?['id']) {
      showMessage(context, context.tr("Đã lưu mẫu riêng."));
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    title.dispose();
    description.dispose();
    body.dispose();
  }

  Future<void> confirmDelete(
    String title,
    Future<void> Function() remove,
  ) async {
    final accepted = await accountDialog<bool>(
      builder: (_) => _WorkspaceSaveDialog(
        title: Text(context.tr("Xóa khỏi không gian làm việc?")),
        content: SizedBox(
          width: 440,
          child: Text(
            context.tr(
              "“{0}” sẽ bị xóa. Các ghi chú đã tạo hoặc nằm trong bộ sưu tập vẫn được giữ lại.",
              [title],
            ),
          ),
        ),
        saveLabel: context.tr("Xóa"),
        onSave: () async {
          if (account != c.user?['id']) {
            throw StateError(context.tr("Tài khoản đã thay đổi."));
          }
          await remove();
        },
      ),
    );
    if (accepted == true && mounted && account == c.user?['id']) {
      showMessage(context, context.tr("Đã xóa."));
    }
  }

  Future<void> importFile() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(label: 'NoteTogether JSON', extensions: ['json']),
        ],
      );
      if (file == null || !mounted || account != c.user?['id']) return;
      if (await file.length() > 5 * 1024 * 1024) {
        throw const FormatException('File vượt quá 5 MiB.');
      }
      final imported = decodeNoteBundle(await file.readAsBytes());
      if (!mounted || account != c.user?['id']) return;
      final accepted = await accountDialog<bool>(
        builder: (_) => AlertDialog(
          title: Text(context.tr("Nhập {0} ghi chú?", [imported.length])),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      "Mỗi ghi chú được tạo mới trong tài khoản của bạn, rồi đồng bộ khi có mạng. File chỉ chứa tiêu đề và nội dung; tệp đính kèm không được nhập.",
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final n in imported)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        n.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr("Hủy")),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr("Tạo các ghi chú mới")),
            ),
          ],
        ),
      );
      if (accepted == true && mounted && account == c.user?['id']) {
        await c.importNotes(imported);
        if (mounted && account == c.user?['id']) {
          showMessage(
            context,
            context.tr("Đã lưu {0} ghi chú vào thiết bị.", [imported.length]),
          );
        }
      }
    } catch (e) {
      if (mounted && account == c.user?['id']) {
        showMessage(
          context,
          e is FormatException
              ? e.message
              : context.tr("Chưa nhập được ghi chú. Hãy thử lại."),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> exportFile() async {
    if (!c.workspaceNotes.any((n) => n.role == 'owner')) {
      showMessage(context, context.tr("Chưa có ghi chú của bạn để xuất."));
      return;
    }
    final selected = <String>{};
    final accepted = await accountDialog<bool>(
      builder: (_) => StatefulBuilder(
        builder: (context, update) {
          final available = c.workspaceNotes
              .where((n) => n.role == 'owner')
              .toList();
          return AlertDialog(
            title: Text(context.tr("Xuất ghi chú ({0}/50)", [selected.length])),
            content: SizedBox(
              width: 560,
              height: 380,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        context.tr(
                          "File xuất không mã hóa. Chỉ chứa tên và nội dung của ghi chú chưa khóa; không gồm tệp đính kèm.",
                        ),
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: available.length,
                    itemBuilder: (context, i) {
                      final n = available[i];
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: selected.contains(n.id),
                        onChanged:
                            selected.length >= 50 && !selected.contains(n.id)
                            ? null
                            : (v) => update(() {
                                v == true
                                    ? selected.add(n.id)
                                    : selected.remove(n.id);
                              }),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr("Hủy")),
              ),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                child: Text(context.tr("Xuất file")),
              ),
            ],
          );
        },
      ),
    );
    if (accepted != true || !mounted || account != c.user?['id']) return;
    // Re-read source after confirmation. A remotely locked/revoked selection aborts.
    final source = c.workspaceNotes
        .where((n) => selected.contains(n.id) && n.role == 'owner')
        .toList();
    if (source.length != selected.length) {
      showMessage(
        context,
        context.tr("Quyền truy cập đã thay đổi. Hãy chọn lại."),
      );
      return;
    }
    try {
      final bytes = Uint8List.fromList(encodeNoteBundle(source));
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final dispatched = await saveAttachment(
        'NoteTogether-$date.notetogether.json',
        'application/json',
        bytes,
      );
      if (mounted && account == c.user?['id']) {
        showMessage(
          context,
          dispatched
              ? context.tr("Đã gửi file tới trình lưu của thiết bị.")
              : context.tr("Chưa lưu file."),
        );
      }
    } catch (e) {
      if (mounted && account == c.user?['id']) {
        showMessage(
          context,
          e is FormatException ? e.message : context.tr("Chưa xuất được file."),
        );
      }
    }
  }

  Widget noteRow(Note n) => SurfacePanel(
    padding: const EdgeInsets.all(12),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined),
      title: Text(n.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        n.role == 'owner'
            ? context.tr("Ghi chú của bạn")
            : n.role == 'viewer'
            ? context.tr("Chỉ xem")
            : context.tr("Có thể chỉnh sửa"),
      ),
      onTap: () => openWorkspaceNote(context, c, n.id),
      trailing: IconButton(
        tooltip: c.workspace.favorites.contains(n.id)
            ? context.tr("Bỏ yêu thích")
            : context.tr("Yêu thích"),
        onPressed: () => run(() => c.toggleFavorite(n.id)),
        icon: Icon(
          c.workspace.favorites.contains(n.id)
              ? Icons.star_rounded
              : Icons.star_border_rounded,
        ),
        color: c.workspace.favorites.contains(n.id)
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) {
      if (account == null || c.user?['id'] != account) {
        tasks.clear();
        return Scaffold(
          body: Center(child: Text(context.tr("Phiên đăng nhập đã thay đổi."))),
        );
      }
      final visible = c.workspaceNotes;
      // Purge task snapshots even when a different tab is active.
      tasks.purge(visible);
      final allTasks = tab == 0 || tab == 4
          ? tasks.select(visible)
          : <WorkspaceTask>[];
      final byId = {for (final n in visible) n.id: n};
      final favorite = visible
          .where((n) => c.workspace.favorites.contains(n.id))
          .toList();
      final recent = c.workspace.recent
          .where(byId.containsKey)
          .map((id) => byId[id]!)
          .toList();
      final view = c.workspace.views.where((v) => v.id == viewId).firstOrNull;
      final collectionNotes = view == null
          ? <Note>[]
          : visible.where(view.matches).toList();
      final query = taskQuery.text.trim().toLowerCase();
      final scopedTasks = allTasks
          .where(
            (r) =>
                (taskScope == 0 ||
                    (taskScope == 1
                        ? r.note.role == 'owner'
                        : r.note.role != 'owner')) &&
                (query.isEmpty ||
                    '${r.task.text}\n${r.note.title}'.toLowerCase().contains(
                      query,
                    )),
          )
          .toList();
      final rows = scopedTasks
          .where((r) => allStatuses || r.task.done == done)
          .toList();
      final completed = scopedTasks.where((r) => r.task.done).length;
      final taskProgressIds = scopedTasks.map((r) => r.note.id).toSet().toList()
        ..sort();
      final titles = [
        context.tr("Tổng quan"),
        context.tr("Yêu thích"),
        context.tr("Gần đây"),
        context.tr("Bộ sưu tập"),
        context.tr("Công việc"),
        context.tr("Mẫu riêng"),
        context.tr("Nhập / xuất"),
        context.tr("Tập trung"),
        context.tr("Kế hoạch"),
      ];
      final icons = [
        Icons.space_dashboard_outlined,
        Icons.star_border_rounded,
        Icons.history,
        Icons.filter_alt_outlined,
        Icons.checklist,
        Icons.auto_awesome_mosaic_outlined,
        Icons.import_export,
        Icons.timer_outlined,
        Icons.view_kanban_outlined,
      ];
      Widget content;
      Widget? itemSliver;
      Widget noteSliver(List<Note> source) => SliverList.builder(
        itemCount: source.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: noteRow(source[i]),
        ),
      );
      if (tab == 0) {
        content = SurfacePanel(
          tinted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeading(
                context.tr("Một nơi cho những việc quan trọng"),
                detail: context.tr(
                  "Ghi chú thành kế hoạch, lưu ý tưởng thành mẫu và quay lại đúng nơi bạn đang làm.",
                ),
                icon: Icons.auto_awesome,
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  MetadataPill(context.tr("{0} yêu thích", [favorite.length])),
                  MetadataPill(
                    context.tr("{0} việc cần làm", [
                      allTasks.where((r) => !r.task.done).length,
                    ]),
                  ),
                  MetadataPill(
                    context.tr("{0} mẫu riêng", [c.workspace.templates.length]),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => createWorkspaceDraft(
                      context,
                      c,
                      journalTemplate(DateTime.now()),
                    ),
                    icon: const Icon(Icons.today_outlined),
                    label: Text(context.tr("Nhật ký hôm nay")),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => tab = 4),
                    icon: const Icon(Icons.checklist),
                    label: Text(context.tr("Xem công việc")),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => tab = 5),
                    icon: const Icon(Icons.auto_awesome_mosaic_outlined),
                    label: Text(context.tr("Mẫu của tôi")),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => tab = 7),
                    icon: const Icon(Icons.timer_outlined),
                    label: Text(context.tr("Phiên tập trung")),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => tab = 8),
                    icon: const Icon(Icons.view_kanban_outlined),
                    label: Text(context.tr("Bảng kế hoạch")),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                context.tr(
                  "Yêu thích, lịch sử mở, bộ sưu tập và mẫu riêng được mã hóa theo tài khoản trên thiết bị này. Nội dung ghi chú vẫn đồng bộ qua server như bình thường.",
                ),
              ),
            ],
          ),
        );
      } else if (tab == 1 || tab == 2) {
        final source = tab == 1 ? favorite : recent;
        content = source.isEmpty
            ? StatusNotice(
                message: tab == 1
                    ? context.tr(
                        "Chọn ngôi sao trong Tìm nhanh hoặc bộ sưu tập để giữ ghi chú ở đây.",
                      )
                    : context.tr(
                        "Ghi chú bạn mở sẽ xuất hiện ở đây. Ghi chú khóa và mất quyền luôn được ẩn.",
                      ),
              )
            : const SizedBox.shrink();
        itemSliver = noteSliver(source);
      } else if (tab == 3) {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in c.workspace.views)
                  InputChip(
                    label: Text(v.name),
                    selected: v.id == viewId,
                    onPressed: () => setState(() => viewId = v.id),
                    onDeleted: () => confirmDelete(
                      v.name,
                      () => c.deleteWorkspaceView(v.id),
                    ),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: Text(context.tr("Tạo bộ sưu tập")),
                  onPressed: () => editView(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (view != null) ...[
              SectionHeading(
                view.name,
                detail: context.tr("{0} · {1} · {2} ghi chú", [
                  view.shared
                      ? context.tr("Được chia sẻ")
                      : context.tr("Của bạn"),
                  view.query.isEmpty ? context.tr("Mọi từ khóa") : view.query,
                  collectionNotes.length,
                ]),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => editView(view),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(context.tr("Sửa điều kiện")),
                ),
              ),
              const SizedBox(height: 12),
              if (collectionNotes.isEmpty)
                StatusNotice(
                  message: context.tr(
                    "Chưa có ghi chú khớp điều kiện. Bộ sưu tập tự cập nhật khi ghi chú thay đổi.",
                  ),
                ),
            ] else
              StatusNotice(
                message: context.tr(
                  "Tạo và chọn bộ sưu tập để lưu điều kiện tìm kiếm theo từ khóa, nhãn và nguồn ghi chú.",
                ),
              ),
          ],
        );
        if (view != null) itemSliver = noteSliver(collectionNotes);
      } else if (tab == 4) {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeading(
              context.tr("Checklist thành bảng công việc"),
              detail: context.tr(
                "Đọc tối đa 200 ghi chú chưa khóa và 100 mục mỗi ghi chú. Mở ghi chú để xử lý bản nháp hoặc xung đột.",
              ),
              icon: Icons.checklist,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(context.tr("Cần làm")),
                  selected: !allStatuses && !done,
                  onSelected: (_) => setState(() {
                    done = false;
                    allStatuses = false;
                  }),
                ),
                ChoiceChip(
                  label: Text(context.tr("Hoàn thành")),
                  selected: !allStatuses && done,
                  onSelected: (_) => setState(() {
                    done = true;
                    allStatuses = false;
                  }),
                ),
                ChoiceChip(
                  label: Text(context.tr("Tất cả trạng thái")),
                  selected: allStatuses,
                  onSelected: (_) => setState(() => allStatuses = true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: taskQuery,
              key: const Key('workspace-task-search'),
              maxLength: 200,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.tr("Tìm công việc hoặc tên ghi chú"),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: taskQuery.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: context.tr("Xóa tìm công việc"),
                        onPressed: () => setState(taskQuery.clear),
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < 3; i++)
                  ChoiceChip(
                    label: Text(
                      [
                        context.tr("Mọi nguồn"),
                        context.tr("Của bạn"),
                        context.tr("Được chia sẻ"),
                      ][i],
                    ),
                    selected: taskScope == i,
                    onSelected: (_) => setState(() => taskScope = i),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.tr("{0}/{1} hoàn thành · {2} kết quả", [
                completed,
                scopedTasks.length,
                rows.length,
              ]),
              key: const Key('workspace-task-progress'),
            ),
            const SizedBox(height: 8),
            PrismProgress(
              key: ValueKey(
                taskProgressIds.map((id) => '${id.length}:$id').join('|'),
              ),
              value: scopedTasks.isEmpty ? 0 : completed / scopedTasks.length,
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              StatusNotice(
                message: allTasks.isEmpty
                    ? context.tr(
                        "Chưa có công việc. Thêm checklist trong ghi chú để theo dõi ở đây.",
                      )
                    : context.tr(
                        "Không có công việc khớp bộ lọc. Hãy đổi trạng thái, nguồn hoặc từ khóa.",
                      ),
              ),
          ],
        );
        itemSliver = SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final row = rows[i];
            final editable =
                row.note.role != 'viewer' &&
                !c.hasPending(row.note.id) &&
                !c.drafts.containsKey(row.note.id) &&
                !c.conflicts.containsKey(row.note.id) &&
                !inFlight.contains(row.note.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfacePanel(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      semanticLabel: row.task.text,
                      value: row.task.done,
                      onChanged: !editable
                          ? null
                          : (_) async {
                              setState(() => inFlight.add(row.note.id));
                              await run(() => c.toggleWorkspaceTask(row));
                              if (mounted) {
                                setState(() => inFlight.remove(row.note.id));
                              }
                            },
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(row.task.text),
                        subtitle: Text(
                          '${row.note.title}${editable ? '' : context.tr(" · Mở để xem / xử lý")}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => openWorkspaceNote(context, c, row.note.id),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else if (tab == 5) {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => editTemplate(),
                icon: const Icon(Icons.add),
                label: Text(context.tr("Tạo mẫu riêng")),
              ),
            ),
            const SizedBox(height: 16),
            if (c.workspace.templates.isEmpty)
              StatusNotice(
                message: context.tr(
                  "Lưu cấu trúc bạn hay dùng. Mỗi lần sử dụng sẽ tạo một bản nháp mới.",
                ),
              ),
            for (final t in c.workspace.templates)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SurfacePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeading(t.title, detail: t.description),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: () =>
                                createWorkspaceDraft(context, c, t),
                            child: Text(context.tr("Dùng mẫu")),
                          ),
                          TextButton(
                            onPressed: () => editTemplate(t),
                            child: Text(context.tr("Sửa mẫu")),
                          ),
                          TextButton(
                            onPressed: () => confirmDelete(
                              t.title,
                              () => c.deletePersonalTemplate(t.id),
                            ),
                            child: Text(context.tr("Xóa mẫu")),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      } else if (tab == 7) {
        content = FocusPanel(controller: c);
      } else if (tab == 8) {
        content = const SizedBox.shrink();
        itemSliver = PlannerSliver(
          controller: c,
          view: plannerView,
          onOpen: (id) => openWorkspaceNote(context, c, id),
        );
      } else {
        content = SurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeading(
                context.tr("Mang ghi chú theo bạn"),
                detail: context.tr(
                  "File NoteTogether JSON giữ nội dung và định dạng soạn thảo. Tối đa 50 ghi chú / 5 MiB một lần.",
                ),
                icon: Icons.import_export,
              ),
              Text(
                context.tr(
                  "Bản xuất không mã hóa, không gồm ghi chú khóa, ghi chú được chia sẻ hoặc tệp đính kèm. Nhập sẽ tạo ID mới và không thay đổi quyền hay ghi đè ghi chú hiện có.",
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : importFile,
                    icon: const Icon(Icons.file_upload_outlined),
                    label: Text(
                      busy ? context.tr("Đang nhập…") : context.tr("Nhập file"),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : exportFile,
                    icon: const Icon(Icons.file_download_outlined),
                    label: Text(context.tr("Xuất ghi chú")),
                  ),
                ],
              ),
            ],
          ),
        );
      }
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
              showQuickFind(context, c),
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
              showQuickFind(context, c),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: noteAppBar(
              title: Text(
                context.tr("Không gian làm việc"),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  tooltip: context.tr("Tìm nhanh · Ctrl+K"),
                  onPressed: () => showQuickFind(context, c),
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            body: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: CustomScrollView(
                  key: PageStorageKey('workspace-tab-$tab'),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.all(
                        MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (MediaQuery.sizeOf(context).width >= 900 &&
                                MediaQuery.sizeOf(context).height >= 700 &&
                                MediaQuery.textScalerOf(context).scale(1) <
                                    1.5) ...[
                              PageIntro(
                                title: context.tr(
                                  "Không gian của những ý tưởng",
                                ),
                                detail: context.tr(
                                  "Tìm lại ghi chú, sắp xếp công việc và dành thời gian cho điều quan trọng.",
                                ),
                                icon: Icons.space_dashboard_outlined,
                                eyebrow: 'WORKSPACE',
                                accent: 2,
                              ),
                              const SizedBox(height: 24),
                            ],
                            if (MediaQuery.sizeOf(context).width < 600 ||
                                MediaQuery.textScalerOf(context).scale(1) >=
                                    1.5)
                              DropdownButtonFormField<int>(
                                key: ValueKey('workspace-navigation-$tab'),
                                initialValue: tab,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: context.tr("Phần đang xem"),
                                ),
                                items: [
                                  for (int i = 0; i < titles.length; i++)
                                    DropdownMenuItem(
                                      value: i,
                                      child: Text(titles[i]),
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => tab = v);
                                },
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (int i = 0; i < titles.length; i++)
                                    ChoiceChip(
                                      showCheckmark: false,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 4,
                                      ),
                                      labelPadding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      avatar: Icon(icons[i], size: 16),
                                      label: Text(titles[i]),
                                      selected: tab == i,
                                      onSelected: (_) =>
                                          setState(() => tab = i),
                                    ),
                                ],
                              ),
                            if (tab != 8) ...[
                              const SizedBox(height: 24),
                              PrismReveal(
                                key: ValueKey('workspace-section-$tab'),
                                duration: PrismMotion.section,
                                distance: 8,
                                child: content,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (itemSliver != null)
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.sizeOf(context).width < 600
                              ? 16
                              : 28,
                        ),
                        sliver: itemSliver,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
