import 'package:flutter/material.dart';

/// Shared visual rhythm; decoration never changes a control's hit bounds.
abstract final class StudioStyle {
  static const double control = 14, card = 20, panel = 24, hero = 28;

  static List<Color> headingColors(ColorScheme colors) => [
    Color.alphaBlend(
      colors.primaryContainer.withValues(alpha: .55),
      colors.surface,
    ),
    colors.surface,
    Color.alphaBlend(
      colors.tertiaryContainer.withValues(alpha: .36),
      colors.surface,
    ),
  ];

  static List<BoxShadow> shadows(BuildContext context, {bool raised = false}) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: colors.onSurface.withValues(alpha: dark ? .045 : .035),
        blurRadius: raised ? 28 : 18,
        offset: Offset(0, raised ? 8 : 4),
      ),
    ];
  }
}

/// Opaque, softly lit chrome; text never relies on the underlying canvas.
class StudioHeaderPanel extends StatelessWidget {
  const StudioHeaderPanel({
    super.key,
    required this.child,
    this.compact = false,
  });
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const Key('studio-heading-surface'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: StudioStyle.headingColors(colors),
          stops: const [0, .6, 1],
        ),
        borderRadius: BorderRadius.circular(StudioStyle.hero),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: StudioStyle.shadows(context),
      ),
      child: Padding(padding: EdgeInsets.all(compact ? 18 : 24), child: child),
    );
  }
}

/// Static vector artwork with no user data, ticker, blur or interactive layer.
class StudioNotebookArt extends StatelessWidget {
  const StudioNotebookArt({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: SizedBox(
            width: 128,
            height: 128,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: .15,
                  child: Container(
                    width: 82,
                    height: 106,
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -.12,
                  child: Container(
                    width: 82,
                    height: 106,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: .18),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            color: colors.onPrimaryContainer,
                            size: 26,
                          ),
                          const Spacer(),
                          Container(
                            height: 3,
                            width: 36,
                            color: colors.onPrimaryContainer.withValues(
                              alpha: .35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 3,
                            width: 24,
                            color: colors.onPrimaryContainer.withValues(
                              alpha: .2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick labels use one scroll row on phones; the full filter stays in view.
/// Large text uses natural wrapping and retains the same native controls.
class StudioFilterStrip extends StatelessWidget {
  const StudioFilterStrip({
    super.key,
    required this.labels,
    required this.fullFilter,
    required this.compact,
  });
  final List<Widget> labels;
  final Widget fullFilter;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact && MediaQuery.textScalerOf(context).scale(1) < 1.5) {
      return Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const Key('studio-quick-label-scroll'),
              scrollDirection: Axis.horizontal,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    labels[i],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 152, child: fullFilter),
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [...labels, fullFilter],
    );
  }
}
