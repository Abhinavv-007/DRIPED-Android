import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';

/// Extended, neo-brutalist FAB. Optionally pulses when [hasAlert] is true.
class PulsingFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasAlert;
  const PulsingFab({
    super.key,
    required this.label,
    this.icon = LucideIcons.plus,
    required this.onTap,
    this.hasAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.medium();
        onTap();
      },
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.gold,
          border: Border.all(color: AppColors.shadowInk, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowInk,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.ink),
            const SizedBox(width: 8),
            Text(label,
                style: AppTypography.buttonMd
                    .copyWith(color: AppColors.ink, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );

    if (hasAlert) {
      btn = btn
          .animate(onPlay: (c) => c.repeat())
          .scaleXY(
            begin: 1.0,
            end: 1.08,
            duration: 750.ms,
            curve: Curves.easeInOut,
          )
          .then()
          .scaleXY(
            begin: 1.08,
            end: 1.0,
            duration: 750.ms,
            curve: Curves.easeInOut,
          );
    }

    return btn;
  }
}
