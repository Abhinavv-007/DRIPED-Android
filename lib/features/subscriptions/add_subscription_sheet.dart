import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/services_catalog.dart';
import '../../core/models/app_category.dart';
import '../../core/models/billing_cycle.dart';
import '../../core/models/subscription.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/custom_brand_logo_store.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/drag_handle.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_segmented.dart';
import '../../core/widgets/neo_button.dart';
import '../../core/widgets/service_avatar.dart';
import '../payment_methods/add_payment_method_sheet.dart';
import '../payment_methods/widgets/pm_icon.dart';

Future<void> showAddSubscriptionSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => const _AddSubscriptionSheet(),
  );
}

Future<void> showEditSubscriptionSheet(BuildContext context, Subscription sub) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => _AddSubscriptionSheet(existing: sub),
  );
}

class _AddSubscriptionSheet extends ConsumerStatefulWidget {
  final Subscription? existing;
  const _AddSubscriptionSheet({this.existing});

  @override
  ConsumerState<_AddSubscriptionSheet> createState() =>
      _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends ConsumerState<_AddSubscriptionSheet>
    with TickerProviderStateMixin {
  int _step = 0;
  static const _total = 5;

  // Step 1
  ServicePattern? _service;
  String _customName = '';
  final _customNameCtl = TextEditingController();
  String _websiteUrl = '';
  final _websiteCtl = TextEditingController();

  // Step 2
  final _amountCtl = TextEditingController();
  String _currency = 'INR';
  BillingCycle _cycle = BillingCycle.monthly;

  // Step 3
  DateTime _startDate = DateTime.now();
  DateTime? _renewalDate;
  bool _isTrial = false;
  DateTime? _trialEndDate;

  // Step 4
  String? _paymentMethodId;

  // Step 5
  String? _categoryId;
  final _notesCtl = TextEditingController();
  bool _remind7 = true;
  bool _remind3 = true;
  bool _remind1 = true;

  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _customName = e.serviceName;
      _customNameCtl.text = e.serviceName;
      _websiteUrl = CustomBrandLogoStore.websiteForSlug(e.serviceSlug) ?? '';
      _websiteCtl.text = _websiteUrl;
      _amountCtl.text = e.amount.toStringAsFixed(0);
      _currency = e.currency;
      _cycle = e.billingCycle;
      _startDate = e.startDate ?? DateTime.now();
      _renewalDate = e.nextRenewalDate;
      _isTrial = e.isTrial;
      _trialEndDate = e.trialEndDate;
      _paymentMethodId = e.paymentMethodId;
      _categoryId = e.categoryId;
      _notesCtl.text = e.notes ?? '';
      _remind7 = e.remind7d;
      _remind3 = e.remind3d;
      _remind1 = e.remind1d;
    } else {
      _renewalDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _customNameCtl.dispose();
    _websiteCtl.dispose();
    _amountCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _service != null || _customName.trim().isNotEmpty;
      case 1:
        return double.tryParse(_amountCtl.text) != null &&
            double.parse(_amountCtl.text) > 0;
      case 2:
        return _renewalDate != null;
      case 3:
        return true;
      case 4:
        return true;
    }
    return false;
  }

  void _next() {
    Haptics.tap();
    if (_step < _total - 1) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _back() {
    Haptics.tap();
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _save() async {
    final notifier = ref.read(subscriptionsProvider.notifier);
    final amount = double.parse(_amountCtl.text);
    final name = _service?.name ?? _customName.trim();
    final slug = _service?.slug ??
        CustomBrandLogoStore.slugFromNameOrWebsite(
          name: name,
          websiteUrl: _websiteUrl,
        );
    final cats = ref.read(categoriesProvider);
    final otherCategory = cats.where((c) => c.slug == 'other');
    final fallbackCategoryId = otherCategory.isNotEmpty
        ? otherCategory.first.id
        : (cats.isNotEmpty ? cats.first.id : 'cat_other');
    final catId = _categoryId ?? fallbackCategoryId;

    if (widget.existing != null) {
      await notifier.update(widget.existing!.copyWith(
        serviceName: name,
        serviceSlug: slug,
        amount: amount,
        currency: _currency,
        billingCycle: _cycle,
        startDate: _startDate,
        nextRenewalDate: _renewalDate,
        isTrial: _isTrial,
        trialEndDate: _isTrial ? _trialEndDate : null,
        paymentMethodId: _paymentMethodId,
        categoryId: catId,
        notes: _notesCtl.text.trim().isEmpty ? null : _notesCtl.text.trim(),
        remind7d: _remind7,
        remind3d: _remind3,
        remind1d: _remind1,
        status: _isTrial ? SubscriptionStatus.trial : widget.existing!.status,
      ));
      Haptics.success();
      await _persistCustomBrandLogo(slug);
      setState(() => _saved = true);
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      final id = newId();
      final user = ref.read(currentUserProvider);
      final sub = Subscription(
        id: id,
        userId: user.id,
        serviceName: name,
        serviceSlug: slug,
        amount: amount,
        currency: _currency,
        billingCycle: _cycle,
        startDate: _startDate,
        nextRenewalDate: _renewalDate,
        status: _isTrial ? SubscriptionStatus.trial : SubscriptionStatus.active,
        isTrial: _isTrial,
        trialEndDate: _isTrial ? _trialEndDate : null,
        paymentMethodId: _paymentMethodId,
        categoryId: catId,
        source: SubscriptionSource.manual,
        notes: _notesCtl.text.trim().isEmpty ? null : _notesCtl.text.trim(),
        remind7d: _remind7,
        remind3d: _remind3,
        remind1d: _remind1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await notifier.add(sub);
      Haptics.success();
      await _persistCustomBrandLogo(slug);
      setState(() => _saved = true);
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pop();
      GoRouter.of(context).go('/subscriptions/$id');
    }
  }

  Future<void> _persistCustomBrandLogo(String slug) async {
    if (_service != null) return;
    final sanitizedWebsite = CustomBrandLogoStore.sanitizeWebsiteUrl(_websiteUrl);
    final logoUrl = CustomBrandLogoStore.logoUrlForWebsite(_websiteUrl);
    if (sanitizedWebsite == null || logoUrl == null) {
      await CustomBrandLogoStore.clearForSlug(slug);
      return;
    }
    await CustomBrandLogoStore.saveForSlug(
      slug: slug,
      websiteUrl: sanitizedWebsite,
      logoUrl: logoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    final size = MediaQuery.of(context).size;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        height: size.height * 0.92,
        decoration: const BoxDecoration(
          color: AppColors.inkRaised,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(
            top: BorderSide(color: AppColors.glassBorderHi),
          ),
        ),
        child: _saved ? _SuccessView() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        const SizedBox(height: 8),
        const DragHandle(),
        _progress(),
        _header(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
                child: c,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: _stepBody(),
            ),
          ),
        ),
        _footer(),
      ],
    );
  }

  Widget _progress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Row(
        children: List.generate(_total, (i) {
          final done = i <= _step;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i == _total - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: done ? AppColors.gold : AppColors.glassFill,
                borderRadius: BorderRadius.circular(2),
                boxShadow: done
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ]
                    : [],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _header() {
    final titles = [
      'Which service?',
      'How much?',
      'When does it renew?',
      'How do you pay?',
      'Last details',
    ];
    final subs = [
      'Pick from popular services or add a custom one',
      'Amount, currency, billing cycle',
      'Start date, next renewal, free trial',
      'Link a payment method',
      'Category, notes, reminders',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Step ${_step + 1} of $_total',
                  style: AppTypography.micro
                      .copyWith(color: AppColors.gold, letterSpacing: 1.4)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(LucideIcons.x, color: AppColors.textMid),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(titles[_step], style: AppTypography.sectionTitle),
          const SizedBox(height: 4),
          Text(subs[_step],
              style: AppTypography.caption.copyWith(color: AppColors.textMid)),
        ],
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _stepService();
      case 1:
        return _stepPricing();
      case 2:
        return _stepSchedule();
      case 3:
        return _stepPayment();
      case 4:
        return _stepDetails();
    }
    return const SizedBox.shrink();
  }

  Widget _footer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: NeoButton.ghost(
                label: _step == 0 ? 'Cancel' : 'Back',
                onPressed: _back,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: NeoButton(
                label: _step == _total - 1
                    ? (widget.existing == null
                        ? 'Save subscription'
                        : 'Save changes')
                    : 'Continue',
                leading: _step == _total - 1
                    ? LucideIcons.check
                    : LucideIcons.arrowRight,
                onPressed: _canContinue ? _next : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Service ---
  Widget _stepService() {
    final services = ServicesCatalog.all();
    final query = _customName.trim().toLowerCase();
    final filtered = query.isEmpty
        ? services
        : services.where((s) => s.name.toLowerCase().contains(query)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          radius: 999,
          child: Row(
            children: [
              const Icon(LucideIcons.search,
                  size: 16, color: AppColors.textMid),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _customNameCtl,
                  onChanged: (v) {
                    setState(() => _customName = v);
                  },
                  style: AppTypography.body,
                  decoration: InputDecoration(
                    hintText: 'Search or enter custom name',
                    hintStyle:
                        AppTypography.body.copyWith(color: AppColors.textLow),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  cursorColor: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.84,
          ),
          itemCount: filtered.length + 1,
          itemBuilder: (_, i) {
            if (i == filtered.length) {
              final isCustom =
                  _service == null && _customName.trim().isNotEmpty;
              return _ServiceTile(
                selected: isCustom,
                onTap: () {
                  Haptics.tap();
                  setState(() => _service = null);
                },
                avatar: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.glassFill,
                    border: Border.all(
                        color: AppColors.glassBorder, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.plus, color: AppColors.textMid),
                ),
                label: 'Custom',
              );
            }
            final s = filtered[i];
            final selected = _service?.slug == s.slug;
            return _ServiceTile(
              selected: selected,
              onTap: () {
                Haptics.tap();
                final categories = ref.read(categoriesProvider);
                String? suggestedCategoryId;
                for (final category in categories) {
                  if (category.slug == s.categorySlug) {
                    suggestedCategoryId = category.id;
                    break;
                  }
                }
                setState(() {
                  _service = s;
                  _customName = s.name;
                  _customNameCtl.text = s.name;
                  _websiteUrl = '';
                  _websiteCtl.clear();
                  _categoryId ??= suggestedCategoryId;
                  _step = 1;
                });
              },
              avatar: ServiceAvatar(
                serviceSlug: s.slug,
                serviceName: s.name,
                size: 44,
                glow: false,
              ),
              label: s.name,
            );
          },
        ),
        if (_service == null && _customName.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          _customWebsiteField(),
        ],
      ],
    );
  }

  Widget _customWebsiteField() {
    final previewUrl = CustomBrandLogoStore.logoUrlForWebsite(_websiteUrl);
    final sanitizedWebsite = CustomBrandLogoStore.sanitizeWebsiteUrl(_websiteUrl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Website URL',
          style: AppTypography.caption
              .copyWith(color: AppColors.textMid, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              const Icon(
                LucideIcons.globe,
                size: 16,
                color: AppColors.textMid,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _websiteCtl,
                  onChanged: (value) {
                    setState(() => _websiteUrl = value);
                  },
                  style: AppTypography.body,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'https://www.netflix.com',
                    hintStyle:
                        AppTypography.body.copyWith(color: AppColors.textLow),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  cursorColor: AppColors.gold,
                ),
              ),
              if (_websiteUrl.trim().isNotEmpty)
                TextButton(
                  onPressed: () {
                    Haptics.tap();
                    setState(() {
                      _websiteUrl = '';
                      _websiteCtl.clear();
                    });
                  },
                  child: Text(
                    'Clear',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Official website of the service',
          style: AppTypography.caption.copyWith(color: AppColors.textLow),
        ),
        if (previewUrl != null && sanitizedWebsite != null) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Logo',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textMid, letterSpacing: 0.8),
              ),
              const Spacer(),
              Text(
                sanitizedWebsite,
                style: AppTypography.micro.copyWith(color: AppColors.textLow),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.inkRaised,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Image.network(
                    previewUrl,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => const Icon(
                      LucideIcons.image,
                      color: AppColors.textMid,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Logo Preview', style: AppTypography.cardTitle),
                      const SizedBox(height: 3),
                      Text(
                        'External image from the official domain',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textMid),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- Step 2: Pricing ---
  Widget _stepPricing() {
    const currencies = ['INR', 'USD', 'EUR', 'GBP', 'AED', 'AUD'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_currencySymbol(_currency),
                    style: AppTypography.midNumber
                        .copyWith(color: AppColors.gold)),
              ),
              const SizedBox(width: 6),
              IntrinsicWidth(
                child: TextField(
                  controller: _amountCtl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  textAlign: TextAlign.center,
                  style:
                      AppTypography.bigNumber.copyWith(color: AppColors.gold),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: AppTypography.bigNumber
                        .copyWith(color: AppColors.textLow),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  cursorColor: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: currencies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = currencies[i];
              final sel = c == _currency;
              return GestureDetector(
                onTap: () {
                  Haptics.tap();
                  setState(() => _currency = c);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.gold.withOpacity(0.16)
                        : AppColors.glassFill,
                    border: Border.all(
                      color: sel ? AppColors.gold : AppColors.glassBorder,
                      width: sel ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Text(_currencySymbol(c),
                          style: AppTypography.caption.copyWith(
                              color: sel ? AppColors.gold : AppColors.textMid,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      Text(c,
                          style: AppTypography.caption.copyWith(
                              color: sel ? AppColors.gold : AppColors.textMid,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Text('Billing cycle',
            style: AppTypography.caption
                .copyWith(color: AppColors.textMid, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        GlassSegmented<BillingCycle>(
          options: const [
            SegmentedOption(BillingCycle.weekly, 'Weekly'),
            SegmentedOption(BillingCycle.monthly, 'Monthly'),
            SegmentedOption(BillingCycle.quarterly, 'Quarter'),
            SegmentedOption(BillingCycle.yearly, 'Yearly'),
            SegmentedOption(BillingCycle.lifetime, 'Lifetime'),
          ],
          selected: _cycle,
          onChanged: (v) => setState(() => _cycle = v),
        ),
      ],
    );
  }

  String _currencySymbol(String c) {
    switch (c) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'AED':
        return 'د.إ';
      case 'JPY':
        return '¥';
      case 'SGD':
        return 'S\$';
      case 'AUD':
        return 'A\$';
      case 'INR':
      default:
        return '₹';
    }
  }

  // --- Step 3: Schedule ---
  Widget _stepSchedule() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        _dateTile(
          icon: LucideIcons.calendar,
          label: 'Start date',
          value: _startDate,
          onTap: () async {
            final d = await _pickDate(_startDate);
            if (d != null) {
              setState(() {
                _startDate = d;
                _renewalDate ??= d.add(Duration(days: _cycle.periodDays));
              });
            }
          },
        ),
        const SizedBox(height: 10),
        _dateTile(
          icon: LucideIcons.repeat,
          label: 'Next renewal',
          value: _renewalDate,
          onTap: () async {
            final d = await _pickDate(_renewalDate ?? DateTime.now());
            if (d != null) setState(() => _renewalDate = d);
          },
          trailing: TextButton(
            onPressed: () {
              Haptics.tap();
              setState(() {
                _renewalDate =
                    _startDate.add(Duration(days: _cycle.periodDays));
              });
            },
            child: Text('Auto',
                style: AppTypography.caption.copyWith(color: AppColors.gold)),
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.sparkles,
                      size: 18, color: AppColors.info),
                  const SizedBox(width: 10),
                  Text('Free trial', style: AppTypography.cardTitle),
                  const Spacer(),
                  Switch(
                    value: _isTrial,
                    onChanged: (v) {
                      Haptics.tap();
                      setState(() {
                        _isTrial = v;
                        _trialEndDate ??=
                            DateTime.now().add(const Duration(days: 14));
                      });
                    },
                  ),
                ],
              ),
              if (_isTrial) ...[
                const Divider(color: AppColors.hairline, height: 20),
                _dateTile(
                  icon: LucideIcons.clock,
                  label: 'Trial ends',
                  value: _trialEndDate,
                  inline: true,
                  onTap: () async {
                    final d = await _pickDate(_trialEndDate ??
                        DateTime.now().add(const Duration(days: 14)));
                    if (d != null) setState(() => _trialEndDate = d);
                  },
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateTile({
    required IconData icon,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    Widget? trailing,
    bool inline = false,
  }) {
    final txt = value == null
        ? 'Pick a date'
        : '${value.day} ${_mon(value.month)} ${value.year}';
    final core = Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMid),
        const SizedBox(width: 12),
        Text(label, style: AppTypography.body),
        const Spacer(),
        Text(txt,
            style: AppTypography.body.copyWith(
              color: value == null ? AppColors.textLow : AppColors.gold,
              fontWeight: FontWeight.w700,
            )),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ] else ...[
          const SizedBox(width: 6),
          const Icon(LucideIcons.chevronRight,
              size: 16, color: AppColors.textLow),
        ],
      ],
    );
    if (inline) {
      return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: core,
          ));
    }
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      onTap: onTap,
      child: core,
    );
  }

  Future<DateTime?> _pickDate(DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            onPrimary: AppColors.ink,
            surface: AppColors.inkRaised,
            onSurface: AppColors.text,
          ),
          dialogBackgroundColor: AppColors.inkRaised,
        ),
        child: child!,
      ),
    );
  }

  String _mon(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];

  // --- Step 4: Payment ---
  Widget _stepPayment() {
    final pms = ref.watch(paymentMethodsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        ...pms.map((pm) {
          final sel = _paymentMethodId == pm.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              borderColour: sel ? AppColors.gold : null,
              emphasised: sel,
              onTap: () {
                Haptics.tap();
                setState(() => _paymentMethodId = pm.id);
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Center(
                      child: paymentMethodMark(
                        type: pm.type,
                        name: pm.name,
                        iconSlug: pm.iconSlug,
                        size: 18,
                        fallbackColor: AppColors.textMid,
                        padding: const EdgeInsets.all(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pm.name, style: AppTypography.cardTitle),
                        const SizedBox(height: 2),
                        Text(pm.maskedLabel,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textMid)),
                      ],
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? AppColors.gold : AppColors.glassBorderHi,
                        width: 2,
                      ),
                      color: sel ? AppColors.gold : Colors.transparent,
                    ),
                    child: sel
                        ? const Icon(LucideIcons.check,
                            size: 12, color: AppColors.ink)
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          dashedBorder: true,
          tint: Colors.transparent,
          onTap: () async {
            Haptics.tap();
            await showAddPaymentMethodSheet(context);
            if (!mounted) return;
            final methods = ref.read(paymentMethodsProvider);
            if (methods.isNotEmpty) {
              setState(() => _paymentMethodId = methods.first.id);
            }
          },
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.plus,
                    size: 18, color: AppColors.gold),
              ),
              const SizedBox(width: 12),
              Text('Add a new payment method',
                  style: AppTypography.body.copyWith(
                      color: AppColors.gold, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () {
              Haptics.tap();
              setState(() => _paymentMethodId = null);
              _next();
            },
            child: Text('Skip for now',
                style:
                    AppTypography.caption.copyWith(color: AppColors.textMid)),
          ),
        ),
      ],
    );
  }

  // --- Step 5: Details ---
  Widget _stepDetails() {
    final cats = ref.watch(categoriesProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      children: [
        Text('Category',
            style: AppTypography.caption
                .copyWith(color: AppColors.textMid, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cats.map((c) {
            final sel = c.id == _categoryId;
            return GestureDetector(
              onTap: () {
                Haptics.tap();
                setState(() => _categoryId = c.id);
              },
              child: _CategoryPill(c: c, selected: sel),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Text('Notes',
            style: AppTypography.caption
                .copyWith(color: AppColors.textMid, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: TextField(
            controller: _notesCtl,
            maxLines: 3,
            style: AppTypography.body,
            decoration: InputDecoration(
              hintText: 'Anything to remember (plan, seat count, shared with…)',
              hintStyle: AppTypography.body.copyWith(color: AppColors.textLow),
              border: InputBorder.none,
              isDense: true,
            ),
            cursorColor: AppColors.gold,
          ),
        ),
        const SizedBox(height: 18),
        Text('Reminders',
            style: AppTypography.caption
                .copyWith(color: AppColors.textMid, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        _reminderTile(
            '7 days before', _remind7, (v) => setState(() => _remind7 = v)),
        const SizedBox(height: 8),
        _reminderTile(
            '3 days before', _remind3, (v) => setState(() => _remind3 = v)),
        const SizedBox(height: 8),
        _reminderTile(
            '1 day before', _remind1, (v) => setState(() => _remind1 = v)),
      ],
    );
  }

  Widget _reminderTile(String label, bool value, ValueChanged<bool> onChanged) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          const Icon(LucideIcons.bell, size: 16, color: AppColors.textMid),
          const SizedBox(width: 10),
          Text(label, style: AppTypography.body),
          const Spacer(),
          Switch(
            value: value,
            onChanged: (v) {
              Haptics.tap();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget avatar;
  final String label;
  const _ServiceTile({
    required this.selected,
    required this.onTap,
    required this.avatar,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:
              selected ? AppColors.gold.withOpacity(0.10) : AppColors.glassFill,
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.glassBorder,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Center(child: avatar),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 30,
                  child: Center(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      strutStyle: const StrutStyle(height: 1.15),
                      style: AppTypography.caption.copyWith(
                        color: selected ? AppColors.gold : AppColors.text,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.check,
                      size: 10, color: AppColors.ink),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final AppCategory c;
  final bool selected;
  const _CategoryPill({required this.c, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? c.colour.withOpacity(0.18) : AppColors.glassFill,
        border: Border.all(
          color: selected ? c.colour : AppColors.glassBorder,
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: c.colour,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: c.colour.withOpacity(0.5), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(c.name,
              style: AppTypography.caption.copyWith(
                color: selected ? c.colour : AppColors.text,
                fontWeight: FontWeight.w800,
              )),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
              boxShadow: [
                BoxShadow(
                    color: AppColors.gold.withOpacity(0.45), blurRadius: 24),
              ],
            ),
            child:
                const Icon(LucideIcons.check, size: 44, color: AppColors.gold),
          )
              .animate()
              .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: 320.ms,
                  curve: Curves.easeOutBack)
              .then(delay: 120.ms)
              .shake(duration: 260.ms, hz: 2),
          const SizedBox(height: 20),
          Text('Saved', style: AppTypography.pageTitle)
              .animate()
              .fadeIn(delay: 200.ms, duration: 260.ms),
          const SizedBox(height: 6),
          Text('Watching this one for you.',
                  style:
                      AppTypography.caption.copyWith(color: AppColors.textMid))
              .animate()
              .fadeIn(delay: 260.ms, duration: 260.ms),
        ],
      ),
    );
  }
}
