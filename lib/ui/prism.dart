import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'palette_tokens.dart';

/// Decorative tones are derived from opaque IDs, never stored as note metadata.
@immutable
class PrismTone {
  const PrismTone(this.ink, this.light);
  final Color ink, light;
  @override
  bool operator ==(Object other) =>
      other is PrismTone && ink == other.ink && light == other.light;
  @override
  int get hashCode => Object.hash(ink, light);
  PrismTone lerp(PrismTone other, double t) => PrismTone(
    Color.lerp(ink, other.ink, t)!,
    Color.lerp(light, other.light, t)!,
  );
}

@immutable
class PrismPalette extends ThemeExtension<PrismPalette> {
  const PrismPalette({
    required this.canvas,
    required this.tones,
    required this.rim,
  });
  final Color canvas;
  final List<PrismTone> tones;
  final List<Color> rim;
  @override
  bool operator ==(Object other) =>
      other is PrismPalette &&
      canvas == other.canvas &&
      listEquals(tones, other.tones) &&
      listEquals(rim, other.rim);
  @override
  int get hashCode =>
      Object.hash(canvas, Object.hashAll(tones), Object.hashAll(rim));
  static const actionColors = [
    Color(0xff272b25),
    Color(0xff333c31),
    Color(0xff4d5948),
  ];

  factory PrismPalette.forBrightness(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return PrismPalette(
      canvas: Color(dark ? 0xff101426 : 0xfff5f5fc),
      tones: dark
          ? const [
              PrismTone(Color(0xffc7d4bd), Color(0xffa6b69b)),
              PrismTone(Color(0xffced8e2), Color(0xffa8b8c8)),
              PrismTone(Color(0xffc9ded0), Color(0xffa1bbac)),
              PrismTone(Color(0xffe4c5bc), Color(0xffc7a19a)),
              PrismTone(Color(0xffead5a5), Color(0xffcbb788)),
              PrismTone(Color(0xffd4dfbd), Color(0xffa7b798)),
            ]
          : const [
              PrismTone(Color(0xff4f6450), Color(0xffa6b69b)),
              PrismTone(Color(0xff546374), Color(0xffa8b8c8)),
              PrismTone(Color(0xff566e65), Color(0xffa1bbac)),
              PrismTone(Color(0xff815957), Color(0xffc7a19a)),
              PrismTone(Color(0xff80602f), Color(0xffcbb788)),
              PrismTone(Color(0xff53694b), Color(0xffa7b798)),
            ],
      rim: dark
          ? const [Color(0xff535b49), Color(0xff535b49), Color(0xff535b49)]
          : const [Color(0xffd0d1c3), Color(0xffd0d1c3), Color(0xffd0d1c3)],
    );
  }

  static PrismPalette of(BuildContext context) =>
      Theme.of(context).extension<PrismPalette>() ??
      PrismPalette.forBrightness(Theme.of(context).brightness);

  PrismTone tone(String id) {
    // Stable across rebuilds and sessions; unrelated to private title/content.
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return tones[hash % tones.length];
  }

  @override
  PrismPalette copyWith({
    Color? canvas,
    List<PrismTone>? tones,
    List<Color>? rim,
  }) => PrismPalette(
    canvas: canvas ?? this.canvas,
    tones: tones ?? this.tones,
    rim: rim ?? this.rim,
  );
  @override
  PrismPalette lerp(covariant PrismPalette? other, double t) => other == null
      ? this
      : PrismPalette(
          canvas: Color.lerp(canvas, other.canvas, t)!,
          tones: List.generate(
            tones.length,
            (i) => tones[i].lerp(other.tones[i], t),
          ),
          rim: List.generate(
            rim.length,
            (i) => Color.lerp(rim[i], other.rim[i], t)!,
          ),
        );
}

abstract final class PrismMotion {
  static const hover = Duration(milliseconds: 180);
  static const reveal = Duration(milliseconds: 420);
  static const section = Duration(milliseconds: 220);
  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}

/// One entrance only, never an exit retaining stale private content.
class PrismReveal extends StatelessWidget {
  const PrismReveal({
    super.key,
    required this.child,
    this.duration = PrismMotion.reveal,
    this.distance = 12,
  });
  final Widget child;
  final Duration duration;
  final double distance;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: PrismMotion.duration(context, duration),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (_, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, distance * (1 - value)),
        child: child,
      ),
    ),
  );
}

/// Animates only the bar; its semantics always describe the current value.
class PrismProgress extends StatelessWidget {
  const PrismProgress({super.key, required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => Semantics(
    value: '${(value.clamp(0, 1) * 100).round()}%',
    child: ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: PrismMotion.duration(context, PrismMotion.section),
        curve: Curves.easeOutCubic,
        builder: (_, progress, _) => LinearProgressIndicator(value: progress),
      ),
    ),
  );
}

class PrismPageTransitions extends PageTransitionsBuilder {
  const PrismPageTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final eased = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: eased.drive(
          Tween(begin: const Offset(0, .018), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}

/// Static optical atmosphere: no blur layers, per-frame shaders or looping ticker.
class PrismBackdrop extends StatelessWidget {
  const PrismBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(
        child: ExcludeSemantics(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _Atmosphere(PrismPalette.of(context)),
              ),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class _Atmosphere extends CustomPainter {
  _Atmosphere(this.palette);
  final PrismPalette palette;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.canvas);
  }

  @override
  bool shouldRepaint(covariant _Atmosphere old) => old.palette != palette;
}

/// Opaque reading surface with an iridescent rim, so long text never sits on blur.
class PrismSurface extends StatelessWidget {
  const PrismSurface({
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
    final p = PrismPalette.of(context);
    final surface = Theme.of(context).colorScheme.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.rim,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? .12
                  : .045,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Material(
          color: surface,
          borderRadius: BorderRadius.circular(11),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    backgroundColors ??
                    [
                      Color.alphaBlend(
                        p.tones[0].light.withValues(alpha: tinted ? .06 : 0),
                        surface,
                      ),
                      surface,
                      Color.alphaBlend(
                        p.tones[2].light.withValues(alpha: tinted ? .04 : 0),
                        surface,
                      ),
                    ],
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class PrismCard extends StatefulWidget {
  const PrismCard({
    super.key,
    required this.child,
    required this.onTap,
    this.tone,
    this.rich = false,
  });
  final Widget child;
  final VoidCallback onTap;
  final PrismTone? tone; // null is neutral for locked notes.
  final bool rich;
  @override
  State<PrismCard> createState() => _PrismCardState();
}

class _PrismCardState extends State<PrismCard> {
  bool hovered = false, focused = false, pressed = false;
  @override
  Widget build(BuildContext context) {
    final p = PrismPalette.of(context);
    final colors = Theme.of(context).colorScheme;
    final tone = widget.tone;
    final active = hovered || focused;
    final accent = tone?.light ?? colors.outlineVariant;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rich = widget.rich && tone != null;
    return RepaintBoundary(
      // Keep pointer/focus/tap bounds fixed; only the painted card moves.
      // Moving InkWell itself can repeatedly exit/re-enter at a stationary edge.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          hoverDuration: PrismMotion.duration(context, PrismMotion.hover),
          onHover: (v) => setState(() => hovered = v),
          onFocusChange: (v) => setState(() => focused = v),
          onHighlightChanged: (v) => setState(() => pressed = v),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: PrismMotion.duration(context, PrismMotion.hover),
            curve: Curves.easeOutCubic,
            transformAlignment: Alignment.center,
            transform:
                Matrix4.diagonal3Values(
                  pressed && !MediaQuery.disableAnimationsOf(context)
                      ? .985
                      : 1,
                  pressed && !MediaQuery.disableAnimationsOf(context)
                      ? .985
                      : 1,
                  1,
                )..setTranslationRaw(
                  0,
                  active && !pressed && !MediaQuery.disableAnimationsOf(context)
                      ? -2
                      : 0,
                  0,
                ),
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: tone == null
                    ? [colors.outlineVariant, colors.outlineVariant]
                    : [
                        Color.lerp(p.rim[0], accent, active ? .8 : .45)!,
                        p.rim[1],
                        Color.lerp(p.rim[2], accent, .3)!,
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: active ? .16 : .06),
                  blurRadius: active ? 14 : 6,
                  offset: Offset(0, active ? 5 : 2),
                ),
              ],
            ),
            child: RepaintBoundary(
              child: Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(11),
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(
                          accent.withValues(
                            alpha: pressed
                                ? .09
                                : tone == null
                                ? .025
                                : rich
                                ? (dark ? .05 : .045)
                                : .03,
                          ),
                          colors.surface,
                        ),
                        Color.alphaBlend(
                          accent.withValues(
                            alpha: rich ? (dark ? .03 : .025) : 0,
                          ),
                          colors.surface,
                        ),
                      ],
                      stops: [0, rich ? 1 : .72],
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (tone != null)
                        Positioned(
                          top: 0,
                          left: 16,
                          width: 52,
                          height: 3,
                          child: ExcludeSemantics(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [tone.ink, tone.light],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      widget.child,
                      // Native ink is beneath the opaque body; paint focus above it.
                      if (focused)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ExcludeSemantics(
                              child: DecoratedBox(
                                key: const Key('prism-card-focus-ring'),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colors.primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrismAction extends StatelessWidget {
  const PrismAction({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: onPressed == null ? null : Colors.transparent,
      foregroundColor: onPressed == null ? null : Colors.white,
      shadowColor: Colors.transparent,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? null
            : LinearGradient(colors: PaletteTokens.of(context).brand),
        borderRadius: BorderRadius.circular(8),
      ),
      child: icon == null
          ? FilledButton(onPressed: onPressed, style: style, child: child)
          : FilledButton.icon(
              onPressed: onPressed,
              style: style,
              icon: icon!,
              label: child,
            ),
    );
  }
}

class PrismArtwork extends StatelessWidget {
  const PrismArtwork({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox(
        width: 300,
        height: 240,
        child: CustomPaint(painter: _Crystal(PrismPalette.of(context))),
      ),
    ),
  );
}

class _Crystal extends CustomPainter {
  _Crystal(this.palette);
  final PrismPalette palette;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 240);
    const a = Offset(142, 14),
        b = Offset(255, 77),
        c = Offset(220, 196),
        d = Offset(104, 224),
        e = Offset(44, 128),
        center = Offset(151, 117);
    final points = [a, b, c, d, e];
    for (var i = 0; i < points.length; i++) {
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(points[i].dx, points[i].dy)
        ..lineTo(
          points[(i + 1) % points.length].dx,
          points[(i + 1) % points.length].dy,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.tones[i].light.withValues(alpha: .82),
              palette.tones[(i + 2) % 6].light.withValues(alpha: .20),
            ],
          ).createShader(path.getBounds()),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    }
    final shine = Path()
      ..moveTo(142, 14)
      ..lineTo(176, 89)
      ..lineTo(104, 224)
      ..lineTo(124, 96)
      ..close();
    canvas.drawPath(shine, Paint()..color = Colors.white.withValues(alpha: .2));
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(216, 112 + i * 7),
        Offset(291, 91 + i * 22),
        Paint()
          ..color = palette.tones[i].light.withValues(alpha: .65)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      const Offset(31, 65),
      5,
      Paint()..color = palette.tones[3].light,
    );
    canvas.drawCircle(
      const Offset(263, 199),
      3,
      Paint()..color = palette.tones[2].light,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Crystal old) => old.palette != palette;
}
