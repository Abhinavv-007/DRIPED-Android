import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_card.dart';

class ProfileInfoScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<InfoSection> sections;

  const ProfileInfoScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  factory ProfileInfoScreen.help() {
    return const ProfileInfoScreen(
      title: 'Help & feedback',
      subtitle: 'How Driped works, what Gmail scan reads, and where to send issues.',
      sections: [
        InfoSection(
          heading: 'What Driped tracks',
          body:
              'Driped keeps a personal list of subscriptions, payment methods, renewal dates, reminders, and category totals so you can understand recurring spend in one place.',
        ),
        InfoSection(
          heading: 'How Gmail scan works',
          body:
              'When you connect Gmail, the app requests read-only Gmail access and scans receipt-like messages for subscription senders, amounts, billing cycles, and renewal dates. The goal is detection, not inbox storage.',
        ),
        InfoSection(
          heading: 'Need help or found a bug?',
          body:
              'Use the latest app build, reproduce the issue once, and capture the exact screen or error text. That is the fastest path to fixing broken flows like sign-in, scan parsing, or payment mapping.',
        ),
      ],
    );
  }

  factory ProfileInfoScreen.privacy() {
    return const ProfileInfoScreen(
      title: 'Privacy policy',
      subtitle: 'A short plain-language view of what Driped stores and why.',
      sections: [
        InfoSection(
          heading: 'Account data',
          body:
              'Driped stores your profile basics, preferred currency, subscriptions, payment methods, and settings so the dashboard, reminders, and analytics can work.',
        ),
        InfoSection(
          heading: 'Gmail access',
          body:
              'If you connect Gmail, the app requests read-only access for subscription discovery. It is intended to inspect receipt and billing emails so the app can suggest subscriptions to track.',
        ),
        InfoSection(
          heading: 'What is not needed',
          body:
              'The app does not need permission to send email, delete messages, or change mailbox settings. Payment methods are tracked for organization and spend mapping, not transaction processing.',
        ),
      ],
    );
  }

  factory ProfileInfoScreen.terms() {
    return const ProfileInfoScreen(
      title: 'Terms of service',
      subtitle: 'Plain-language usage rules for the current Driped build.',
      sections: [
        InfoSection(
          heading: 'Personal tracking only',
          body:
              'Driped is designed for personal subscription tracking, reminders, and analysis. You are responsible for the accuracy of the subscriptions, payment methods, and notes you add.',
        ),
        InfoSection(
          heading: 'Connected services',
          body:
              'If you connect Gmail, the app depends on Google sign-in and Gmail API access that you authorize separately. Those providers can limit, revoke, or rate-limit access independently of the app.',
        ),
        InfoSection(
          heading: 'Planning, not payments',
          body:
              'Driped helps you organize recurring charges, but it does not execute card payments, cancel subscriptions for you, or guarantee that a merchant will stop billing after you change a reminder or status.',
        ),
      ],
    );
  }

  factory ProfileInfoScreen.versionHistory() {
    return const ProfileInfoScreen(
      title: 'Version history',
      subtitle: 'Milestone history of the current Driped build line up to today.',
      sections: [
        InfoSection(
          heading: 'v1.0.0 · Current build',
          body:
              'Stabilized Android device builds, refreshed onboarding, added support pages, tightened payment-method setup, and cleaned the app for the latest test run.',
        ),
        InfoSection(
          heading: 'v0.9.0 · Dashboard and profile pass',
          body:
              'Reworked the home overview, improved light mode, added currency refresh handling, and made profile preferences and Gmail scan states clearer.',
        ),
        InfoSection(
          heading: 'v0.8.0 · Brand and icon system',
          body:
              'Switched the app to a larger branded icon set, added resolver logic for services and payment methods, and normalized inconsistent logo alignment.',
        ),
        InfoSection(
          heading: 'v0.7.0 · Payments and subscriptions',
          body:
              'Fixed add/edit flows, optimistic local persistence, reminder behavior, and empty-state CTA behavior across subscriptions and payment methods.',
        ),
        InfoSection(
          heading: 'v0.6.0 · Gmail scan and Google auth prep',
          body:
              'Wired Gmail scan, clarified Google sign-in requirements, and aligned the app with Firebase plus Gmail API setup for future live scans.',
        ),
        InfoSection(
          heading: 'v0.5.0 · Currency sync',
          body:
              'Added exchange-rate caching, preference switching, worker-side refresh logic, and daily update scheduling support for user currency conversions.',
        ),
        InfoSection(
          heading: 'v0.4.0 · Analytics and tracking model',
          body:
              'Improved category tracking, active versus paused subscription views, spend rollups, and linked payment-to-subscription relationships.',
        ),
        InfoSection(
          heading: 'v0.3.0 · Onboarding and startup fixes',
          body:
              'Fixed onboarding progression, stopped the app from relaunching the tutorial every time, and moved blocking startup work out of the first frame path.',
        ),
        InfoSection(
          heading: 'v0.2.0 · Android wrapper recovery',
          body:
              'Restored missing Android entrypoints, aligned Gradle and plugin compatibility, and brought the Flutter Android shell back to a runnable state in Android Studio.',
        ),
        InfoSection(
          heading: 'v0.1.0 · Core Driped concept',
          body:
              'Initial Flutter subscription-tracking shell with Home, Subs, Analytics, Payments, and Profile surfaces.',
        ),
      ],
    );
  }

  factory ProfileInfoScreen.about() {
    return const ProfileInfoScreen(
      title: 'About Driped',
      subtitle: 'Current build notes for the Android app, in the same spirit as a product readme.',
      sections: [
        InfoSection(
          heading: 'Current release',
          body:
              'Version 1.0.0+1 for package com.abhnv.driped. This build is aimed at direct Android device testing with Flutter on the client and a Cloudflare Worker backend.',
        ),
        InfoSection(
          heading: 'What the app includes',
          body:
              'Home dashboard, subscriptions, analytics, payment methods, profile preferences, Gmail scan entry, local persistence, currency switching, reminders, and branded icon mapping.',
        ),
        InfoSection(
          heading: 'Runtime dependencies',
          body:
              'Firebase Authentication for sign-in, Google Gmail API for inbox-based subscription detection, a Cloudflare Worker API for app data, and ExchangeRate-API for currency conversion refresh.',
        ),
        InfoSection(
          heading: 'Build philosophy',
          body:
              'The current direction is Android-first polish: direct installable APKs, clean onboarding, readable light and dark themes, and manual control over subscriptions and payment rails in one place.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);

    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textColor,
        title: Text(
          title,
          style: AppTypography.sectionTitle.copyWith(color: textColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            subtitle,
            style: AppTypography.body.copyWith(color: subColor),
          ),
          const SizedBox(height: 18),
          for (final section in sections) ...[
            GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.35),
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.fileText,
                          size: 14,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          section.heading,
                          style: AppTypography.cardTitle
                              .copyWith(color: textColor, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    section.body,
                    style: AppTypography.body.copyWith(color: subColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class InfoSection {
  final String heading;
  final String body;

  const InfoSection({
    required this.heading,
    required this.body,
  });
}
