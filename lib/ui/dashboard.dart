import 'package:flutter/material.dart';

import 'design_system.dart';

/// Static optical areas, excluded from interaction and semantics.
class DashboardBackdrop extends StatelessWidget {
  const DashboardBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(
        child: _Decoration(
          child: CustomPaint(
            painter: _DashboardFacets(
              dark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme.copyWith(
      surface: const Color(0xff24255f),
      onSurface: Colors.white,
      onSurfaceVariant: DashboardColors.sidebarMuted,
      primary: DashboardColors.selected,
      secondaryContainer: DashboardColors.selected,
      onSecondaryContainer: DashboardColors.selectedInk,
      outlineVariant: const Color(0xff545787),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: DashboardColors.sidebar,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: _Decoration(
              child: CustomPaint(painter: _DashboardFacets(sidebar: true)),
            ),
          ),
          Theme(
            data: theme.copyWith(
              colorScheme: colors,
              textTheme: theme.textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
              iconTheme: theme.iconTheme.copyWith(color: Colors.white),
              listTileTheme: const ListTileThemeData(
                textColor: Colors.white,
                iconColor: Colors.white,
                selectedColor: DashboardColors.selectedInk,
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xff545787),
                space: 1,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: DashboardColors.selected,
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Builder(builder: builder),
            ),
          ),
        ],
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
  });
  final String title, detail, syncLabel;
  final int count;
  final bool online;
  final VoidCallback onSync;
  final Widget? action, notice;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = MediaQuery.sizeOf(context).width < 600;
    final dark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark ? DashboardColors.darkHeader : DashboardColors.header,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            const Positioned.fill(
              child: _Decoration(
                child: CustomPaint(painter: _DashboardFacets(header: true)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(small ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontSize: small ? 26 : 36,
                          ),
                        ),
                      ),
                      if (action != null) ...[
                        const SizedBox(width: 16),
                        action!,
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DashboardColors.heroMuted,
                    ),
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '$count ghi chú',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DashboardColors.heroMuted,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: onSync,
                        icon: Icon(
                          online
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_off_outlined,
                          size: 18,
                        ),
                        label: Text(syncLabel),
                      ),
                    ],
                  ),
                  if (notice != null) ...[
                    const SizedBox(height: 12),
                    Theme(
                      data: theme.copyWith(
                        colorScheme: theme.colorScheme.copyWith(
                          surfaceContainerHighest: dark
                              ? DashboardColors.darkNotice
                              : DashboardColors.notice,
                          onSurface: dark
                              ? DashboardColors.darkNoticeInk
                              : DashboardColors.noticeInk,
                          onSurfaceVariant: dark
                              ? DashboardColors.darkNoticeInk
                              : DashboardColors.noticeInk,
                          primary: dark
                              ? DashboardColors.darkNoticeInk
                              : DashboardColors.noticeInk,
                        ),
                      ),
                      child: notice!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Decoration extends StatelessWidget {
  const _Decoration({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(child: RepaintBoundary(child: child)),
  );
}

class _DashboardFacets extends CustomPainter {
  const _DashboardFacets({
    this.dark = false,
    this.header = false,
    this.sidebar = false,
  });
  final bool dark, header, sidebar;
  @override
  void paint(Canvas canvas, Size size) {
    if (!header && !sidebar) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = dark ? DashboardColors.darkCanvas : DashboardColors.canvas,
      );
    }
    final w = size.width, h = size.height;
    void facet(List<Offset> points, Color color) {
      canvas.drawPath(Path()..addPolygon(points, true), Paint()..color = color);
    }

    if (sidebar) {
      facet([
        Offset(0, h * .66),
        Offset(w, h * .49),
        Offset(w * .47, h * .84),
      ], const Color(0xff8583ff).withValues(alpha: .15));
      facet([
        Offset(w, h * .49),
        Offset(w * .47, h * .84),
        Offset(w, h),
      ], const Color(0xff8c5df3).withValues(alpha: .12));
    } else if (header) {
      facet([
        Offset(w * .72, 0),
        Offset(w * .85, h * .43),
        Offset(w * .80, h),
      ], Colors.white.withValues(alpha: .07));
      facet([
        Offset(w * .85, h * .43),
        Offset(w, 0),
        Offset(w, h),
      ], const Color(0xff8cf1ff).withValues(alpha: .07));
    } else {
      facet([
        Offset(w * .70, 0),
        Offset(w, 0),
        Offset(w * .92, h * .55),
      ], const Color(0xff99bdff).withValues(alpha: dark ? .04 : .10));
      facet([
        Offset(w * .85, h * .42),
        Offset(w, h * .35),
        Offset(w, h * .88),
      ], const Color(0xff80daca).withValues(alpha: dark ? .025 : .08));
      facet([
        Offset(w * .74, h * .78),
        Offset(w, h * .57),
        Offset(w, h),
      ], const Color(0xffbaa4f4).withValues(alpha: dark ? .025 : .09));
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardFacets oldDelegate) =>
      dark != oldDelegate.dark ||
      header != oldDelegate.header ||
      sidebar != oldDelegate.sidebar;
}
