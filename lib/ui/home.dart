import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/note.dart';
import '../state/app_controller.dart';
import 'app.dart';
import 'editor.dart';
import 'design_system.dart';
import 'password_dialog.dart';
import 'note_protection.dart';
import 'avatar_editor.dart';
import 'sharing.dart';

class UnverifiedBanner extends StatelessWidget {
  const UnverifiedBanner({super.key, required this.onCheck, this.delivery});
  final VoidCallback onCheck;
  final String? delivery;
  @override
  Widget build(BuildContext context) => StatusNotice(
    icon: Icons.mark_email_unread_outlined,
    message: ['not_configured', 'delivery_failed'].contains(delivery)
        ? 'Email chưa xác minh. Chưa gửi được mã.'
        : 'Email của bạn chưa được xác minh.',
    action: TextButton(onPressed: onCheck, child: const Text('Xác minh')),
  );
}

Future<bool> confirmDelete(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ghi chú?'),
        content: Text('“$title” sẽ bị xóa sau khi đồng bộ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
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
  AppController get c => widget.controller;
  @override
  void dispose() {
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(controller: c, id: editorId),
      ),
    );
  }

  static const destinations = ['Ghi chú', 'Được chia sẻ', 'Hỏi ghi chú'];
  static const icons = [
    Icons.notes_outlined,
    Icons.people_outline,
    Icons.auto_awesome_outlined,
  ];

  Widget createButton() => PrismAction(
    key: const Key('new-note'),
    onPressed: () => open(),
    icon: const Icon(Icons.add),
    child: const Text('Ghi chú mới'),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final small = size.maxWidth < 600;
      selectedLabels.removeWhere((id) => !c.labels.contains(id));
      final sidebar =
          size.maxWidth >= 1024 &&
          size.maxHeight >= 700 &&
          MediaQuery.textScalerOf(context).scale(1) < 1.5;
      final totalPending =
          c.pending.length +
          c.pendingPreferences.length +
          c.pendingLabels.length;
      final syncLabel = c.syncing
          ? 'Đang đồng bộ…'
          : !c.online
          ? 'Offline · $totalPending thay đổi chờ'
          : totalPending > 0
          ? '$totalPending thay đổi chờ đồng bộ'
          : c.realtimeLive
          ? 'Trực tiếp'
          : c.realtime != null
          ? 'Đang nối lại'
          : 'Đã đồng bộ';
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
              searchFocus.requestFocus(),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: small
                ? AppBar(
                    title: const Brand(),
                    actions: [
                      IconButton(
                        tooltip: 'Hồ sơ và tùy chỉnh',
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
                        label: destinations[i],
                      ),
                    ),
                  )
                : null,
            floatingActionButton: small && destination != 2
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: PrismPalette.actionColors,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: .18),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FloatingActionButton.extended(
                      key: const Key('new-note'),
                      onPressed: () => open(),
                      icon: const Icon(Icons.add),
                      label: const Text('Ghi chú mới'),
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  )
                : null,
            body: SafeArea(
              child: Row(
                children: [
                  if (!small)
                    sidebar
                        ? SizedBox(
                            width: Space.sidebar,
                            child: Material(
                              color: Theme.of(context).colorScheme.surface,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Brand(),
                                    ),
                                    const SizedBox(height: 32),
                                    SurfacePanel(
                                      tinted: true,
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'KHÔNG GIAN CỦA BẠN',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: .8,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${c.notes.where((n) => n.role == 'owner').length} ghi chú · ${c.labels.length} nhãn',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ...List.generate(
                                      3,
                                      (i) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: ListTile(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          selected: destination == i,
                                          selectedTileColor: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                          leading: Icon(icons[i]),
                                          title: Text(destinations[i]),
                                          onTap: () =>
                                              setState(() => destination = i),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ListTile(
                                      leading: const Icon(Icons.label_outline),
                                      title: const Text('Quản lý nhãn'),
                                      onTap: manageLabels,
                                    ),
                                    const Spacer(),
                                    const Divider(),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      leading: AccountAvatar(
                                        controller: c,
                                        radius: 18,
                                      ),
                                      title: Text(
                                        c.user?['name'] as String? ?? 'Hồ sơ',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: const Text(
                                        'Hồ sơ và tùy chỉnh',
                                      ),
                                      onTap: settings,
                                    ),
                                    TextButton.icon(
                                      onPressed: logout,
                                      icon: const Icon(Icons.logout),
                                      label: const Text('Đăng xuất'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : NavigationRail(
                            selectedIndex: destination,
                            labelType: NavigationRailLabelType.all,
                            leading: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Brand(compact: true),
                            ),
                            trailing: IconButton(
                              tooltip: 'Hồ sơ và tùy chỉnh',
                              onPressed: settings,
                              icon: const Icon(Icons.account_circle_outlined),
                            ),
                            onDestinationSelected: (v) =>
                                setState(() => destination = v),
                            destinations: List.generate(
                              3,
                              (i) => NavigationRailDestination(
                                icon: Icon(icons[i]),
                                label: Text(destinations[i]),
                              ),
                            ),
                          ),
                  if (!small) const VerticalDivider(width: 1),
                  Expanded(
                    child: destination == 2
                        ? SingleChildScrollView(
                            child: EmptyNotes(
                              icon: Icons.auto_awesome_outlined,
                              title: 'Hỏi từ những ghi chú của bạn',
                              detail: 'Hỏi đáp có nguồn hiện chưa khả dụng. Bạn vẫn có thể tìm nội dung trong Ghi chú.',
                              action: OutlinedButton.icon(
                                onPressed: () =>
                                    setState(() => destination = 0),
                                icon: const Icon(Icons.search),
                                label: const Text('Tìm trong ghi chú'),
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, area) {
                              final padding = small ? 16.0 : 32.0;
                              final scale = MediaQuery.textScalerOf(context)
                                  .scale(1);
                              final list =
                                  c.notes
                                      .where(
                                        (n) =>
                                            (destination == 1
                                                ? n.role != 'owner'
                                                : n.role == 'owner') &&
                                            (query.isEmpty ||
                                                !n.locked &&
                                                    '${n.title} ${n.content}'
                                                        .toLowerCase()
                                                        .contains(query)) &&
                                            (selectedLabels.isEmpty ||
                                                !n.locked &&
                                                    selectedLabels.every(
                                                      c
                                                          .noteLabelIds(n)
                                                          .contains,
                                                    )),
                                      )
                                      .toList()
                                    ..sort(compareNotes);
                              final pinned = list
                                  .where((n) => n.pinnedAt != null)
                                  .toList();
                              final remaining = list
                                  .where((n) => n.pinnedAt == null)
                                  .toList();
                              return CustomScrollView(
                                key: PageStorageKey('notes-$destination'),
                                slivers: [
                                  SliverPadding(
                                    padding: EdgeInsets.fromLTRB(
                                      padding,
                                      small ? 12 : 32,
                                      padding,
                                      small ? 12 : 24,
                                    ),
                                    sliver: SliverToBoxAdapter(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (!small) ...[
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    destination == 1
                                                        ? 'Được chia sẻ với bạn'
                                                        : 'Ghi chú của bạn',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineLarge,
                                                  ),
                                                ),
                                                createButton(),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          if (small)
                                            Text(
                                              destination == 1
                                                  ? 'Được chia sẻ'
                                                  : 'Ghi chú của bạn',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall,
                                            ),
                                          const SizedBox(height: 8),
                                          Text(
                                            destination == 1
                                                ? 'Cùng theo dõi những điều quan trọng của nhóm.'
                                                : 'Ý tưởng, bài học và kế hoạch — gọn trong một nơi.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 4,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                '${list.length} ghi chú',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                              TextButton.icon(
                                                onPressed: c.synchronize,
                                                icon: Icon(
                                                  c.online
                                                      ? Icons
                                                            .cloud_done_outlined
                                                      : Icons
                                                            .cloud_off_outlined,
                                                  size: 18,
                                                ),
                                                label: Text(syncLabel),
                                              ),
                                            ],
                                          ),
                                          if (c.user?['verified'] != true) ...[
                                            const SizedBox(height: 12),
                                            UnverifiedBanner(
                                              delivery: c.emailDelivery,
                                              onCheck: () =>
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute<void>(
                                                      builder: (_) =>
                                                          TokenScreen(
                                                            controller: c,
                                                          ),
                                                    ),
                                                  ),
                                            ),
                                          ],
                                          if (c.error != null) ...[
                                            const SizedBox(height: 12),
                                            StatusNotice(
                                              message: c.localWriteFailed
                                                  ? c.error!
                                                  : c.online
                                                  ? 'Chưa thể đồng bộ. Hãy thử lại.'
                                                  : 'Đang offline. Các thay đổi đã lưu trên thiết bị đang chờ kết nối.',
                                              icon: Icons.cloud_off_outlined,
                                              action: TextButton(
                                                onPressed: c.synchronize,
                                                child: const Text('Thử lại'),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 24),
                                          TextField(
                                            key: const Key('note-search'),
                                            controller: search,
                                            focusNode: searchFocus,
                                            decoration: InputDecoration(
                                              prefixIcon: const Icon(
                                                Icons.search,
                                              ),
                                              hintText: 'Tìm trong tiêu đề và nội dung',
                                              labelText: 'Tìm ghi chú',
                                              helperText: area.maxWidth < 800
                                                  ? null
                                                  : 'Tìm ngay khi nhập · Ctrl + F để đến ô tìm kiếm',
                                              suffixIcon: search.text.isEmpty
                                                  ? null
                                                  : IconButton(
                                                      tooltip: 'Xóa tìm kiếm',
                                                      icon: const Icon(
                                                        Icons.close,
                                                      ),
                                                      onPressed: () {
                                                        search.clear();
                                                        setState(
                                                          () => query = '',
                                                        );
                                                      },
                                                    ),
                                            ),
                                            onChanged: (v) {
                                              setState(() {});
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
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              SegmentedButton<bool>(
                                                showSelectedIcon: false,
                                                style:
                                                    SegmentedButton.styleFrom(
                                                      minimumSize: const Size(
                                                        48,
                                                        48,
                                                      ),
                                                    ),
                                                segments: const [
                                                  ButtonSegment(
                                                    value: true,
                                                    icon: Icon(Icons.grid_view),
                                                    label: Text('Lưới'),
                                                  ),
                                                  ButtonSegment(
                                                    value: false,
                                                    icon: Icon(
                                                      Icons.view_list_outlined,
                                                    ),
                                                    label: Text('Danh sách'),
                                                  ),
                                                ],
                                                selected: {c.grid},
                                                onSelectionChanged: (values) =>
                                                    c.setPreferences({
                                                      'grid': values.single,
                                                    }),
                                              ),
                                              if (small)
                                                IconButton(
                                                  tooltip: 'Quản lý nhãn',
                                                  onPressed: manageLabels,
                                                  icon: const Icon(
                                                    Icons.label_outline,
                                                  ),
                                                ),
                                              if (!small && !sidebar)
                                                Tooltip(
                                                  message: 'Quản lý nhãn',
                                                  child: TextButton.icon(
                                                    onPressed: manageLabels,
                                                    icon: const Icon(
                                                      Icons.label_outline,
                                                    ),
                                                    label: const Text(
                                                      'Quản lý nhãn',
                                                    ),
                                                  ),
                                                ),
                                              ...c.labels.map(
                                                (label) => FilterChip(
                                                  backgroundColor:
                                                      Color.alphaBlend(
                                                        PrismPalette.of(context)
                                                            .tone(label)
                                                            .light
                                                            .withValues(
                                                              alpha: .08,
                                                            ),
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .surface,
                                                      ),
                                                  selectedColor:
                                                      Color.alphaBlend(
                                                        PrismPalette.of(context)
                                                            .tone(label)
                                                            .light
                                                            .withValues(
                                                              alpha: .22,
                                                            ),
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .surface,
                                                      ),
                                                  labelStyle: TextStyle(
                                                    color: PrismPalette.of(
                                                      context,
                                                    ).tone(label).ink,
                                                  ),
                                                  checkmarkColor:
                                                      PrismPalette.of(context)
                                                          .tone(label)
                                                          .ink,
                                                  label: Text(
                                                    c.labelName(label),
                                                  ),
                                                  selected: selectedLabels
                                                      .contains(label),
                                                  onSelected: (v) =>
                                                      setState(() {
                                                        if (v) {
                                                          selectedLabels.add(
                                                            label,
                                                          );
                                                        } else {
                                                          selectedLabels.remove(
                                                            label,
                                                          );
                                                        }
                                                      }),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (selectedLabels.isNotEmpty)
                                            Padding(
                                              padding: EdgeInsets.only(top: 8),
                                              child: Wrap(
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                spacing: 8,
                                                children: [
                                                  const Text(
                                                    'Khớp tất cả nhãn đã chọn',
                                                  ),
                                                  TextButton(
                                                    onPressed: () => setState(
                                                      selectedLabels.clear,
                                                    ),
                                                    child: const Text(
                                                      'Bỏ bộ lọc nhãn',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (c.drafts.isNotEmpty)
                                            Wrap(
                                              spacing: 8,
                                              children: c.drafts.keys
                                                  .map(
                                                    (id) => ActionChip(
                                                      avatar: const Icon(
                                                        Icons.edit_note,
                                                      ),
                                                      label: const Text(
                                                        'Khôi phục bản nháp',
                                                      ),
                                                      onPressed: () =>
                                                          open(draftId: id),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          if (c.recoveries.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12,
                                              ),
                                              child: StatusNotice(
                                                icon: Icons
                                                    .enhanced_encryption_outlined,
                                                message:
                                                    '${c.recoveries.length} bản chỉnh sửa đã được giữ an toàn trên thiết bị.',
                                                action: TextButton(
                                                  key: const Key(
                                                    'open-recovery',
                                                  ),
                                                  onPressed: recovery,
                                                  child: const Text('Phục hồi'),
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
                                                selectedLabels.isNotEmpty
                                            ? 'Không tìm thấy ghi chú phù hợp'
                                            : destination == 1
                                            ? 'Chưa có ghi chú được chia sẻ'
                                            : 'Bắt đầu với ghi chú đầu tiên',
                                        detail:
                                            query.isNotEmpty ||
                                                selectedLabels.isNotEmpty
                                            ? 'Thử từ khóa khác hoặc bỏ bớt nhãn.'
                                            : destination == 1
                                            ? 'Ghi chú được chia sẻ với tài khoản của bạn sẽ xuất hiện ở đây.'
                                            : 'Một ý tưởng, một bài học, một điều cần nhớ.',
                                        action:
                                            query.isNotEmpty ||
                                                selectedLabels.isNotEmpty
                                            ? TextButton(
                                                onPressed: () {
                                                  search.clear();
                                                  setState(() {
                                                    query = '';
                                                    selectedLabels.clear();
                                                  });
                                                },
                                                child: const Text(
                                                  'Xóa tìm kiếm và bộ lọc',
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  if (pinned.isNotEmpty)
                                    ...section(
                                      'Đã ghim',
                                      pinned,
                                      area.maxWidth,
                                      padding,
                                      scale,
                                    ),
                                  if (remaining.isNotEmpty)
                                    ...section(
                                      pinned.isEmpty
                                          ? 'Tất cả ghi chú'
                                          : 'Các ghi chú khác',
                                      remaining,
                                      area.maxWidth,
                                      padding,
                                      scale,
                                    ),
                                  const SliverToBoxAdapter(
                                    child: SizedBox(height: 104),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
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
  ) => [
    SliverPadding(
      padding: EdgeInsets.fromLTRB(padding, 8, padding, 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            if (title == 'Đã ghim') ...[
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
    SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      sliver: c.grid && title == 'Đã ghim' && notes.length == 1
          ? SliverToBoxAdapter(child: noteCard(notes.single, compact: true))
          : c.grid
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
                (_, i) => noteCard(notes[i]),
                childCount: notes.length,
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

  Widget noteCard(Note note, {bool compact = false}) {
    final colors = Theme.of(context).colorScheme;
    final palette = PrismPalette.of(context);
    final tone = note.locked ? null : palette.tone(note.id);
    final date = DateTime.tryParse(note.updatedAt)?.toLocal();
    final dateText = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return PrismCard(
      key: ValueKey('card-${note.id}'),
      tone: tone,
      onTap: () => open(note: note),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: c.grid && !compact
              ? MainAxisSize.max
              : MainAxisSize.min,
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
                    note.locked ? 'Ghi chú đã khóa' : note.title,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (note.role == 'owner' && !note.locked)
                  PopupMenuButton<String>(
                    tooltip: 'Thao tác ghi chú',
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
                      const PopupMenuItem(
                        value: 'share',
                        child: Text('Chia sẻ'),
                      ),
                      PopupMenuItem(
                        value: 'pin',
                        child: Text(note.pinnedAt == null ? 'Ghim' : 'Bỏ ghim'),
                      ),
                      const PopupMenuItem(
                        value: 'protect',
                        child: Text('Bật khóa ghi chú'),
                      ),
                      const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.locked ? 'Mở khóa để xem nội dung.' : note.content,
              maxLines: c.grid && !compact ? 4 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: c.fontSize,
                height: 1.5,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (c.grid && !compact) const Spacer(),
            if (!note.locked && note.role != 'owner')
              Text(
                'Từ ${note.sharedByName ?? note.sharedByEmail ?? 'Chủ sở hữu'} · ${sharingDate(note.sharedAt ?? '')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (note.pinnedAt != null)
                  MetadataPill(
                    'Đã ghim',
                    icon: Icons.push_pin_outlined,
                    tone: palette.tones[4],
                  ),
                if (!note.locked &&
                    (note.role != 'owner' || note.sharedCount > 0))
                  Tooltip(
                    message: note.role == 'owner'
                        ? 'Đã chia sẻ cho ${note.sharedCount} người'
                        : 'Được chia sẻ với bạn',
                    child: const Icon(
                      Icons.people_outline,
                      size: 20,
                      semanticLabel: 'Ghi chú được chia sẻ',
                    ),
                  ),
                if (note.locked)
                  const Icon(
                    Icons.lock_outline,
                    size: 20,
                    semanticLabel: 'Đã khóa',
                  ),
                if (note.role != 'owner')
                  Text(
                    note.role == 'viewer' ? 'Chỉ xem' : 'Có thể chỉnh sửa',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (!note.locked)
                  ...c
                      .noteLabelIds(note)
                      .take(2)
                      .map(
                        (l) => MetadataPill(
                          '#${c.labelName(l, note)}',
                          tone: palette.tone(l),
                        ),
                      ),
                if (!note.locked && c.noteLabelIds(note).length > 2)
                  Text(
                    '+${c.noteLabelIds(note).length - 2} nhãn',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(dateText, style: Theme.of(context).textTheme.bodySmall),
                if (c.hasPending(note.id))
                  Text(
                    'Chờ đồng bộ',
                    style: TextStyle(color: colors.primary, fontSize: 13),
                  ),
                if (c.conflicts.containsKey(note.id))
                  ActionChip(
                    label: const Text('Xử lý xung đột'),
                    onPressed: () => conflict(note.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> recovery() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const DialogHeading(
          'Phục hồi chỉnh sửa local',
          icon: Icons.restore_outlined,
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tạo ghi chú mới từ nội dung bạn đã gõ trước khi quyền truy cập thay đổi. Bản phục hồi chỉ có trên thiết bị này; ghi chú gốc vẫn giữ quyền bảo vệ của nó.',
                ),
                const SizedBox(height: 16),
                ...c.recoveries.entries.map(
                  (entry) => ListTile(
                    leading: const Icon(Icons.enhanced_encryption_outlined),
                    title: const Text('Bản chỉnh sửa đã giữ'),
                    subtitle: Text('Lưu: ${(entry.value as Map)['saved_at']}'),
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
            child: const Text('Đóng'),
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
          'Chưa tạo được bản nháp phục hồi. Bản mã hóa vẫn được giữ; hãy thử lại.',
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
          title: const Text('Đăng xuất khi còn thay đổi?'),
          content: const Text(
            'Thay đổi đã lưu trên thiết bị sẽ nằm trong tài khoản này. Đăng nhập lại để tiếp tục đồng bộ.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ở lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất'),
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
        title: const DialogHeading(
          'Có hai phiên bản thay đổi',
          icon: Icons.difference_outlined,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Giữ bản của bạn dưới dạng ghi chú mới, hoặc dùng bản từ máy chủ và bỏ thay đổi chưa đồng bộ.',
              ),
              if (local != null && !local.locked) ...[
                const SizedBox(height: 16),
                const Text('Bản trên thiết bị'),
                Text(local.title),
                Text(
                  local.content,
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
            child: const Text('Để sau'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Dùng bản máy chủ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Giữ bản sao của tôi'),
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
            'Chưa lưu được lựa chọn phục hồi. Bản cũ vẫn được giữ; hãy thử lại.',
          );
        }
      }
    }
  }

  Future<void> manageLabels() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AnimatedBuilder(
        animation: c,
        builder: (context, _) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SectionHeading(
                  'Nhãn của tôi',
                  detail: 'Sắp xếp ghi chú theo chủ đề. Nhãn được đồng bộ theo tài khoản.',
                  icon: Icons.label_outline,
                ),
                ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: c.labels
                      .map(
                        (l) => ListTile(
                          leading: const Icon(Icons.label_outline),
                          contentPadding: EdgeInsets.zero,
                          title: Text(c.labelName(l)),
                          subtitle: c.labelConflicts.containsKey(l)
                              ? const Text(
                                  'Tên nhãn có thay đổi khác trên máy chủ.',
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Đổi tên ${c.labelName(l)}',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () async {
                                  final name = await askText(
                                    context,
                                    'Tên nhãn mới',
                                    initial: c.labelName(l),
                                    validator: (value) =>
                                        c.validateLabelName(value, l),
                                  );
                                  if (name != null) {
                                    await labelAction(
                                      () => c.renameLabel(l, name),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Xóa nhãn ${c.labelName(l)}',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final accepted = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Xóa nhãn?'),
                                      content: Text(
                                        'Bỏ nhãn “${c.labelName(l)}”; các ghi chú vẫn còn.',
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
                                          child: const Text('Xóa nhãn'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (accepted == true) {
                                    await labelAction(() => c.removeLabel(l));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (c.labels.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Chưa có nhãn. Thêm nhãn để sắp xếp ghi chú.'),
                  ),
                const Text('Xóa nhãn chỉ bỏ nhãn; ghi chú vẫn còn.'),
                Text(
                  c.pendingLabels.isEmpty
                      ? 'Nhãn theo tài khoản; thiết bị khác nhận khi đồng bộ.'
                      : '${c.pendingLabels.length} thay đổi nhãn chờ đồng bộ.',
                ),
                for (final id in c.labelConflicts.keys)
                  ListTile(
                    title: Text('Xung đột nhãn “${c.labelName(id)}”'),
                    subtitle: const Text(
                      'Đổi tên để giữ lựa chọn của bạn, hoặc dùng nhãn trên máy chủ.',
                    ),
                    trailing: TextButton(
                      onPressed: c.syncing
                          ? null
                          : () => labelAction(() => c.useRemoteLabel(id)),
                      child: const Text('Dùng bản máy chủ'),
                    ),
                  ),
                TextButton.icon(
                  onPressed: c.syncing ? null : c.synchronize,
                  icon: const Icon(Icons.sync),
                  label: const Text('Đồng bộ nhãn'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final name = await askText(
                      context,
                      'Thêm nhãn',
                      validator: c.validateLabelName,
                    );
                    if (name != null) await labelAction(() => c.addLabel(name));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm nhãn'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    selectedLabels.removeWhere((l) => !c.labels.contains(l));
    if (mounted) setState(() {});
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
                    const Expanded(
                      child: SectionHeading(
                        'Hồ sơ và tùy chỉnh',
                        icon: Icons.tune_outlined,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng tùy chỉnh',
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
                    tooltip: 'Sửa tên hiển thị',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final name = await askText(
                        context,
                        'Tên hiển thị',
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
                  label: const Text('Đổi ảnh đại diện'),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 20),
                const SectionHeading(
                  'Giao diện',
                  detail: 'Chọn không gian dễ đọc nhất với bạn.',
                  icon: Icons.palette_outlined,
                ),
                SwitchListTile(
                  title: const Text('Giao diện tối'),
                  value: c.dark,
                  onChanged: (v) => c.setPreferences({'dark': v}),
                ),
                const SizedBox(height: 16),
                const SectionHeading('Ghi chú', icon: Icons.text_fields),
                const SizedBox(height: 8),
                Text('Cỡ chữ ghi chú: ${c.fontSize.round()}'),
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
                    'Một ý tưởng đáng giữ. Một ghi chú dễ đọc.',
                    style: TextStyle(fontSize: c.fontSize, height: 1.6),
                  ),
                ),
                Text(
                  c.pendingPreferences.isNotEmpty
                      ? 'Đã lưu trên thiết bị · ${c.pendingPreferences.length} tùy chỉnh chờ đồng bộ.'
                      : c.online
                      ? 'Tùy chỉnh theo tài khoản; thiết bị khác nhận khi đồng bộ.'
                      : 'Đang dùng tùy chỉnh đã lưu trên thiết bị.',
                ),
                if (c.error != null) Text(c.error!),
                TextButton.icon(
                  onPressed: c.synchronize,
                  icon: const Icon(Icons.sync),
                  label: const Text('Đồng bộ tùy chỉnh'),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 20),
                const SectionHeading(
                  'Tài khoản',
                  icon: Icons.verified_user_outlined,
                ),
                Text(
                  c.user?['verified'] == true
                      ? 'Email đã xác minh'
                      : 'Email chưa xác minh',
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    unawaited(logout());
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    changePassword();
                  },
                  child: const Text('Đổi mật khẩu'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> labelAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showMessage(
          context,
          c.localWriteFailed
              ? 'Chưa ghi được thay đổi nhãn trên thiết bị. Giữ app mở và thử lại.'
              : friendlyError(e),
        );
      }
    }
  }

  Future<void> changePassword() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PasswordChangeDialog(controller: c),
  );
}
