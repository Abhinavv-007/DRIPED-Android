import 'package:flutter/material.dart';

import 'neo_colors.dart';

/// Hard-offset shadows. Never blurred. Shadow color = ink.
class NeoShadows {
  NeoShadows._();

  /// Helper \u2014 builds a solid (unblurred) BoxShadow.
  static BoxShadow _solid(Color color, double dx, double dy) => BoxShadow(
        color: color,
        offset: Offset(dx, dy),
        blurRadius: 0,
        spreadRadius: 0,
      );

  static List<BoxShadow> sm(BuildContext c) =>
      [_solid(NeoColors.ink(c), 2, 2)];
  static List<BoxShadow> md(BuildContext c) =>
      [_solid(NeoColors.ink(c), 4, 4)];
  static List<BoxShadow> lg(BuildContext c) =>
      [_solid(NeoColors.ink(c), 6, 6)];

  static List<BoxShadow> gold(BuildContext c) =>
      [_solid(NeoColors.gold(c), 4, 4)];
  static List<BoxShadow> danger(BuildContext c) =>
      [_solid(NeoColors.danger(c), 4, 4)];

  /// Hover variant \u2014 one step bigger than the given base.
  static List<BoxShadow> hover(List<BoxShadow> base) {
    if (base.isEmpty) return base;
    final b = base.first;
    return [
      BoxShadow(
        color: b.color,
        offset: Offset(b.offset.dx + 2, b.offset.dy + 2),
        blurRadius: 0,
      ),
    ];
  }
}
