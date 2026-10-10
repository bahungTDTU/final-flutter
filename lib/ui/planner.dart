import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/note.dart';
import '../domain/note_plan.dart';
import '../state/app_controller.dart';
import 'design_system.dart';

/// Route-owned UI state contains only user-entered filters, no note snapshots.
class PlannerViewState extends ChangeNotifier {
  PlannerViewState() {
    query.addListener(notifyListeners);
  }
  final query = TextEditingController();
  PlanStage stage = PlanStage.planned;
  PlanWindow window = PlanWindow.all;
  bool highOnly = false;
  void selectStage(PlanStage value) {
    stage = value;
    notifyListeners();
  }

  void selectWindow(PlanWindow value) {
    window = value;
    notifyListeners();
  }

  void selectHigh(bool value) {
    highOnly = value;
    notifyListeners();
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }
}

String _dateLabel(String day) {
  final date = DateTime.parse(day);
  return '${date.day}/${date.month}/${date.year}';
}

class PlannerSliver extends StatefulWidget {
  const PlannerSliver({
    super.key,
    required this.controller,
    required this.view,
    required this.onOpen,
  });
  final AppController controller;
  final PlannerViewState view;
  final void Function(String id) onOpen;
  @override
  State<PlannerSliver> createState() => _PlannerSliverState();
}

class _PlannerSliverState extends State<PlannerSliver>
    with WidgetsBindingObserver {
  AppController get c => widget.controller;
  PlannerViewState get view => widget.view;
  late final account = c.user?['id'];
  final busy = <String>{};
  String? error;
  Timer? midnight;
  bool get active => mounted && c.user?['id'] == account;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scheduleDay();
  }

  void scheduleDay() {
    midnight?.cancel();
    final now = DateTime.now();
    midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (mounted) {
          setState(() {});
          scheduleDay();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      scheduleDay();
    }
  }

  @override
  void dispose() {
    midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> act(String id, Future<void> Function() action) async {
    if (busy.contains(id) || !active) return;
    setState(() {
      busy.add(id);
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (active) {
        setState(
          () => error = e is StateError
              ? e.message.toString()
              : 'Chưa lưu được kế hoạch. Hãy thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => busy.remove(id));
    }
  }

  Future<void> add() async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => _PlanPicker(controller: c),
    );
    if (id != null && active) await edit(id);
  }

  Future<void> edit(String id) async {
    if (!c.workspaceNotes.any((n) => n.id == id) || !active) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PlanForm(controller: c, id: id),
    );
  }

  Future<void> remove(String id) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ khỏi kế hoạch?'),
        content: const Text('Ghi chú vẫn được giữ nguyên.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bỏ khỏi kế hoạch'),
          ),
        ],
      ),
    );
    if (accepted == true && active) await act(id, () => c.removeNotePlan(id));
  }

  Widget card(Note n, NotePlan plan, DateTime now) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: PrismReveal(
      key: ValueKey('plan-reveal-${n.id}-${plan.stage.name}'),
      duration: PrismMotion.section,
      distance: 6,
      child: PrismCard(
        key: ValueKey('plan-card-${n.id}'),
        tone: PrismPalette.of(context).tones[[0, 1, 5][plan.stage.index]],
        rich: true,
        onTap: () => widget.onOpen(n.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      n.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  PopupMenuButton<String>(
                    enabled: !busy.contains(n.id),
                    tooltip: 'Thao tác kế hoạch ${n.title}',
                    onSelected: (value) {
                      if (value == 'edit') {
                        edit(n.id);
                      } else if (value == 'remove') {
                        remove(n.id);
                      } else {
                        act(
                          n.id,
                          () => c.moveNotePlan(
                            n.id,
                            PlanStage.values.firstWhere((s) => s.name == value),
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      for (final stage in PlanStage.values)
                        PopupMenuItem(
                          value: stage.name,
                          child: Text('Chuyển sang ${stage.label}'),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Ưu tiên và ngày hạn'),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('Bỏ khỏi kế hoạch'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                n.plainContent.replaceAll(RegExp(r'\s+'), ' '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MetadataPill('Ưu tiên ${plan.priority.label.toLowerCase()}'),
                  if (plan.dueDay != null)
                    MetadataPill(
                      '${plan.overdue(now) ? 'Quá hạn' : 'Hạn'} ${_dateLabel(plan.dueDay!)}',
                    ),
                  if (n.role != 'owner') const MetadataPill('Được chia sẻ'),
                ],
              ),
              if (busy.contains(n.id))
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('Đang lưu…'),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([c, view]),
    builder: (context, _) {
      if (!active) return const SliverToBoxAdapter(child: SizedBox.shrink());
      // Always derive current note content; no outgoing widgets/snapshots on lock.
      final byId = {for (final note in c.workspaceNotes) note.id: note};
      final all = c.workspace.plans.values
          .where((p) => byId.containsKey(p.noteId))
          .toList();
      final now = DateTime.now();
      final query = view.query.text.trim().toLowerCase();
      final plans =
          all
              .where(
                (p) =>
                    p.matches(view.window, now) &&
                    (!view.highOnly || p.priority == PlanPriority.high) &&
                    (query.isEmpty ||
                        byId[p.noteId]!.title.toLowerCase().contains(query)),
              )
              .toList()
            ..sort(comparePlans);
      final groups = {
        for (final stage in PlanStage.values)
          stage: plans.where((p) => p.stage == stage).toList(),
      };
      final wide =
          MediaQuery.sizeOf(context).width >= 1000 &&
          MediaQuery.textScalerOf(context).scale(1) < 1.5;
      final completed = all.where((p) => p.stage == PlanStage.done).length;
      final progressIds = all.map((p) => p.noteId).toList()..sort();
      Widget heading(PlanStage stage) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
        child: Row(
          children: [
            Icon(
              [
                Icons.lightbulb_outline,
                Icons.bolt_rounded,
                Icons.task_alt,
              ][stage.index],
              color: Theme.of(context).colorScheme.primary,
              size: 21,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stage.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            MetadataPill('${groups[stage]!.length}'),
          ],
        ),
      );
      final selected = groups[view.stage]!;
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrismReveal(
                  duration: PrismMotion.section,
                  child: SurfacePanel(
                    tinted: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeading(
                          'Từ ý tưởng đến hoàn thành',
                          detail: 'Chọn ghi chú, đặt ưu tiên và chia công việc thành ba chặng rõ ràng.',
                          icon: Icons.view_kanban_outlined,
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            MetadataPill(
                              '${all.length} ghi chú trong kế hoạch',
                            ),
                            MetadataPill('$completed hoàn thành'),
                            MetadataPill(
                              '${all.where((p) => p.overdue(now)).length} quá hạn',
                            ),
                            FilledButton.icon(
                              onPressed: add,
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm vào kế hoạch'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        PrismProgress(
                          // Dispose the previous bar if a source is locked/revoked.
                          key: ValueKey(
                            progressIds
                                .map((id) => '${id.length}:$id')
                                .join('|'),
                          ),
                          value: all.isEmpty ? 0 : completed / all.length,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Kế hoạch cá nhân được mã hóa trên thiết bị. Ghi chú khóa hoặc mất quyền được ẩn. Ngày hạn chỉ hiển thị trong ứng dụng.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: view.query,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: 'Tìm trong kế hoạch',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: view.query.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa tìm kế hoạch',
                            onPressed: view.query.clear,
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final window in PlanWindow.values)
                      ChoiceChip(
                        label: Text(
                          [
                            'Tất cả ngày',
                            'Quá hạn',
                            'Hôm nay',
                            '7 ngày tới',
                          ][window.index],
                        ),
                        selected: view.window == window,
                        onSelected: (_) => view.selectWindow(window),
                      ),
                    FilterChip(
                      label: const Text('Ưu tiên cao'),
                      selected: view.highOnly,
                      onSelected: view.selectHigh,
                    ),
                  ],
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: StatusNotice(message: error!),
                  ),
                const SizedBox(height: 20),
                if (!wide) ...[
                  DropdownButtonFormField<PlanStage>(
                    key: ValueKey(view.stage),
                    initialValue: view.stage,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Chặng đang xem',
                    ),
                    items: [
                      for (final stage in PlanStage.values)
                        DropdownMenuItem(
                          value: stage,
                          child: Text(
                            '${stage.label} (${groups[stage]!.length})',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) view.selectStage(value);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          if (wide)
            SliverToBoxAdapter(
              child: SizedBox(
                height: math.max(
                  420,
                  math.min(640, MediaQuery.sizeOf(context).height * .6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final stage in PlanStage.values) ...[
                      if (stage != PlanStage.planned) const SizedBox(width: 16),
                      Expanded(
                        child: SurfacePanel(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              heading(stage),
                              Expanded(
                                child: groups[stage]!.isEmpty
                                    ? const Center(
                                        child: Text('Chưa có ghi chú'),
                                      )
                                    : ListView.builder(
                                        key: PageStorageKey(
                                          'plan-column-${stage.name}',
                                        ),
                                        primary: false,
                                        itemCount: groups[stage]!.length,
                                        itemBuilder: (_, i) {
                                          final p = groups[stage]![i];
                                          return card(byId[p.noteId]!, p, now);
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else if (selected.isEmpty)
            const SliverToBoxAdapter(
              child: StatusNotice(
                message: 'Chưa có ghi chú phù hợp trong chặng này.',
              ),
            )
          else
            SliverList.builder(
              itemCount: selected.length,
              itemBuilder: (_, i) {
                final p = selected[i];
                return card(byId[p.noteId]!, p, now);
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      );
    },
  );
}

class _PlanPicker extends StatefulWidget {
  const _PlanPicker({required this.controller});
  final AppController controller;
  @override
  State<_PlanPicker> createState() => _PlanPickerState();
}

class _PlanPickerState extends State<_PlanPicker> {
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
      final active = c.user?['id'] == account;
      final notes = active
          ? c.workspaceNotes
                .where(
                  (n) =>
                      !c.workspace.plans.containsKey(n.id) &&
                      n.title.toLowerCase().contains(
                        query.text.trim().toLowerCase(),
                      ),
                )
                .toList()
          : <Note>[];
      return AlertDialog(
        scrollable: true,
        title: const Text('Chọn ghi chú cho kế hoạch'),
        content: !active
            ? const Text('Phiên đăng nhập đã thay đổi.')
            : SizedBox(
                width: 520,
                height: 340,
                child: Column(
                  children: [
                    TextField(
                      controller: query,
                      enabled: active,
                      maxLength: 200,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Tìm ghi chú để lên kế hoạch',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: notes.isEmpty
                          ? Center(
                              child: const Text(
                                'Không có ghi chú phù hợp chưa nằm trong kế hoạch.',
                              ),
                            )
                          : ListView.builder(
                              itemCount: notes.length,
                              itemBuilder: (_, i) {
                                final n = notes[i];
                                return ListTile(
                                  title: Text(
                                    n.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    n.role == 'owner'
                                        ? 'Ghi chú của bạn'
                                        : 'Được chia sẻ',
                                  ),
                                  onTap: () => Navigator.pop(context, n.id),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      );
    },
  );
}

class _PlanForm extends StatefulWidget {
  const _PlanForm({required this.controller, required this.id});
  final AppController controller;
  final String id;
  @override
  State<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends State<_PlanForm> {
  late final account = widget.controller.user?['id'];
  late PlanStage stage;
  late PlanPriority priority;
  String? dueDay, error;
  bool busy = false;
  bool get active =>
      widget.controller.user?['id'] == account &&
      widget.controller.workspaceNotes.any((n) => n.id == widget.id);
  @override
  void initState() {
    super.initState();
    final plan = widget.controller.workspace.plans[widget.id];
    stage = plan?.stage ?? PlanStage.planned;
    priority = plan?.priority ?? PlanPriority.normal;
    dueDay = plan?.dueDay;
  }

  Future<void> chooseDate() async {
    final day = await showDatePicker(
      context: context,
      initialDate: dueDay == null ? DateTime.now() : DateTime.parse(dueDay!),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      builder: (context, child) => AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => active
            ? child!
            : AlertDialog(
                content: const Text('Ghi chú không còn khả dụng.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
      ),
    );
    if (day != null && mounted && active) setState(() => dueDay = planDay(day));
  }

  Future<void> save() async {
    if (busy || !active) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.controller.saveNotePlan(
        widget.id,
        stage: stage,
        priority: priority,
        dueDay: dueDay,
      );
      if (mounted && active) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is StateError
              ? e.message.toString()
              : 'Chưa lưu được kế hoạch. Dữ liệu vẫn ở đây để bạn thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => PopScope(
      canPop: !busy,
      child: AlertDialog(
        scrollable: true,
        title: const Text('Ưu tiên và ngày hạn'),
        content: SizedBox(
          width: 520,
          child: active
              ? AbsorbPointer(
                  absorbing: busy,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<PlanStage>(
                        initialValue: stage,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Chặng kế hoạch',
                        ),
                        items: [
                          for (final value in PlanStage.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => stage = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PlanPriority>(
                        initialValue: priority,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Mức ưu tiên',
                        ),
                        items: [
                          for (final value in PlanPriority.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => priority = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: chooseDate,
                            icon: const Icon(Icons.event_outlined),
                            label: Text(
                              dueDay == null
                                  ? 'Chọn ngày hạn'
                                  : 'Hạn: ${_dateLabel(dueDay!)}',
                            ),
                          ),
                          if (dueDay != null)
                            IconButton(
                              tooltip: 'Xóa ngày hạn',
                              onPressed: () => setState(() => dueDay = null),
                              icon: const Icon(Icons.close),
                            ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final offset in [0, 1, 7])
                            TextButton(
                              onPressed: () {
                                final now = DateTime.now();
                                setState(
                                  () => dueDay = planDay(
                                    DateTime(
                                      now.year,
                                      now.month,
                                      now.day + offset,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                offset == 0
                                    ? 'Hôm nay'
                                    : offset == 1
                                    ? 'Ngày mai'
                                    : '+7 ngày',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Ngày hạn và trạng thái là kế hoạch cá nhân trên thiết bị, không thay đổi nội dung hoặc quyền ghi chú.',
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: StatusNotice(message: error!),
                        ),
                    ],
                  ),
                )
              : const Text(
                  'Ghi chú bị khóa, mất quyền hoặc tài khoản đã thay đổi.',
                ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: busy || !active ? null : save,
            child: Text(busy ? 'Đang lưu…' : 'Lưu kế hoạch'),
          ),
        ],
      ),
    ),
  );
}
