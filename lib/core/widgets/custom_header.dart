import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/haptics.dart';

const IconData kHeaderSearchIcon = LucideIcons.search;
const IconData kHeaderPlusIcon = LucideIcons.plus;
const IconData kHeaderFilterIcon = LucideIcons.slidersHorizontal;

class CustomHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<HeaderAction> actions;
  final EdgeInsetsGeometry padding;

  const CustomHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(20, 22, 20, 14),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.pageTitle.copyWith(
                    color: AppColors.textPrimary(context),
                    fontSize: 30,
                    height: 1.03,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (final action in actions) ...[
            const SizedBox(width: 8),
            _HeaderIconButton(action: action),
          ],
        ],
      ),
    );
  }
}

class HeaderAction {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool badge;

  const HeaderAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badge = false,
  });
}

class _HeaderIconButton extends StatelessWidget {
  final HeaderAction action;

  const _HeaderIconButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Tooltip(
      message: action.tooltip ?? '',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.tap();
          action.onTap();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.inkRaised.withOpacity(0.78)
                : AppColors.lightCard.withOpacity(0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder(context)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                action.icon,
                size: 20,
                color: AppColors.textPrimary(context),
              ),
              if (action.badge)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackInitial;
  final double size;
  final VoidCallback? onTap;

  const HeaderAvatar({
    super.key,
    this.imageUrl,
    required this.fallbackInitial,
    this.size = 44,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sandyClay, AppColors.thistle],
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.cardFill(context, emphasised: true),
        ),
        child: imageUrl == null || imageUrl!.isEmpty
            ? Center(
                child: Text(
                  fallbackInitial.toUpperCase(),
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.textPrimary(context),
                  ),
                ),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    fallbackInitial.toUpperCase(),
                    style: AppTypography.cardTitle.copyWith(
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
              ),
      ),
    );

    if (onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.tap();
        onTap!();
      },
      child: child,
    );
  }
}
