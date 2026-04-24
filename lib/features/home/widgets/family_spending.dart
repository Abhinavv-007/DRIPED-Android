import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/glass_card.dart';

class FamilyMemberStub {
  final String name;
  final double share;
  final Color colour;
  const FamilyMemberStub(this.name, this.share, this.colour);
}

/// Demo-only family split. Real family-sharing lives behind Phase B.
const familyHomeStub = <FamilyMemberStub>[
  FamilyMemberStub('Me', 0.48, AppColors.gold),
  FamilyMemberStub('Parents', 0.29, AppColors.info),
  FamilyMemberStub('Sarah', 0.17, AppColors.danger),
];

const familyFullStub = <FamilyMemberStub>[
  FamilyMemberStub('Me', 0.48, AppColors.gold),
  FamilyMemberStub('Parents', 0.29, AppColors.info),
  FamilyMemberStub('Sarah', 0.17, AppColors.danger),
  FamilyMemberStub('Kids', 0.06, AppColors.success),
];

class FamilySpendingRow extends ConsumerWidget {
  const FamilySpendingRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final ccy = ref.watch(preferredCurrencyProvider);
    final monthly = CurrencyUtil.convert(summary.monthlyTotalINR, 'INR', ccy);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          for (int i = 0; i < familyHomeStub.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _MemberTile(
                member: familyHomeStub[i],
                amount: monthly * familyHomeStub[i].share,
                ccy: ccy,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final FamilyMemberStub member;
  final double amount;
  final String ccy;
  const _MemberTile(
      {required this.member, required this.amount, required this.ccy});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.alphaBlend(Colors.white.withOpacity(0.2), member.colour),
                  member.colour,
                ],
                radius: 0.85,
                focal: Alignment.topLeft,
                focalRadius: 0.1,
              ),
              border: Border.all(
                  color: Colors.white.withOpacity(0.1), width: 1),
              boxShadow: [
                BoxShadow(
                    color: member.colour.withOpacity(0.4), blurRadius: 12),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              member.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(member.name,
              style: AppTypography.cardTitle.copyWith(fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            CurrencyUtil.formatAmount(amount, code: ccy),
            style: AppTypography.caption.copyWith(
                color: AppColors.textMid, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
