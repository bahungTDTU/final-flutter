import 'package:flutter/material.dart';

import 'design_system.dart';
import 'deskbook.dart';

/// Quiet canvas: the document covers carry the hierarchy.
class DashboardBackdrop extends StatelessWidget {
  const DashboardBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: child,
  );
}

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Builder(builder: builder),
  );
}

/// Indexed navigation retains the framework's focus and keyboard behavior.
class LibraryDestination extends StatelessWidget {
  const LibraryDestination({
    super.key,
    required this.index,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final int index;
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: selected ? colors.primary : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: ListTile(
        selected: selected,
        selectedColor: colors.onSurface,
        selectedTileColor: colors.primary.withValues(alpha: .055),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ExcludeSemantics(
          child: Text(
            '${index + 1}'.padLeft(2, '0'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: Icon(icon, size: 19),
        onTap: onTap,
      ),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.title,
    required this.detail,
    required this.count,
    required this.syncLabel,
    required this.online,
    required this.onSync,
    this.action,
    this.notice,
    this.workbench = false,
  });
  final String title, detail, syncLabel;
  final int count;
  final bool online;
  final VoidCallback onSync;
  final Widget? action, notice;
  final bool workbench;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final compact =
        MediaQuery.sizeOf(context).width < 600 ||
        MediaQuery.sizeOf(context).height < 740;
    final sync = TextButton.icon(
      onPressed: onSync,
      icon: Icon(
        online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
        size: 18,
      ),
      label: Text(syncLabel),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact && !workbench) ...[
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'KHÔNG GIAN GHI CHÚ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
        ],
        LayoutBuilder(
          builder: (context, area) {
            final wide =
                !compact &&
                area.maxWidth >= 700 &&
                MediaQuery.textScalerOf(context).scale(1) < 1.5;
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: compact ? 28 : 46,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -1.2,
                      height: 1.2,
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 12),
                  Text(detail, style: theme.textTheme.bodyMedium),
                ],
                if (action != null) ...[const SizedBox(height: 20), action!],
                if (!wide) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('$count ghi chú', style: theme.textTheme.bodySmall),
                      sync,
                    ],
                  ),
                ],
              ],
            );
            if (workbench) {
              return NotebookTitle(
                title: title,
                detail: detail,
                count: count,
                sync: sync,
              );
            }
            if (!wide) return titleBlock;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 36),
                SizedBox(
                  width: 220,
                  child: Theme(
                    data: noteTheme(
                      theme.brightness == Brightness.light
                          ? Brightness.dark
                          : Brightness.light,
                    ),
                    child: Builder(
                      builder: (context) {
                        final plate = Theme.of(context);
                        return Container(
                          key: const Key('library-count-plate'),
                          padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                          decoration: BoxDecoration(
                            color: plate.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ExcludeSemantics(
                                child: Text(
                                  '$count'.padLeft(2, '0'),
                                  style: plate.textTheme.displayLarge?.copyWith(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w300,
                                    height: 1.05,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$count ghi chú',
                                style: plate.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              sync,
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (notice != null) ...[
          const SizedBox(height: 20),
          Theme(
            data: theme.copyWith(
              colorScheme: colors.copyWith(
                surfaceContainerHighest: theme.brightness == Brightness.dark
                    ? DashboardColors.darkNotice
                    : DashboardColors.notice,
                onSurface: theme.brightness == Brightness.dark
                    ? DashboardColors.darkNoticeInk
                    : DashboardColors.noticeInk,
                onSurfaceVariant: theme.brightness == Brightness.dark
                    ? DashboardColors.darkNoticeInk
                    : DashboardColors.noticeInk,
                primary: theme.brightness == Brightness.dark
                    ? DashboardColors.darkNoticeInk
                    : DashboardColors.noticeInk,
              ),
            ),
            child: notice!,
          ),
        ],
        const SizedBox(height: 20),
        Divider(color: colors.onSurface, thickness: 1),
      ],
    );
  }
}

/// Only two covers are eager; the rest of the catalogue remains a sliver.
class PinnedShelf extends StatelessWidget {
  const PinnedShelf({
    super.key,
    required this.first,
    required this.second,
    required this.height,
  });
  final Widget first, second;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 7, child: first),
        const SizedBox(width: 20),
        Expanded(flex: 5, child: second),
      ],
    ),
  );
}
