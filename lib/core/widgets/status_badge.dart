import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final SubscriptionStatus status;
  final double scale;
  const StatusBadge({super.key, required this.status, this.scale = 1});

  Color get _fg {
    switch (status) {
      case SubscriptionStatus.active:    return AppColors.success;
      case SubscriptionStatus.trial:     return AppColors.warning;
      case SubscriptionStatus.paused:    return AppColors.info;
      case SubscriptionStatus.cancelled: return AppColors.danger;
      case SubscriptionStatus.archived:  return AppColors.textMid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = _fg;
    return Semantics(
      label: 'Status: ${status.label}',
      child: Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 5 * scale),
      decoration: BoxDecoration(
        color: fg.withOpacity(0.12),
        border: Border.all(color: fg.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6 * scale,
            height: 6 * scale,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          SizedBox(width: 6 * scale),
          Text(
            status.label.toUpperCase(),
            style: AppTypography.micro.copyWith(
              color: fg,
              fontSize: 10 * scale,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
