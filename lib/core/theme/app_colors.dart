import 'package:flutter/material.dart';

/// Driped Neo \u2014 Playful Neo-Brutal + Dark palette.
///
/// All legacy symbols (gunmetal, shadowGrey, sandyClay, thistle, glass*, etc.)
/// are preserved for backward compatibility \u2014 they've been remapped to the
/// Neo equivalents so existing screens render the new look without edits.
class AppColors {
  AppColors._();

  // ─── Neo primitives (new canonical names) ───
  // Dark
  static const Color neoBg            = Color(0xFF0E0B08);
  static const Color neoSurface       = Color(0xFF1A1612);
  static const Color neoSurfaceRaised = Color(0xFF241E18);
  static const Color neoSurfaceSunken = Color(0xFF0A0705);
  static const Color neoInk           = Color(0xFFF7F1E4);
  static const Color neoInkMid        = Color(0xFFC8BFAC);
  static const Color neoInkLow        = Color(0xFF8C836F);
  static const Color neoInkGhost      = Color(0xFF4A4338);
  static const Color neoGold          = Color(0xFFE8B168);
  static const Color neoGoldDeep      = Color(0xFFC4894B);
  static const Color neoGoldSoft      = Color(0xFF3A2E1E);
  static const Color neoCream         = Color(0xFFFFF3D6);
  static const Color neoMint          = Color(0xFFB8F0C9);
  static const Color neoCoral         = Color(0xFFFFAE9B);
  static const Color neoSky           = Color(0xFF9BD4FF);
  static const Color neoLilac         = Color(0xFFD9BBFF);
  static const Color neoLemon         = Color(0xFFFFE58A);

  // Light counterparts
  static const Color neoBgLight            = Color(0xFFFFF8F0);
  static const Color neoSurfaceLight       = Color(0xFFFFFFFF);
  static const Color neoSurfaceRaisedLight = Color(0xFFFFF0DB);
  static const Color neoSurfaceSunkenLight = Color(0xFFF5EDE3);
  static const Color neoInkLight           = Color(0xFF1A1612);
  static const Color neoInkMidLight        = Color(0xFF4A4338);
  static const Color neoInkLowLight        = Color(0xFF7A6E63);
  static const Color neoInkGhostLight      = Color(0xFFC8BFAC);
  static const Color neoGoldLight          = Color(0xFFC4894B);
  static const Color neoGoldDeepLight      = Color(0xFFA26F37);
  static const Color neoGoldSoftLight      = Color(0xFFF5E7D3);

  // ─── Legacy aliases (kept so existing code compiles unchanged) ───
  // Old palette names \u2014 now point at Neo equivalents.
  static const Color gunmetal      = neoInkGhost;                 // mid dark ink
  static const Color shadowGrey    = neoBg;                       // old scaffold bg
  static const Color sandyClay     = neoGold;                     // primary accent
  static const Color sandyClaySoft = Color(0x33E8B168);           // 20% gold
  static const Color deepMocha     = neoSurfaceRaised;            // raised card bg (dark)
  static const Color thistle       = neoInk;                      // primary text

  static const Color ink           = neoBg;
  static const Color inkRaised     = neoSurfaceRaised;
  static const Color inkCard       = neoSurface;
  static const Color inkOverlay    = neoSurfaceRaised;

  static const Color shadowDark       = neoSurfaceSunken;
  static const Color shadowLight      = Color(0xFF1E1612);
  static const Color lightShadowDark  = neoInkMid;
  static const Color lightShadowLight = Color(0x88FFFFFF);

  // Glass surfaces \u2014 intentionally toned down since brutalism prefers solids,
  // but we keep them readable on both modes via hairline-translucent fills.
  static const Color glassFill     = Color(0x14F7F1E4);  // 8% cream on dark
  static const Color glassFillHi   = Color(0x26F7F1E4);  // 15% cream on dark
  static const Color glassBorder   = Color(0x33F7F1E4);  // 20% cream
  static const Color glassBorderHi = Color(0x4DF7F1E4);  // 30% cream

  // Accents
  static const Color gold     = neoGold;
  static const Color goldDeep = neoGoldDeep;
  static const Color goldSoft = neoGoldSoft;

  // Semantics
  static const Color success  = Color(0xFF34D97A);
  static const Color warning  = Color(0xFFFFC53B);
  static const Color danger   = Color(0xFFFF5B5B);
  static const Color info     = Color(0xFF5BAEFF);

  // Typography \u2014 Dark Mode
  static const Color textHi    = neoInk;
  static const Color text      = neoInk;
  static const Color textMid   = neoInkMid;
  static const Color textLow   = neoInkLow;
  static const Color textGhost = neoInkGhost;

  // Dividers
  static const Color hairline = Color(0x1AF7F1E4); // 10% cream

  // Shadow accent (legacy neo-brutalist)
  static const Color shadowInk = neoInk;

  // ─── Light Mode ───
  static const Color lightCream   = neoBgLight;
  static const Color lightButter  = neoSurfaceRaisedLight;
  static const Color lightCard    = neoSurfaceLight;
  static const Color lightText    = neoInkLight;
  static const Color lightTextMid = neoInkMidLight;
  static const Color lightTextLow = neoInkLowLight;
  static const Color lightHair    = Color(0x1A1A1612);
  static const Color lightGlass   = Color(0x00000000);

  // ─── Context-aware resolvers ───
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color pageBackground(BuildContext context) =>
      isDark(context) ? neoBg : neoBgLight;

  static Color neumorphicDark(BuildContext context) =>
      isDark(context) ? shadowDark : lightShadowDark;
  static Color neumorphicLight(BuildContext context) =>
      isDark(context) ? shadowLight : lightShadowLight;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? neoInk : neoInkLight;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? neoInkMid : neoInkMidLight;

  static Color textTertiary(BuildContext context) =>
      isDark(context) ? neoInkLow : neoInkLowLight;

  /// Returns the right surface color. `emphasised` = raised card (accent).
  static Color cardFill(BuildContext context, {bool emphasised = false}) {
    if (isDark(context)) {
      return emphasised ? neoSurfaceRaised : neoSurface;
    }
    return emphasised ? neoSurfaceRaisedLight : neoSurfaceLight;
  }

  /// Strong border = full ink (brutalist), soft = ghost.
  static Color cardBorder(BuildContext context, {bool strong = false}) {
    if (isDark(context)) {
      return strong ? neoInk : neoInkGhost;
    }
    return strong ? neoInkLight : neoInkGhostLight;
  }

  static Color divider(BuildContext context) =>
      isDark(context) ? hairline : lightHair;

  /// Playful-pastel accents resolved per mode (used by StatTile-style cards).
  static Color mint(BuildContext context) =>
      isDark(context) ? neoMint : const Color(0xFF8FE3A7);
  static Color coral(BuildContext context) =>
      isDark(context) ? neoCoral : const Color(0xFFFF8F78);
  static Color sky(BuildContext context) =>
      isDark(context) ? neoSky : const Color(0xFF6FBFFF);
  static Color lilac(BuildContext context) =>
      isDark(context) ? neoLilac : const Color(0xFFB89BFF);
  static Color lemon(BuildContext context) =>
      isDark(context) ? neoLemon : const Color(0xFFFFD060);
}
