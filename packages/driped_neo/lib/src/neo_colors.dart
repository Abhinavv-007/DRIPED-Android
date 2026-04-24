import 'package:flutter/material.dart';

/// Color tokens for Driped Neo.
///
/// Mirrors `@driped/neo` CSS custom properties `--neo-*` one-to-one.
/// Use [NeoColors.of] inside widgets to resolve brightness-aware values.
class NeoColors {
  NeoColors._();

  // ─── Dark palette (default) ───
  static const Color darkBg            = Color(0xFF0E0B08);
  static const Color darkSurface       = Color(0xFF1A1612);
  static const Color darkSurfaceRaised = Color(0xFF241E18);
  static const Color darkSurfaceSunken = Color(0xFF0A0705);

  static const Color darkInk      = Color(0xFFF7F1E4);
  static const Color darkInkMid   = Color(0xFFC8BFAC);
  static const Color darkInkLow   = Color(0xFF8C836F);
  static const Color darkInkGhost = Color(0xFF4A4338);

  static const Color darkGold     = Color(0xFFE8B168);
  static const Color darkGoldDeep = Color(0xFFC4894B);
  static const Color darkGoldSoft = Color(0xFF3A2E1E);
  static const Color darkCream    = Color(0xFFFFF3D6);

  static const Color darkMint  = Color(0xFFB8F0C9);
  static const Color darkCoral = Color(0xFFFFAE9B);
  static const Color darkSky   = Color(0xFF9BD4FF);
  static const Color darkLilac = Color(0xFFD9BBFF);
  static const Color darkLemon = Color(0xFFFFE58A);

  static const Color darkSuccess = Color(0xFF34D97A);
  static const Color darkWarning = Color(0xFFFFC53B);
  static const Color darkDanger  = Color(0xFFFF5B5B);
  static const Color darkInfo    = Color(0xFF5BAEFF);

  // ─── Light palette ───
  static const Color lightBg            = Color(0xFFFFF8F0);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightSurfaceRaised = Color(0xFFFFF0DB);
  static const Color lightSurfaceSunken = Color(0xFFF5EDE3);

  static const Color lightInk      = Color(0xFF1A1612);
  static const Color lightInkMid   = Color(0xFF4A4338);
  static const Color lightInkLow   = Color(0xFF7A6E63);
  static const Color lightInkGhost = Color(0xFFC8BFAC);

  static const Color lightGold     = Color(0xFFC4894B);
  static const Color lightGoldDeep = Color(0xFFA26F37);
  static const Color lightGoldSoft = Color(0xFFF5E7D3);
  static const Color lightCream    = Color(0xFFFFF3D6);

  static const Color lightMint  = Color(0xFF8FE3A7);
  static const Color lightCoral = Color(0xFFFF8F78);
  static const Color lightSky   = Color(0xFF6FBFFF);
  static const Color lightLilac = Color(0xFFB89BFF);
  static const Color lightLemon = Color(0xFFFFD060);

  static const Color lightSuccess = Color(0xFF00A650);
  static const Color lightWarning = Color(0xFFD9A100);
  static const Color lightDanger  = Color(0xFFD93A3A);
  static const Color lightInfo    = Color(0xFF2B7ED9);

  // ─── Context-aware resolvers ───
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext c)            => isDark(c) ? darkBg : lightBg;
  static Color surface(BuildContext c)       => isDark(c) ? darkSurface : lightSurface;
  static Color surfaceRaised(BuildContext c) => isDark(c) ? darkSurfaceRaised : lightSurfaceRaised;
  static Color surfaceSunken(BuildContext c) => isDark(c) ? darkSurfaceSunken : lightSurfaceSunken;

  static Color ink(BuildContext c)      => isDark(c) ? darkInk : lightInk;
  static Color inkMid(BuildContext c)   => isDark(c) ? darkInkMid : lightInkMid;
  static Color inkLow(BuildContext c)   => isDark(c) ? darkInkLow : lightInkLow;
  static Color inkGhost(BuildContext c) => isDark(c) ? darkInkGhost : lightInkGhost;

  static Color gold(BuildContext c)     => isDark(c) ? darkGold : lightGold;
  static Color goldDeep(BuildContext c) => isDark(c) ? darkGoldDeep : lightGoldDeep;
  static Color goldSoft(BuildContext c) => isDark(c) ? darkGoldSoft : lightGoldSoft;
  static Color cream(BuildContext c)    => isDark(c) ? darkCream : lightCream;

  static Color border(BuildContext c)     => ink(c);
  static Color borderSoft(BuildContext c) => inkGhost(c);

  static Color mint(BuildContext c)  => isDark(c) ? darkMint : lightMint;
  static Color coral(BuildContext c) => isDark(c) ? darkCoral : lightCoral;
  static Color sky(BuildContext c)   => isDark(c) ? darkSky : lightSky;
  static Color lilac(BuildContext c) => isDark(c) ? darkLilac : lightLilac;
  static Color lemon(BuildContext c) => isDark(c) ? darkLemon : lightLemon;

  static Color success(BuildContext c) => isDark(c) ? darkSuccess : lightSuccess;
  static Color warning(BuildContext c) => isDark(c) ? darkWarning : lightWarning;
  static Color danger(BuildContext c)  => isDark(c) ? darkDanger : lightDanger;
  static Color info(BuildContext c)    => isDark(c) ? darkInfo : lightInfo;
}
