import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/app_user.dart';
import '../../core/providers/data_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/driped_logo.dart';
import '../../core/widgets/neo_button.dart';
import '../email_scanner/gmail_scanner.dart';
import '../email_scanner/scan_result_sheet.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  bool _busy = false;

  String? _errorMsg;

  Future<void> _connectGoogle() async {
    Haptics.medium();
    setState(() {
      _busy = true;
      _errorMsg = null;
    });

    try {
      final googleSignIn = GoogleSignIn(scopes: [
        'email',
        'https://www.googleapis.com/auth/gmail.readonly',
      ]);
      final gAccount = await googleSignIn.signIn();
      if (gAccount == null) {
        setState(() => _busy = false);
        return; // user cancelled
      }
      // Scope declared at GoogleSignIn() init — no separate requestScopes() needed

      final gAuth = await gAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw Exception('Firebase sign-in returned null user');
      }

      // Sync user with backend
      final repo = ref.read(userRepoProvider);
      final syncResult = await repo.syncUser(
        email: fbUser.email ?? gAccount.email,
        fullName: fbUser.displayName ?? gAccount.displayName,
        avatarUrl: fbUser.photoURL ?? gAccount.photoUrl,
      );

      syncResult.when(
        success: (user) {
          ref.read(currentUserProvider.notifier).state = user;
        },
        failure: (_) {
          // API sync failed — build user from Firebase data and cache it locally
          final localUser = AppUser(
            id: fbUser.uid,
            email: fbUser.email ?? gAccount.email,
            fullName: fbUser.displayName ?? gAccount.displayName ?? '',
            avatarUrl: fbUser.photoURL ?? gAccount.photoUrl,
            currency: 'INR',
            createdAt: DateTime.now(),
          );
          ref.read(currentUserProvider.notifier).state = localUser;
          // Write to Hive so it survives a restart
          try {
            Hive.box('driped_cache').put('current_user', {
              'id': localUser.id,
              'email': localUser.email,
              'full_name': localUser.fullName,
              'avatar_url': localUser.avatarUrl,
              'currency': localUser.currency,
              'created_at': localUser.createdAt.toIso8601String(),
            });
          } catch (_) {}
        },
      );

      if (!mounted) return;
      ref.read(onboardingCompleteProvider.notifier).state = true;
      ref.read(authCompleteProvider.notifier).state = true;
      Haptics.success();

      final shouldRunScan = ref.read(subscriptionsProvider).isEmpty;
      if (shouldRunScan) {
        await _runFirstLoginScan(googleSignIn);
      }

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMsg = _friendlyGoogleError(e);
      });
      Haptics.warn();
    }
  }

  Future<void> _runFirstLoginScan(GoogleSignIn googleSignIn) async {
    final navContext = Navigator.of(context, rootNavigator: true).context;

    final scanScanned = ValueNotifier<int>(0);
    final scanTotal = ValueNotifier<int>(0);
    final scanStatus = ValueNotifier<String>('Preparing Gmail scan...');
    final scanError = ValueNotifier<String?>(null);
    final scanDetail = ValueNotifier<ScanProgress?>(null);

    // Show scan progress with live updates
    showModalBottomSheet(
      context: navContext,
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
      scanStatus.value = 'Querying Gmail for subscription emails...';

      final scanner = GmailScanner(googleSignIn);
      final result = await scanner.fullScan(
        onProgress: (s, t) {
          scanScanned.value = s;
          scanTotal.value = t;
          scanStatus.value = 'Scanning emails ($s/$t)...';
        },
        onDetailedProgress: (progress) {
          scanDetail.value = progress;
          scanScanned.value = progress.scanned;
          scanTotal.value = progress.total;
        },
      );

      if (!mounted) return;
      Navigator.of(navContext).pop(); // dismiss progress

      if (result.subscriptions.isNotEmpty) {
        await showModalBottomSheet(
          context: navContext,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ScanResultSheet(detected: result.subscriptions),
        );
        ref.read(subscriptionsProvider.notifier).fetch();
      } else {
        ScaffoldMessenger.of(navContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Gmail connected, but no subscription emails matched yet.',
            ),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('[ConnectScan] Error: $e\n$stack');
      if (mounted) {
        // Show error inside the sheet instead of dismissing
        scanError.value = '$e';
        scanStatus.value = 'Scan failed';
      }
    } finally {
      scanScanned.dispose();
      scanTotal.dispose();
      scanStatus.dispose();
    }
  }

  void _manual() {
    Haptics.tap();
    ref.read(onboardingCompleteProvider.notifier).state = true;
    ref.read(authCompleteProvider.notifier).state = true;
    context.go('/home');
  }

  String _friendlyGoogleError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('gmail permission') || msg.contains('scope')) {
      return 'Gmail permission was not granted. Sign in again and approve Gmail readonly access so Driped can scan receipts.';
    }
    if (msg.contains('apiexception') ||
        msg.contains('sign_in_failed') ||
        msg.contains('12500') ||
        msg.contains('10')) {
      return 'Google Sign-In is not configured for this Android app yet. Add the Android SHA keys in Firebase, download a fresh google-services.json into android/app/, then enable Gmail API access.';
    }
    return 'Sign-in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final topGap = (constraints.maxHeight * 0.08).clamp(28.0, 72.0);
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: topGap),
                    const DripedLogo(size: 88)
                        .animate()
                        .scaleXY(
                          begin: 0.6,
                          end: 1,
                          duration: 480.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 360.ms),
                    const SizedBox(height: 26),
                    Text('Driped',
                            style: AppTypography.pageTitle.copyWith(
                                fontSize: 44,
                                color: AppColors.textHi,
                                letterSpacing: -1.5))
                        .animate()
                        .fadeIn(delay: 120.ms, duration: 320.ms)
                        .slideY(begin: 0.08, end: 0),
                    const SizedBox(height: 6),
                    Text('Stop the Drip.',
                            style: AppTypography.sectionTitle
                                .copyWith(color: AppColors.gold, fontSize: 18))
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 320.ms),
                    const SizedBox(height: 20),
                    Text(
                            'Connect Gmail and we\'ll map every subscription\n'
                            'you pay for in the next 30 seconds.',
                            style: AppTypography.body.copyWith(
                                color: AppColors.textMid, height: 1.55))
                        .animate()
                        .fadeIn(delay: 260.ms, duration: 360.ms),
                    const SizedBox(height: 36),
                    NeoButton(
                      label: _busy ? 'Signing in...' : 'Continue with Google',
                      leading: LucideIcons.mail,
                      loading: _busy,
                      onPressed: _connectGoogle,
                    ).animate().fadeIn(delay: 360.ms, duration: 320.ms).slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 340.ms,
                        curve: Curves.easeOutCubic),
                    const SizedBox(height: 10),
                    Center(
                      child: NeoButton.ghost(
                        label: "I'll add everything manually",
                        onPressed: _manual,
                        height: 44,
                      ),
                    ).animate().fadeIn(delay: 460.ms, duration: 280.ms),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          _errorMsg!,
                          style: AppTypography.micro
                              .copyWith(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.lock,
                            size: 12, color: AppColors.textLow),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'We only read subscription emails. Never stored.',
                            style: AppTypography.micro
                                .copyWith(color: AppColors.textLow),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 560.ms, duration: 320.ms),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
