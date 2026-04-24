import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/urgency.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/service_avatar.dart';

/// Big one-row card calling out the very next renewal.
/// Label reads "TOMORROW" / "TODAY" / "IN N DAYS".
class NextUpCard extends ConsumerWidget {
  const NextUpCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingRenewalsProvider);
    if (upcoming.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.28)),
                ),
                child: const Icon(
                  LucideIcons.calendarCheck2,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No urgent renewals',
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.textPrimary(context),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nothing is due in the next 30 days. The dashboard is stable.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 220.ms);
    }
    final sub = upcoming.first;
    final days = sub.daysUntilRenewal;
    if (days == null || days < 0 || days > 30) return const SizedBox.shrink();

    final ccy = ref.watch(preferredCurrencyProvider);
    final shown = CurrencyUtil.convert(sub.amount, sub.currency, ccy);
    final urgency = urgencyFromDays(days);
    final fg = urgencyColour(urgency);
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);

    final label = sub.renewalDisplayLabel.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        onTap: () => context.go('/subscriptions/${sub.id}'),
        child: Row(
          children: [
            ServiceAvatar(
              serviceSlug: sub.serviceSlug,
              serviceName: sub.serviceName,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.micro.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        fontSize: 11,
                      )),
                  const SizedBox(height: 2),
                  Text(sub.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle
                          .copyWith(fontSize: 17, color: textColor)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              CurrencyUtil.formatAmount(shown, code: ccy),
              style: AppTypography.cardTitle
                  .copyWith(color: textColor, fontSize: 17),
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.chevronRight, color: subColor, size: 18),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 280.ms);
  }
}
