import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens. Inter for body, Space Grotesk for headings,
/// JetBrains Mono for amounts + IDs.
class NeoTypography {
  NeoTypography._();

  // Font sizes (matches CSS tokens)
  static const double xs   = 12;
  static const double sm   = 13;
  static const double base = 15;
  static const double md   = 17;
  static const double lg   = 20;
  static const double xl   = 24;
  static const double xxl  = 32;
  static const double xxxl = 40;
  static const double xxxxl = 56;

  // Letter spacing
  static const double tightTracking  = -0.02 * 16; // em \u2192 logical px at 16 baseline
  static const double labelTracking  =  0.08 * 16;
  static const double capsTracking   =  0.16 * 16;

  static TextStyle display({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: xxxxl,
        fontWeight: FontWeight.w900,
        letterSpacing: tightTracking,
        color: color,
        height: 1.05,
      );

  static TextStyle h1({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: xxxl,
        fontWeight: FontWeight.w900,
        letterSpacing: tightTracking,
        color: color,
        height: 1.1,
      );

  static TextStyle h2({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: xxl,
        fontWeight: FontWeight.w900,
        letterSpacing: tightTracking,
        color: color,
        height: 1.15,
      );

  static TextStyle h3({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: xl,
        fontWeight: FontWeight.w800,
        letterSpacing: tightTracking,
        color: color,
        height: 1.2,
      );

  static TextStyle h4({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: lg,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.25,
      );

  static TextStyle body({Color? color, FontWeight? weight}) => GoogleFonts.inter(
        fontSize: base,
        fontWeight: weight ?? FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyBold({Color? color}) =>
      body(color: color, weight: FontWeight.w700);

  static TextStyle caption({Color? color}) => GoogleFonts.inter(
        fontSize: sm,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  static TextStyle micro({Color? color}) => GoogleFonts.inter(
        fontSize: xs,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  /// Eyebrow / section labels: uppercase, heavy tracking.
  static TextStyle label({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: xs - 2,
        fontWeight: FontWeight.w900,
        letterSpacing: capsTracking,
        color: color,
        height: 1.3,
      );

  /// Amounts / numeric values \u2014 mono for tabular feel.
  static TextStyle amount({Color? color, double size = xl}) => GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.01 * 16,
      );
}
