import 'package:flutter/widgets.dart';

/// Motion tokens. Interactions feel physical:
/// - hover: lift (-1, -1) + shadow grows, 150ms easeOut
/// - press: slam (+2, +2) + shadow collapses, 80ms easeIn
class NeoMotion {
  NeoMotion._();

  static const Duration fast = Duration(milliseconds: 80);
  static const Duration base = Duration(milliseconds: 150);
  static const Duration slow = Duration(milliseconds: 300);

  /// Matches CSS `cubic-bezier(0.22, 1, 0.36, 1)`.
  static const Curve easeOut = Cubic(0.22, 1, 0.36, 1);
  /// Matches CSS `cubic-bezier(0.65, 0, 0.35, 1)`.
  static const Curve easeInOut = Cubic(0.65, 0, 0.35, 1);
  /// Matches CSS `cubic-bezier(0.68, -0.55, 0.265, 1.55)`.
  static const Curve bounce = Cubic(0.68, -0.55, 0.265, 1.55);

  static const Offset hoverLift = Offset(-1, -1);
  static const Offset pressSlam = Offset(2, 2);
}
