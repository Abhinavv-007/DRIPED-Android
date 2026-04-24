import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/haptics.dart';

/// Friendly error widget with retry. Replaces raw error text everywhere.
class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorCard({super.key, this.message = 'Something went wrong', this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle, size: 40, color: AppColors.danger.withOpacity(0.7)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textMid),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  Haptics.tap();
                  onRetry!();
                },
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: Text('Retry', style: AppTypography.caption.copyWith(color: AppColors.gold)),
                style: TextButton.styleFrom(foregroundColor: AppColors.gold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
