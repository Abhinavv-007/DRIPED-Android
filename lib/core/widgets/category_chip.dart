import 'package:flutter/material.dart';

import '../models/app_category.dart';
import '../theme/app_typography.dart';

/// Small category identifier — colored dot + name.
class CategoryChip extends StatelessWidget {
  final AppCategory category;
  final bool compact;
  const CategoryChip({super.key, required this.category, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: category.colour.withOpacity(0.14),
        border: Border.all(color: category.colour.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 5 : 7,
            height: compact ? 5 : 7,
            decoration: BoxDecoration(
              color: category.colour,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: category.colour.withOpacity(0.7),
                    blurRadius: 6,
                    spreadRadius: 0.5),
              ],
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            category.name,
            style: AppTypography.caption.copyWith(
              color: category.colour,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
