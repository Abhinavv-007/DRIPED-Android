import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Hard-offset shadows for the Neo look. Never blurred.
class NeoShadows {
  NeoShadows._();

  static BoxShadow _solid(Color color, double dx, double dy) => BoxShadow(
        color: color,
        offset: Offset(dx, dy),
        blurRadius: 0,
        spreadRadius: 0,
      );

  static List<BoxShadow> sm(BuildContext c) =>
      [_solid(AppColors.textPrimary(c), 2, 2)];
  static List<BoxShadow> md(BuildContext c) =>
      [_solid(AppColors.textPrimary(c), 4, 4)];
  static List<BoxShadow> lg(BuildContext c) =>
      [_solid(AppColors.textPrimary(c), 6, 6)];

  static List<BoxShadow> gold(BuildContext c) =>
      [_solid(AppColors.gold, 4, 4)];
  static List<BoxShadow> danger(BuildContext c) =>
      [_solid(AppColors.danger, 4, 4)];

  /// One step bigger than the given base (for hover states).
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
