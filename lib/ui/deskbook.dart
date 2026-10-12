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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            const Brand(),
            const SizedBox(width: 36),
            Expanded(
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++) ...[
                    Expanded(
                      child: Semantics(
                        selected: i == selected,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: i == selected
                                    ? colors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: TextButton.icon(
                            onPressed: () => onSelected(i),
                            style: TextButton.styleFrom(
                              foregroundColor: i == selected
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant,
                            ),
                            icon: ExcludeSemantics(
                              child: Text(
                                '${i + 1}'.padLeft(2, '0'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            label: Text(destinations[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Tìm nhanh · Ctrl+K',
              onPressed: onQuickFind,
              icon: const Icon(Icons.manage_search),
            ),
            const SizedBox(width: 12),
            create,
            const SizedBox(width: 16),
            IconButton(
              tooltip: 'Hồ sơ và tùy chỉnh',
              onPressed: onAccount,
              icon: avatar,
            ),
          ],
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
        color: colors.surfaceContainerLow,
        border: Border(left: BorderSide(color: colors.outlineVariant)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'NGĂN BÀN',
              style: theme.textTheme.bodySmall?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Từ ý tưởng\nđến bản nháp.',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Những công cụ nhỏ, luôn trong tầm tay.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            _DrawerAction(
              icon: Icons.auto_awesome_mosaic_outlined,
              title: 'Xưởng ghi chú',
              detail: 'Bắt đầu từ một mẫu',
              onTap: onTemplates,
            ),
            const SizedBox(height: 12),
            _DrawerAction(
              icon: Icons.space_dashboard_outlined,
              title: 'Không gian làm việc',
              detail: 'Kế hoạch, việc cần làm và tập trung',
              onTap: onWorkspace,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Tooltip(
              message: 'Quản lý nhãn',
              child: TextButton.icon(
                onPressed: onLabels,
                icon: const Icon(Icons.label_outline),
                label: const Text('Quản lý nhãn'),
              ),
            ),
            TextButton.icon(
              onPressed: onAccount,
              icon: const Icon(Icons.tune),
              label: const Text('Tùy chỉnh'),
            ),
            const SizedBox(height: 36),
            Text(
              'ĐƯỜNG TẮT',
              style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Ctrl + F  /  Tìm trong thư viện\nCtrl + K  /  Tìm nhanh',
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
    required this.detail,
    required this.onTap,
  });
  final IconData icon;
  final String title, detail;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(icon, color: colors.primary)),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
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
    required this.sync,
  });
  final String title, detail;
  final int count;
  final Widget sync;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 52,
            height: 92,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(26),
              ),
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              color: colors.onPrimary,
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SỔ GHI / NOTETOGETHER',
                style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(detail, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('$count ghi chú', style: theme.textTheme.bodySmall),
                  sync,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
