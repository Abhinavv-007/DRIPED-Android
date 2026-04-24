import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/app_category.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/animated_counter.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/widgets/glass_card.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slices = ref.watch(categoryBreakdownProvider);
    final cats = ref.watch(categoriesProvider);
    final ccy = ref.watch(preferredCurrencyProvider);
    final totalSpend =
        slices.fold<double>(0, (a, s) => a + s.totalInUserCurrency);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: CustomHeader(
                title: 'Categories',
                subtitle: '${cats.length} categories  ·  '
                    '${slices.length} in use',
                actions: [
                  HeaderAction(
                    icon: LucideIcons.plus,
                    tooltip: 'Add category',
                    onTap: () => _showAddCategoryDialog(context, ref),
                  ),
                ],
                leading: GestureDetector(
                  onTap: () {
                    Haptics.tap();
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/home');
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      border: Border.all(color: AppColors.glassBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.arrowLeft,
                        color: AppColors.textMid),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly total',
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.textMid,
                                  letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          AnimatedCurrency(
                            value: totalSpend,
                            currency: ccy,
                            compact: true,
                            color: AppColors.gold,
                            style: AppTypography.midNumber,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.gold),
                        ),
                        child: const Icon(LucideIcons.layers,
                            color: AppColors.gold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final c = cats[i];
                    final slice = slices.where((x) => x.category.id == c.id).toList();
                    final spend =
                        slice.isEmpty ? 0.0 : slice.first.totalInUserCurrency;
                    final count = slice.isEmpty ? 0 : slice.first.subCount;
                    return _CategoryCard(
                      category: c,
                      spend: spend,
                      count: count,
                      ccy: ccy,
                      onDelete: c.isDefault
                          ? null
                          : () => _confirmDeleteCategory(context, ref, c),
                    ).animate().fadeIn(
                        delay: (i * 40).ms, duration: 260.ms).slideY(
                        begin: 0.06, end: 0, duration: 300.ms,
                        curve: Curves.easeOutCubic);
                  },
                  childCount: cats.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(
      BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    Color selectedColour = AppColors.gold;
    String selectedIcon = 'tag';
    final options = <String, IconData>{
      'tag': LucideIcons.tag,
      'film': LucideIcons.film,
      'music': LucideIcons.music,
      'briefcase': LucideIcons.briefcase,
      'book': LucideIcons.book,
      'heart': LucideIcons.heart,
      'wallet': LucideIcons.wallet,
      'shopping-bag': LucideIcons.shoppingBag,
      'code': LucideIcons.code,
      'zap': LucideIcons.zap,
    };
    final palette = [
      AppColors.gold,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
      const Color(0xFF8B5CF6),
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.inkOverlay
                  : AppColors.lightCard,
              title: Text('Add category',
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.textPrimary(context),
                  )),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category name',
                        hintText: 'Ex: Streaming',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: budgetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monthly budget (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Icon', style: AppTypography.caption),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: options.entries.map((entry) {
                        final selected = selectedIcon == entry.key;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setDialogState(() {
                            selectedIcon = entry.key;
                          }),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: selected
                                  ? selectedColour.withOpacity(0.18)
                                  : AppColors.cardFill(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? selectedColour
                                    : AppColors.cardBorder(context),
                              ),
                            ),
                            child: Icon(
                              entry.value,
                              size: 18,
                              color: selected ? selectedColour : AppColors.textPrimary(context),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Accent', style: AppTypography.caption),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: palette.map((colour) {
                        final selected = selectedColour == colour;
                        return InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => setDialogState(() {
                            selectedColour = colour;
                          }),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: colour,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final slug = name
                        .toLowerCase()
                        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                        .replaceAll(RegExp(r'_+'), '_')
                        .replaceAll(RegExp(r'^_|_$'), '');
                    ref.read(categoriesProvider.notifier).add(
                          AppCategory(
                            id: 'cat_${newId()}',
                            userId: '',
                            name: name,
                            slug: slug.isEmpty ? 'custom' : slug,
                            colour: selectedColour,
                            iconName: selectedIcon,
                            budgetLimit: double.tryParse(
                              budgetController.text.trim(),
                            ),
                            isDefault: false,
                          ),
                        );
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteCategory(
      BuildContext context, WidgetRef ref, AppCategory category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.inkOverlay
              : AppColors.lightCard,
          title: Text('Delete category',
              style: AppTypography.sectionTitle.copyWith(
                color: AppColors.textPrimary(context),
              )),
          content: Text(
            'Remove ${category.name}? Subscriptions already using it will stay tracked, but they will no longer resolve to this custom category.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      ref.read(categoriesProvider.notifier).remove(category.id);
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final AppCategory category;
  final double spend;
  final int count;
  final String ccy;
  final VoidCallback? onDelete;
  const _CategoryCard({
    required this.category,
    required this.spend,
    required this.count,
    required this.ccy,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final budget = category.budgetLimit;
    final progress =
        budget == null || budget == 0 ? 0.0 : (spend / budget).clamp(0.0, 1.0);
    final over = budget != null && spend > budget;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      onTap: () {
        Haptics.tap();
        GoRouter.of(context).go('/categories/${category.id}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: category.colour.withOpacity(0.18),
                  border: Border.all(color: category.colour, width: 1.4),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: category.colour.withOpacity(0.4),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(_icon(category.iconName),
                    size: 16, color: category.colour),
              ),
              const Spacer(),
              if (onDelete != null)
                GestureDetector(
                  onTap: () {
                    Haptics.tap();
                    onDelete!();
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.28),
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.trash2,
                      size: 14,
                      color: AppColors.danger,
                    ),
                  ),
                )
              else
                Text('$count',
                    style: AppTypography.cardTitle.copyWith(
                        color: AppColors.textMid, fontSize: 16)),
            ],
          ),
          const Spacer(),
          Text(category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.cardTitle),
          const SizedBox(height: 4),
          Text(
            spend == 0
                ? 'No subs yet'
                : '${CurrencyUtil.formatAmount(spend, code: ccy, compact: true)}/mo',
            style: AppTypography.caption.copyWith(
                color: AppColors.gold, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (budget != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 4, color: AppColors.glassFill),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: over ? AppColors.danger : category.colour,
                        boxShadow: [
                          BoxShadow(
                              color: (over ? AppColors.danger : category.colour)
                                  .withOpacity(0.5),
                              blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              over
                  ? 'Over by ${CurrencyUtil.formatAmount(spend - budget, code: ccy, compact: true)}'
                  : '${CurrencyUtil.formatAmount(budget, code: ccy, compact: true)} budget',
              style: AppTypography.micro.copyWith(
                  color: over ? AppColors.danger : AppColors.textLow),
            ),
          ] else
            Text('No budget set',
                style: AppTypography.micro.copyWith(color: AppColors.textLow)),
        ],
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
