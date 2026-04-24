import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/neo_button.dart';
import 'painters/dashboard_slide_painter.dart';
import 'painters/scan_beam_painter.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pc = PageController();
  int _page = 0;

  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  @override
  void dispose() {
    _pc.dispose();
    _scan.dispose();
    _slide.dispose();
    super.dispose();
  }

  void _next() {
    Haptics.tap();
    if (_page < 2) {
      _pc.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _skip() {
    Haptics.tap();
    _finish();
  }

  void _finish() {
    ref.read(onboardingCompleteProvider.notifier).state = true;
    context.go('/connect');
  }

  @override
  Widget build(BuildContext context) {
    const slides = <_SlideData>[
      _SlideData(
        title: 'Your money is\ndripping away.',
        subtitle:
            'Every forgotten trial. Every silent renewal.\nLittle drops that add up to thousands.',
        kind: _SlideKind.drops,
      ),
      _SlideData(
        title: 'We find every\ncharge. Automatically.',
        subtitle:
            'Driped scans your Gmail locally for\nsubscription receipts. Nothing leaves your device.',
        kind: _SlideKind.scan,
      ),
      _SlideData(
        title: "You're always\nin control.",
        subtitle:
            'Pause, cancel, budget — one tap.\nKnow exactly what you\'re paying for, always.',
        kind: _SlideKind.dashboard,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            // top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text('DRIPED',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: AppColors.gold,
                      )),
                  const Spacer(),
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMid,
                    ),
                    child: Text('Skip',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textMid)),
                  ),
                ],
              ),
            ),
            // pages
            Expanded(
              child: PageView.builder(
                controller: _pc,
                onPageChanged: (i) {
                  setState(() => _page = i);
                  Haptics.tap();
                  if (i == 2) {
                    _slide
                      ..reset()
                      ..forward();
                  }
                  if (i == 1) {
                    _scan
                      ..reset()
                      ..repeat();
                  }
                },
                itemCount: slides.length,
                itemBuilder: (_, i) => _Slide(
                  data: slides[i],
                  scan: _scan,
                  slide: _slide,
                ),
              ),
            ),
            // dots
            _Dots(count: slides.length, index: _page),
            const SizedBox(height: 22),
            // cta
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: NeoButton(
                label: _page == 2 ? 'Continue' : 'Next',
                trailing: LucideIcons.arrowRight,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SlideKind { drops, scan, dashboard }

class _SlideData {
  final String title;
  final String subtitle;
  final _SlideKind kind;
  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.kind,
  });
}

class _Slide extends StatelessWidget {
  final _SlideData data;
  final AnimationController scan;
  final AnimationController slide;
  const _Slide({
    required this.data,
    required this.scan,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    if (data.kind == _SlideKind.drops) {
      // Full-bleed background image for the first slide
      return Stack(
        fit: StackFit.expand,
        children: [
          // Edge-to-edge background image
          Positioned.fill(
            child: Image.asset(
              'assets/onboarding/money-drain-hero.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0.0, -0.3),
            ),
          ),
          // Gradient overlay so text remains readable
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.ink.withOpacity(0.3),
                    AppColors.ink.withOpacity(0.85),
                    AppColors.ink,
                  ],
                  stops: const [0.0, 0.35, 0.55, 0.72],
                ),
              ),
            ),
          ),
          // Text content pinned to bottom
          Positioned(
            left: 24,
            right: 24,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title,
                        style: AppTypography.pageTitle.copyWith(height: 1.0))
                    .animate()
                    .fadeIn(duration: 320.ms)
                    .slideY(
                        begin: 0.15,
                        end: 0,
                        duration: 420.ms,
                        curve: Curves.easeOutCubic),
                const SizedBox(height: 14),
                Text(data.subtitle,
                        style: AppTypography.body
                            .copyWith(color: AppColors.textMid, height: 1.5))
                    .animate()
                    .fadeIn(delay: 180.ms, duration: 360.ms)
                    .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 420.ms,
                        curve: Curves.easeOutCubic),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.topCenter,
              child: AspectRatio(
                aspectRatio: 1,
                child: _illustration(),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data.title,
                        style: AppTypography.pageTitle.copyWith(height: 1.0))
                    .animate()
                    .fadeIn(duration: 320.ms)
                    .slideY(
                        begin: 0.15,
                        end: 0,
                        duration: 420.ms,
                        curve: Curves.easeOutCubic),
                const SizedBox(height: 14),
                Text(data.subtitle,
                        style: AppTypography.body
                            .copyWith(color: AppColors.textMid, height: 1.5))
                    .animate()
                    .fadeIn(delay: 180.ms, duration: 360.ms)
                    .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 420.ms,
                        curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _illustration() {
    switch (data.kind) {
      case _SlideKind.drops:
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            child: SizedBox(
              width: 1180,
              height: 1180,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Image.asset(
                  'assets/onboarding/money-drain-hero.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
        );
      case _SlideKind.scan:
        return AnimatedBuilder(
          animation: scan,
          builder: (_, __) => CustomPaint(
            painter: ScanBeamPainter(t: scan.value),
          ),
        );
      case _SlideKind.dashboard:
        return AnimatedBuilder(
          animation: slide,
          builder: (_, __) => CustomPaint(
            painter: DashboardSlidePainter(t: slide.value),
          ),
        );
    }
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? AppColors.gold : AppColors.glassBorderHi,
              borderRadius: BorderRadius.circular(999),
              boxShadow: i == index
                  ? [
                      BoxShadow(
                          color: AppColors.gold.withOpacity(0.6),
                          blurRadius: 10),
                    ]
                  : null,
            ),
          ),
      ],
    );
  }
}
