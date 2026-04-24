import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/urgency.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/service_avatar.dart';
import '../../../core/widgets/section_header.dart';

/// Vertical list of renewals landing in the next 7 days.
class Upcoming7dList extends ConsumerWidget {
  const Upcoming7dList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(upcomingRenewalsProvider);
    final within7 = all
        .where((s) {
          final d = s.daysUntilRenewal ?? 999;
          return d >= 0 && d <= 7;
        })
        .take(6)
        .toList();
    if (within7.isEmpty) return const SizedBox.shrink();
    final ccy = ref.watch(preferredCurrencyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'UPCOMING (7 DAYS)',
          trailingLabel: 'View All',
          onTrailingTap: () => context.go('/subscriptions'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (int i = 0; i < within7.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: AppColors.hairline,
                      indent: 52,
                    ),
                  _UpcomingRow(sub: within7[i], ccy: ccy),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  final dynamic sub;
  final String ccy;
  const _UpcomingRow({required this.sub, required this.ccy});

  @override
  Widget build(BuildContext context) {
    final days = sub.daysUntilRenewal as int?;
    final urgency = urgencyFromDays(days);
    final fg = urgencyColour(urgency);
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textTertiary(context);
    final shown =
        CurrencyUtil.convert(sub.amount as double, sub.currency as String, ccy);
    final label = sub.renewalDisplayLabel;

    return InkWell(
      onTap: () => context.go('/subscriptions/${sub.id}'),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            ServiceAvatar(
              serviceSlug: sub.serviceSlug as String,
              serviceName: sub.serviceName as String,
              size: 34,
              glow: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.serviceName as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle
                          .copyWith(fontSize: 14, color: textColor)),
                  const SizedBox(height: 2),
                  Text(sub.billingCycle.label as String,
                      style: AppTypography.micro.copyWith(
                          color: subColor, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyUtil.formatAmount(shown, code: ccy),
                  style: AppTypography.cardTitle
                      .copyWith(color: textColor, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(label,
                    style: AppTypography.micro.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
