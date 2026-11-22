import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';

import 'design_system.dart';

/// The app destinations stay in one masthead; tools live beside the library.
class DeskMasthead extends StatelessWidget {
  const DeskMasthead({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelected,
    required this.create,
    required this.avatar,
    required this.onAccount,
    required this.onQuickFind,
  });
  final List<String> destinations;
  final int selected;
  final ValueChanged<int> onSelected;
  final Widget create, avatar;
  final VoidCallback onAccount, onQuickFind;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: Container(
        key: const Key('desk-masthead'),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            const Brand(),
            const SizedBox(width: 36),
            Expanded(
              child: DeskDestinationStrip(
                destinations: destinations,
                selected: selected,
                onSelected: onSelected,
              ),
            ),
            IconButton(
              tooltip: context.tr("Tìm nhanh · Ctrl+K"),
              onPressed: onQuickFind,
              icon: const Icon(Icons.manage_search),
            ),
            const SizedBox(width: 12),
            create,
            const SizedBox(width: 16),
            IconButton(
              tooltip: context.tr("Hồ sơ và tùy chỉnh"),
              onPressed: onAccount,
              icon: avatar,
            ),
          ],
        ),
      ),
    );
  }
}

/// Three clearly bounded destinations; framework buttons own focus and input.
class DeskDestinationStrip extends StatelessWidget {
  const DeskDestinationStrip({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelected,
  });
  final List<String> destinations;
  final int selected;
  final ValueChanged<int> onSelected;
  static const icons = [
    Icons.notes_rounded,
    Icons.people_outline_rounded,
    Icons.auto_awesome_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final destinationTones = [
      colors.primary,
      colors.secondary,
      colors.tertiary,
    ];
    final selectedInks = [
      colors.onPrimary,
      colors.onSecondary,
      colors.onTertiary,
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: context.tr("Điều hướng chính"),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: MergeSemantics(
                    child: Semantics(
                      selected: i == selected,
                      child: TextButton(
                        key: ValueKey('desk-destination-$i'),
                        onPressed: () => onSelected(i),
                        style: ButtonStyle(
                          minimumSize: const WidgetStatePropertyAll(
                            Size(0, 52),
                          ),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          animationDuration: PrismMotion.duration(
                            context,
                            PrismMotion.hover,
                          ),
                          backgroundColor: WidgetStatePropertyAll(
                            i == selected
                                ? destinationTones[i % destinationTones.length]
                                : Colors.transparent,
                          ),
                          foregroundColor: WidgetStatePropertyAll(
                            i == selected
                                ? selectedInks[i % selectedInks.length]
                                : colors.onSurface,
                          ),
                          overlayColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.pressed)) {
                              return (i == selected
                                      ? selectedInks[i % selectedInks.length]
                                      : colors.primary)
                                  .withValues(alpha: .12);
                            }
                            if (states.contains(WidgetState.hovered)) {
                              return (i == selected
                                      ? selectedInks[i % selectedInks.length]
                                      : colors.primary)
                                  .withValues(alpha: .06);
                            }
                            return Colors.transparent;
                          }),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          side: WidgetStateProperty.resolveWith(
                            (states) => BorderSide(
                              color: states.contains(WidgetState.focused)
                                  ? i == selected
                                        ? selectedInks[i % selectedInks.length]
                                        : colors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          textStyle: WidgetStatePropertyAll(
                            theme.textTheme.labelLarge?.copyWith(
                              fontSize: 14,
                              height: 1.3,
                              fontWeight: i == selected
                                  ? FontWeight.w600
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            ExcludeSemantics(
                              child: Icon(
                                i < icons.length
                                    ? icons[i]
                                    : Icons.notes_rounded,
                                color: i == selected
                                    ? null
                                    : destinationTones[i %
                                          destinationTones.length],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(context.tr(destinations[i]))),
                            const SizedBox(width: 6),
                            ExcludeSemantics(
                              child: SizedBox(
                                width: 16,
                                child: i == selected
                                    ? const Icon(Icons.check_rounded, size: 16)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DeskToolDrawer extends StatelessWidget {
  const DeskToolDrawer({
    super.key,
    required this.onTemplates,
    required this.onWorkspace,
    required this.onLabels,
    required this.onAccount,
  });
  final VoidCallback onTemplates, onWorkspace, onLabels, onAccount;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('desk-tool-drawer'),
      width: 244,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surface, colors.surfaceContainerLow],
        ),
        borderRadius: BorderRadius.circular(StudioStyle.panel),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: StudioStyle.shadows(context),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr("Ngăn bàn"),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr("Từ ý tưởng\nđến bản nháp."),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr("Những công cụ nhỏ, luôn trong tầm tay."),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            _DrawerAction(
              icon: Icons.auto_awesome_mosaic_outlined,
              title: context.tr("Xưởng ghi chú"),
              detail: context.tr("Bắt đầu từ một mẫu"),
              accent: (colors.secondary, colors.onSecondary),
              onTap: onTemplates,
            ),
            const SizedBox(height: 12),
            _DrawerAction(
              icon: Icons.space_dashboard_outlined,
              title: context.tr("Không gian làm việc"),
              detail: context.tr("Kế hoạch, việc cần làm và tập trung"),
              accent: (colors.tertiary, colors.onTertiary),
              onTap: onWorkspace,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Tooltip(
              message: context.tr("Quản lý nhãn"),
              child: _DrawerAction(
                onTap: onLabels,
                icon: Icons.label_outline,
                title: context.tr("Quản lý nhãn"),
              ),
            ),
            const SizedBox(height: 8),
            _DrawerAction(
              onTap: onAccount,
              icon: Icons.tune,
              title: context.tr("Tùy chỉnh"),
            ),
            const SizedBox(height: 36),
            Text(context.tr("Đường tắt"), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Text(
              context.tr(
                "Ctrl + F  /  Tìm trong thư viện\nCtrl + K  /  Tìm nhanh",
              ),
              style: theme.textTheme.bodySmall?.copyWith(height: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerAction extends StatelessWidget {
  const _DrawerAction({
    required this.icon,
    required this.title,
    this.detail,
    this.accent,
    required this.onTap,
  });

  final (Color, Color)? accent;
  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (tone, onTone) = accent ?? (colors.primary, colors.onPrimary);
    final description = detail;
    final compact = description == null;
    final label = Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
    final arrow = ExcludeSemantics(
      child: Icon(Icons.chevron_right_rounded, size: 20, color: tone),
    );
    return OutlinedButton(
      onPressed: onTap,
      style:
          OutlinedButton.styleFrom(
            foregroundColor: tone,
            backgroundColor: Color.alphaBlend(
              tone.withValues(alpha: compact ? .05 : .14),
              colors.surface,
            ),
            minimumSize: const Size(0, 48),
            visualDensity: VisualDensity.standard,
            padding: EdgeInsets.all(compact ? 12 : 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ).copyWith(
            side: WidgetStateProperty.resolveWith((states) {
              final active =
                  states.contains(WidgetState.focused) ||
                  states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed);
              return BorderSide(
                color: active
                    ? tone
                    : Color.alphaBlend(
                        tone.withValues(alpha: compact ? .42 : .56),
                        colors.surface,
                      ),
                width: states.contains(WidgetState.focused) ? 2 : 1,
              );
            }),
          ),
      child: compact
          ? Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Expanded(child: label),
                arrow,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: tone,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(icon, color: onTone, size: 22),
                      ),
                    ),
                    const Spacer(),
                    arrow,
                  ],
                ),
                const SizedBox(height: 12),
                label,
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}

class NotebookTitle extends StatelessWidget {
  const NotebookTitle({
    super.key,
    required this.title,
    required this.detail,
    required this.count,
    this.total,
    required this.sync,
    this.dense = false,
  });
  final String title, detail;
  final int count;
  final int? total;
  final Widget sync;

  /// One-line heading once the library has notes: title, count and sync only.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final countChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(
        AppStrings.of(context).noteCount(count, total: total),
        style: theme.textTheme.bodySmall,
      ),
    );
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    final heading = Semantics(
      header: true,
      child: Text(
        title,
        // One line in the dense row so its height never depends on the
        // sync label's length.
        maxLines: dense && !largeText ? 1 : null,
        overflow: dense && !largeText ? TextOverflow.ellipsis : null,
        style: theme.textTheme.headlineLarge?.copyWith(
          fontSize: dense ? 30 : 38,
          fontWeight: FontWeight.w600,
          height: 1.2,
          letterSpacing: dense ? -.5 : -.8,
        ),
      ),
    );
    if (dense) {
      // A Row keeps one fixed height while the sync label changes length;
      // a Wrap would reflow and shift every card below on each sync pulse.
      return StudioHeaderPanel(
        compact: true,
        child: largeText
            ? Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [heading, countChip, sync],
              )
            : Row(
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 16),
                  countChip,
                  const SizedBox(width: 12),
                  sync,
                ],
              ),
      );
    }
    return StudioHeaderPanel(
      child: LayoutBuilder(
        builder: (context, area) => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr("Sổ ghi / NoteTogether"),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  heading,
                  const SizedBox(height: 10),
                  Text(detail, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [countChip, sync],
                  ),
                ],
              ),
            ),
            if (area.maxWidth >= 760 &&
                MediaQuery.textScalerOf(context).scale(1) < 1.3) ...[
              const SizedBox(width: 24),
              const StudioNotebookArt(),
            ],
          ],
        ),
      ),
    );
  }
}
