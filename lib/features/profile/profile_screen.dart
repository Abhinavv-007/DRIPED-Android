import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app.dart';
import '../../core/models/billing_cycle.dart';
import '../../core/providers/data_providers.dart';
import '../../core/router/app_router.dart';
import '../email_scanner/gmail_scanner.dart';
import '../email_scanner/scan_result_sheet.dart';
import '../email_scanner/subscription_parser.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/animated_counter.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _renewNotif = true;
  bool _trialNotif = true;
  bool _weeklyDigest = false;
  bool _scanning = false;
  final _shareKey = GlobalKey();

  // ── Scan caching ──
  static const _scanCacheKey = 'gmail_scan_cache';
  static const _scanCacheDateKey = 'gmail_scan_cache_date';
  static const _scanCacheTtlDays = 7;

  /// Returns true if there are cached scan results less than 7 days old.
  bool _hasFreshScanCache() {
    try {
      final box = Hive.box('driped_cache');
      final dateStr = box.get(_scanCacheDateKey) as String?;
      if (dateStr == null) return false;
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;
      return DateTime.now().difference(date).inDays < _scanCacheTtlDays;
    } catch (_) {
      return false;
    }
  }

  /// Loads cached detected subscriptions from Hive.
  List<DetectedSubscription>? _loadCachedScanResults() {
    try {
      final box = Hive.box('driped_cache');
      final raw = box.get(_scanCacheKey);
      if (raw == null) return null;
      final list = (raw as List).cast<Map>();
      return list.map((m) => _detectedFromMap(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return null;
    }
  }

  /// Persists scan results to Hive.
  void _saveScanCache(List<DetectedSubscription> results) {
    try {
      final box = Hive.box('driped_cache');
      box.put(_scanCacheKey, results.map((d) => _detectedToMap(d)).toList());
      box.put(_scanCacheDateKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  static Map<String, dynamic> _detectedToMap(DetectedSubscription d) => {
    'serviceName': d.serviceName,
    'serviceSlug': d.serviceSlug,
    'categorySlug': d.categorySlug,
    'storeName': d.storeName,
    'amount': d.amount,
    'currency': d.currency,
    'billingCycle': d.billingCycle.name,
    'nextRenewalDate': d.nextRenewalDate?.toIso8601String(),
    'isTrial': d.isTrial,
    'emailSubject': d.emailSubject,
    'emailDate': d.emailDate?.toIso8601String(),
    'paymentMethodLabel': d.paymentMethodLabel,
    'isCancellation': d.isCancellation,
    'isRefund': d.isRefund,
    'isFailedPayment': d.isFailedPayment,
    'isOneTimePurchase': d.isOneTimePurchase,
  };

  static DetectedSubscription _detectedFromMap(Map<String, dynamic> m) {
    return DetectedSubscription(
      serviceName: m['serviceName'] as String,
      serviceSlug: m['serviceSlug'] as String,
      categorySlug: m['categorySlug'] as String,
      storeName: m['storeName'] as String?,
      amount: (m['amount'] as num).toDouble(),
      currency: m['currency'] as String? ?? 'INR',
      billingCycle: BillingCycle.values.firstWhere(
        (b) => b.name == m['billingCycle'],
        orElse: () => BillingCycle.monthly,
      ),
      nextRenewalDate: m['nextRenewalDate'] != null
          ? DateTime.tryParse(m['nextRenewalDate'] as String)
          : null,
      isTrial: m['isTrial'] as bool? ?? false,
      emailSubject: m['emailSubject'] as String?,
      emailDate: m['emailDate'] != null
          ? DateTime.tryParse(m['emailDate'] as String)
          : null,
      paymentMethodLabel: m['paymentMethodLabel'] as String?,
      isCancellation: m['isCancellation'] as bool? ?? false,
      isRefund: m['isRefund'] as bool? ?? false,
      isFailedPayment: m['isFailedPayment'] as bool? ?? false,
      isOneTimePurchase: m['isOneTimePurchase'] as bool? ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currencyRatesInitProvider);
    final user = ref.watch(currentUserProvider);
    final ccy = ref.watch(preferredCurrencyProvider);
    final summary = ref.watch(dashboardSummaryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark ? AppColors.textMid : AppColors.lightTextMid;
    final tertiaryText = isDark ? AppColors.textLow : AppColors.lightTextLow;
    final dialogSurface = isDark ? AppColors.inkOverlay : AppColors.lightCard;
    final displayName = (user.fullName?.trim().isNotEmpty ?? false)
        ? user.fullName!
        : (user.email.isNotEmpty ? user.email : 'Driped user');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 140),
          children: [
            CustomHeader(
              title: 'Profile',
              subtitle: 'Preferences & account',
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, duration: 400.ms, curve: Curves.easeOutCubic),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                emphasised: true,
                child: Row(
                  children: [
                    _Avatar(
                        url: user.avatarUrl,
                        initial: user.firstName.isNotEmpty
                            ? user.firstName[0]
                            : 'D'),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName,
                              style: AppTypography.cardTitle
                                  .copyWith(fontSize: 18)),
                          const SizedBox(height: 2),
                          Text(user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption
                                  .copyWith(color: secondaryText)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _miniStat('ACTIVE', '${summary.activeCount}',
                                  AppColors.gold),
                              const SizedBox(width: 16),
                              _miniStatWidget(
                                'MONTHLY',
                                AnimatedCurrency(
                                  value: CurrencyUtil.convert(
                                      summary.monthlyTotalINR, 'INR', ccy),
                                  currency: ccy,
                                  compact: true,
                                  color: AppColors.gold,
                                  style: AppTypography.body.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 50.ms, duration: 400.ms).slideY(begin: 0.05),
            const SectionHeader(title: 'Gmail scan').animate().fadeIn(delay: 100.ms, duration: 400.ms),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (FirebaseAuth.instance.currentUser != null
                                ? AppColors.success
                                : AppColors.info)
                            .withOpacity(0.14),
                        border: Border.all(
                            color: FirebaseAuth.instance.currentUser != null
                                ? AppColors.success
                                : AppColors.info),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                          FirebaseAuth.instance.currentUser != null
                              ? LucideIcons.mailCheck
                              : LucideIcons.mail,
                          color: FirebaseAuth.instance.currentUser != null
                              ? AppColors.success
                              : AppColors.info,
                          size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              FirebaseAuth.instance.currentUser != null
                                  ? 'Gmail connected'
                                  : 'Connect Gmail',
                              style: AppTypography.cardTitle),
                          const SizedBox(height: 2),
                          Text(
                              FirebaseAuth.instance.currentUser != null
                                  ? (_hasFreshScanCache()
                                      ? 'Cached results available \u2022 Long-press to rescan'
                                      : 'Tap Scan now to detect subscriptions')
                                  : 'Auto-detect subscriptions from receipts',
                              style: AppTypography.caption
                                  .copyWith(color: secondaryText)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onLongPress: _scanning
                          ? null
                          : () {
                              Haptics.heavy();
                              _runIncrementalScan(forceRescan: true);
                            },
                      child: TextButton(
                        onPressed: _scanning ? null : _runIncrementalScan,
                        child: Text(
                            FirebaseAuth.instance.currentUser != null
                                ? (_hasFreshScanCache() ? 'View results' : 'Scan now')
                                : 'Connect',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.gold)),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.05),
            const SectionHeader(title: 'Preferences').animate().fadeIn(delay: 200.ms, duration: 400.ms),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Column(
                  children: [
                    _settingsTile(
                      icon: LucideIcons.globe,
                      label: 'Currency',
                      trailing: _currencyPicker(ccy),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 30, bottom: 6),
                      child: Text(
                        'Rates updated ${CurrencyUtil.ratesUpdatedLabel()}',
                        style: AppTypography.micro
                            .copyWith(color: tertiaryText, fontSize: 10),
                      ),
                    ),
                    Divider(color: AppColors.divider(context), height: 0),
                    _toggle(
                      icon: LucideIcons.moon,
                      label: 'Dark mode',
                      value: ref.watch(themeModeProvider) == ThemeMode.dark,
                      onChanged: (v) {
                        ref.read(themeModeProvider.notifier).state =
                            v ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.05),
            const SectionHeader(title: 'Notifications').animate().fadeIn(delay: 300.ms, duration: 400.ms),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Column(
                  children: [
                    _toggle(
                      icon: LucideIcons.bellRing,
                      label: 'Renewal reminders',
                      value: _renewNotif,
                      onChanged: (v) => setState(() => _renewNotif = v),
                    ),
                    Divider(color: AppColors.divider(context), height: 0),
                    _toggle(
                      icon: LucideIcons.sparkles,
                      label: 'Trial ending alerts',
                      value: _trialNotif,
                      onChanged: (v) => setState(() => _trialNotif = v),
                    ),
                    Divider(color: AppColors.divider(context), height: 0),
                    _toggle(
                      icon: LucideIcons.mail,
                      label: 'Weekly digest',
                      value: _weeklyDigest,
                      onChanged: (v) => setState(() => _weeklyDigest = v),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.05),
            const SectionHeader(title: 'Data').animate().fadeIn(delay: 400.ms, duration: 400.ms),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Column(
                  children: [
                    _link(LucideIcons.share2, 'Share my spend',
                        () => _shareSpend(summary, ccy)),
                    Divider(color: AppColors.divider(context), height: 0),
                    _link(LucideIcons.download, 'Export subscriptions',
                        _exportSubscriptions),
                    Divider(color: AppColors.divider(context), height: 0),
                    _link(LucideIcons.tags, 'Manage categories',
                        () => context.push('/categories')),
                    Divider(color: AppColors.divider(context), height: 0),
                    _link(LucideIcons.trash2, 'Clear local cache', () async {
                      Haptics.medium();
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: dialogSurface,
                          title: Text('Clear cache?',
                              style: AppTypography.sectionTitle),
                          content: Text(
                              'This will clear locally cached data. Your cloud data is safe.',
                              style: AppTypography.body
                                  .copyWith(color: secondaryText)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: Text('Cancel',
                                  style: AppTypography.body
                                      .copyWith(color: secondaryText)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: Text('Clear',
                                  style: AppTypography.body.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared')),
                        );
                      }
                    }),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideY(begin: 0.05),
            const SectionHeader(title: 'About').animate().fadeIn(delay: 500.ms, duration: 400.ms),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Column(
                  children: [
                    _link(LucideIcons.helpCircle, 'Help & feedback',
                        () => context.push('/profile/help')),
                    Divider(color: AppColors.divider(context), height: 0),
                    _link(LucideIcons.shieldCheck, 'Terms of service',
                        () => context.push('/profile/terms')),
                    Divider(color: AppColors.divider(context), height: 0),
                    _link(LucideIcons.fileText, 'Privacy policy',
                        () => context.push('/profile/privacy')),
                    Divider(color: AppColors.divider(context), height: 0),
                    _link(LucideIcons.history, 'Version history',
                        () => context.push('/profile/history')),
                    Divider(color: AppColors.divider(context), height: 0),
                    _link(LucideIcons.info, 'About Driped',
                        () => context.push('/profile/about')),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 550.ms, duration: 400.ms).slideY(begin: 0.05),
            const SectionHeader(title: 'Account').animate().fadeIn(delay: 600.ms, duration: 400.ms),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                tint: AppColors.danger.withOpacity(0.03),
                child: Column(
                  children: [
                    _link(LucideIcons.logOut, 'Sign out', () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: dialogSurface,
                          title: Text('Sign out?',
                              style: AppTypography.sectionTitle),
                          content: Text('You can sign back in any time.',
                              style: AppTypography.body
                                  .copyWith(color: secondaryText)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: Text('Cancel',
                                  style: AppTypography.body
                                      .copyWith(color: secondaryText)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: Text('Sign out',
                                  style: AppTypography.body.copyWith(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await FirebaseAuth.instance.signOut();
                        await GoogleSignIn().signOut();
                        ref.read(onboardingCompleteProvider.notifier).state =
                            false;
                        ref.read(authCompleteProvider.notifier).state = false;
                        if (context.mounted) context.go('/onboarding');
                      }
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Center(
                child: Text(
                  'Driped v1.0.0 • Made with \u2764\uFE0F',
                  style: AppTypography.micro.copyWith(
                    color: tertiaryText,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runIncrementalScan({bool forceRescan = false}) async {
    // \u2500\u2500 Check Hive cache before hitting Gmail \u2500\u2500
    if (!forceRescan && _hasFreshScanCache()) {
      final cached = _loadCachedScanResults();
      if (cached != null && cached.isNotEmpty) {
        if (!mounted) return;
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ScanResultSheet(detected: cached),
        );
        ref.read(subscriptionsProvider.notifier).fetch();
        return;
      }
    }

    setState(() => _scanning = true);
    Haptics.medium();

    final scanScanned = ValueNotifier<int>(0);
    final scanTotal = ValueNotifier<int>(0);
    final scanStatus = ValueNotifier<String>('Connecting to Google...');
    final scanError = ValueNotifier<String?>(null);
    final scanDetail = ValueNotifier<ScanProgress?>(null);

    // Show progress sheet with live-updating ValueListenableBuilders
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ValueListenableBuilder<String?>(
        valueListenable: scanError,
        builder: (_, errorVal, __) => ValueListenableBuilder<ScanProgress?>(
          valueListenable: scanDetail,
          builder: (_, detailVal, __) => ValueListenableBuilder<String>(
            valueListenable: scanStatus,
            builder: (_, statusVal, __) => ValueListenableBuilder<int>(
              valueListenable: scanTotal,
              builder: (_, totalVal, __) => ValueListenableBuilder<int>(
                valueListenable: scanScanned,
                builder: (_, scannedVal, __) => ScanProgressSheet(
                  scanned: scannedVal,
                  total: totalVal,
                  message: statusVal,
                  errorMessage: errorVal,
                  phaseName: detailVal?.phaseName,
                  currentEmailSubject: detailVal?.currentEmailSubject,
                  currentEmailFrom: detailVal?.currentEmailFrom,
                  foundServiceSlugs: detailVal?.foundServiceSlugs ?? const [],
                  foundServiceNames: detailVal?.foundServiceNames ?? const [],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    try {
      scanStatus.value = 'Signing into Google...';

      // Always create with gmail scope declared upfront so it's
      // requested during the login dialog — not via requestScopes()
      // which is unimplemented on Android.
      final googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'https://www.googleapis.com/auth/gmail.readonly',
        ],
      );

      // Try silent sign-in first (already authenticated)
      var account = await googleSignIn.signInSilently();

      // If silent sign-in didn't return an account, do interactive sign-in
      // which will show the Google picker + permission dialog
      if (account == null) {
        scanStatus.value = 'Requesting Google sign-in...';
        // Sign out any stale session so the picker always shows with scopes
        await googleSignIn.signOut();
        account = await googleSignIn.signIn();
      }

      if (account == null) {
        if (mounted) Navigator.of(context).pop();
        setState(() => _scanning = false);
        return;
      }
      // No _ensureGmailScope call needed — scope is declared at init

      scanStatus.value = 'Signed in as ${account.email}. Querying Gmail...';

      final scanner = GmailScanner(googleSignIn);
      final existingSubs = ref.read(subscriptionsProvider);

      scanStatus.value = existingSubs.isEmpty
          ? 'Full scan — searching all emails...'
          : 'Incremental scan — checking last 48h...';

      void onProgress(int s, int t) {
        scanScanned.value = s;
        scanTotal.value = t;
        scanStatus.value = 'Scanning emails ($s/$t)...';
      }

      void onDetail(ScanProgress progress) {
        scanDetail.value = progress;
        scanScanned.value = progress.scanned;
        scanTotal.value = progress.total;
      }

      final result = existingSubs.isEmpty
          ? await scanner.fullScan(
              onProgress: onProgress,
              onDetailedProgress: onDetail,
            )
          : await scanner.incrementalScan(
              onProgress: onProgress,
              onDetailedProgress: onDetail,
            );

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss progress sheet

      if (result.subscriptions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No new subscriptions found.')),
        );
      } else {
        // Cache results so next "Scan now" tap is instant
        _saveScanCache(result.subscriptions);

        // Show results sheet
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ScanResultSheet(detected: result.subscriptions),
        );
        // Refresh subscriptions
        ref.read(subscriptionsProvider.notifier).fetch();
      }
    } catch (e, stack) {
      debugPrint('[GmailScan] Error: $e\n$stack');
      if (mounted) {
        // Show error inside the sheet instead of dismissing
        scanError.value = '$e';
        scanStatus.value = 'Scan failed';
        // Wait for user to dismiss via the Close button
      }
    } finally {
      scanScanned.dispose();
      scanTotal.dispose();
      scanStatus.dispose();
      // Don't dispose scanError until sheet is closed
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _shareSpend(DashboardSummary summary, String ccy) async {
    Haptics.medium();
    final monthlyInCcy =
        CurrencyUtil.convert(summary.monthlyTotalINR, 'INR', ccy);
    final amtStr = CurrencyUtil.formatAmount(monthlyInCcy, code: ccy);
    final subs = ref.read(liveSubscriptionsProvider);
    final top3 = subs.take(3).toList();
    final months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthName = months[DateTime.now().month];

    // Build offscreen widget for capture
    final shareWidget = RepaintBoundary(
      key: _shareKey,
      child: Container(
        width: 360,
        height: 360,
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(color: AppColors.ink),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('driped',
                style: AppTypography.pageTitle
                    .copyWith(color: AppColors.gold, fontSize: 24)),
            const SizedBox(height: 2),
            Text('Stop the drip.',
                style: AppTypography.micro.copyWith(color: AppColors.textLow)),
            const SizedBox(height: 24),
            Text('My $monthName spend',
                style:
                    AppTypography.caption.copyWith(color: AppColors.textMid)),
            const SizedBox(height: 6),
            Text(amtStr,
                style: AppTypography.heroNumber
                    .copyWith(color: AppColors.gold, fontSize: 48)),
            if (top3.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: top3
                    .map((s) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.glassFillHi,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  s.serviceName.substring(0, 1).toUpperCase(),
                                  style: AppTypography.cardTitle
                                      .copyWith(color: AppColors.gold),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(s.serviceName,
                                  style: AppTypography.micro.copyWith(
                                      color: AppColors.textMid, fontSize: 10)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
            const Spacer(),
            Text('Track yours \u2192 driped.app',
                style: AppTypography.micro
                    .copyWith(color: AppColors.textLow, fontSize: 10)),
          ],
        ),
      ),
    );

    // Insert into overlay to render
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -500,
        top: -500,
        child: shareWidget,
      ),
    );
    overlay.insert(entry);

    // Wait for render
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final boundary = _shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        entry.remove();
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        entry.remove();
        return;
      }
      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/driped_share.png');
      await file.writeAsBytes(bytes);

      entry.remove();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'I spend $amtStr/month on subscriptions \u{1F4B8} #Driped',
      );
    } catch (e) {
      entry.remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  Future<void> _exportSubscriptions() async {
    Haptics.medium();
    final subs = ref.read(safeSubscriptionsProvider);
    final paymentMethods = ref.read(safePaymentMethodsProvider);
    final methodsById = {
      for (final method in paymentMethods) method.id: method.maskedLabel,
    };
    final payload = {
      'exported_at': DateTime.now().toIso8601String(),
      'subscription_count': subs.length,
      'subscriptions': subs
          .map((sub) => {
                'service_name': sub.serviceName,
                'service_slug': sub.serviceSlug,
                'status': sub.status.label,
                'amount': sub.amount,
                'currency': sub.currency,
                'billing_cycle': sub.billingCycle.label,
                'next_renewal_date': sub.nextRenewalDate?.toIso8601String(),
                'renewal_label': sub.renewalDisplayLabel,
                'payment_method': methodsById[sub.paymentMethodId],
                'notes': sub.notes,
                'source': sub.source.wire,
              })
          .toList(),
    };

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/driped_subscriptions_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Driped subscription export',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  // NOTE: canAccessScopes() and requestScopes() are NOT implemented on Android.
  // Scopes must be declared in the GoogleSignIn constructor instead.
  // This method is kept only for reference and is no longer called.
  Future<void> _ensureGmailScope(GoogleSignIn googleSignIn) async {
    // No-op: scope is now declared at GoogleSignIn init time
  }

  Widget _miniStat(String label, String value, Color colour) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.micro
                .copyWith(color: _tertiaryText(context), letterSpacing: 1.2)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.body.copyWith(
                color: colour, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }

  Widget _miniStatWidget(String label, Widget value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.micro
                .copyWith(color: _tertiaryText(context), letterSpacing: 1.2)),
        const SizedBox(height: 2),
        value,
      ],
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    required Widget trailing,
  }) {
    final secondary = _secondaryText(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _toggle({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final secondary = _secondaryText(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
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

  Widget _link(IconData icon, String label, VoidCallback? onTap) {
    final secondary = _secondaryText(context);
    final tertiary = _tertiaryText(context);
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      onTap: onTap == null
          ? null
          : () {
              Haptics.tap();
              onTap();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            if (onTap != null)
              Icon(LucideIcons.chevronRight, size: 16, color: tertiary),
          ],
        ),
      ),
    );
  }

  Widget _currencyPicker(String current) {
    return GestureDetector(
      onTap: () async {
        Haptics.tap();
        final picked = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.inkOverlay
              : AppColors.lightCard,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (sheetContext) {
            final sheetHeight = MediaQuery.of(sheetContext).size.height * 0.72;
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: sheetHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Currency',
                        style: AppTypography.sectionTitle.copyWith(
                          color: AppColors.textPrimary(sheetContext),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: CurrencyUtil.supported.length,
                          separatorBuilder: (_, __) => Divider(
                            color: AppColors.divider(sheetContext),
                            height: 0,
                          ),
                          itemBuilder: (_, index) {
                            final c = CurrencyUtil.supported[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Text(
                                CurrencyUtil.symbol(c),
                                style: AppTypography.cardTitle
                                    .copyWith(color: AppColors.gold),
                              ),
                              title: Text(
                                c,
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textPrimary(sheetContext),
                                ),
                              ),
                              trailing: current == c
                                  ? const Icon(
                                      LucideIcons.check,
                                      color: AppColors.gold,
                                    )
                                  : null,
                              onTap: () => Navigator.pop(sheetContext, c),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
        if (picked != null && picked != current) {
          final user = ref.read(currentUserProvider);
          ref.read(preferredCurrencyProvider.notifier).state = picked;
          ref.read(currentUserProvider.notifier).state =
              user.copyWith(currency: picked);
          if (user.email.isNotEmpty) {
            final result = await ref.read(userRepoProvider).syncUser(
                  email: user.email,
                  fullName: user.fullName,
                  avatarUrl: user.avatarUrl,
                  currency: picked,
                );
            result.when(
              success: (synced) {
                ref.read(currentUserProvider.notifier).state = synced;
                ref.read(preferredCurrencyProvider.notifier).state =
                    synced.currency;
              },
              failure: (_) {},
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.14),
          border: Border.all(color: AppColors.gold),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(CurrencyUtil.symbol(current),
                style: AppTypography.caption.copyWith(
                    color: AppColors.gold, fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            Text(current,
                style: AppTypography.caption.copyWith(
                    color: AppColors.gold, fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronDown,
                size: 12, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}

Color _secondaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textMid
      : AppColors.lightTextMid;
}

Color _tertiaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textLow
      : AppColors.lightTextLow;
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String initial;
  const _Avatar({this.url, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.gold.withOpacity(0.4), blurRadius: 14),
        ],
      ),
      child: ClipOval(
        child: (url == null || url!.isEmpty)
            ? Container(
                color: AppColors.glassFillHi,
                alignment: Alignment.center,
                child: Text(initial,
                    style: AppTypography.midNumber
                        .copyWith(color: AppColors.gold, fontSize: 28)),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.glassFillHi,
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: AppTypography.midNumber
                          .copyWith(color: AppColors.gold, fontSize: 28)),
                ),
              ),
      ),
    ).animate().fadeIn(duration: 240.ms).scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1, 1),
        curve: Curves.easeOutBack,
        duration: 320.ms);
  }
}
