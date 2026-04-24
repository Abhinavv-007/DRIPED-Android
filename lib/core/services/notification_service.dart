import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/subscription.dart';
import '../utils/currency.dart';

/// Top-level handler for notifications received while app is in background.
@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse resp) {
  // Deep-linking is handled in foreground via GoRouter.
  // Background handler simply records the tap — GoRouter picks up on resume.
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static GoRouter? _router;
  static void setRouter(GoRouter r) => _router = r;

  // ── Channels ──
  static const _renewalChannel = AndroidNotificationChannel(
    'renewals',
    'Renewal reminders',
    description: 'Upcoming subscription renewal alerts',
    importance: Importance.high,
    ledColor: Color(0xFFF5B841),
  );

  static const _trialChannel = AndroidNotificationChannel(
    'trials',
    'Trial alerts',
    description: 'Trial ending notifications',
    importance: Importance.high,
    ledColor: Color(0xFFF87171),
  );

  static const _summaryChannel = AndroidNotificationChannel(
    'summary',
    'Monthly summary',
    description: 'Monthly spending recap',
    importance: Importance.defaultImportance,
  );

  // ── Init ──
  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    // Create Android channels
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_renewalChannel);
    await androidPlugin?.createNotificationChannel(_trialChannel);
    await androidPlugin?.createNotificationChannel(_summaryChannel);

    // Request permission (Android 13+)
    await androidPlugin?.requestNotificationsPermission();
  }

  // ── Tap handler ──
  void _onTap(NotificationResponse resp) {
    if (resp.payload == null || _router == null) return;
    try {
      final data = jsonDecode(resp.payload!) as Map<String, dynamic>;
      final type = data['type'] as String?;
      switch (type) {
        case 'renewal':
          _router!.go('/subscriptions/${data['subscriptionId']}');
          break;
        case 'new_sub':
          _router!.go('/subscriptions');
          break;
        case 'summary':
          _router!.go('/analytics');
          break;
      }
    } catch (_) {}
  }

  // ── Schedule renewal ──
  Future<void> scheduleRenewal(Subscription sub, int daysAhead) async {
    if (sub.nextRenewalDate == null) return;
    final fireAt = sub.nextRenewalDate!.subtract(Duration(days: daysAhead));
    final scheduledDate = tz.TZDateTime(
      tz.local,
      fireAt.year,
      fireAt.month,
      fireAt.day,
      9,
      0,
    );
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final s = daysAhead == 1 ? '' : 's';
    final amtStr = CurrencyUtil.formatAmount(sub.amount, code: sub.currency);
    final dateStr = _fmtDate(sub.nextRenewalDate!);

    await _plugin.zonedSchedule(
      _notifId(sub.id, daysAhead),
      '${sub.serviceName} renews in $daysAhead day$s',
      '$amtStr will be charged on $dateStr',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _renewalChannel.id,
          _renewalChannel.name,
          channelDescription: _renewalChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'type': 'renewal', 'subscriptionId': sub.id}),
    );
  }

  // ── Schedule trial ending ──
  Future<void> scheduleTrialEnding(Subscription sub, int daysAhead) async {
    final endDate = sub.trialEndDate ?? sub.nextRenewalDate;
    if (endDate == null) return;
    final fireAt = endDate.subtract(Duration(days: daysAhead));
    final scheduledDate = tz.TZDateTime(
      tz.local,
      fireAt.year,
      fireAt.month,
      fireAt.day,
      9,
      0,
    );
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final amtStr = CurrencyUtil.formatAmount(sub.amount, code: sub.currency);
    final dateStr = _fmtDate(endDate);

    await _plugin.zonedSchedule(
      _notifId(sub.id, 100 + daysAhead),
      '${sub.serviceName} trial ends in $daysAhead days',
      'Cancel before $dateStr to avoid $amtStr charge',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _trialChannel.id,
          _trialChannel.name,
          channelDescription: _trialChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'type': 'renewal', 'subscriptionId': sub.id}),
    );
  }

  // ── Immediate: new sub found ──
  Future<void> showNewSubFound(String serviceName, double amount) async {
    final amtStr = CurrencyUtil.formatAmount(amount, code: 'INR');
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      'New: $serviceName detected',
      '$amtStr/mo \u2014 tap to review',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _renewalChannel.id,
          _renewalChannel.name,
          channelDescription: _renewalChannel.description,
        ),
      ),
      payload: jsonEncode({'type': 'new_sub'}),
    );
  }

  // ── Monthly summary ──
  Future<void> showMonthlySummary(double total, int count) async {
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
    final now = DateTime.now();
    final monthName = months[now.month];
    final amtStr = CurrencyUtil.formatAmount(total, code: 'INR');

    await _plugin.show(
      99999,
      '$monthName recap',
      '$amtStr across $count subscriptions',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _summaryChannel.id,
          _summaryChannel.name,
          channelDescription: _summaryChannel.description,
        ),
      ),
      payload: jsonEncode({'type': 'summary'}),
    );
  }

  // ── Cancel all for a subscription ──
  Future<void> cancelForSubscription(String subId) async {
    for (final d in [1, 3, 7, 101, 102, 103]) {
      await _plugin.cancel(_notifId(subId, d));
    }
  }

  // ── Helpers ──
  int _notifId(String subId, int variant) =>
      (subId.hashCode.abs() % 90000) + variant;

  String _fmtDate(DateTime d) {
    const m = [
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
    return '${d.day} ${m[d.month]} ${d.year}';
  }
}
