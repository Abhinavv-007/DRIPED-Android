import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Inter everywhere. Extreme weight contrast — 900 for hero numbers,
/// 400 for body text. Negative letter spacing on headlines for poster feel.
class AppTypography {
  AppTypography._();

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    Color? color,
    double height = 1.15,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle _mono({
    required double size,
    required FontWeight weight,
    Color? color,
    double height = 1.1,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // ─── display — hero numbers, headline stat cards ───
  static TextStyle get heroNumber => _inter(
        size: 64,
        weight: FontWeight.w900,
        height: 1.0,
        letterSpacing: -2.5,
      );

  static TextStyle get bigNumber => _inter(
        size: 44,
        weight: FontWeight.w900,
        height: 1.0,
        letterSpacing: -1.6,
      );

  static TextStyle get midNumber => _inter(
        size: 28,
        weight: FontWeight.w800,
        height: 1.0,
        letterSpacing: -0.8,
      );

  // ─── headings ───
  static TextStyle get pageTitle => _inter(
        size: 34,
        weight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.0,
      );

  static TextStyle get sectionTitle => _inter(
        size: 20,
        weight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.4,
      );

  static TextStyle get cardTitle => _inter(
        size: 16,
        weight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.2,
      );

  // ─── body + labels ───
  static TextStyle get body => _inter(
        size: 15,
        weight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get bodyStrong => _inter(
        size: 15,
        weight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get caption => _inter(
        size: 13,
        weight: FontWeight.w500,
        height: 1.3,
      );

  static TextStyle get micro => _inter(
        size: 11,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.4,
      );

  static TextStyle get label => _inter(
        size: 12,
        weight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.8,
      );

  // ─── buttons ───
  static TextStyle get buttonLg => _inter(
        size: 16,
        weight: FontWeight.w800,
        color: AppColors.ink,
        height: 1.1,
        letterSpacing: -0.1,
      );

  static TextStyle get buttonMd => _inter(
        size: 14,
        weight: FontWeight.w700,
        color: AppColors.textHi,
        height: 1.1,
        letterSpacing: 0,
      );

  // ─── specialised ───
  static TextStyle get tickerMono => _mono(
        size: 12,
        weight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get countdown => _inter(
        size: 96,
        weight: FontWeight.w900,
        height: 0.9,
        letterSpacing: -4,
      );
}
