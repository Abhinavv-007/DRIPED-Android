import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Renewal / trial urgency colour.
/// ≤3 days → danger, ≤7 → warning, else → success.
enum Urgency { danger, warning, success, neutral }

Urgency urgencyFromDays(int? days) {
  if (days == null) return Urgency.neutral;
  if (days < 0) return Urgency.danger; // overdue / expired
  if (days <= 3) return Urgency.danger;
  if (days <= 7) return Urgency.warning;
  return Urgency.success;
}

Color urgencyColour(Urgency u) {
  switch (u) {
    case Urgency.danger:  return AppColors.danger;
    case Urgency.warning: return AppColors.warning;
    case Urgency.success: return AppColors.success;
    case Urgency.neutral: return AppColors.textMid;
  }
}
