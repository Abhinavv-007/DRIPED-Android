import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/payment_method.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';

/// Red alert banner shown at top of home when any payment method
/// expires within the next 60 days. Tapping navigates to payments.
class PaymentExpiryAlert extends ConsumerWidget {
  const PaymentExpiryAlert({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pms = ref.watch(safePaymentMethodsProvider);
    final expiring = _firstExpiring(pms);
    if (expiring == null) return const SizedBox.shrink();
    final subColor = AppColors.textSecondary(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        tint: AppColors.danger.withOpacity(0.10),
        borderColour: AppColors.danger.withOpacity(0.55),
        onTap: () => context.go('/payments'),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withOpacity(0.4)),
              ),
              child: const Icon(LucideIcons.creditCard,
                  color: AppColors.danger, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Method Expiring',
                      style: AppTypography.cardTitle
                          .copyWith(color: AppColors.danger, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(
                    '${expiring.name} expires soon. Update to avoid interruption.',
                    style: AppTypography.caption.copyWith(
                        color: subColor.withOpacity(0.9), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                color: AppColors.danger, size: 18),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.15, end: 0, duration: 320.ms, curve: Curves.easeOutCubic);
  }

  PaymentMethod? _firstExpiring(List<PaymentMethod> all) {
    final now = DateTime.now();
    PaymentMethod? soonest;
    int? soonestDays;
    for (final pm in all) {
      if (pm.expiryMonth == null || pm.expiryYear == null) continue;
      final expiry =
          DateTime(pm.expiryYear!, pm.expiryMonth! + 1, 0); // end of month
      final days = expiry.difference(now).inDays;
      if (days < 0 || days > 60) continue;
      if (soonestDays == null || days < soonestDays) {
        soonest = pm;
        soonestDays = days;
      }
    }
    return soonest;
  }
}
