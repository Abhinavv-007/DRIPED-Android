import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/section_header.dart';

/// 2x2 grid of the top-4 spending categories.
class TopCategoriesGrid extends ConsumerWidget {
  const TopCategoriesGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slices = ref.watch(categoryBreakdownProvider);
    if (slices.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'TOP CATEGORIES'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Text(
                'Category insights will appear once live recurring spend starts landing in the account.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ),
        ],
      );
    }
    final ccy = ref.watch(preferredCurrencyProvider);
    final top = slices.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'TOP CATEGORIES'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              for (int row = 0; row < (top.length / 2).ceil(); row++) ...[
                if (row > 0) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _CatTile(slice: top[row * 2], ccy: ccy)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: row * 80), duration: 260.ms)
                          .slideY(begin: 0.04, end: 0, duration: 240.ms, curve: Curves.easeOutCubic),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: (row * 2 + 1) < top.length
                          ? _CatTile(slice: top[row * 2 + 1], ccy: ccy)
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: row * 80 + 40), duration: 260.ms)
                              .slideY(begin: 0.04, end: 0, duration: 240.ms, curve: Curves.easeOutCubic)
                          : const SizedBox(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CatTile extends StatelessWidget {
  final dynamic slice;
  final String ccy;
  const _CatTile({required this.slice, required this.ccy});

  @override
  Widget build(BuildContext context) {
    final cat = slice.category;
    final amount = slice.totalInUserCurrency as double;
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: cat.colour,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: cat.colour.withOpacity(0.6), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.micro.copyWith(
                        color: subColor,
                        fontSize: 11,
                        letterSpacing: 0.3)),
                const SizedBox(height: 2),
                Text(
                  CurrencyUtil.formatAmount(amount, code: ccy),
                  style: AppTypography.cardTitle
                      .copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
