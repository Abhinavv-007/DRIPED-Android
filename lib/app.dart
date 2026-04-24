import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/models/app_user.dart';
import 'core/providers/data_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';

/// Theme mode — toggled from profile.
const _themeModeKey = 'ui.theme_mode';
const _onboardingCompleteCacheKey = 'launch.onboarding_complete';
const _authCompleteCacheKey = 'launch.auth_complete';

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final value =
      Hive.box('driped_cache').get(_themeModeKey, defaultValue: 'dark') as String;
  return value == 'light' ? ThemeMode.light : ThemeMode.dark;
});

/// Firebase auth state stream exposed via Riverpod.
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class DripedApp extends ConsumerStatefulWidget {
  const DripedApp({super.key});

  @override
  ConsumerState<DripedApp> createState() => _DripedAppState();
}

class _DripedAppState extends ConsumerState<DripedApp> {
  @override
  void initState() {
    super.initState();

    // Override default error widget so errors are visible on dark backgrounds
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF331111),
          border: Border.all(color: const Color(0xFFFF4444), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ Widget Error',
                style: TextStyle(
                    color: Color(0xFFFF6644),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              details.exceptionAsString(),
              style: const TextStyle(
                  color: Color(0xFFFFAAAA), fontSize: 12, height: 1.4),
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    };

    // Bootstrap: restore auth for signed-in Firebase users.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        ref.read(authCompleteProvider.notifier).state = true;

        // 1. Immediately populate with Firebase data so UI shows name/avatar
        final cached = ref.read(userRepoProvider).getCachedUser();
        if (cached.data != null) {
          ref.read(currentUserProvider.notifier).state = cached.data!;
        } else if (user.displayName != null || user.email != null) {
          ref.read(currentUserProvider.notifier).state = AppUser(
            id: user.uid,
            email: user.email ?? '',
            fullName: user.displayName ?? '',
            avatarUrl: user.photoURL,
            currency: 'INR',
            createdAt: DateTime.now(),
          );
        }

        // 2. Then re-sync with backend in the background to get latest data
        final repo = ref.read(userRepoProvider);
        final result = await repo.syncUser(
          email: user.email ?? '',
          fullName: user.displayName,
          avatarUrl: user.photoURL,
        );
        result.when(
          success: (synced) =>
              ref.read(currentUserProvider.notifier).state = synced,
          failure: (_) {}, // keep local data if sync fails
        );
      });
    }
    // Init currency rates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currencyRatesInitProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode != ThemeMode.light;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    // Listen to auth state — redirect on sign-out
    ref.listen<AsyncValue<User?>>(firebaseAuthStateProvider, (prev, next) {
      next.whenData((user) {
        if (user == null && prev?.valueOrNull != null) {
          ref.read(authCompleteProvider.notifier).state = false;
        }
      });
    });
    ref.listen<ThemeMode>(themeModeProvider, (_, next) {
      Hive.box('driped_cache')
          .put(_themeModeKey, next == ThemeMode.light ? 'light' : 'dark');
    });
    ref.listen<bool>(onboardingCompleteProvider, (_, next) {
      Hive.box('driped_cache').put(_onboardingCompleteCacheKey, next);
    });
    ref.listen<bool>(authCompleteProvider, (_, next) {
      Hive.box('driped_cache').put(_authCompleteCacheKey, next);
    });

    final router = ref.watch(routerProvider);
    // Wire notification deep-linking to router
    NotificationService.setRouter(router);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Driped',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
