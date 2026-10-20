import '../l10n/app_strings.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/note.dart';
import '../domain/writing_tools.dart';
import '../state/app_controller.dart';
import '../state/note_listing.dart';
import 'note_filters.dart';
import 'label_manager.dart';
import 'language_picker.dart';
import 'palette_picker.dart';
import 'dashboard.dart';
import 'dashboard_sync.dart';
import 'note_preview.dart';
import 'deskbook.dart';
import 'app.dart';
import 'editor.dart';
import 'design_system.dart';
import 'password_dialog.dart';
import 'note_protection.dart';
import 'avatar_editor.dart';
import 'sharing.dart';
import 'ai.dart';
import 'writing_studio.dart';
import 'workspace.dart';
import 'security_center.dart';

class UnverifiedBanner extends StatelessWidget {
  const UnverifiedBanner({super.key, required this.onCheck, this.delivery});
  final VoidCallback onCheck;
  final String? delivery;
  @override
  Widget build(BuildContext context) => StatusNotice(
    icon: Icons.mark_email_unread_outlined,
    message: ['not_configured', 'delivery_failed', 'failed'].contains(delivery)
        ? context.tr("Email chưa xác minh. Chưa gửi được mã.")
        : ['queued', 'retrying'].contains(delivery)
        ? context.tr(
            "Email chưa xác minh. Mã đang chờ gửi; ghi chú vẫn dùng được.",
          )
        : context.tr("Email của bạn chưa được xác minh."),
    action: TextButton(onPressed: onCheck, child: Text(context.tr("Xác minh"))),
  );
}

Future<bool> confirmDelete(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr("Xóa ghi chú?")),
        content: Text(context.tr("“{0}” sẽ bị xóa sau khi đồng bộ.", [title])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr("Hủy")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr("Xóa")),
          ),
        ],
      ),
    ) ??
    false;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String query = '';
  final search = TextEditingController();
  final searchFocus = FocusNode();
  final selectedLabels = <String>{};
  int destination = 0;
  Timer? searchDelay;
  final listingCache = NoteListingCache();
  bool routeCurrent = true;
  late List<Object?> observedView;
  AppController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    observedView = captureView();
    c.addListener(controllerChanged);
  }

  // Metadata needed by this view; no private body/search index is added.
  // Sync-only fields belong to DashboardSync, which listens independently.
  List<Object?> captureView() => [
    c.user?['id'],
    c.user?['name'],
    c.user?['verified'],
    c.avatarBytes,
    c.cachedAvatarRevision,
    c.grid,
    c.dark,
    c.language,
    c.palette,
    c.fontSize,
    c.error,
    c.localWriteFailed,
    if (c.error != null) c.online,
    c.emailDelivery,
    c.recoveries.length,
    c.protectedVaults.values.any((v) => v['dirty'] == true),
    for (final id in c.drafts.keys) ('draft', id),
    for (final id
        in (c.pending.map((op) => op['note_id']).toSet().toList()
          ..sort((a, b) => '$a'.compareTo('$b'))))
      ('pending', id),
    for (final id in (c.conflicts.keys.toList()..sort())) ('conflict', id),
    for (final id in c.labels) ('label-order', id),
    for (final entry in c.labelCatalogue.entries)
      ('label', entry.key, entry.value['name'], entry.value['deleted']),
  ];

  void controllerChanged() {
    // Source changes also purge private widgets retained behind a route.
    final sourceChanged = listingCache.invalidateSource(
      c.user?['id'] as String?,
      c.notes,
    );
    final nextView = captureView();
    final viewChanged = !listEquals(observedView, nextView);
    observedView = nextView;
    if (mounted && (sourceChanged || routeCurrent && viewChanged)) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeCurrent = ModalRoute.isCurrentOf(context) ?? true;
  }

  Future<void> filterLabels() async {
    final account = c.user?['id'];
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => NoteLabelFilter(controller: c, selected: selectedLabels),
    );
    if (!mounted || result == null || account != c.user?['id']) return;
    setState(() {
      selectedLabels
        ..clear()
        ..addAll(result.where(c.labels.contains));
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != c) {
      oldWidget.controller.removeListener(controllerChanged);
      listingCache.clear();
      observedView = captureView();
      c.addListener(controllerChanged);
    }
  }

  @override
  void dispose() {
    c.removeListener(controllerChanged);
    listingCache.clear();
    search.dispose();
    searchFocus.dispose();
    searchDelay?.cancel();
    super.dispose();
  }

  void open({Note? note, String? draftId}) {
    if (note?.locked == true) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProtectedNoteScreen(controller: c, id: note!.id),
        ),
      );
      return;
    }
    final editorId = note?.id ?? draftId ?? c.uuid.v4();
    if (note != null) {
      unawaited(c.recordRecent(note.id).catchError((Object _) {}));
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(controller: c, id: editorId),
      ),
    );
  }

  static const destinations = ['Ghi chú', 'Được chia sẻ', 'Hỏi ghi chú'];
  Future<void> createFromTemplate() async {
    final account = c.user?['id'];
    final template = await Navigator.of(context).push<NoteTemplate>(
      MaterialPageRoute(builder: (_) => const TemplateGallery()),
    );
    if (!mounted ||
        template == null ||
        account == null ||
        c.user?['id'] != account) {
      return;
    }
    final id = c.uuid.v4();
    try {
      await c.draft(id, template.title, template.content);
      if (mounted && c.user?['id'] == account) open(draftId: id);
    } catch (e) {
      if (mounted) {
        showMessage(
          context,
          context.tr("Chưa lưu được bản nháp từ mẫu. Hãy thử lại."),
        );
      }
    }
  }

  static const icons = [
    Icons.notes_outlined,
    Icons.people_outline,
    Icons.auto_awesome_outlined,
  ];

  Widget createButton({bool compact = false}) => compact
      ? IconButton.filled(
          key: const Key('new-note'),
          tooltip: context.tr("Ghi chú mới"),
          onPressed: () => open(),
          style: IconButton.styleFrom(
            backgroundColor: DashboardColors.action,
            foregroundColor: DashboardColors.actionInk,
          ),
          icon: const Icon(Icons.add),
        )
      : FilledButton.icon(
          key: const Key('new-note'),
          onPressed: () => open(),
          style: FilledButton.styleFrom(
            backgroundColor: DashboardColors.action,
            foregroundColor: DashboardColors.actionInk,
          ),
          icon: const Icon(Icons.add),
          label: Text(context.tr("Ghi chú mới")),
        );

  Widget dashboardHeader(
    bool small,
    int count,
    String syncLabel, {
    bool studio = false,
  }) => DashboardHeader(
    key: const Key('dashboard-header'),
    workbench: studio,
    title: destination == 1
        ? (small
              ? context.tr("Được chia sẻ")
              : context.tr("Được chia sẻ với bạn"))
        : context.tr("Ghi chú của bạn"),
    detail: destination == 1
        ? context.tr("Cùng theo dõi những điều quan trọng của nhóm.")
        : context.tr("Ý tưởng, bài học và kế hoạch — gọn trong một nơi."),
    count: count,
    syncLabel: syncLabel,
    syncIndicator: DashboardSync(controller: c),
    online: c.online,
    onSync: c.synchronize,
    action: small || studio
        ? null
        : createButton(
            compact:
                MediaQuery.textScalerOf(context).scale(1) >= 1.5 ||
                MediaQuery.sizeOf(context).width < 900,
          ),
    notice: c.user?['verified'] == true && c.error == null
        ? null
        : Column(
            children: [
              if (c.user?['verified'] != true)
                UnverifiedBanner(
                  delivery: c.emailDelivery,
                  onCheck: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TokenScreen(controller: c),
                    ),
                  ),
                ),
              if (c.error != null) ...[
                if (c.user?['verified'] != true) const SizedBox(height: 12),
                StatusNotice(
                  message: c.localWriteFailed
                      ? c.error!
                      : c.online
                      ? context.tr("Chưa thể đồng bộ. Hãy thử lại.")
                      : context.tr(
                          "Đang offline. Các thay đổi đã lưu trên thiết bị đang chờ kết nối.",
                        ),
                  icon: Icons.cloud_off_outlined,
                  action: TextButton(
                    onPressed: c.synchronize,
                    child: Text(context.tr("Thử lại")),
                  ),
                ),
              ],
            ],
          ),
  );

  void openWorkspace() => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => WorkspaceScreen(controller: c)),
  );

  Widget filterToolbar(bool small, bool sidebar) {
    final colors = Theme.of(context).colorScheme;
    final palette = PrismPalette.of(context);
    // Keep the first viewport useful even with hundreds of labels.
    final visibleLabels = selectedLabels
        .followedBy(c.labels.where((id) => !selectedLabels.contains(id)))
        .take(6);
    final tools = <Widget>[
      SegmentedButton<bool>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(minimumSize: const Size(48, 48)),
        segments: [
          ButtonSegment(
            value: true,
            icon: small ? null : const Icon(Icons.grid_view),
            label: Text(context.tr("Lưới")),
          ),
          ButtonSegment(
            value: false,
            icon: small ? null : const Icon(Icons.view_list_outlined),
            label: Text(context.tr("Danh sách")),
          ),
        ],
        selected: {c.grid},
        onSelectionChanged: (values) =>
            c.setPreferences({'grid': values.single}),
      ),
      if (!small && !sidebar)
        TextButton.icon(
          key: const Key('note-templates'),
          onPressed: createFromTemplate,
          icon: const Icon(Icons.auto_awesome_mosaic_outlined),
          label: Text(context.tr("Xưởng ghi chú")),
        ),
      if (!sidebar && !small)
        TextButton.icon(
          key: const Key('open-workspace'),
          onPressed: openWorkspace,
          icon: const Icon(Icons.space_dashboard_outlined),
          label: Text(context.tr("Không gian làm việc")),
        ),
      if (!sidebar && !small)
        IconButton(
          tooltip: context.tr("Tìm nhanh · Ctrl+K"),
          onPressed: () => showQuickFind(context, c),
          icon: const Icon(Icons.manage_search),
        ),
      if (!sidebar)
        IconButton(
          tooltip: context.tr("Quản lý nhãn"),
          onPressed: manageLabels,
          icon: const Icon(Icons.label_outline),
        ),
      if (small)
        PopupMenuButton<String>(
          key: const Key('library-tools'),
          tooltip: context.tr("Công cụ thư viện"),
          icon: const Icon(Icons.more_horiz),
          onSelected: (value) {
            if (value == 'workspace') {
              openWorkspace();
            } else {
              showQuickFind(context, c);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'workspace',
              child: Text(context.tr("Không gian làm việc")),
            ),
            PopupMenuItem(value: 'find', child: Text(context.tr("Tìm nhanh"))),
          ],
        ),
    ];
    return SurfacePanel(
      key: const Key('note-filter-toolbar'),
      backgroundColors: [
        Color.alphaBlend(
          palette.tones[0].light.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? .10 : .20,
          ),
          colors.surface,
        ),
        Color.alphaBlend(
          palette.tones[1].light.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? .07 : .10,
          ),
          colors.surface,
        ),
      ],
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: c.labels.isEmpty ? 0 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (small && MediaQuery.textScalerOf(context).scale(1) < 1.5)
            Row(
              children: [
                Expanded(child: tools.first),
                ...tools.skip(1),
              ],
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: tools,
            ),
          if (c.labels.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final label in visibleLabels)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: FilterChip(
                      backgroundColor: Color.alphaBlend(
                        palette.tone(label).light.withValues(alpha: .08),
                        colors.surface,
                      ),
                      selectedColor: Color.alphaBlend(
                        palette.tone(label).light.withValues(alpha: .22),
                        colors.surface,
                      ),
                      labelStyle: TextStyle(color: palette.tone(label).ink),
                      checkmarkColor: palette.tone(label).ink,
                      tooltip: c.labelName(label),
                      label: Text(
                        c.labelName(label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: selectedLabels.contains(label),
                      onSelected: (value) => setState(() {
                        if (value) {
                          selectedLabels.add(label);
                        } else {
                          selectedLabels.remove(label);
                        }
                      }),
                    ),
                  ),
                OutlinedButton.icon(
                  key: const Key('all-label-filters'),
                  onPressed: filterLabels,
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(
                    selectedLabels.isEmpty
                        ? context.tr("Bộ lọc nhãn")
                        : context.tr("Bộ lọc ({0})", [selectedLabels.length]),
                  ),
                ),
              ],
            ),
          ],
          if (selectedLabels.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  context.tr("Khớp tất cả {0} nhãn đã chọn", [
                    selectedLabels.length,
                  ]),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: () => setState(selectedLabels.clear),
                  child: Text(context.tr("Bỏ bộ lọc nhãn")),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final small = size.maxWidth < 600;
      selectedLabels.removeWhere((id) => !c.labels.contains(id));
      final sidebar =
          size.maxWidth >= 1180 &&
          size.maxHeight >= 700 &&
          MediaQuery.textScalerOf(context).scale(1) < 1.5;
      final totalPending =
          c.pending.length +
          c.pendingPreferences.length +
          c.pendingLabels.length;
      final syncLabel = c.syncing
          ? context.tr("Đang đồng bộ…")
          : !c.online
          ? context.tr("Offline · {0} thay đổi chờ", [totalPending])
          : totalPending > 0
          ? context.tr("{0} thay đổi chờ đồng bộ", [totalPending])
          : c.realtimeLive
          ? context.tr("Trực tiếp")
          : c.realtime != null
          ? context.tr("Đang nối lại")
          : context.tr("Đã đồng bộ");
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
              searchFocus.requestFocus(),
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
              showQuickFind(context, c),
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
              showQuickFind(context, c),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: small
                ? noteAppBar(
                    title: const Brand(),
                    actions: [
                      if (destination != 2)
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary,
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onPrimary,
                          ),
                          key: const Key('new-note'),
                          tooltip: context.tr("Ghi chú mới"),
                          onPressed: () => open(),
                          icon: const Icon(Icons.add),
                        ),
                      IconButton(
                        key: const Key('note-templates'),
                        tooltip: context.tr("Xưởng ghi chú"),
                        onPressed: createFromTemplate,
                        icon: const Icon(Icons.auto_awesome_mosaic_outlined),
                      ),
                      IconButton(
                        tooltip: context.tr("Hồ sơ và tùy chỉnh"),
                        onPressed: settings,
                        icon: const Icon(Icons.account_circle_outlined),
                      ),
                    ],
                  )
                : null,
            bottomNavigationBar: small
                ? NavigationBar(
                    selectedIndex: destination,
                    onDestinationSelected: (v) =>
                        setState(() => destination = v),
                    destinations: List.generate(
                      3,
                      (i) => NavigationDestination(
                        icon: Icon(icons[i]),
                        label: context.tr(destinations[i]),
                      ),
                    ),
                  )
                : null,
            body: SafeArea(
              child: DashboardBackdrop(
                child: Column(
                  children: [
                    if (sidebar)
                      DeskMasthead(
                        destinations: destinations
                            .map((s) => context.tr(s))
                            .toList(),
                        selected: destination,
                        onSelected: (value) =>
                            setState(() => destination = value),
                        create: createButton(),
                        avatar: AccountAvatar(controller: c, radius: 16),
                        onAccount: settings,
                        onQuickFind: () => showQuickFind(context, c),
                      ),
                    Expanded(
                      child: Row(
                        children: [
                          if (!small && !sidebar)
                            NavigationRail(
                              selectedIndex: destination,
                              labelType: NavigationRailLabelType.all,
                              leading: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Brand(compact: true),
                              ),
                              trailing: IconButton(
                                tooltip: context.tr("Hồ sơ và tùy chỉnh"),
                                onPressed: settings,
                                icon: const Icon(Icons.account_circle_outlined),
                              ),
                              onDestinationSelected: (v) =>
                                  setState(() => destination = v),
                              destinations: List.generate(
                                3,
                                (i) => NavigationRailDestination(
                                  icon: Icon(icons[i]),
                                  label: Text(context.tr(destinations[i])),
                                ),
                              ),
                            ),
                          if (!small && !sidebar)
                            const VerticalDivider(width: 1),
                          Expanded(
                            child: destination == 2
                                ? AiQuestionsPanel(controller: c)
                                : LayoutBuilder(
                                    builder: (context, area) {
                                      final padding = small ? 16.0 : 24.0;
                                      final scale = MediaQuery.textScalerOf(
                                        context,
                                      ).scale(1);
                                      final listing = listingCache.select(
                                        account: c.user?['id'] as String?,
                                        notes: c.notes,
                                        query: query,
                                        shared: destination == 1,
                                        labels: selectedLabels,
                                        deletedLabels: c.labelCatalogue.entries
                                            .where(
                                              (entry) =>
                                                  entry.value['deleted'] ==
                                                  true,
                                            )
                                            .map((entry) => entry.key)
                                            .toSet(),
                                      );
                                      final list = listing.all,
                                          pinned = listing.pinned,
                                          remaining = listing.remaining;
                                      return CustomScrollView(
                                        key: PageStorageKey(
                                          'notes-$destination',
                                        ),
                                        slivers: [
                                          SliverPadding(
                                            padding: EdgeInsets.fromLTRB(
                                              padding,
                                              small ? 12 : 16,
                                              padding,
                                              small ? 12 : 24,
                                            ),
                                            sliver: SliverToBoxAdapter(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  dashboardHeader(
                                                    small,
                                                    list.length,
                                                    syncLabel,
                                                    studio: sidebar,
                                                  ),
                                                  const SizedBox(height: 24),
                                                  TextField(
                                                    key: const Key(
                                                      'note-search',
                                                    ),
                                                    controller: search,
                                                    focusNode: searchFocus,
                                                    decoration: InputDecoration(
                                                      prefixIcon: const Icon(
                                                        Icons.search,
                                                      ),
                                                      hintText: context.tr(
                                                        "Tìm trong tiêu đề và nội dung",
                                                      ),
                                                      labelText: context.tr(
                                                        "Tìm ghi chú",
                                                      ),
                                                      helperText:
                                                          area.maxWidth < 800
                                                          ? null
                                                          : context.tr(
                                                              "Tìm ngay khi nhập · Ctrl + F để đến ô tìm kiếm",
                                                            ),
                                                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                                        valueListenable: search,
                                                        builder: (_, value, _) =>
                                                            value.text.isEmpty
                                                            ? const SizedBox.shrink()
                                                            : IconButton(
                                                                tooltip: context
                                                                    .tr(
                                                                      "Xóa tìm kiếm",
                                                                    ),
                                                                icon: const Icon(
                                                                  Icons.close,
                                                                ),
                                                                onPressed: () {
                                                                  searchDelay
                                                                      ?.cancel();
                                                                  search
                                                                      .clear();
                                                                  setState(
                                                                    () =>
                                                                        query =
                                                                            '',
                                                                  );
                                                                },
                                                              ),
                                                      ),
                                                    ),
                                                    onChanged: (v) {
                                                      searchDelay?.cancel();
                                                      searchDelay = Timer(
                                                        const Duration(
                                                          milliseconds: 300,
                                                        ),
                                                        () {
                                                          if (mounted) {
                                                            setState(
                                                              () => query = v
                                                                  .trim()
                                                                  .toLowerCase(),
                                                            );
                                                          }
                                                        },
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 16),
                                                  filterToolbar(small, sidebar),
                                                  if (c.drafts.isNotEmpty)
                                                    Wrap(
                                                      spacing: 8,
                                                      children: c.drafts.keys
                                                          .map(
                                                            (id) => ActionChip(
                                                              avatar: const Icon(
                                                                Icons.edit_note,
                                                              ),
                                                              label: Text(
                                                                context.tr(
                                                                  "Khôi phục bản nháp",
                                                                ),
                                                              ),
                                                              onPressed: () =>
                                                                  open(
                                                                    draftId: id,
                                                                  ),
                                                            ),
                                                          )
                                                          .toList(),
                                                    ),
                                                  if (c.protectedVaults.values
                                                      .any(
                                                        (r) =>
                                                            r['dirty'] == true,
                                                      ))
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 12,
                                                          ),
                                                      child: StatusNotice(
                                                        icon:
                                                            Icons.lock_outline,
                                                        message: context.tr(
                                                          "Có bản nháp bảo vệ được giữ mã hóa trên thiết bị.",
                                                        ),
                                                        action: TextButton(
                                                          key: const Key(
                                                            'open-protected-recovery',
                                                          ),
                                                          onPressed:
                                                              protectedRecovery,
                                                          child: Text(
                                                            context.tr(
                                                              "Bản nháp bảo vệ",
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (c.recoveries.isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 12,
                                                          ),
                                                      child: StatusNotice(
                                                        icon: Icons
                                                            .enhanced_encryption_outlined,
                                                        message: context.tr(
                                                          "{0} bản chỉnh sửa đã được giữ an toàn trên thiết bị.",
                                                          [c.recoveries.length],
                                                        ),
                                                        action: TextButton(
                                                          key: const Key(
                                                            'open-recovery',
                                                          ),
                                                          onPressed: recovery,
                                                          child: Text(
                                                            context.tr(
                                                              "Phục hồi",
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (list.isEmpty)
                                            SliverToBoxAdapter(
                                              child: EmptyNotes(
                                                title:
                                                    query.isNotEmpty ||
                                                        selectedLabels
                                                            .isNotEmpty
                                                    ? context.tr(
                                                        "Không tìm thấy ghi chú phù hợp",
                                                      )
                                                    : destination == 1
                                                    ? context.tr(
                                                        "Chưa có ghi chú được chia sẻ",
                                                      )
                                                    : context.tr(
                                                        "Bắt đầu với ghi chú đầu tiên",
                                                      ),
                                                detail:
                                                    query.isNotEmpty ||
                                                        selectedLabels
                                                            .isNotEmpty
                                                    ? context.tr(
                                                        "Thử từ khóa khác hoặc bỏ bớt nhãn.",
                                                      )
                                                    : destination == 1
                                                    ? context.tr(
                                                        "Ghi chú được chia sẻ với tài khoản của bạn sẽ xuất hiện ở đây.",
                                                      )
                                                    : context.tr(
                                                        "Một ý tưởng, một bài học, một điều cần nhớ.",
                                                      ),
                                                action:
                                                    query.isNotEmpty ||
                                                        selectedLabels
                                                            .isNotEmpty
                                                    ? TextButton(
                                                        onPressed: () {
                                                          searchDelay?.cancel();
                                                          search.clear();
                                                          setState(() {
                                                            query = '';
                                                            selectedLabels
                                                                .clear();
                                                          });
                                                        },
                                                        child: Text(
                                                          context.tr(
                                                            "Xóa tìm kiếm và bộ lọc",
                                                          ),
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          if (pinned.isNotEmpty)
                                            ...section(
                                              context.tr("Đã ghim"),
                                              pinned,
                                              area.maxWidth,
                                              padding,
                                              scale,
                                            ),
                                          if (remaining.isNotEmpty)
                                            ...section(
                                              pinned.isEmpty
                                                  ? context.tr("Tất cả ghi chú")
                                                  : context.tr(
                                                      "Các ghi chú khác",
                                                    ),
                                              remaining,
                                              area.maxWidth,
                                              padding,
                                              scale,
                                            ),
                                          const SliverToBoxAdapter(
                                            child: SizedBox(height: 32),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                          if (sidebar && destination != 2)
                            DeskToolDrawer(
                              onTemplates: createFromTemplate,
                              onWorkspace: openWorkspace,
                              onLabels: manageLabels,
                              onAccount: settings,
                            ),
                        ],
                      ),
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

  List<Widget> section(
    String title,
    List<Note> notes,
    double width,
    double padding,
    double scale,
  ) {
    // At large text scales use naturally sized cards instead of guessing a
    // fixed tile height. The saved grid preference is preserved on resize.
    final tiles = c.grid && scale < 1.5;
    final shelf =
        tiles &&
        title == context.tr("Đã ghim") &&
        notes.length >= 2 &&
        width - padding * 2 >= 800;
    final extent =
        (320 +
            (notes.any((n) => !n.locked && n.role != 'owner') ? 48 : 0) +
            (c.fontSize - 16).clamp(0, 8) * 10 +
            (c.conflicts.isNotEmpty ? 64 : 0)) *
        scale;
    Widget cover(Note note) => note.locked
        ? noteCard(note, tile: true)
        : Theme(
            data: noteTheme(
              Theme.of(context).brightness == Brightness.light
                  ? Brightness.dark
                  : Brightness.light,
              palette: c.palette,
            ),
            child: Builder(
              builder: (appearance) =>
                  noteCard(note, tile: true, appearance: appearance),
            ),
          );
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(padding, 8, padding, 16),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              if (title == context.tr("Đã ghim")) ...[
                Icon(
                  Icons.push_pin_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${notes.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      if (shelf)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, 20),
          sliver: SliverToBoxAdapter(
            child: PinnedShelf(
              first: cover(notes[0]),
              second: noteCard(notes[1], tile: true),
              height: extent,
            ),
          ),
        ),
      if (!shelf || notes.length > 2)
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          sliver: tiles && title == context.tr("Đã ghim") && notes.length == 1
              ? SliverToBoxAdapter(child: noteCard(notes.single, compact: true))
              : tiles
              ? SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ((width - padding * 2) / (260 * scale))
                        .floor()
                        .clamp(1, 4),
                    mainAxisExtent:
                        (320 +
                            (notes.any((n) => !n.locked && n.role != 'owner')
                                ? 48
                                : 0) +
                            (c.fontSize - 16).clamp(0, 8) * 10 +
                            (c.conflicts.isNotEmpty ? 64 : 0)) *
                        scale,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => noteCard(notes[i + (shelf ? 2 : 0)], tile: true),
                    childCount: notes.length - (shelf ? 2 : 0),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: noteCard(notes[i]),
                    ),
                    childCount: notes.length,
                  ),
                ),
        ),
    ];
  }

  Widget noteCard(
    Note note, {
    bool compact = false,
    bool tile = false,
    BuildContext? appearance,
  }) {
    final visual = appearance ?? context;
    final colors = Theme.of(visual).colorScheme;
    final palette = PrismPalette.of(visual);
    final tone = note.locked ? null : palette.tone(note.id);
    final date = note.locked
        ? null
        : DateTime.tryParse(note.updatedAt)?.toLocal();
    final dateText = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final labelIds = note.locked ? const <String>[] : c.noteLabelIds(note);
    return PrismCard(
      key: ValueKey('card-${note.id}'),
      tone: tone,
      rich: true,
      onTap: () => open(note: note),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: tile ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: note.locked
                          ? colors.surfaceContainerHighest
                          : Color.alphaBlend(
                              tone!.light.withValues(alpha: .22),
                              colors.surface,
                            ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      note.locked
                          ? Icons.lock_outline
                          : Icons.description_outlined,
                      size: 20,
                      color: note.locked ? colors.onSurfaceVariant : tone!.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.locked ? context.tr("Ghi chú đã khóa") : note.title,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(visual).textTheme.titleMedium?.copyWith(
                      fontSize: appearance != null ? 26 : 18,
                      fontWeight: appearance != null
                          ? FontWeight.w500
                          : FontWeight.w600,
                    ),
                  ),
                ),
                if (note.role == 'owner' && !note.locked)
                  PopupMenuButton<String>(
                    tooltip: context.tr("Thao tác ghi chú"),
                    onSelected: (action) async {
                      if (action == 'pin') {
                        await c.save(
                          note.id,
                          note.title,
                          note.content,
                          updatePin: true,
                          pinnedAt: note.pinnedAt == null
                              ? DateTime.now().toUtc().toIso8601String()
                              : null,
                        );
                      }
                      if (action == 'delete' &&
                          mounted &&
                          await confirmDelete(context, note.title)) {
                        await c.delete(note);
                      }
                      if (action == 'protect' && mounted) {
                        await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => NoteProtectionDialog(
                            controller: c,
                            id: note.id,
                            action: ProtectionAction.enable,
                          ),
                        );
                      }
                      if (action == 'share' && mounted) {
                        await showDialog<void>(
                          context: context,
                          builder: (_) =>
                              ShareDialog(controller: c, noteId: note.id),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'share',
                        child: Text(context.tr("Chia sẻ")),
                      ),
                      PopupMenuItem(
                        value: 'pin',
                        child: Text(
                          note.pinnedAt == null
                              ? context.tr('Ghim')
                              : context.tr("Bỏ ghim"),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'protect',
                        child: Text(context.tr("Bật khóa ghi chú")),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(context.tr("Xóa")),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            NotePreview(
              note: note,
              maxLines: tile ? 4 : 2,
              style: TextStyle(
                fontSize: c.fontSize,
                height: 1.5,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (tile) const Spacer(),
            if (!note.locked && note.role != 'owner')
              Text(
                context.tr("Từ {0} · {1}", [
                  note.sharedByName ??
                      note.sharedByEmail ??
                      context.tr("Chủ sở hữu"),
                  sharingDate(note.sharedAt ?? ''),
                ]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(visual).textTheme.bodySmall,
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (note.pinnedAt != null)
                  MetadataPill(
                    context.tr("Đã ghim"),
                    icon: Icons.push_pin_outlined,
                    tone: palette.tones[4],
                  ),
                if (note.isShared)
                  Tooltip(
                    message: note.locked
                        ? context.tr("Ghi chú được chia sẻ")
                        : note.role == 'owner'
                        ? context.tr("Đã chia sẻ cho {0} người", [
                            note.sharedCount,
                          ])
                        : context.tr("Được chia sẻ với bạn"),
                    child: Icon(
                      Icons.people_outline,
                      size: 20,
                      semanticLabel: context.tr("Ghi chú được chia sẻ"),
                    ),
                  ),
                if (note.locked)
                  Icon(
                    Icons.lock_outline,
                    size: 20,
                    semanticLabel: context.tr("Đã khóa"),
                  ),
                if (note.role != 'owner')
                  Text(
                    note.role == 'viewer'
                        ? context.tr("Chỉ xem")
                        : context.tr("Có thể chỉnh sửa"),
                    style: Theme.of(visual).textTheme.bodySmall,
                  ),
                if (!note.locked)
                  ...labelIds
                      .take(2)
                      .map(
                        (l) => MetadataPill(
                          '#${c.labelName(l, note)}',
                          tone: palette.tone(l),
                        ),
                      ),
                if (!note.locked && labelIds.length > 2)
                  Text(
                    context.tr("+{0} nhãn", [labelIds.length - 2]),
                    style: Theme.of(visual).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(dateText, style: Theme.of(visual).textTheme.bodySmall),
                if (c.hasPending(note.id))
                  Text(
                    context.tr("Chờ đồng bộ"),
                    style: TextStyle(color: colors.primary, fontSize: 13),
                  ),
                if (c.conflicts.containsKey(note.id))
                  ActionChip(
                    label: Text(
                      context.tr(
                        c.conflicts[note.id]['status'] == 422
                            ? 'Xử lý thay đổi bị từ chối'
                            : "Xử lý xung đột",
                      ),
                    ),
                    onPressed: () => conflict(note.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> protectedRecovery() async {
    final items = c.protectedVaults.entries
        .where((r) => r.value['dirty'] == true)
        .toList();
    final id = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(context.tr("Bản nháp bảo vệ")),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              context.tr(
                "Cần mật khẩu cũ để đọc bản chỉnh sửa riêng. Không cấp quyền truy cập lên máy chủ.",
              ),
            ),
          ),
          for (var i = 0; i < items.length; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, items[i].key),
              child: Text(context.tr("Bản chỉnh sửa {0}", [i + 1])),
            ),
        ],
      ),
    );
    if (id != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ProtectedNoteScreen(controller: c, id: id, recoveryMode: true),
        ),
      );
    }
  }

  Future<void> recovery() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: DialogHeading(
          context.tr("Phục hồi chỉnh sửa local"),
          icon: Icons.restore_outlined,
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr(
                    "Tạo ghi chú mới từ nội dung bạn đã gõ trước khi quyền truy cập thay đổi. Bản phục hồi chỉ có trên thiết bị này; ghi chú gốc vẫn giữ quyền bảo vệ của nó.",
                  ),
                ),
                const SizedBox(height: 16),
                ...c.recoveries.entries.map(
                  (entry) => ListTile(
                    leading: const Icon(Icons.enhanced_encryption_outlined),
                    title: Text(context.tr("Bản chỉnh sửa đã giữ")),
                    subtitle: Text(
                      context.tr("Lưu: {0}", [
                        (entry.value as Map)['saved_at'],
                      ]),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, entry.key),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr("Đóng")),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    try {
      final draftId = await c.restoreRecovery(choice);
      if (mounted) open(draftId: draftId);
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          context.tr(
            "Chưa tạo được bản nháp phục hồi. Bản mã hóa vẫn được giữ; hãy thử lại.",
          ),
        );
      }
    }
  }

  Future<void> logout() async {
    if (c.pending.isNotEmpty ||
        c.pendingPreferences.isNotEmpty ||
        c.pendingLabels.isNotEmpty) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr("Đăng xuất khi còn thay đổi?")),
          content: Text(
            context.tr(
              "Thay đổi đã lưu trên thiết bị sẽ nằm trong tài khoản này. Đăng nhập lại để tiếp tục đồng bộ.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr("Ở lại")),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr("Đăng xuất")),
            ),
          ],
        ),
      );
      if (accepted != true) return;
    }
    await c.logout();
  }

  Future<void> conflict(String id) async {
    final local = c.notes.where((n) => n.id == id).firstOrNull;
    final action = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: DialogHeading(
          context.tr(
            c.conflicts[id]?['status'] == 422
                ? 'Máy chủ từ chối thay đổi'
                : "Có hai phiên bản thay đổi",
          ),
          icon: Icons.difference_outlined,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(
                  "Giữ bản của bạn dưới dạng ghi chú mới, hoặc dùng bản từ máy chủ và bỏ thay đổi chưa đồng bộ.",
                ),
              ),
              if (local != null && !local.locked) ...[
                const SizedBox(height: 16),
                Text(context.tr("Bản trên thiết bị")),
                Text(local.title),
                Text(
                  local.plainContent,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr("Để sau")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr("Dùng bản máy chủ")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr("Giữ bản sao của tôi")),
          ),
        ],
      ),
    );
    if (action != null) {
      try {
        await c.resolveConflict(id, keepCopy: action);
      } catch (_) {
        if (mounted) {
          showMessage(
            context,
            context.tr(
              "Chưa lưu được lựa chọn phục hồi. Bản cũ vẫn được giữ; hãy thử lại.",
            ),
          );
        }
      }
    }
  }

  Future<void> manageLabels() async {
    final account = c.user?['id'];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => LabelManager(controller: c),
    );
    if (!mounted || account != c.user?['id']) return;
    selectedLabels.removeWhere((l) => !c.labels.contains(l));
    setState(() {});
  }

  Future<void> settings() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AnimatedBuilder(
      animation: c,
      builder: (context, _) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SectionHeading(
                        context.tr("Hồ sơ và tùy chỉnh"),
                        icon: Icons.tune_outlined,
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr("Đóng tùy chỉnh"),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  tileColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: AccountAvatar(controller: c),
                  title: Text(c.user?['name'] as String? ?? ''),
                  trailing: IconButton(
                    tooltip: context.tr("Sửa tên hiển thị"),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final name = await askText(
                        context,
                        context.tr("Tên hiển thị"),
                        initial: c.user?['name'] as String? ?? '',
                      );
                      if (name == null) return;
                      try {
                        await c.api.call(
                          'PATCH',
                          '/me',
                          token: c.token,
                          body: {'name': name},
                        );
                        await c.synchronize();
                      } catch (e) {
                        if (context.mounted) {
                          showMessage(context, friendlyError(e));
                        }
                      }
                    },
                  ),
                ),
                SelectableText(
                  c.user?['email'] as String? ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AvatarEditor(controller: c),
                  ),
                  icon: const Icon(Icons.image_outlined),
                  label: Text(context.tr("Đổi ảnh đại diện")),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 20),
                SectionHeading(
                  context.tr("Giao diện"),
                  detail: context.tr("Chọn không gian dễ đọc nhất với bạn."),
                  icon: Icons.palette_outlined,
                ),
                LanguagePicker(controller: c),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(context.tr("Giao diện tối")),
                  value: c.dark,
                  onChanged: (v) => c.setPreferences({'dark': v}),
                ),
                const SizedBox(height: 24),
                SectionHeading(
                  context.tr('Bảng màu giao diện'),
                  icon: Icons.palette_outlined,
                ),
                PalettePicker(controller: c),
                const SizedBox(height: 24),
                SectionHeading(context.tr("Ghi chú"), icon: Icons.text_fields),
                const SizedBox(height: 8),
                Text(context.tr("Cỡ chữ ghi chú: {0}", [c.fontSize.round()])),
                Slider(
                  value: c.fontSize,
                  min: 14,
                  max: 24,
                  divisions: 5,
                  label: c.fontSize.round().toString(),
                  onChanged: (v) => c.setPreferences({'font_size': v}),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.tr("Một ý tưởng đáng giữ. Một ghi chú dễ đọc."),
                    style: TextStyle(fontSize: c.fontSize, height: 1.6),
                  ),
                ),
                Text(
                  c.pendingPreferences.isNotEmpty
                      ? context.tr(
                          "Đã lưu trên thiết bị · {0} tùy chỉnh chờ đồng bộ.",
                          [c.pendingPreferences.length],
                        )
                      : c.online
                      ? context.tr(
                          "Tùy chỉnh theo tài khoản; thiết bị khác nhận khi đồng bộ.",
                        )
                      : context.tr("Đang dùng tùy chỉnh đã lưu trên thiết bị."),
                ),
                if (c.error != null) Text(context.trMessage(c.error!)),
                TextButton.icon(
                  onPressed: c.synchronize,
                  icon: const Icon(Icons.sync),
                  label: Text(context.tr("Đồng bộ tùy chỉnh")),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 20),
                SectionHeading(
                  context.tr("Tài khoản"),
                  icon: Icons.verified_user_outlined,
                ),
                Text(
                  c.user?['verified'] == true
                      ? context.tr("Email đã xác minh")
                      : context.tr("Email chưa xác minh"),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    unawaited(logout());
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(context.tr("Đăng xuất")),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(this.context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SecurityCenterScreen(controller: c),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shield_outlined),
                  label: Text(context.tr("Trung tâm bảo mật")),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    changePassword();
                  },
                  child: Text(context.tr("Đổi mật khẩu")),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> changePassword() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PasswordChangeDialog(controller: c),
  );
}
