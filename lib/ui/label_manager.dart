import '../l10n/app_strings.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'app.dart';
import 'design_system.dart';

/// Account-scoped catalogue. Rows are mounted lazily, including conflict actions.
class LabelManager extends StatefulWidget {
  const LabelManager({super.key, required this.controller});
  final AppController controller;
  @override
  State<LabelManager> createState() => _LabelManagerState();
}

class _LabelManagerState extends State<LabelManager> {
  AppController get c => widget.controller;
  late final account = c.user?['id'];
  late final token = c.token;
  final search = TextEditingController();
  final scroll = ScrollController();
  late List<Object?> observed;
  bool busy = false;
  String? error;
  bool get active =>
      account != null && c.user?['id'] == account && c.token == token;
  List<Object?> capture() => [
    c.user?['id'],
    c.token,
    c.syncing,
    c.online,
    c.localWriteFailed,
    c.pendingLabels.length,
    for (final id in c.labels)
      (id, c.labelName(id), c.labelConflicts.containsKey(id)),
    for (final id in c.labelConflicts.keys) ('conflict', id, c.labelName(id)),
  ];

  @override
  void initState() {
    super.initState();
    observed = capture();
    c.addListener(changed);
  }

  void changed() {
    if (!mounted) return;
    final next = capture();
    if (listEquals(observed, next)) return;
    observed = next;
    if (!active) {
      search.clear();
      error = null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    c.removeListener(changed);
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> action(Future<void> Function() work) async {
    if (!active || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await work();
    } catch (e) {
      if (mounted && active) {
        setState(
          () => error = c.localWriteFailed
              ? context.tr(
                  "Chưa ghi được nhãn trên thiết bị. Giữ cửa sổ mở và thử lại.",
                )
              : friendlyError(e),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit([String? id]) async {
    if (!active || busy) return;
    final form = GlobalKey<FormState>();
    var value = '';
    final name = await showDialog<String>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final available = active && (id == null || c.labels.contains(id));
          return AlertDialog(
            scrollable: true,
            title: Text(
              id == null ? context.tr("Thêm nhãn") : context.tr("Đổi tên nhãn"),
            ),
            content: available
                ? Form(
                    key: form,
                    child: TextFormField(
                      errorBuilder: (context, message) =>
                          Text(context.trMessage(message)),
                      key: const Key('label-name-input'),
                      initialValue: id == null ? '' : c.labelName(id),
                      autofocus: true,
                      maxLength: 60,
                      decoration: InputDecoration(
                        labelText: context.tr("Tên nhãn"),
                      ),
                      validator: (v) => c.validateLabelName(v ?? '', id),
                      onSaved: (v) => value = (v ?? '').trim(),
                    ),
                  )
                : Text(
                    context.tr(
                      "Tài khoản hoặc nhãn đã thay đổi. Hãy đóng cửa sổ này.",
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr("Hủy")),
              ),
              FilledButton(
                onPressed: !available
                    ? null
                    : () {
                        if (!form.currentState!.validate()) return;
                        form.currentState!.save();
                        Navigator.pop(context, value);
                      },
                child: Text(context.tr("Xác nhận")),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted ||
        !active ||
        name == null ||
        id != null && !c.labels.contains(id)) {
      return;
    }
    await action(() => id == null ? c.addLabel(name) : c.renameLabel(id, name));
  }

  Future<void> delete(String id) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final available = active && c.labels.contains(id);
          return AlertDialog(
            scrollable: true,
            title: Text(context.tr("Xóa nhãn?")),
            content: Text(
              available
                  ? context.tr("Bỏ nhãn “{0}”; các ghi chú vẫn còn.", [
                      c.labelName(id),
                    ])
                  : context.tr(
                      "Tài khoản hoặc nhãn đã thay đổi. Hãy đóng cửa sổ này.",
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr("Hủy")),
              ),
              FilledButton(
                onPressed: available
                    ? () => Navigator.pop(context, true)
                    : null,
                child: Text(context.tr("Xóa nhãn")),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted || !active || accepted != true || !c.labels.contains(id)) {
      return;
    }
    await action(() => c.removeLabel(id));
  }

  Widget row(String id) {
    final conflict = c.labelConflicts.containsKey(id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        key: ValueKey('managed-label-$id'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(c.labelName(id)),
                trailing: c.labels.contains(id)
                    ? PopupMenuButton<String>(
                        tooltip: context.tr("Thao tác với {0}", [
                          c.labelName(id),
                        ]),
                        enabled: !busy,
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (value) =>
                            value == 'rename' ? edit(id) : delete(id),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text(context.tr("Đổi tên")),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(context.tr("Xóa nhãn")),
                          ),
                        ],
                      )
                    : null,
              ),
              if (conflict) ...[
                const Divider(),
                Text(
                  context.tr(
                    "Tên nhãn có thay đổi khác trên máy chủ. Đổi tên để giữ lựa chọn của bạn, hoặc dùng bản máy chủ.",
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: c.syncing || busy
                        ? null
                        : () => action(() => c.useRemoteLabel(id)),
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: Text(context.tr("Dùng bản máy chủ")),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    final compact =
        room < 600 || MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final query = search.text.trim().toLowerCase();
    final ids = active
        ? {...c.labels, ...c.labelConflicts.keys}
              .where((id) => c.labelName(id).toLowerCase().contains(query))
              .toList()
        : <String>[];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: (room * .9).clamp(0, 720),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Scrollbar(
                    controller: scroll,
                    child: CustomScrollView(
                      key: const Key('label-manager-list'),
                      controller: scroll,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SectionHeading(
                                context.tr("Nhãn của tôi"),
                                detail: context.tr(
                                  "Nhóm ghi chú theo chủ đề. Xóa nhãn chỉ bỏ nhãn; ghi chú vẫn còn.",
                                ),
                                icon: Icons.label_outline,
                              ),
                              const SizedBox(height: 16),
                              if (active) ...[
                                TextField(
                                  key: const Key('label-manager-search'),
                                  controller: search,
                                  onChanged: (_) {
                                    if (scroll.hasClients) scroll.jumpTo(0);
                                    setState(() {});
                                  },
                                  decoration: InputDecoration(
                                    labelText: context.tr("Tìm nhãn"),
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: search.text.isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: context.tr("Xóa tìm nhãn"),
                                            icon: const Icon(Icons.close),
                                            onPressed: () {
                                              search.clear();
                                              if (scroll.hasClients) {
                                                scroll.jumpTo(0);
                                              }
                                              setState(() {});
                                            },
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  context.tr(
                                    "{0}/{1} nhãn · {2} thay đổi chờ đồng bộ",
                                    [
                                      ids.length,
                                      {
                                        ...c.labels,
                                        ...c.labelConflicts.keys,
                                      }.length,
                                      c.pendingLabels.length,
                                    ],
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (!c.online)
                                  Text(
                                    context.tr(
                                      "Offline: nhãn được lưu trên thiết bị và gửi khi kết nối lại.",
                                    ),
                                  ),
                              ] else
                                StatusNotice(
                                  message: context.tr(
                                    "Phiên đăng nhập đã thay đổi. Đóng và mở lại quản lý nhãn.",
                                  ),
                                ),
                              if (error != null)
                                StatusNotice(message: error!, error: true),
                              const SizedBox(height: 16),
                              if (active && ids.isEmpty)
                                Text(
                                  query.isEmpty
                                      ? context.tr(
                                          "Chưa có nhãn. Thêm nhãn để bắt đầu.",
                                        )
                                      : context.tr(
                                          "Không tìm thấy nhãn. Thử từ khóa khác.",
                                        ),
                                ),
                            ],
                          ),
                        ),
                        SliverList.builder(
                          itemCount: ids.length,
                          itemBuilder: (_, index) => row(ids[index]),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.tr("Đóng")),
                    ),
                    TextButton.icon(
                      onPressed: !active || busy || c.syncing
                          ? null
                          : () => action(c.synchronize),
                      icon: const Icon(Icons.sync),
                      label: Text(
                        c.syncing
                            ? context.tr("Đang đồng bộ…")
                            : compact
                            ? context.tr("Đồng bộ")
                            : context.tr("Đồng bộ nhãn"),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: !active || busy ? null : () => edit(),
                      icon: const Icon(Icons.add),
                      label: Text(context.tr("Thêm nhãn")),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
