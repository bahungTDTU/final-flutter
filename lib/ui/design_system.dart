import 'package:flutter/material.dart';

import 'prism.dart';
export 'prism.dart';

abstract final class Space {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32;
  static const double sidebar = 248, reading = 800;
}

/// Brand chrome shared by dashboard, routes and account surfaces.
abstract final class DashboardColors {
  static const sidebar = [Color(0xff191d50), Color(0xff2e2c7b)];
  static const header = [Color(0xff5c43c9), Color(0xff2468a7)];
  static const darkHeader = [Color(0xff433284), Color(0xff204d75)];
  static const canvas = Color(0xffeceefb);
  static const darkCanvas = Color(0xff12182d);
  static const sidebarMuted = Color(0xffccd3f2);
  static const selected = Color(0xffd0c4ff);
  static const selectedInk = Color(0xff2d2269);
  static const heroMuted = Color(0xfffaf8ff);
  static const action = Color(0xffe8e0ff);
  static const actionInk = Color(0xff31246f);
  static const notice = Color(0xfffff3dc);
  static const noticeInk = Color(0xff744813);
  static const darkNotice = Color(0xff3b3025);
  static const darkNoticeInk = Color(0xffffdcaa);
}

/// Uses the same static gradient as the dashboard, without a new animation layer.
class BrandGradient extends StatelessWidget {
  const BrandGradient({super.key, required this.child, this.radius = 0});
  final Widget child;
  final double radius;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: Theme.of(context).brightness == Brightness.dark
            ? DashboardColors.darkHeader
            : DashboardColors.header,
      ),
    ),
    child: child,
  );
}

/// AppBar remains the framework widget so navigation, focus and menus keep their behavior.
AppBar noteAppBar({Widget? title, Widget? leading, List<Widget>? actions}) =>
    AppBar(
      title: title,
      leading: leading,
      actions: actions,
      flexibleSpace: const BrandGradient(child: SizedBox.expand()),
    );

class BrandPanel extends StatelessWidget {
  const BrandPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(32),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BrandGradient(
      radius: 22,
      child: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            onSurface: Colors.white,
            onSurfaceVariant: DashboardColors.heroMuted,
            onPrimaryContainer: Colors.white,
            surfaceContainerHighest: Colors.white.withValues(alpha: .08),
          ),
          textTheme: theme.textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          iconTheme: theme.iconTheme.copyWith(color: Colors.white),
        ),
        child: DefaultTextStyle.merge(
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Shared reading/writing surface. Padding is derived from available space,
/// including short landscape windows; controllers stay owned by the route.
class ReadingCanvas extends StatelessWidget {
  const ReadingCanvas({
    super.key,
    required this.child,
    this.controller,
    this.panel = true,
  });
  final Widget child;
  final ScrollController? controller;
  final bool panel;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, area) {
        final compact = area.maxWidth < 600 || area.maxHeight < 440;
        final inset = compact ? 12.0 : 24.0;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.reading),
            child: SingleChildScrollView(
              controller: controller,
              padding: EdgeInsets.all(inset),
              child: panel
                  ? SurfacePanel(
                      padding: EdgeInsets.all(compact ? 16 : 28),
                      child: child,
                    )
                  : child,
            ),
          ),
        );
      },
    ),
  );
}

ThemeData noteTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final palette = PrismPalette.forBrightness(brightness).copyWith(
    canvas: dark ? DashboardColors.darkCanvas : DashboardColors.canvas,
  );
  final canvas = palette.canvas;
  final surface = Color(dark ? 0xff191e33 : 0xfffbfaff);
  final primary = dark ? const Color(0xffc8bdff) : DashboardColors.header.first;
  final ink = Color(dark ? 0xffeef0ff : 0xff19223b);
  final muted = Color(dark ? 0xffb8bfd6 : 0xff55617d);
  final outline = Color(dark ? 0xff8996b8 : 0xff717b9d);
  final scheme =
      ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
        primary: primary,
        secondary: Color(dark ? 0xffa6cdff : 0xff2468a7),
        onSecondary: Color(dark ? 0xff163454 : 0xffffffff),
        tertiary: Color(dark ? 0xffa0eed1 : 0xff126b54),
        primaryContainer: Color(dark ? 0xff352e59 : 0xffeeebff),
        onPrimaryContainer: Color(dark ? 0xffded5ff : 0xff33296e),
        secondaryContainer: Color(dark ? 0xff293751 : 0xffe5ecff),
        onSecondaryContainer: Color(dark ? 0xffd6e4ff : 0xff263e73),
        onPrimary: dark ? const Color(0xff251850) : Colors.white,
        surface: surface,
        onSurface: ink,
        onSurfaceVariant: muted,
        surfaceContainerLowest: Color(dark ? 0xff151b2e : 0xffffffff),
        surfaceContainerLow: Color(dark ? 0xff20263b : 0xfff3f1fc),
        surfaceContainer: Color(dark ? 0xff252c45 : 0xffeef0fb),
        surfaceContainerHigh: Color(dark ? 0xff2c3450 : 0xffe8ebf9),
        surfaceContainerHighest: Color(dark ? 0xff343e5e : 0xffe0e5f4),
        outline: outline,
        outlineVariant: Color(dark ? 0xff414b6b : 0xffdce0ef),
        error: Color(dark ? 0xffffb4ab : 0xffa52b24),
      );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'NotoSans',
    extensions: [palette],
  );
  return base.copyWith(
    scaffoldBackgroundColor: canvas,
    textTheme: base.textTheme
        .copyWith(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: ink,
            height: 1.25,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: ink,
            height: 1.3,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: ink),
          bodyMedium: TextStyle(fontSize: 15, height: 1.5, color: ink),
          bodySmall: TextStyle(fontSize: 13, height: 1.4, color: muted),
        )
        .apply(fontFamily: 'NotoSans'),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.all(Space.lg),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: scheme.outline,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      iconTheme: WidgetStateProperty.fromMap({
        WidgetState.selected: IconThemeData(color: primary),
        WidgetState.any: IconThemeData(color: muted),
      }),
      labelTextStyle: WidgetStateProperty.fromMap({
        WidgetState.selected: TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        WidgetState.any: TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: muted,
        ),
      }),
      height: 80,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: canvas,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: primary),
      unselectedIconTheme: IconThemeData(color: muted),
      selectedLabelTextStyle: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: muted),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        backgroundColor: WidgetStateProperty.fromMap({
          WidgetState.selected: scheme.secondaryContainer,
          WidgetState.any: scheme.surfaceContainerLowest,
        }),
        foregroundColor: WidgetStateProperty.fromMap({
          WidgetState.disabled: scheme.onSurface.withValues(alpha: .38),
          WidgetState.selected: scheme.onSecondaryContainer,
          WidgetState.any: muted,
        }),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: primary,
      selectedColor: scheme.onPrimaryContainer,
      selectedTileColor: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: scheme.surfaceContainerLowest,
      selectedColor: scheme.primaryContainer,
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(fontFamily: 'NotoSans', fontSize: 15, color: ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(
        fontFamily: 'NotoSans',
        color: scheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: scheme.primaryContainer,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 13,
        color: scheme.onInverseSurface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PrismPageTransitions(),
        TargetPlatform.iOS: PrismPageTransitions(),
        TargetPlatform.windows: PrismPageTransitions(),
        TargetPlatform.macOS: PrismPageTransitions(),
        TargetPlatform.linux: PrismPageTransitions(),
      },
    ),
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: PrismPalette.actionColors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.auto_stories_outlined, color: Colors.white),
      ),
      if (!compact) ...[
        const SizedBox(width: 12),
        const Flexible(
          child: Text(
            'NoteTogether',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ],
  );
}

class StatusNotice extends StatelessWidget {
  const StatusNotice({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.action,
    this.error = false,
  });
  final String message;
  final IconData icon;
  final Widget? action;
  final bool error;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error ? colors.errorContainer : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: error
              ? colors.error.withValues(alpha: .4)
              : colors.outlineVariant,
        ),
      ),
      child: Builder(
        builder: (context) {
          final stacked =
              MediaQuery.sizeOf(context).width < 360 ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.5;
          final description = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 24,
                color: error
                    ? colors.onErrorContainer
                    : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: error ? colors.onErrorContainer : colors.onSurface,
                  ),
                ),
              ),
              if (!stacked && action != null) action!,
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              description,
              if (stacked && action != null)
                Align(alignment: Alignment.centerRight, child: action),
            ],
          );
        },
      ),
    );
  }
}

/// Shared structure for real management flows; owns no business state.
class DialogHeading extends StatelessWidget {
  const DialogHeading(this.title, {super.key, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(title),
        ),
      ),
    ],
  );
}

class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.tinted = false,
    this.backgroundColors,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool tinted;
  final List<Color>? backgroundColors;
  @override
  Widget build(BuildContext context) {
    return PrismSurface(
      padding: padding,
      tinted: tinted,
      backgroundColors: backgroundColors,
      child: child,
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.detail, this.icon});
  final String title;
  final String? detail;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
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
          ],
        ),
        if (detail != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(detail!, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    ),
  );
}

class MetadataPill extends StatelessWidget {
  const MetadataPill(this.label, {super.key, this.icon, this.tone});
  final String label;
  final IconData? icon;
  final PrismTone? tone;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: tone == null
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Color.alphaBlend(
              tone!.light.withValues(alpha: .14),
              Theme.of(context).colorScheme.surface,
            ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: tone?.ink),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: tone?.ink),
          ),
        ),
      ],
    ),
  );
}

class EmptyNotes extends StatelessWidget {
  const EmptyNotes({
    super.key,
    required this.title,
    required this.detail,
    this.action,
    this.icon = Icons.edit_note_outlined,
  });
  final String title, detail;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
    child: Column(
      children: [
        ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(detail, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}
