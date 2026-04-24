import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../payment_methods/widgets/pm_icon.dart';

/// Payment methods home section — each row shows # subs and monthly spend.
class WalletList extends ConsumerWidget {
  const WalletList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pms = ref.watch(safePaymentMethodsProvider);
    final subs = ref.watch(liveSubscriptionsProvider);
    final ccy = ref.watch(preferredCurrencyProvider);
    if (pms.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'WALLET',
            trailingLabel: 'Manage',
            onTrailingTap: () => context.go('/payments'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Text(
                'Add a payment method to track which card, wallet, or bank is funding each recurring charge.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final rows = <_WalletRow>[];
    for (final pm in pms) {
      final linked = subs.where((s) => s.paymentMethodId == pm.id);
      if (linked.isEmpty) continue;
      double monthly = 0;
      for (final s in linked) {
        final m =
            CurrencyUtil.convert(s.billingCycle.toMonthly(s.amount), s.currency, ccy);
        monthly += m;
      }
      rows.add(_WalletRow(pm: pm, count: linked.length, monthly: monthly));
    }
    if (rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'WALLET',
            trailingLabel: 'Manage',
            onTrailingTap: () => context.go('/payments'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Text(
                'Payment methods are ready. Link them to subscriptions to unlock per-wallet spend and renewal risk.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'WALLET',
          trailingLabel: 'Manage',
          onTrailingTap: () => context.go('/payments'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                rows[i].build(context, ccy)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: i * 60), duration: 280.ms)
                    .slideY(begin: 0.04, end: 0, duration: 260.ms, curve: Curves.easeOutCubic),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WalletRow {
  final dynamic pm;
  final int count;
  final double monthly;
  const _WalletRow(
      {required this.pm, required this.count, required this.monthly});

  Widget build(BuildContext context, String ccy) {
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      onTap: () => GoRouter.of(context).go('/payments/${pm.id}'),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.glassFillHi,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.glassBorder),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(6),
            child: paymentMethodMark(
              type: pm.type,
              name: pm.name as String,
              iconSlug: pm.iconSlug as String?,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pm.maskedLabel as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle
                        .copyWith(fontSize: 14, color: textColor)),
                const SizedBox(height: 2),
                Text('$count ${count == 1 ? 'subscription' : 'subscriptions'}',
                    style: AppTypography.micro.copyWith(
                        color: subColor, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${CurrencyUtil.formatAmount(monthly, code: ccy, compact: true)}/mo',
            style: AppTypography.cardTitle.copyWith(
                color: textColor, fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
