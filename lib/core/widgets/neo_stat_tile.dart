import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/neo_shadows.dart';

enum NeoTileTone { mint, coral, sky, lilac, lemon, gold }

/// Playful-pastel KPI tile. Matches the web `StatTile` exactly.
class NeoStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? delta;
  final NeoTileTone tone;
  final IconData? icon;
  final VoidCallback? onTap;

  const NeoStatTile({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.tone = NeoTileTone.gold,
    this.icon,
    this.onTap,
  });

  Color _bg(BuildContext c) {
    switch (tone) {
      case NeoTileTone.mint:  return AppColors.mint(c);
      case NeoTileTone.coral: return AppColors.coral(c);
      case NeoTileTone.sky:   return AppColors.sky(c);
      case NeoTileTone.lilac: return AppColors.lilac(c);
      case NeoTileTone.lemon: return AppColors.lemon(c);
      case NeoTileTone.gold:  return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.isDark(context) && tone == NeoTileTone.gold
        ? AppColors.neoSurface
        : AppColors.neoInkLight;

    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textPrimary(context), width: 2),
        boxShadow: NeoShadows.md(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.bigNumber.copyWith(color: fg),
          ),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Text(
              delta!,
              style: AppTypography.caption.copyWith(
                color: fg.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: content,
    );
  }
}
