import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/billing_cycle.dart';
import '../../core/models/subscription.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/drag_handle.dart';
import '../../core/widgets/skeuo_card.dart';
import '../../core/widgets/skeuo_button.dart';
import '../../core/widgets/service_avatar.dart';
import 'subscription_parser.dart';

final bool _emailScanImportsStayLocal = true;

/// Shows scan results — user can review, edit, skip, and bulk-save.
class ScanResultSheet extends ConsumerStatefulWidget {
  final List<DetectedSubscription> detected;

  const ScanResultSheet({super.key, required this.detected});

  @override
  ConsumerState<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends ConsumerState<ScanResultSheet> {
  late List<DetectedSubscription> _items;
  final Set<int> _approvedIndices = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.detected.where(
        (d) => !d.isOneTimePurchase && !d.isRefund && !d.isFailedPayment))
      ..sort((a, b) {
        if (a.requiresReview != b.requiresReview) {
          return a.requiresReview ? 1 : -1;
        }
        return b.confidence.compareTo(a.confidence);
      });
    // Auto-approve deterministic matches. AI-only finds stay visible but need
    // explicit approval so model guesses cannot be imported silently.
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].requiresReview) _approvedIndices.add(i);
    }
  }

  int get _count => _items.length;
  int get _approvedCount => _approvedIndices.length;
  bool get _allSelected => _count > 0 && _approvedCount == _count;

  void _toggleSelectAll() {
    Haptics.medium();
    setState(() {
      if (_allSelected) {
        _approvedIndices.clear();
      } else {
        _approvedIndices.addAll(List.generate(_count, (i) => i));
      }
    });
  }

  void _reject(int index) {
    Haptics.medium();
    setState(() {
      _approvedIndices.remove(index);
      _items.removeAt(index);
      // We'll have to shift approved indices if they were after this index,
      // but since we are replacing the set it's easier to just rebuild it or keep a map.
      // Actually, removing shifts the array.
      final newApproved = <int>{};
      for (final i in _approvedIndices) {
        if (i > index) {
          newApproved.add(i - 1);
        } else if (i < index) {
          newApproved.add(i);
        }
      }
      _approvedIndices.clear();
      _approvedIndices.addAll(newApproved);
    });
  }

  static String? _buildNotes(DetectedSubscription det) {
    final parts = [
      if (det.storeName?.isNotEmpty == true) 'Store: ${det.storeName}',
      if (det.paymentMethodLabel?.isNotEmpty == true)
        'Payment: ${det.paymentMethodLabel}',
    ];
    final joined = parts.join(' • ');
    return joined.isEmpty ? null : joined;
  }

  /// Compute the next renewal date from detector data.
  /// Priority: parser-found date (if it's in the future) → advance emailDate by
  /// one billing cycle → fall back to 30 days from now.
  static DateTime _computeRenewalDate(DetectedSubscription det) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Use the parser-extracted date only if it's in the future
    if (det.nextRenewalDate != null && !det.nextRenewalDate!.isBefore(today)) {
      return det.nextRenewalDate!;
    }

    // Advance from email date by one billing period
    final base = det.emailDate ?? now;
    switch (det.billingCycle) {
      case BillingCycle.weekly:
        return base.add(const Duration(days: 7));
      case BillingCycle.monthly:
        final m = base.month + 1;
        final y = base.year + (m > 12 ? 1 : 0);
        return DateTime(y, m > 12 ? m - 12 : m, base.day);
      case BillingCycle.quarterly:
        final m = base.month + 3;
        final y = base.year + (m > 12 ? 1 : 0);
        return DateTime(y, m > 12 ? m - 12 : m, base.day);
      case BillingCycle.yearly:
        return DateTime(base.year + 1, base.month, base.day);
      case BillingCycle.lifetime:
        return now.add(const Duration(days: 365 * 99));
    }
  }

  void _toggleApprove(int index) {
    Haptics.tap();
    setState(() {
      if (_approvedIndices.contains(index)) {
        _approvedIndices.remove(index);
      } else {
        _approvedIndices.add(index);
      }
    });
  }

  Future<void> _saveApproved() async {
    if (_approvedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No subscriptions selected to save.')));
      return;
    }

    Haptics.medium();
    setState(() => _saving = true);

    try {
      final subsNotifier = ref.read(subscriptionsProvider.notifier);
      final user = ref.read(currentUserProvider);
      final historyRepo = ref.read(paymentHistoryRepoProvider);
      final scanLogRepo = ref.read(scanLogRepoProvider);

      final historyEntries = <Map<String, dynamic>>[];
      final savedCount = _approvedIndices.length;

      for (final index in _approvedIndices) {
        final det = _items[index];

        final SubscriptionStatus detectedStatus;
        if (det.isCancellation) {
          detectedStatus = SubscriptionStatus.cancelled;
        } else if (det.isTrial) {
          detectedStatus = SubscriptionStatus.trial;
        } else {
          detectedStatus = SubscriptionStatus.active;
        }

        final sub = Subscription(
          id: newId(),
          userId: user.id,
          serviceName: det.serviceName,
          serviceSlug: det.serviceSlug,
          categoryId: null,
          amount: det.amount,
          currency: det.currency,
          billingCycle: det.billingCycle,
          startDate: det.emailDate ?? DateTime.now(),
          // If the parser found a future renewal date use it; otherwise compute
          // the next expected charge by advancing one cycle from the email date.
          nextRenewalDate: _computeRenewalDate(det),
          isTrial: det.isTrial,
          status: detectedStatus,
          lastEmailDetectedAt: det.emailDate,
          notes: _buildNotes(det),
          source: SubscriptionSource.emailScan,
          createdAt: DateTime.now(), // import timestamp, not email date
          updatedAt: DateTime.now(),
        );

        // Save locally immediately. Email-derived details stay on device by
        // default; there is deliberately no cloud AI or cloud import fallback.
        if (_emailScanImportsStayLocal) {
          await subsNotifier.addLocal(sub);
        } else {
          subsNotifier.add(sub).ignore();
        }

        if (det.amount > 0 && det.emailDate != null) {
          historyEntries.add({
            'subscription_id': sub.id,
            'amount': det.amount,
            'currency': det.currency,
            'charged_at': det.emailDate!.toIso8601String(),
            'email_subject': det.emailSubject,
          });
        }
      }

      // Fire-and-forget non-critical network calls only when cloud sync for
      // scan imports is explicitly enabled.
      if (!_emailScanImportsStayLocal && historyEntries.isNotEmpty) {
        historyRepo.bulkInsert(historyEntries).ignore();
      }
      if (!_emailScanImportsStayLocal) {
        scanLogRepo
            .logScan(
              scanType: 'full',
              emailsScanned: widget.detected.length,
              subscriptionsFound: savedCount,
            )
            .ignore();
      }

      // Clear scan cache so next 'Scan now' runs fresh instead of
      // re-showing subscriptions the user just imported
      try {
        final box = Hive.box('driped_cache');
        box.delete('gmail_scan_cache');
        box.delete('gmail_scan_cache_date');
      } catch (_) {}

      Haptics.success();
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Imported $savedCount subscription${savedCount == 1 ? '' : 's'} successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Import failed: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14141C) : const Color(0xFFF3F0E6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  children: [
                    const DragHandle(),
                    const SizedBox(height: 20),
                    Text(
                      'Review Desk',
                      style: AppTypography.sectionTitle.copyWith(
                          color: AppColors.textPrimary(context), fontSize: 22),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 6),
                    Text(
                      'Tap to approve, edit details, or swipe to reject non-subscriptions.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary(context),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Auto-select all on first load
              Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0x22FFFFFF)
                      : const Color(0x18000000)),
              // ── Select-all row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Row(
                  children: [
                    Text(
                      '$_count detected',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleSelectAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _allSelected
                              ? AppColors.success.withOpacity(0.15)
                              : AppColors.gold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _allSelected
                                ? AppColors.success.withOpacity(0.4)
                                : AppColors.gold.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _allSelected
                                  ? LucideIcons.checkSquare
                                  : LucideIcons.square,
                              size: 14,
                              color: _allSelected
                                  ? AppColors.success
                                  : AppColors.gold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _allSelected ? 'Deselect all' : 'Select all',
                              style: AppTypography.micro.copyWith(
                                color: _allSelected
                                    ? AppColors.success
                                    : AppColors.gold,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── List ──
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.mailX,
                                size: 48, color: AppColors.textLow),
                            const SizedBox(height: 12),
                            Text('No recurring subscriptions found.',
                                style: AppTypography.body
                                    .copyWith(color: AppColors.textMid)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final isApproved = _approvedIndices.contains(index);
                          return Dismissible(
                            key:
                                ValueKey('${_items[index].serviceSlug}_$index'),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _reject(index),
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(LucideIcons.trash2,
                                  color: AppColors.danger),
                            ),
                            child: _DetectedSubCard(
                              sub: _items[index],
                              isApproved: isApproved,
                              onToggleApprove: () => _toggleApprove(index),
                              onAmountChanged: (v) =>
                                  setState(() => _items[index].amount = v),
                              onCycleChanged: (v) => setState(
                                  () => _items[index].billingCycle = v),
                              onRenewalChanged: (d) => setState(
                                  () => _items[index].nextRenewalDate = d),
                              onPaymentMethodChanged: (v) => setState(
                                  () => _items[index].paymentMethodLabel = v),
                            ).animate().fadeIn(
                                delay: Duration(milliseconds: index * 40),
                                duration: 200.ms),
                          );
                        },
                      ),
              ),

              // ── Bottom bar ──
              SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.paddingOf(context).bottom > 0 ? 8 : 24,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1B24) : Colors.white,
                    border: Border(
                        top: BorderSide(
                            color: isDark
                                ? const Color(0x33FFFFFF)
                                : const Color(0x18000000))),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_approvedCount of $_count selected for import',
                        style: AppTypography.micro
                            .copyWith(color: AppColors.textSecondary(context)),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SkeuoButton(
                          text: _approvedCount > 0
                              ? 'Import $_approvedCount Subscription${_approvedCount == 1 ? '' : 's'}'
                              : 'Select subscriptions above',
                          color: _approvedCount > 0
                              ? AppColors.gold
                              : AppColors.textLow,
                          textColor: isDark ? AppColors.ink : Colors.white,
                          isLoading: _saving,
                          onTap: _approvedCount > 0 ? _saveApproved : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════
// Individual detected subscription card
// ═══════════════════════════════════════
class _DetectedSubCard extends StatelessWidget {
  final DetectedSubscription sub;
  final bool isApproved;
  final VoidCallback onToggleApprove;
  final ValueChanged<double> onAmountChanged;
  final ValueChanged<BillingCycle> onCycleChanged;
  final ValueChanged<DateTime?> onRenewalChanged;
  final ValueChanged<String?> onPaymentMethodChanged;

  const _DetectedSubCard({
    required this.sub,
    required this.isApproved,
    required this.onToggleApprove,
    required this.onAmountChanged,
    required this.onCycleChanged,
    required this.onRenewalChanged,
    required this.onPaymentMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SkeuoCard(
        emphasised: isApproved,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox equivalent
            GestureDetector(
              onTap: onToggleApprove,
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 10, right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isApproved
                      ? AppColors.success
                      : (isDark
                          ? const Color(0xFF0F0F14)
                          : const Color(0xFFE5E2DA)),
                  border: Border.all(
                      color: isApproved
                          ? AppColors.success
                          : (isDark
                              ? const Color(0x33FFFFFF)
                              : const Color(0x33000000))),
                  boxShadow: isApproved
                      ? [
                          BoxShadow(
                              color: AppColors.success.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]
                      : [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2)
                        ],
                ),
                child: isApproved
                    ? const Icon(LucideIcons.check,
                        size: 14, color: Colors.white)
                    : null,
              ),
            ),
            ServiceAvatar(
              serviceSlug: sub.serviceSlug,
              serviceName: sub.serviceName,
              size: 44,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(sub.serviceName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.cardTitle.copyWith(
                                color: AppColors.textPrimary(context),
                                fontSize: 16)),
                      ),
                      // Swipe to reject hint
                      if (!isApproved)
                        Icon(LucideIcons.arrowLeft,
                            size: 14,
                            color: AppColors.textLow.withOpacity(0.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _interactivePill(
                        context,
                        label: sub.amount > 0
                            ? CurrencyUtil.formatAmount(sub.amount,
                                code: sub.currency)
                            : 'Set Amount',
                        icon: LucideIcons.coins,
                        accent: AppColors.gold,
                        onTap: () => _editAmount(context),
                      ),
                      _interactivePill(
                        context,
                        label: sub.billingCycle.label,
                        icon: LucideIcons.refreshCw,
                        accent: AppColors.info,
                        onTap: () => _editCycle(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _interactivePill(
                        context,
                        label: sub.nextRenewalDate != null
                            ? _formatDate(sub.nextRenewalDate!)
                            : 'Set Date',
                        icon: LucideIcons.calendar,
                        accent: AppColors.textMid,
                        onTap: () => _editRenewal(context),
                      ),
                      _interactivePill(
                        context,
                        label: sub.paymentMethodLabel?.isNotEmpty == true
                            ? sub.paymentMethodLabel!
                            : 'Set Payment',
                        icon: LucideIcons.creditCard,
                        accent: AppColors.textMid,
                        onTap: () => _editPayment(context),
                      ),
                    ],
                  ),
                  if (sub.isTrial) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Free Trial Found',
                          style: AppTypography.micro.copyWith(
                              color: AppColors.warning, fontSize: 11)),
                    ),
                  ],
                  if (sub.requiresReview) ...[
                    const SizedBox(height: 8),
                    _statusBadge(
                      context,
                      label: 'AI Review',
                      icon: LucideIcons.sparkles,
                      color: AppColors.info,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context,
      {required String label, required IconData icon, required Color color}) {
    final isDark = AppColors.isDark(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.micro.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 160.ms).scaleXY(
          begin: 0.94,
          end: 1,
          duration: 180.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _interactivePill(BuildContext context,
      {required String label,
      required IconData icon,
      required Color accent,
      required VoidCallback onTap}) {
    final isDark = AppColors.isDark(context);
    final maxPillWidth =
        (MediaQuery.sizeOf(context).width - 144).clamp(120.0, 280.0);
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: maxPillWidth),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E28) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color:
                    isDark ? const Color(0x22FFFFFF) : const Color(0x18000000)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1))
            ]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.micro.copyWith(
                      color: AppColors.textSecondary(context), fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _editAmount(BuildContext context) {
    final controller = TextEditingController(
        text: sub.amount > 0 ? sub.amount.toString() : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            AppColors.isDark(context) ? const Color(0xFF1B1B24) : Colors.white,
        title: Text('Edit Amount',
            style: AppTypography.cardTitle
                .copyWith(color: AppColors.textPrimary(context))),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: AppTypography.body
              .copyWith(color: AppColors.textPrimary(context)),
          decoration: InputDecoration(
            prefix: Text('${CurrencyUtil.symbol(sub.currency)} ',
                style: AppTypography.body.copyWith(color: AppColors.gold)),
            filled: true,
            fillColor: AppColors.isDark(context)
                ? const Color(0xFF14141C)
                : const Color(0xFFF3F0E6),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null) onAmountChanged(v);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPayment(BuildContext context) {
    final controller =
        TextEditingController(text: sub.paymentMethodLabel ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            AppColors.isDark(context) ? const Color(0xFF1B1B24) : Colors.white,
        title: Text('Edit Payment Method',
            style: AppTypography.cardTitle
                .copyWith(color: AppColors.textPrimary(context))),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.body
              .copyWith(color: AppColors.textPrimary(context)),
          decoration: InputDecoration(
            hintText: 'e.g. Visa 4242',
            hintStyle: TextStyle(color: AppColors.textLow),
            filled: true,
            fillColor: AppColors.isDark(context)
                ? const Color(0xFF14141C)
                : const Color(0xFFF3F0E6),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              onPaymentMethodChanged(controller.text.trim().isEmpty
                  ? null
                  : controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editCycle(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.isDark(context)
          ? const Color(0xFF14141C)
          : const Color(0xFFF3F0E6),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const DragHandle(),
            const SizedBox(height: 16),
            ...BillingCycle.values
                .where((c) => c != BillingCycle.lifetime)
                .map((c) => ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(c.label,
                          style: AppTypography.body
                              .copyWith(color: AppColors.textPrimary(context))),
                      trailing: sub.billingCycle == c
                          ? const Icon(LucideIcons.checkCircle2,
                              color: AppColors.success, size: 20)
                          : null,
                      onTap: () {
                        onCycleChanged(c);
                        Navigator.pop(ctx);
                      },
                    ))
                .toList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _editRenewal(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
        context: context,
        initialDate: sub.nextRenewalDate ?? now,
        firstDate: now.subtract(const Duration(days: 365)),
        lastDate: now.add(const Duration(days: 365 * 10)),
        builder: (context, child) {
          return Theme(
            data: AppColors.isDark(context)
                ? ThemeData.dark()
                : ThemeData.light(),
            child: child!,
          );
        });
    if (picked != null) {
      onRenewalChanged(picked);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
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
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

// ═══════════════════════════════════════
// Scan progress sheet — shown during scan
// Rich interactive UI with live email
// ticker, found icons, phase dots
// ═══════════════════════════════════════
class ScanProgressSheet extends StatelessWidget {
  final int scanned;
  final int total;
  final String message;
  final String? errorMessage;
  final VoidCallback? onCancel;

  // Rich progress fields
  final String? phaseName;
  final int phaseIndex;
  final int totalPhases;
  final String? currentEmailSubject;
  final String? currentEmailFrom;
  final List<String> foundServiceSlugs;
  final List<String> foundServiceNames;

  const ScanProgressSheet({
    super.key,
    required this.scanned,
    required this.total,
    this.message = 'Searching for emails...',
    this.errorMessage,
    this.onCancel,
    this.phaseName,
    this.phaseIndex = 0,
    this.totalPhases = 5,
    this.currentEmailSubject,
    this.currentEmailFrom,
    this.foundServiceSlugs = const [],
    this.foundServiceNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final progress = total > 0 ? scanned / total : 0.0;
    final hasError = errorMessage != null && errorMessage!.isNotEmpty;
    final foundCount = foundServiceSlugs.length;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: viewInsets),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF14141C) : const Color(0xFFF3F0E6),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(hasError ? 0 : 0.1),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DragHandle(),
                    const SizedBox(height: 24),
                    if (hasError) ...[
                      Icon(LucideIcons.alertTriangle,
                              size: 48, color: AppColors.danger)
                          .animate()
                          .shake(duration: 400.ms),
                      const SizedBox(height: 16),
                      Text('Scan Blocked',
                          style: AppTypography.sectionTitle
                              .copyWith(color: AppColors.danger, fontSize: 18)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.danger.withOpacity(0.25)),
                        ),
                        child: Text(errorMessage!,
                            style: AppTypography.body.copyWith(
                                color: AppColors.textPrimary(context),
                                fontSize: 13),
                            textAlign: TextAlign.center),
                      ),
                    ],
                    if (!hasError) ...[
                      _buildScanIcon(),
                      const SizedBox(height: 20),
                      Text(
                        phaseName ?? message,
                        style: AppTypography.cardTitle.copyWith(
                            color: AppColors.textPrimary(context),
                            fontSize: 16),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      if (totalPhases > 1) ...[
                        _buildPhaseDots(),
                        const SizedBox(height: 20),
                      ],
                      _buildProgressBar(progress, isDark),
                      const SizedBox(height: 12),
                      _buildStatsRow(foundCount, context),
                      const SizedBox(height: 16),
                      if (currentEmailSubject != null ||
                          currentEmailFrom != null) ...[
                        _buildEmailTicker(context),
                        const SizedBox(height: 16),
                      ],
                      if (foundCount > 0) ...[
                        _buildFoundServicesGrid(),
                        const SizedBox(height: 12),
                      ],
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SkeuoButton(
                        text: hasError ? 'Close' : 'Cancel Scan',
                        color: isDark
                            ? const Color(0xFF262633)
                            : const Color(0xFFE2DFD6),
                        textColor: AppColors.textPrimary(context),
                        onTap: () {
                          if (onCancel != null) {
                            onCancel!();
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanIcon() {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.gold.withOpacity(0.2), width: 2),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 0.8, end: 1.25, duration: 1500.ms)
              .fadeOut(duration: 1500.ms),
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withOpacity(0.12))),
          const Icon(LucideIcons.scanFace, size: 28, color: AppColors.gold),
        ],
      ),
    );
  }

  Widget _buildPhaseDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalPhases, (i) {
        final isActive = i == phaseIndex;
        final isDone = i < phaseIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDone
                ? AppColors.gold
                : (isActive
                    ? AppColors.gold.withOpacity(0.7)
                    : AppColors.textLow.withOpacity(0.2)),
          ),
        );
      }),
    );
  }

  Widget _buildProgressBar(double progress, bool isDark) {
    return Container(
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F14) : const Color(0xFFE5E2DA),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)
          ]),
      height: 12,
      child: Stack(
        children: [
          if (total > 0)
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                        colors: [AppColors.goldDeep, AppColors.gold]),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.gold.withOpacity(0.6),
                          blurRadius: 6,
                          offset: const Offset(0, 1))
                    ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int foundCount, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$scanned / $total emails',
          style: AppTypography.micro.copyWith(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600),
        ),
        Text(
          '$foundCount found',
          style: AppTypography.micro
              .copyWith(color: AppColors.gold, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildEmailTicker(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return SkeuoCard(
      padding: const EdgeInsets.all(12),
      baseColor: isDark ? const Color(0xFF1B1B24) : Colors.white,
      child: Row(
        children: [
          Icon(LucideIcons.mail, size: 14, color: AppColors.textLow),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentEmailFrom != null)
                  Text(currentEmailFrom!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w700)),
                if (currentEmailSubject != null)
                  Text(currentEmailSubject!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.micro
                          .copyWith(color: AppColors.textSecondary(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundServicesGrid() {
    final limit = foundServiceSlugs.length > 6 ? 5 : foundServiceSlugs.length;
    final extra = foundServiceSlugs.length - limit;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < limit; i++)
          Padding(
            padding:
                EdgeInsets.only(right: (i < limit - 1 || extra > 0) ? 6 : 0),
            child: ServiceAvatar(
                serviceSlug: foundServiceSlugs[i],
                serviceName: foundServiceNames[i],
                size: 28),
          ).animate().scale(duration: 200.ms),
        if (extra > 0)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textLow.withOpacity(0.1)),
            alignment: Alignment.center,
            child: Text('+$extra',
                style: AppTypography.micro.copyWith(
                    color: AppColors.textMid, fontWeight: FontWeight.w800)),
          ).animate().scale(),
      ],
    );
  }
}
