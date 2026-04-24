import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/subscription.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/urgency.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/service_avatar.dart';

class RenewingSoon extends ConsumerWidget {
  const RenewingSoon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref
        .watch(upcomingRenewalsProvider)
        .where((s) {
          final d = s.daysUntilRenewal ?? 999;
          return d >= 0 && d <= 30;
        })
        .take(8)
        .toList();

    if (upcoming.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: GlassCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(LucideIcons.coffee,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nothing renewing in the next 30 days. Relax.',
                  style: AppTypography.body
                      .copyWith(color: AppColors.text),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: upcoming.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _RenewalCard(sub: upcoming[i])
            .animate()
            .fadeIn(delay: (i * 60).ms, duration: 280.ms)
            .slideX(begin: 0.05, end: 0, duration: 260.ms),
      ),
    );
  }
}

class _RenewalCard extends ConsumerWidget {
  final Subscription sub;
  const _RenewalCard({required this.sub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = sub.daysUntilRenewal;
    final urgency = urgencyFromDays(days);
    final fg = urgencyColour(urgency);
    final ccy = ref.watch(preferredCurrencyProvider);
    final shown = CurrencyUtil.convert(sub.amount, sub.currency, ccy);

    return GlassCard(
      width: 190,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      onTap: () {
        Haptics.tap();
        GoRouter.of(context).go('/subscriptions/${sub.id}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ServiceAvatar(
                serviceSlug: sub.serviceSlug,
                serviceName: sub.serviceName,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sub.serviceName,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitle.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.renewalDisplayLabel,
                    style: AppTypography.bodyStrong.copyWith(
                      color: fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyUtil.formatContextual(
                      shown,
                      code: ccy,
                      cycle: sub.billingCycle,
                    ),
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textMid),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fg,
                  boxShadow: [BoxShadow(color: fg.withOpacity(0.6), blurRadius: 6)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
