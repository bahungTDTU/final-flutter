import 'package:flutter/material.dart';

/// Informational metadata has no checkbox or button semantics.
class InspectorBadge extends StatelessWidget {
  const InspectorBadge(this.label, {super.key, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ExcludeSemantics(child: Icon(icon, size: 16)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A bounded, naturally sized section shared by document information drawers.
/// No transitions retain its private children after a reader gate closes.
class InspectorSection extends StatelessWidget {
  const InspectorSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(height: 8),
              children[index],
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-width controls keep a stable icon column and allow long labels to wrap.
class InspectorAction extends StatelessWidget {
  const InspectorAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary, destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final child = Row(
      children: [
        ExcludeSemantics(child: Icon(icon, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, textAlign: TextAlign.left)),
      ],
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    if (primary) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: shape,
          alignment: Alignment.centerLeft,
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: destructive ? colors.error : colors.onSurface,
        backgroundColor: colors.surfaceContainerLow,
        side: BorderSide(color: destructive ? colors.error : colors.outline),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: shape,
        alignment: Alignment.centerLeft,
      ),
      child: child,
    );
  }
}
