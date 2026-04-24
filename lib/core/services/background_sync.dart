import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../api/repositories/currency_repository.dart';
import '../api/api_client.dart';
import '../models/subscription.dart';
import '../utils/currency.dart';
import '../../features/email_scanner/gmail_scanner.dart';
import '../../firebase/firebase_init.dart';
import 'notification_service.dart';

const kDailySyncTask = 'driped_daily_sync';

/// Top-level callback — runs outside of any widget tree.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    try {
      await initFirebase();

      switch (taskName) {
        case kDailySyncTask:
          await _runDailySync();
          break;
      }
    } catch (_) {}
    return true;
  });
}

Future<void> _runDailySync() async {
  // 1. Check auth
  final fbUser = FirebaseAuth.instance.currentUser;
  if (fbUser == null) return;

  // 2. Init Hive for cache access
  await Hive.initFlutter();
  final box = await Hive.openBox('driped_cache');

  // 3. Init notifications
  await NotificationService.instance.init();

  // 4. Incremental Gmail scan
  try {
    final googleSignIn = GoogleSignIn(scopes: [
      'email',
      'https://www.googleapis.com/auth/gmail.readonly',
    ]);
    final account = await googleSignIn.signInSilently();
    if (account != null) {
      final scanner = GmailScanner(googleSignIn);
      final result = await scanner.incrementalScan();

      // Show notification for each new subscription
      for (final sub in result.subscriptions) {
        await NotificationService.instance
            .showNewSubFound(sub.serviceName, sub.amount);
      }

      // Email-derived scan metadata stays local by default; no background scan
      // counts are posted to the Worker.
    }
  } catch (_) {}

  // 5. Schedule renewal notifications from cached subscriptions
  try {
    final cached = box.get('subscriptions');
    if (cached != null) {
      final list = (cached as List).map((m) {
        return Subscription.fromMap(Map<String, dynamic>.from(m));
      }).toList();

      final now = DateTime.now();
      for (final sub in list) {
        if (sub.status != SubscriptionStatus.active &&
            sub.status != SubscriptionStatus.trial) {
          continue;
        }

        // Renewal reminders
        if (sub.nextRenewalDate != null) {
          final days = sub.nextRenewalDate!.difference(now).inDays;
          if (days == 7 && sub.remind7d) {
            await NotificationService.instance.scheduleRenewal(sub, 7);
          }
          if (days == 3 && sub.remind3d) {
            await NotificationService.instance.scheduleRenewal(sub, 3);
          }
          if (days == 1 && sub.remind1d) {
            await NotificationService.instance.scheduleRenewal(sub, 1);
          }
        }

        // Trial ending
        if (sub.isTrial) {
          final trialEnd = sub.trialEndDate ?? sub.nextRenewalDate;
          if (trialEnd != null) {
            final days = trialEnd.difference(now).inDays;
            if (days <= 3 && days > 0) {
              await NotificationService.instance.scheduleTrialEnding(sub, days);
            }
          }
        }
      }

      // 6. Monthly summary on 1st
      if (now.day == 1) {
        double total = 0;
        int count = 0;
        for (final s in list) {
          if (s.status == SubscriptionStatus.active ||
              s.status == SubscriptionStatus.trial) {
            total += s.billingCycle
                .toMonthly(CurrencyUtil.convert(s.amount, s.currency, 'INR'));
            count++;
          }
        }
        await NotificationService.instance.showMonthlySummary(total, count);
      }
    }
  } catch (_) {}

  // 7. Refresh currency rates if stale
  try {
    final lastUpdate = box.get('currency_rates_updated_at');
    final stale = lastUpdate == null ||
        DateTime.now()
                .difference(DateTime.parse(lastUpdate.toString()))
                .inHours >=
            23;
    if (stale) {
      final client = ApiClient();
      final currencyRepo = CurrencyRepository(client, box);
      await currencyRepo.getRates();
    }
  } catch (_) {}
}
