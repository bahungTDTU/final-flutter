import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/writing_tools.dart';
import '../state/focus_session.dart';
import 'design_system.dart';

const _templateIcons = <String, IconData>{
  'cornell': Icons.school_outlined,
  'meeting': Icons.groups_outlined,
  'project': Icons.rocket_launch_outlined,
  'decision': Icons.route_outlined,
  'weekly': Icons.calendar_view_week_outlined,
  'idea': Icons.lightbulb_outline,
};

class TemplateGallery extends StatefulWidget {
  const TemplateGallery({super.key});
  @override
  State<TemplateGallery> createState() => _TemplateGalleryState();
}

class _TemplateGalleryState extends State<TemplateGallery> {
  NoteTemplate selected = NoteTemplate.all.first;
  Future<void> previewTemplate() => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DialogHeading(
                      selected.title,
                      icon: _templateIcons[selected.id]!,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng xem trước',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SelectableText(
                selected.content,
                key: const Key('compact-template-preview'),
                style: const TextStyle(fontSize: 15, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Xưởng ghi chú',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, area) {
          final compact =
              area.maxWidth < 600 || MediaQuery.sizeOf(context).height < 500;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!compact) ...[
                const Flexible(
                  child: Text('Tạo bản nháp riêng · dùng được offline'),
                ),
                const SizedBox(width: 16),
              ],
              if (compact)
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('use-template'),
                    onPressed: () => Navigator.pop(context, selected),
                    icon: const Icon(Icons.add),
                    label: const Text('Dùng mẫu'),
                  ),
                ),
              if (!compact)
                FilledButton.icon(
                  key: const Key('use-template'),
                  onPressed: () => Navigator.pop(context, selected),
                  icon: const Icon(Icons.add),
                  label: const Text('Dùng mẫu này'),
                ),
              const SizedBox(width: 8),
              IconButton(
                key: const Key('preview-template'),
                tooltip: 'Xem trước mẫu',
                onPressed: previewTemplate,
                icon: const Icon(Icons.preview_outlined),
              ),
            ],
          );
        },
      ),
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, area) {
          final wide =
              area.maxWidth >= 840 &&
              area.maxHeight >= 440 &&
              MediaQuery.textScalerOf(context).scale(1) < 1.4;
          final cards = [
            const SectionHeading(
              'Bắt đầu từ một cấu trúc tốt',
              detail: 'Chọn một mẫu, rồi viết lại theo cách của bạn. Mẫu không dùng AI.',
              icon: Icons.auto_awesome_mosaic_outlined,
            ),
            const SizedBox(height: 20),
            ...NoteTemplate.all.map(
              (template) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TemplateCard(
                  template: template,
                  selected: selected == template,
                  onTap: () => setState(() => selected = template),
                ),
              ),
            ),
          ];
          final preview = SurfacePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  selected.title,
                  detail: 'Xem trước nội dung có thể chỉnh sửa',
                  icon: _templateIcons[selected.id],
                ),
                const SizedBox(height: 16),
                SelectableText(
                  selected.content,
                  key: const Key('template-preview'),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(24),
                            children: cards,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: preview,
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [...cards, preview],
                    ),
            ),
          );
        },
      ),
    ),
  );
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });
  final NoteTemplate template;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final tone = PrismPalette.of(context)
        .tones[NoteTemplate.all.indexOf(template)];
    return Semantics(
      selected: selected,
      child: Material(
        color: Color.alphaBlend(
          tone.light.withValues(alpha: selected ? .18 : .07),
          Theme.of(context).colorScheme.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected
                ? tone.ink
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('template-${template.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(_templateIcons[template.id], color: tone.ink, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(template.description),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: tone.ink,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Derived text stays in this editor route. Ignore selection-only notifications.
class WritingToolsPanel extends StatefulWidget {
  const WritingToolsPanel({
    super.key,
    required this.controller,
    required this.readOnly,
    required this.onToggle,
    required this.onHeading,
  });
  final TextEditingController controller;
  final bool readOnly;
  final void Function(String expected, WritingTask task) onToggle;
  final ValueChanged<int> onHeading;
  @override
  State<WritingToolsPanel> createState() => _WritingToolsPanelState();
}

class _WritingToolsPanelState extends State<WritingToolsPanel> {
  Timer? delay;
  late String source;
  late WritingSnapshot snapshot;
  @override
  void initState() {
    super.initState();
    refresh();
    widget.controller.addListener(changed);
  }

  void refresh() {
    source = widget.controller.text;
    snapshot = WritingSnapshot(source);
  }

  void changed() {
    if (source == widget.controller.text) return;
    delay?.cancel();
    delay = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(refresh);
    });
  }

  @override
  void didUpdateWidget(covariant WritingToolsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      delay?.cancel();
      oldWidget.controller.removeListener(changed);
      refresh();
      widget.controller.addListener(changed);
    }
  }

  @override
  void dispose() {
    delay?.cancel();
    widget.controller.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          Text('${snapshot.words} từ · ${snapshot.characters} ký tự'),
          Text(
            'Đọc khoảng ${snapshot.readingMinutes < 1 ? 1 : snapshot.readingMinutes} phút',
          ),
          if (snapshot.taskCount > 0)
            Text('${snapshot.completed}/${snapshot.taskCount} việc đã xong'),
        ],
      ),
      const SizedBox(height: 12),
      SurfacePanel(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          key: const Key('writing-outline'),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dàn ý & checklist'),
              const SizedBox(height: 6),
              Text(
                'Dùng # tiêu đề và - [ ] việc cần làm',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          leading: const Icon(Icons.account_tree_outlined),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (snapshot.taskCount > 0) ...[
              LinearProgressIndicator(
                value: snapshot.completed / snapshot.taskCount,
                semanticsLabel:
                    'Tiến độ checklist: ${snapshot.completed} trên ${snapshot.taskCount}',
              ),
              const SizedBox(height: 12),
            ],
            if (snapshot.headings.isEmpty && snapshot.tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Chưa có dàn ý hoặc checklist. Ví dụ: “## Ý chính” và “- [ ] Ôn bài”.',
                ),
              ),
            ...snapshot.headings.map(
              (heading) => Padding(
                padding: EdgeInsets.only(left: (heading.level - 1) * 8.0),
                child: TextButton.icon(
                  onPressed: source == widget.controller.text
                      ? () => widget.onHeading(heading.offset)
                      : null,
                  icon: const Icon(Icons.tag, size: 16),
                  label: Text(heading.text),
                ),
              ),
            ),
            ...snapshot.tasks.map(
              (task) => CheckboxListTile(
                key: Key('writing-task-${task.markerOffset}'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  task.text,
                  style: task.done
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                value: task.done,
                onChanged: widget.readOnly || source != widget.controller.text
                    ? null
                    : (_) => widget.onToggle(source, task),
              ),
            ),
            if (snapshot.taskCount > 100 || snapshot.headings.length == 100)
              const Text(
                'Hiển thị tối đa 100 mục mỗi loại để giữ giao diện gọn.',
              ),
            if (widget.readOnly)
              const Text('Chỉ xem · checklist giữ nguyên nội dung.'),
          ],
        ),
      ),
    ],
  );
}

class FocusBar extends StatelessWidget {
  const FocusBar({super.key, required this.session});
  final FocusSession session;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) {
      final seconds = session.remaining.inSeconds;
      final clock =
          '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
      return SurfacePanel(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.timelapse_outlined),
            Text(
              session.complete
                  ? 'Phiên tập trung hoàn tất'
                  : 'Phiên tập trung · $clock',
              key: const Key('focus-clock'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              key: const Key('focus-start'),
              onPressed: session.complete
                  ? null
                  : session.running
                  ? session.pause
                  : session.start,
              icon: Icon(session.running ? Icons.pause : Icons.play_arrow),
              label: Text(session.running ? 'Tạm dừng' : 'Bắt đầu'),
            ),
            IconButton(
              tooltip: 'Đặt lại 25 phút',
              onPressed: session.reset,
              icon: const Icon(Icons.restart_alt),
            ),
            const Text('Rời app sẽ tạm dừng phiên'),
          ],
        ),
      );
    },
  );
}
