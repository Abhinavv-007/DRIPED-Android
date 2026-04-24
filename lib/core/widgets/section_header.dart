import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/haptics.dart';

/// Section divider label used inside scroll views.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final Color? titleColour;
  final EdgeInsetsGeometry padding;
  const SectionHeader({
    super.key,
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
    this.titleColour,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.sectionTitle.copyWith(
                color: titleColour ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (trailingLabel != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Haptics.tap();
                onTrailingTap?.call();
              },
              child: Text(
                trailingLabel!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
