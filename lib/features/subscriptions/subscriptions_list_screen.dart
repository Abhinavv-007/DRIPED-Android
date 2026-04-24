import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/subscription.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neo_button.dart';
import 'add_subscription_sheet.dart';
import 'widgets/subscription_card.dart';

enum _Filter { all, active, trial, paused, cancelled }

enum _Sort { renewal, name, amount, added }

enum _ViewMode { list, calendar, grid }

enum _AmountView { asBilled, monthly, yearly }

class SubscriptionsListScreen extends ConsumerStatefulWidget {
  const SubscriptionsListScreen({super.key});

  @override
  ConsumerState<SubscriptionsListScreen> createState() =>
      _SubscriptionsListScreenState();
}

class _SubscriptionsListScreenState
    extends ConsumerState<SubscriptionsListScreen> {
  final _searchCtl = TextEditingController();
  _Filter _filter = _Filter.all;
  _Sort _sort = _Sort.renewal;
  _ViewMode _view = _ViewMode.list;
  _AmountView _amountView = _AmountView.asBilled;
  final Set<String> _selected = {};

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  bool _matchesFilter(Subscription s) {
    switch (_filter) {
      case _Filter.all:
        return s.status != SubscriptionStatus.archived;
      case _Filter.active:
        return s.status == SubscriptionStatus.active;
      case _Filter.trial:
        return s.status == SubscriptionStatus.trial || s.isTrial;
      case _Filter.paused:
        return s.status == SubscriptionStatus.paused;
      case _Filter.cancelled:
        return s.status == SubscriptionStatus.cancelled;
    }
  }

  List<Subscription> _visible(List<Subscription> all) {
    final q = _searchCtl.text.trim().toLowerCase();
    var out = all.where(_matchesFilter);
    if (q.isNotEmpty) {
      out = out.where((s) => s.serviceName.toLowerCase().contains(q));
    }
    final list = out.toList();
    switch (_sort) {
      case _Sort.renewal:
        list.sort((a, b) {
          final ad = a.nextRenewalDate ?? DateTime(9999);
          final bd = b.nextRenewalDate ?? DateTime(9999);
          return ad.compareTo(bd);
        });
        break;
      case _Sort.name:
        list.sort((a, b) => a.serviceName.compareTo(b.serviceName));
        break;
      case _Sort.amount:
        list.sort((a, b) => b.monthlyEquivalent.compareTo(a.monthlyEquivalent));
        break;
      case _Sort.added:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return list;
  }

  int _count(List<Subscription> subs, _Filter f) {
    switch (f) {
      case _Filter.all:
        return subs
            .where((s) => s.status != SubscriptionStatus.archived)
            .length;
      case _Filter.active:
        return subs.where((s) => s.status == SubscriptionStatus.active).length;
      case _Filter.trial:
        return subs
            .where((s) => s.status == SubscriptionStatus.trial || s.isTrial)
            .length;
      case _Filter.paused:
        return subs.where((s) => s.status == SubscriptionStatus.paused).length;
      case _Filter.cancelled:
        return subs
            .where((s) => s.status == SubscriptionStatus.cancelled)
            .length;
    }
  }

  String _sectionLabel(_Filter f) {
    switch (f) {
      case _Filter.all:
        return 'ALL';
      case _Filter.active:
        return 'ACTIVE';
      case _Filter.trial:
        return 'TRIAL';
      case _Filter.paused:
        return 'PAUSED';
      case _Filter.cancelled:
        return 'CANCELLED';
    }
  }

  Future<void> _refresh() async {
    Haptics.medium();
    await ref.read(subscriptionsProvider.notifier).fetch();
  }

  void _toggleSelect(String id, bool sel) {
    setState(() {
      if (sel) {
        _selected.add(id);
      } else {
        _selected.remove(id);
      }
    });
  }

  void _bulkArchive() {
    Haptics.medium();
    final notifier = ref.read(subscriptionsProvider.notifier);
    for (final id in _selected) {
      notifier.archive(id);
    }
    setState(_selected.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Archived')),
    );
  }

  void _bulkDelete() {
    Haptics.warn();
    final notifier = ref.read(subscriptionsProvider.notifier);
    for (final id in _selected) {
      notifier.delete(id);
    }
    setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final subs = ref.watch(safeSubscriptionsProvider);
    final visible = _visible(subs);
    final inSelectMode = _selected.isNotEmpty;
    final hasAnySubscriptions = subs.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(showAddButton: hasAnySubscriptions),
            _viewRow(),
            _TabsRow(tabs: _buildTabs(subs)),
            _sectionLabelRow(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.gold,
                backgroundColor: AppColors.isDark(context)
                    ? AppColors.inkRaised
                    : AppColors.lightCard,
                onRefresh: _refresh,
                child: visible.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 154),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight > 156
                                    ? constraints.maxHeight - 156
                                    : 0,
                              ),
                              child: Center(
                                child: EmptyState(
                                  kind: _searchCtl.text.isNotEmpty
                                      ? EmptyStateKind.searchNoResult
                                      : EmptyStateKind.subscriptions,
                                  title: _searchCtl.text.isNotEmpty
                                      ? 'Nothing matches "${_searchCtl.text}"'
                                      : 'Nothing here',
                                  subtitle: _searchCtl.text.isNotEmpty
                                      ? 'Try another search.'
                                      : 'Add your first one — or connect Gmail to find them automatically.',
                                  action: NeoButton(
                                    label: 'Add subscription',
                                    leading: LucideIcons.plus,
                                    onPressed: () =>
                                        showAddSubscriptionSheet(context),
                                    fullWidth: false,
                                  ),
                                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic),
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 154),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final s = visible[i];
                          // Compute the display amount based on _amountView
                          final double displayAmt;
                          final String cycleSuffix;
                          switch (_amountView) {
                            case _AmountView.asBilled:
                              displayAmt = s.amount;
                              cycleSuffix = s.billingCycle.shortSuffix;
                              break;
                            case _AmountView.monthly:
                              displayAmt = s.billingCycle.toMonthly(s.amount);
                              cycleSuffix = '/mo';
                              break;
                            case _AmountView.yearly:
                              displayAmt = s.billingCycle.toYearly(s.amount);
                              cycleSuffix = '/yr';
                              break;
                          }
                          return Dismissible(
                            key: ValueKey(s.id),
                            background: _swipeBg(
                              align: Alignment.centerLeft,
                              icon: LucideIcons.pencil,
                              label: 'Edit',
                              colour: AppColors.info,
                            ),
                            secondaryBackground: _swipeBg(
                              align: Alignment.centerRight,
                              icon: LucideIcons.archive,
                              label: 'Archive',
                              colour: AppColors.warning,
                            ),
                            confirmDismiss: (dir) async {
                              Haptics.medium();
                              if (dir == DismissDirection.startToEnd) {
                                showEditSubscriptionSheet(context, s);
                                return false;
                              }
                              return true;
                            },
                            onDismissed: (_) {
                              ref
                                  .read(subscriptionsProvider.notifier)
                                  .archive(s.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${s.serviceName} archived'),
                                  duration: const Duration(seconds: 4),
                                  action: SnackBarAction(
                                    label: 'UNDO',
                                    onPressed: () => ref
                                        .read(subscriptionsProvider.notifier)
                                        .setStatus(
                                            s.id, SubscriptionStatus.active),
                                  ),
                                ),
                              );
                            },
                            child: SubscriptionCard(
                              sub: s,
                              selectable: inSelectMode,
                              selected: _selected.contains(s.id),
                              onSelectionChanged: (sel) =>
                                  _toggleSelect(s.id, sel),
                              amountOverride: displayAmt,
                              cycleSuffixOverride: cycleSuffix,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: (i * 30).ms, duration: 260.ms)
                              .slideY(
                                  begin: 0.05,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                  duration: 320.ms);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: inSelectMode ? _bulkBar() : null,
    );
  }

  Widget _topBar({required bool showAddButton}) {
    final textColor = AppColors.textPrimary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              radius: 12,
              child: Row(
                children: [
                  Icon(LucideIcons.search,
                      size: 16, color: AppColors.textSecondary(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtl,
                      onChanged: (_) => setState(() {}),
                      style: AppTypography.body.copyWith(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: AppTypography.body
                            .copyWith(color: AppColors.textTertiary(context)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      cursorColor: AppColors.gold,
                    ),
                  ),
                  if (_searchCtl.text.isNotEmpty)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(LucideIcons.x,
                          size: 16, color: AppColors.textMid),
                      onPressed: () {
                        _searchCtl.clear();
                        setState(() {});
                        Haptics.tap();
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SquareIconButton(
            icon: LucideIcons.slidersHorizontal,
            onTap: _openSortSheet,
          ),
          const SizedBox(width: 8),
          _SquareIconButton(
            icon: LucideIcons.moreHorizontal,
            onTap: _openFilterSheet,
          ),
          if (showAddButton) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Haptics.tap();
                showAddSubscriptionSheet(context);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gold, AppColors.goldDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.gold.withOpacity(0.45),
                        blurRadius: 14),
                  ],
                ),
                child: const Icon(LucideIcons.plus,
                    color: AppColors.ink, size: 22),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _viewRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          _ViewToggle(
            icons: const [
              LucideIcons.list,
              LucideIcons.calendar,
              LucideIcons.grid,
            ],
            selected: _view.index,
            onChanged: (i) => setState(() => _view = _ViewMode.values[i]),
          ),
          const Spacer(),
          _AmountDropdown(
            value: _amountView,
            onChanged: (v) => setState(() => _amountView = v),
          ),
        ],
      ),
    );
  }

  List<_TabSpec> _buildTabs(List<Subscription> subs) {
    return [
      for (final f in _Filter.values)
        _TabSpec(
          label: _tabLabel(f),
          count: _count(subs, f),
          selected: _filter == f,
          onTap: () => setState(() => _filter = f),
        ),
    ];
  }

  String _tabLabel(_Filter f) {
    switch (f) {
      case _Filter.all:
        return 'All';
      case _Filter.active:
        return 'Active';
      case _Filter.trial:
        return 'Trial';
      case _Filter.paused:
        return 'Paused';
      case _Filter.cancelled:
        return 'Cancelled';
    }
  }

  Widget _sectionLabelRow() {
    final subColor = AppColors.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Text(_sectionLabel(_filter),
          style: AppTypography.micro.copyWith(
              color: subColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              fontSize: 11)),
    );
  }

  Widget _swipeBg({
    required AlignmentGeometry align,
    required IconData icon,
    required String label,
    required Color colour,
  }) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: colour.withOpacity(0.12),
        border: Border.all(color: colour.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colour, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: AppTypography.micro.copyWith(
                color: colour,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              )),
        ],
      ),
    );
  }

  Widget _bulkBar() {
    final isDark = AppColors.isDark(context);
    final textColor = AppColors.textPrimary(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
        decoration: BoxDecoration(
          color: isDark ? AppColors.inkOverlay : AppColors.lightCard,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder(context, strong: true)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => setState(_selected.clear),
              icon:
                  Icon(LucideIcons.x, color: AppColors.textSecondary(context)),
            ),
            Text('${_selected.length} selected',
                style: AppTypography.cardTitle.copyWith(color: textColor)),
            const Spacer(),
            _BulkBtn(
              icon: LucideIcons.archive,
              label: 'Archive',
              colour: AppColors.warning,
              onTap: _bulkArchive,
            ),
            const SizedBox(width: 8),
            _BulkBtn(
              icon: LucideIcons.trash2,
              label: 'Delete',
              colour: AppColors.danger,
              onTap: _bulkDelete,
            ),
          ],
        ),
      ),
    );
  }

  void _openSortSheet() {
    final isDark = AppColors.isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.inkOverlay : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort by',
                  style: AppTypography.sectionTitle
                      .copyWith(color: AppColors.textPrimary(context))),
              const SizedBox(height: 12),
              for (final opt in _Sort.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _sortLabel(opt),
                    style: AppTypography.body.copyWith(
                      color: _sort == opt
                          ? AppColors.gold
                          : AppColors.textPrimary(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: _sort == opt
                      ? const Icon(LucideIcons.check, color: AppColors.gold)
                      : null,
                  onTap: () {
                    Haptics.tap();
                    setState(() => _sort = opt);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _sortLabel(_Sort s) {
    switch (s) {
      case _Sort.renewal:
        return 'Next renewal';
      case _Sort.name:
        return 'Name (A–Z)';
      case _Sort.amount:
        return 'Amount (high → low)';
      case _Sort.added:
        return 'Recently added';
    }
  }

  void _openFilterSheet() {
    final isDark = AppColors.isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.inkOverlay : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter by status',
                  style: AppTypography.sectionTitle
                      .copyWith(color: AppColors.textPrimary(context))),
              const SizedBox(height: 12),
              for (final f in _Filter.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _tabLabel(f),
                    style: AppTypography.body.copyWith(
                      color: _filter == f
                          ? AppColors.gold
                          : AppColors.textPrimary(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: _filter == f
                      ? const Icon(LucideIcons.check, color: AppColors.gold)
                      : null,
                  onTap: () {
                    Haptics.tap();
                    setState(() => _filter = f);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _TabSpec(
      {required this.label,
      required this.count,
      required this.selected,
      required this.onTap});
}

class _TabsRow extends StatelessWidget {
  final List<_TabSpec> tabs;
  const _TabsRow({required this.tabs});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    final mutedColor = AppColors.textTertiary(context);
    return Container(
      color: AppColors.pageBackground(context).withOpacity(0.92),
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 18),
              itemBuilder: (_, i) {
                final t = tabs[i];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Haptics.tap();
                    t.onTap();
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            t.label,
                            style: AppTypography.body.copyWith(
                              color: t.selected ? textColor : subColor,
                              fontWeight: t.selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${t.count}',
                            style: AppTypography.micro.copyWith(
                              color: t.selected ? AppColors.gold : mutedColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 2,
                        width: t.selected ? 26 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: t.selected
                              ? [
                                  BoxShadow(
                                      color: AppColors.gold.withOpacity(0.6),
                                      blurRadius: 6)
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: AppColors.divider(context), thickness: 0.5),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary(context);
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.cardFill(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder(context)),
        ),
        child: Icon(icon, size: 20, color: textColor),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final List<IconData> icons;
  final int selected;
  final ValueChanged<int> onChanged;
  const _ViewToggle(
      {required this.icons, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.cardFill(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < icons.length; i++)
            GestureDetector(
              onTap: () {
                Haptics.tap();
                onChanged(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 30,
                decoration: BoxDecoration(
                  color: i == selected
                      ? AppColors.cardFill(context, emphasised: true)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icons[i],
                  size: 15,
                  color: i == selected ? textColor : subColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AmountDropdown extends StatelessWidget {
  final _AmountView value;
  final ValueChanged<_AmountView> onChanged;
  const _AmountDropdown({required this.value, required this.onChanged});

  String _label(_AmountView v) {
    switch (v) {
      case _AmountView.asBilled:
        return 'As Billed';
      case _AmountView.monthly:
        return 'Monthly';
      case _AmountView.yearly:
        return 'Yearly';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);
    return GestureDetector(
      onTap: () async {
        Haptics.tap();
        final result = await showModalBottomSheet<_AmountView>(
          context: context,
          backgroundColor: isDark ? AppColors.inkOverlay : AppColors.lightCard,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Show amount as',
                      style: AppTypography.sectionTitle
                          .copyWith(color: AppColors.textPrimary(context))),
                  const SizedBox(height: 12),
                  for (final v in _AmountView.values)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_label(v),
                          style: AppTypography.body.copyWith(
                              color: v == value ? AppColors.gold : textColor,
                              fontWeight: FontWeight.w700)),
                      trailing: v == value
                          ? const Icon(LucideIcons.check, color: AppColors.gold)
                          : null,
                      onTap: () => Navigator.pop(context, v),
                    ),
                ],
              ),
            ),
          ),
        );
        if (result != null) onChanged(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardFill(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_label(value),
                style: AppTypography.caption.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(width: 6),
            Icon(LucideIcons.chevronDown, size: 14, color: subColor),
          ],
        ),
      ),
    );
  }
}

class _BulkBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color colour;
  final VoidCallback onTap;
  const _BulkBtn({
    required this.icon,
    required this.label,
    required this.colour,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colour.withOpacity(0.12),
          border: Border.all(color: colour.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colour),
            const SizedBox(width: 6),
            Text(label,
                style: AppTypography.caption.copyWith(
                  color: colour,
                  fontWeight: FontWeight.w800,
                )),
          ],
        ),
      ),
    );
  }
}
