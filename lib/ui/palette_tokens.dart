import 'package:flutter/material.dart';

import '../domain/app_palette.dart';
export '../domain/app_palette.dart';

/// Curated primitive colours. Reading surfaces remain opaque and calm.
class PaletteSpec {
  const PaletteSpec(
    this.seed,
    this.secondary,
    this.accent,
    this.paper,
    this.night,
  );
  final Color seed, secondary, accent, paper, night;
  static PaletteSpec forPalette(AppPalette id) => switch (id) {
    AppPalette.atelier => const PaletteSpec(
      Color(0xff242622),
      Color(0xff394a40),
      Color(0xff73552b),
      Color(0xfff4f1ea),
      Color(0xff171a17),
    ),
    AppPalette.ocean => const PaletteSpec(
      Color(0xff205caf),
      Color(0xff14666a),
      Color(0xffa15528),
      Color(0xffeef4fc),
      Color(0xff101925),
    ),
    AppPalette.iris => const PaletteSpec(
      Color(0xff6640a6),
      Color(0xff875078),
      Color(0xff3d686a),
      Color(0xfff4f0fc),
      Color(0xff1b1527),
    ),
    AppPalette.rose => const PaletteSpec(
      Color(0xff9f3e68),
      Color(0xff725384),
      Color(0xff896027),
      Color(0xfffcf0f4),
      Color(0xff25171f),
    ),
    AppPalette.amber => const PaletteSpec(
      Color(0xff875623),
      Color(0xff506743),
      Color(0xff9c4543),
      Color(0xfffcf5e9),
      Color(0xff231b13),
    ),
    AppPalette.forest => const PaletteSpec(
      Color(0xff24634e),
      Color(0xff546525),
      Color(0xff9c5538),
      Color(0xffeff7f1),
      Color(0xff111f19),
    ),
  };
  Color canvas(Brightness b) => b == Brightness.dark ? night : paper;
  ColorScheme scheme(Brightness b) {
    final dark = b == Brightness.dark;
    final canvas = this.canvas(b);
    Color tint(Color color, double amount) =>
        Color.lerp(canvas, color, amount)!;
    Color action(Color c) => dark ? Color.lerp(c, Colors.white, .68)! : c;
    return ColorScheme.fromSeed(seedColor: seed, brightness: b).copyWith(
      primary: action(seed),
      onPrimary: dark ? night : Colors.white,
      secondary: action(secondary),
      onSecondary: dark ? night : Colors.white,
      tertiary: action(accent),
      onTertiary: dark ? night : Colors.white,
      primaryContainer: tint(seed, dark ? .26 : .12),
      onPrimaryContainer: dark
          ? const Color(0xfff5f1fc)
          : const Color(0xff252b37),
      secondaryContainer: tint(secondary, dark ? .26 : .12),
      onSecondaryContainer: dark
          ? const Color(0xfff0f5f6)
          : const Color(0xff252b37),
      tertiaryContainer: tint(accent, dark ? .26 : .12),
      onTertiaryContainer: dark
          ? const Color(0xfff9f1ea)
          : const Color(0xff252b37),
      surface: tint(Colors.white, dark ? .035 : .55),
      surfaceContainerLowest: dark ? tint(Colors.black, .12) : Colors.white,
      surfaceContainerLow: tint(dark ? Colors.white : seed, dark ? .055 : .035),
      surfaceContainer: tint(dark ? Colors.white : seed, dark ? .075 : .055),
      surfaceContainerHigh: tint(
        dark ? Colors.white : seed,
        dark ? .095 : .075,
      ),
      surfaceContainerHighest: tint(
        dark ? Colors.white : seed,
        dark ? .12 : .10,
      ),
      onSurface: dark ? const Color(0xfff4f3f7) : const Color(0xff232b37),
      onSurfaceVariant: dark
          ? const Color(0xffc8cbd5)
          : const Color(0xff505866),
      outline: dark ? const Color(0xff929baa) : const Color(0xff747d8c),
      outlineVariant: tint(dark ? Colors.white : seed, dark ? .20 : .20),
      error: dark ? const Color(0xffffb4ab) : const Color(0xffa52b24),
    );
  }
}

/// Extra chrome tokens interpolate with Material's theme animation.
class PaletteTokens extends ThemeExtension<PaletteTokens> {
  const PaletteTokens(this.id, this.brand);
  final AppPalette id;
  final List<Color> brand;
  factory PaletteTokens.forPalette(AppPalette id) {
    final seed = PaletteSpec.forPalette(id).seed;
    return PaletteTokens(
      id,
      id == AppPalette.atelier
          ? const [Color(0xff242622), Color(0xff394a40), Color(0xff536453)]
          : [
              Color.lerp(seed, Colors.black, .40)!,
              Color.lerp(seed, Colors.black, .20)!,
              seed,
            ],
    );
  }
  static PaletteTokens of(BuildContext context) =>
      Theme.of(context).extension<PaletteTokens>() ??
      PaletteTokens.forPalette(AppPalette.atelier);
  @override
  PaletteTokens copyWith({AppPalette? id, List<Color>? brand}) =>
      PaletteTokens(id ?? this.id, brand ?? this.brand);
  @override
  PaletteTokens lerp(covariant PaletteTokens? other, double t) => other == null
      ? this
      : PaletteTokens(
          t < .5 ? id : other.id,
          List.generate(
            brand.length,
            (i) => Color.lerp(brand[i], other.brand[i], t)!,
          ),
        );
}
