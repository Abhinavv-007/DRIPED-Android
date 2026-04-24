import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'neo_colors.dart';

/// Ready-to-use `ThemeData` built from Neo tokens.
class DripedNeoTheme {
  DripedNeoTheme._();

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg       = isDark ? NeoColors.darkBg            : NeoColors.lightBg;
    final surface  = isDark ? NeoColors.darkSurface       : NeoColors.lightSurface;
    final ink      = isDark ? NeoColors.darkInk           : NeoColors.lightInk;
    final inkMid   = isDark ? NeoColors.darkInkMid        : NeoColors.lightInkMid;
    final gold     = isDark ? NeoColors.darkGold          : NeoColors.lightGold;
    final danger   = isDark ? NeoColors.darkDanger        : NeoColors.lightDanger;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: gold,
        onPrimary: isDark ? NeoColors.darkSurface : NeoColors.lightSurface,
        secondary: isDark ? NeoColors.darkSky : NeoColors.lightSky,
        onSecondary: ink,
        error: danger,
        onError: isDark ? NeoColors.darkSurface : NeoColors.lightSurface,
        surface: surface,
        onSurface: ink,
      ),
      textTheme: _textTheme(ink, inkMid),
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: ink,
          fontWeight: FontWeight.w900,
          fontSize: 20,
          letterSpacing: -0.01 * 16,
        ),
      ),
      iconTheme: IconThemeData(color: ink, size: 22),
      dividerTheme: DividerThemeData(
        color: isDark ? NeoColors.darkInkGhost : NeoColors.lightInkGhost,
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: GoogleFonts.inter(color: ink, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: ink, width: 2),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color ink, Color inkMid) {
    final heading = GoogleFonts.spaceGroteskTextTheme();
    final body = GoogleFonts.interTextTheme();

    return TextTheme(
      displayLarge:  heading.displayLarge?.copyWith(color: ink, fontWeight: FontWeight.w900, letterSpacing: -0.02 * 16),
      displayMedium: heading.displayMedium?.copyWith(color: ink, fontWeight: FontWeight.w900, letterSpacing: -0.02 * 16),
      displaySmall:  heading.displaySmall?.copyWith(color: ink, fontWeight: FontWeight.w900, letterSpacing: -0.02 * 16),
      headlineLarge: heading.headlineLarge?.copyWith(color: ink, fontWeight: FontWeight.w900, letterSpacing: -0.02 * 16),
      headlineMedium: heading.headlineMedium?.copyWith(color: ink, fontWeight: FontWeight.w900, letterSpacing: -0.02 * 16),
      headlineSmall: heading.headlineSmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
      titleLarge:    heading.titleLarge?.copyWith(color: ink, fontWeight: FontWeight.w800),
      titleMedium:   heading.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w700),
      titleSmall:    heading.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w700),
      bodyLarge:     body.bodyLarge?.copyWith(color: ink),
      bodyMedium:    body.bodyMedium?.copyWith(color: ink),
      bodySmall:     body.bodySmall?.copyWith(color: inkMid),
      labelLarge:    body.labelLarge?.copyWith(color: ink, fontWeight: FontWeight.w700),
      labelMedium:   body.labelMedium?.copyWith(color: inkMid, fontWeight: FontWeight.w700),
      labelSmall:    body.labelSmall?.copyWith(color: inkMid, fontWeight: FontWeight.w600),
    );
  }
}
