import 'package:flutter/material.dart';

import '../neo_colors.dart';
import '../neo_radius.dart';
import '../neo_shadows.dart';
import '../neo_typography.dart';

/// Heavy uppercase label with tiny hard shadow.
class NeoBadge extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? foreground;
  final IconData? icon;

  const NeoBadge({
    super.key,
    required this.label,
    this.background,
    this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? NeoColors.ink(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? NeoColors.surfaceRaised(context),
        borderRadius: NeoRadius.borderSm,
        border: Border.all(color: NeoColors.border(context), width: 2),
        boxShadow: NeoShadows.sm(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: NeoTypography.label(color: fg),
          ),
        ],
      ),
    );
  }
}

/// Rounded pill variant with 2px border and small offset shadow.
class NeoPill extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? foreground;
  final IconData? icon;

  const NeoPill({
    super.key,
    required this.label,
    this.background,
    this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? NeoColors.ink(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? NeoColors.surface(context),
        borderRadius: const BorderRadius.all(Radius.circular(NeoRadius.pill)),
        border: Border.all(color: NeoColors.border(context), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: NeoTypography.caption(color: fg).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
