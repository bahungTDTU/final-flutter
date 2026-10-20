import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

import 'prism.dart';
import 'studio.dart';
import 'palette_tokens.dart';
export 'palette_tokens.dart';
export 'prism.dart';
export 'studio.dart';

abstract final class Space {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32;
  static const double sidebar = 248, reading = 800;
}

/// Brand chrome shared by dashboard, routes and account surfaces.
abstract final class DashboardColors {
  static const sidebar = [Color(0xff242622), Color(0xff333630)];
  static const header = [
    Color(0xff242622),
    Color(0xff394a40),
    Color(0xff536453),
  ];
  static const darkHeader = [
    Color(0xff242622),
    Color(0xff30352f),
    Color(0xff39443a),
  ];
  static const canvas = Color(0xfff4f1ea);
  static const darkCanvas = Color(0xff171a17);
  static const sidebarMuted = Color(0xff67685e);
  static const selected = Color(0xffe5e8dd);
  static const selectedInk = Color(0xff293b31);
  static const heroMuted = Color(0xfff3efe4);
  static const action = Color(0xffe5e8dd);
  static const actionInk = Color(0xff293b31);
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
        colors: PaletteTokens.of(context).brand,
      ),
    ),
    child: child,
  );
}

/// AppBar remains the framework widget so navigation, focus and menus keep their behavior.
AppBar noteAppBar({Widget? title, Widget? leading, List<Widget>? actions}) =>
    AppBar(title: title, leading: leading, actions: actions, toolbarHeight: 64);

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
      radius: 12,
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

// Immutable themes are shared by the app shell and contrasting editorial covers.
// A controller pulse must not regenerate seeded colors and typography per cover.
final _noteThemes = <(Brightness, AppPalette), ThemeData>{};
ThemeData noteTheme(
  Brightness brightness, {
  AppPalette palette = AppPalette.atelier,
}) => _noteThemes.putIfAbsent((
  brightness,
  palette,
), () => _buildNoteTheme(brightness, palette));

ThemeData _buildNoteTheme(Brightness brightness, AppPalette selected) {
  final dark = brightness == Brightness.dark;
  final spec = PaletteSpec.forPalette(selected);
  final canvas = spec.canvas(brightness);
  var surface = Color(dark ? 0xff242822 : 0xfffcfaf5);
  var primary = dark ? const Color(0xffd7b87f) : DashboardColors.header.first;
  var ink = Color(dark ? 0xfff4f0e6 : 0xff272b25);
  var muted = Color(dark ? 0xffc4c5b8 : 0xff555b51);
  var outline = Color(dark ? 0xffa6ac9a : 0xff858a7d);
  var scheme = ColorScheme.fromSeed(seedColor: primary, brightness: brightness)
      .copyWith(
        primary: primary,
        secondary: Color(dark ? 0xffbed0b7 : 0xff394a40),
        onSecondary: Color(dark ? 0xff203022 : 0xffffffff),
        tertiary: Color(dark ? 0xffd9bd9b : 0xff73552b),
        primaryContainer: Color(dark ? 0xff3a392b : 0xffe8e3d4),
        onPrimaryContainer: Color(dark ? 0xffe9d9b5 : 0xff4f452c),
        secondaryContainer: Color(dark ? 0xff343e32 : 0xffe4e9df),
        onSecondaryContainer: Color(dark ? 0xffdce7d7 : 0xff314735),
        onPrimary: dark ? const Color(0xff302919) : Colors.white,
        surface: surface,
        onSurface: ink,
        onSurfaceVariant: muted,
        surfaceContainerLowest: Color(dark ? 0xff1b201a : 0xffffffff),
        surfaceContainerLow: Color(dark ? 0xff2b3027 : 0xffeeeadf),
        surfaceContainer: Color(dark ? 0xff30362c : 0xffe7e4d8),
        surfaceContainerHigh: Color(dark ? 0xff383e33 : 0xffdfdecf),
        surfaceContainerHighest: Color(dark ? 0xff42493b : 0xffd8dacb),
        outline: outline,
        outlineVariant: Color(dark ? 0xff505747 : 0xffd2d2c4),
        error: Color(dark ? 0xffffb4ab : 0xffa52b24),
      );
  if (selected != AppPalette.atelier) {
    scheme = spec.scheme(brightness);
    surface = scheme.surface;
    primary = scheme.primary;
    ink = scheme.onSurface;
    muted = scheme.onSurfaceVariant;
    outline = scheme.outline;
  }
  final basePalette = PrismPalette.forBrightness(brightness);
  final accents = [
    spec.seed,
    spec.secondary,
    spec.accent,
    Color.lerp(spec.seed, spec.secondary, .5)!,
    Color.lerp(spec.secondary, spec.accent, .5)!,
    Color.lerp(spec.seed, spec.accent, .5)!,
  ];
  final palette = basePalette.copyWith(
    canvas: canvas,
    tones: selected == AppPalette.atelier
        ? null
        : [
            for (final c in accents)
              PrismTone(
                dark ? Color.lerp(c, Colors.white, .72)! : c,
                Color.lerp(c, Colors.white, .72)!,
              ),
          ],
    rim: selected == AppPalette.atelier
        ? null
        : List.filled(3, scheme.outlineVariant),
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'NotoSans',
    extensions: [palette, PaletteTokens.forPalette(selected)],
  );
  return base.copyWith(
    scaffoldBackgroundColor: canvas,
    textTheme: base.textTheme
        .copyWith(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
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
      shape: Border(
        bottom: BorderSide(color: scheme.outlineVariant, width: .5),
      ),
      backgroundColor: surface,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSans',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintStyle: TextStyle(color: muted),
      labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.all(Space.lg),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudioStyle.control),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudioStyle.control),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudioStyle.control),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioStyle.card),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioStyle.control),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioStyle.control),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style:
          IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(StudioStyle.control),
            ),
          ).copyWith(
            side: WidgetStateProperty.fromMap({
              WidgetState.focused: BorderSide(color: primary, width: 2),
              WidgetState.any: BorderSide.none,
            }),
          ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioStyle.panel),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioStyle.control),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: scheme.surfaceContainerLowest,
      selectedColor: scheme.primaryContainer,
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      labelStyle: TextStyle(
        fontFamily: 'NotoSans',
        color: ink,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: 'NotoSans',
        color: scheme.onPrimaryContainer,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(fontFamily: 'NotoSans', fontSize: 15, color: ink),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioStyle.card),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(
        fontFamily: 'NotoSans',
        color: scheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioStyle.control),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioStyle.control),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    scrollbarTheme: ScrollbarThemeData(
      radius: const Radius.circular(12),
      thickness: const WidgetStatePropertyAll(6),
      thumbColor: WidgetStateProperty.fromMap({
        WidgetState.hovered: muted.withValues(alpha: .65),
        WidgetState.any: muted.withValues(alpha: .4),
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: scheme.primaryContainer,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(6.0),
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
          gradient: LinearGradient(colors: PaletteTokens.of(context).brand),
          borderRadius: BorderRadius.circular(StudioStyle.control),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: error ? colors.errorContainer : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
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
              ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        (error
                                ? colors.onErrorContainer
                                : colors.onSurfaceVariant)
                            .withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: error
                        ? colors.onErrorContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.trMessage(message),
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
            borderRadius: BorderRadius.circular(StudioStyle.control),
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

/// Route and feature introductions share hierarchy without owning application state.
class PageIntro extends StatelessWidget {
  const PageIntro({
    super.key,
    required this.title,
    required this.detail,
    required this.icon,
    this.eyebrow,
    this.trailing,
    this.accent = 0,
    this.panel = true,
  });
  final String title, detail;
  final String? eyebrow;
  final IconData icon;
  final Widget? trailing;
  final int accent;
  final bool panel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = PrismPalette.of(context).tones[accent];
    final content = LayoutBuilder(
      builder: (context, area) {
        final compact =
            area.maxWidth < 640 ||
            MediaQuery.textScalerOf(context).scale(1) >= 1.5;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (eyebrow != null && !compact) ...[
              Text(
                eyebrow!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tone.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (MediaQuery.textScalerOf(context).scale(1) < 1.5) ...[
                  ExcludeSemantics(
                    child: Container(
                      width: compact ? 40 : 48,
                      height: compact ? 40 : 48,
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          tone.light.withValues(alpha: .18),
                          theme.colorScheme.surface,
                        ),
                        borderRadius: BorderRadius.circular(
                          StudioStyle.control,
                        ),
                        border: Border.all(
                          color: tone.light.withValues(alpha: .4),
                        ),
                      ),
                      child: Icon(icon, color: tone.ink, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style:
                          (compact
                                  ? theme.textTheme.titleLarge
                                  : theme.textTheme.headlineSmall)
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              detail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
        if (trailing == null) return heading;
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [heading, const SizedBox(height: 20), trailing!],
              )
            : Row(
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 24),
                  trailing!,
                ],
              );
      },
    );
    return panel ? SurfacePanel(tinted: true, child: content) : content;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Semantics(
                header: true,
                child: Padding(
                  padding: EdgeInsets.only(top: icon == null ? 0 : 3),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
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
      border: Border.all(
        color: (tone?.light ?? Theme.of(context).colorScheme.outlineVariant)
            .withValues(alpha: .5),
      ),
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
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
    child: Column(
      children: [
        ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
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
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            detail,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}
