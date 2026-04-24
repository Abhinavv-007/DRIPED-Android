import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/service_avatar.dart';

class GraveyardSection extends ConsumerWidget {
  const GraveyardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ghosts = ref.watch(ghostSubscriptionsProvider);
    if (ghosts.isEmpty) return const SizedBox.shrink();
    final ccy = ref.watch(preferredCurrencyProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                const Icon(LucideIcons.ghost,
                    size: 18, color: AppColors.warning),
                const SizedBox(width: 8),
                Text('Still charging you?',
                    style: AppTypography.sectionTitle
                        .copyWith(color: AppColors.warning, fontSize: 18)),
              ],
            ),
          ),
          SizedBox(
            height: 108,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: ghosts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final s = ghosts[i];
                final shown =
                    CurrencyUtil.convert(s.amount, s.currency, ccy);
                return GlassCard(
                  width: 200,
                  dashedBorder: true,
                  tint: Colors.transparent,
                  borderColour: AppColors.warning.withOpacity(0.5),
                  padding: const EdgeInsets.all(12),
                  onTap: () {
                    Haptics.tap();
                    GoRouter.of(context).go('/subscriptions/${s.id}');
                  },
                  child: Opacity(
                    opacity: 0.72,
                    child: Row(
                      children: [
                        ServiceAvatar(
                          serviceSlug: s.serviceSlug,
                          serviceName: s.serviceName,
                          size: 36,
                          glow: false,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.serviceName,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.cardTitle
                                      .copyWith(fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('no activity 60+ days',
                                  style: AppTypography.micro.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4)),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyUtil.formatContextual(
                                  shown,
                                  code: ccy,
                                  cycle: s.billingCycle,
                                ),
                                style: AppTypography.caption
                                    .copyWith(color: AppColors.textMid),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (i * 80).ms, duration: 320.ms);
              },
            ),
          ),
        ],
      ),
    );
  }
}
