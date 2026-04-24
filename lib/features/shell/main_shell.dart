import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure currency rates are fetched at app boot, not just on profile visit
    ref.watch(currencyRatesInitProvider);
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AmbientBackdrop(),
          shell,
        ],
      ),
      bottomNavigationBar: _FloatingBottomNav(
        currentIndex: shell.currentIndex,
        onTap: (i) {
          Haptics.tap();
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
      ),
    );
  }
}

/// Plain solid background for Neumorphism
class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.pageBackground(context),
        ),
      ),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _FloatingBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = <_NavItem>[
      _NavItem(icon: LucideIcons.home, label: 'Home'),
      _NavItem(icon: LucideIcons.layers, label: 'Subs'),
      _NavItem(icon: LucideIcons.barChart3, label: 'Analytics'),
      _NavItem(icon: LucideIcons.creditCard, label: 'Payments'),
      _NavItem(icon: LucideIcons.user, label: 'Profile'),
    ];
    final safeBottom = MediaQuery.of(context).padding.bottom;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, safeBottom + 10),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.pageBackground(context),
          borderRadius: BorderRadius.circular(999),
          // Soft Neumorphism on the floating pill
          boxShadow: [
            BoxShadow(
              color: AppColors.neumorphicDark(context),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(6, 6),
            ),
            BoxShadow(
              color: AppColors.neumorphicLight(context),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(-6, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: _NavTab(
                  item: items[i],
                  active: currentIndex == i,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavTab extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _NavTab(
      {required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colour = active
        ? AppColors.gold
        : (isDark ? AppColors.textMid : AppColors.lightTextMid);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox.expand(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? AppColors.gold.withOpacity(isDark ? 0.13 : 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 21, color: colour),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.micro.copyWith(
                  color: colour,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
