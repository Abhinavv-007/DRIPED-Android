import 'package:flutter/services.dart';

/// Tiny wrapper so every tap/swipe goes through the same entry point.
/// Per spec: every tap = haptic, every swipe = medium.
class Haptics {
  Haptics._();

  static Future<void> tap() => HapticFeedback.selectionClick();
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
  static Future<void> heavy() => HapticFeedback.heavyImpact();
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 70));
    await HapticFeedback.mediumImpact();
  }
  static Future<void> warn() => HapticFeedback.heavyImpact();
}
