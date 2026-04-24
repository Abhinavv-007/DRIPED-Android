import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/analytics/analytics_screen.dart';
import '../../features/auth/connect_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/categories/category_detail_screen.dart';
import '../../features/forecast/forecast_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/payment_methods/payment_method_detail_screen.dart';
import '../../features/payment_methods/payment_methods_screen.dart';
import '../../features/profile/profile_info_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/savings/savings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/subscriptions/subscription_detail_screen.dart';
import '../../features/subscriptions/subscriptions_list_screen.dart';

/// Launch state — set once on boot so the router can redirect.
const _onboardingCompleteKey = 'launch.onboarding_complete';
const _authCompleteKey = 'launch.auth_complete';

final onboardingCompleteProvider = StateProvider<bool>((ref) {
  return Hive.box('driped_cache')
      .get(_onboardingCompleteKey, defaultValue: false) as bool;
});
final authCompleteProvider = StateProvider<bool>((ref) {
  return Hive.box('driped_cache')
      .get(_authCompleteKey, defaultValue: false) as bool;
});

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final onboarded = ref.read(onboardingCompleteProvider);
      final signedIn = ref.read(authCompleteProvider);
      final loc = state.matchedLocation;

      final isAuthRoute =
          loc.startsWith('/onboarding') || loc.startsWith('/connect');

      if (!onboarded && loc != '/onboarding') return '/onboarding';
      if (onboarded && !signedIn && loc != '/connect') return '/connect';
      if (signedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, s) => const NoTransitionPage(child: OnboardingScreen()),
      ),
      GoRoute(
        path: '/connect',
        pageBuilder: (_, s) => const NoTransitionPage(child: ConnectScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          // ── Home ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          // ── Subscriptions ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subscriptions',
                pageBuilder: (_, s) => const NoTransitionPage(
                  child: SubscriptionsListScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (_, s) => MaterialPage(
                      child: SubscriptionDetailScreen(
                        subscriptionId: s.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // ── Analytics ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: AnalyticsScreen()),
              ),
            ],
          ),
          // ── Payments ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/payments',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: PaymentMethodsScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (_, s) => MaterialPage(
                      child: PaymentMethodDetailScreen(
                        paymentMethodId: s.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // ── Profile ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: ProfileScreen()),
                routes: [
                  GoRoute(
                    path: 'help',
                    pageBuilder: (_, s) =>
                        MaterialPage(child: ProfileInfoScreen.help()),
                  ),
                  GoRoute(
                    path: 'terms',
                    pageBuilder: (_, s) =>
                        MaterialPage(child: ProfileInfoScreen.terms()),
                  ),
                  GoRoute(
                    path: 'history',
                    pageBuilder: (_, s) =>
                        MaterialPage(child: ProfileInfoScreen.versionHistory()),
                  ),
                  GoRoute(
                    path: 'about',
                    pageBuilder: (_, s) =>
                        MaterialPage(child: ProfileInfoScreen.about()),
                  ),
                  GoRoute(
                    path: 'privacy',
                    pageBuilder: (_, s) =>
                        MaterialPage(child: ProfileInfoScreen.privacy()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // ── categories (outside shell, pushed via navigation) ──
      GoRoute(
        path: '/categories',
        pageBuilder: (_, s) => const MaterialPage(child: CategoriesScreen()),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (_, s) => MaterialPage(
              child: CategoryDetailScreen(categoryId: s.pathParameters['id']!),
            ),
          ),
        ],
      ),
      // ── savings (outside shell, pushed) ──
      GoRoute(
        path: '/savings',
        pageBuilder: (_, s) => const MaterialPage(child: SavingsScreen()),
      ),
      // ── forecast (outside shell, pushed) ──
      GoRoute(
        path: '/forecast',
        pageBuilder: (_, s) => const MaterialPage(child: ForecastScreen()),
      ),
    ],
  );
});
