import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/animated_counter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neo_button.dart';
import '../subscriptions/widgets/subscription_card.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String categoryId;
  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState
    extends ConsumerState<CategoryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    final cat = cats.where((c) => c.id == widget.categoryId).toList();
    if (cat.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: EmptyState(
              kind: EmptyStateKind.categoryEmpty,
              title: 'Category missing',
              subtitle: 'It may have been deleted.',
              action: NeoButton(
                label: 'Back',
                leading: LucideIcons.arrowLeft,
                onPressed: () => context.go('/categories'),
                fullWidth: false,
              ),
            ),
          ),
        ),
      );
    }
    final c = cat.first;
    final subs = ref.watch(subsByCategoryProvider(c.id));
    final ccy = ref.watch(preferredCurrencyProvider);
    final monthly = subs.fold<double>(0, (a, s) {
      return a +
          CurrencyUtil.convert(
              s.billingCycle.toMonthly(s.amount), s.currency, ccy);
    });
    final budget = c.budgetLimit;
    final progress =
        budget == null || budget == 0 ? 0.0 : (monthly / budget).clamp(0.0, 1.2);
    final over = budget != null && monthly > budget;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  _roundBtn(LucideIcons.arrowLeft, () {
                    Haptics.tap();
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/categories');
                    }
                  }),
                  const Spacer(),
                  _roundBtn(LucideIcons.sliders, () => _budgetSheet(c.budgetLimit, c.id)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: c.colour.withOpacity(0.18),
                      border: Border.all(color: c.colour, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: c.colour.withOpacity(0.4),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(_icon(c.iconName), color: c.colour),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: AppTypography.pageTitle),
                        const SizedBox(height: 4),
                        Text('${subs.length} subscription${subs.length == 1 ? '' : 's'}',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textMid)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Monthly spend',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textMid, letterSpacing: 1.0)),
                        const Spacer(),
                        if (budget != null)
                          Text(
                              '${CurrencyUtil.formatAmount(budget, code: ccy, compact: true)} budget',
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.textMid)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AnimatedCurrency(
                      value: monthly,
                      currency: ccy,
                      compact: true,
                      color: over ? AppColors.danger : AppColors.gold,
                      style: AppTypography.bigNumber,
                    ),
                    const SizedBox(height: 12),
                    if (budget != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            Container(height: 6, color: AppColors.glassFill),
                            FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: over ? AppColors.danger : c.colour,
                                  boxShadow: [
                                    BoxShadow(
                                        color: (over
                                                ? AppColors.danger
                                                : c.colour)
                                            .withOpacity(0.5),
                                        blurRadius: 8),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        over
                            ? 'Over by ${CurrencyUtil.formatAmount(monthly - budget, code: ccy, compact: true)}'
                            : '${CurrencyUtil.formatAmount(budget - monthly, code: ccy, compact: true)} left',
                        style: AppTypography.caption.copyWith(
                            color:
                                over ? AppColors.danger : AppColors.success,
                            fontWeight: FontWeight.w700),
                      ),
                    ] else
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _budgetSheet(null, c.id),
                        icon: const Icon(LucideIcons.plus,
                            size: 14, color: AppColors.gold),
                        label: Text('Set budget',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.gold)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (subs.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: EmptyState(
                  kind: EmptyStateKind.subscriptions,
                  title: 'No subs in ${c.name}',
                  subtitle: 'Add a subscription and pick this category.',
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text('Subscriptions',
                    style: AppTypography.sectionTitle),
              ),
              ...List.generate(subs.length, (i) {
                final s = subs[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: SubscriptionCard(sub: s)
                      .animate()
                      .fadeIn(delay: (i * 40).ms, duration: 240.ms)
                      .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 300.ms,
                          curve: Curves.easeOutCubic),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          border: Border.all(color: AppColors.glassBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.textMid, size: 18),
      ),
    );
  }

  Future<void> _budgetSheet(double? current, String catId) async {
    final ctl = TextEditingController(
        text: current == null ? '' : current.toStringAsFixed(0));
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.inkOverlay,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly budget', style: AppTypography.sectionTitle),
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: ctl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: AppTypography.midNumber
                    .copyWith(color: AppColors.gold),
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 4, right: 4),
                    child: Icon(LucideIcons.wallet,
                        color: AppColors.textMid),
                  ),
                  prefixIconConstraints: BoxConstraints(minWidth: 36),
                  border: InputBorder.none,
                ),
                cursorColor: AppColors.gold,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: NeoButton.ghost(
                    label: 'Clear',
                    onPressed: () {
                      Haptics.tap();
                      ref
                          .read(categoriesProvider.notifier)
                          .setBudget(catId, null);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: NeoButton(
                    label: 'Save',
                    leading: LucideIcons.check,
                    onPressed: () {
                      Haptics.success();
                      final n = double.tryParse(ctl.text);
                      ref
                          .read(categoriesProvider.notifier)
                          .setBudget(catId, n);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String n) {
    switch (n) {
      case 'film': return LucideIcons.film;
      case 'music': return LucideIcons.music;
      case 'briefcase': return LucideIcons.briefcase;
      case 'book': return LucideIcons.book;
      case 'heart': return LucideIcons.heart;
      case 'wallet': return LucideIcons.wallet;
      case 'shopping-bag': return LucideIcons.shoppingBag;
      case 'code': return LucideIcons.code;
      case 'zap': return LucideIcons.zap;
      case 'gamepad-2': return LucideIcons.gamepad2;
      case 'newspaper': return LucideIcons.newspaper;
      case 'tag':
      default: return LucideIcons.tag;
    }
  }
}
