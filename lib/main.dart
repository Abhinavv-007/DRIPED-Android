import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/services/background_sync.dart';
import 'core/services/notification_service.dart';
import 'core/utils/brand_asset_resolver.dart';
import 'firebase/firebase_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  try {
    await Hive.initFlutter();
    await Hive.openBox('driped_cache');
    await initFirebase();
    await BrandAssetResolver.preload();
    runApp(const ProviderScope(child: DripedApp()));
  } catch (e, stack) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Text(
              'FATAL LAUNCH ERROR:\n$e\n\n$stack',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    ));
  }

  unawaited(_warmStartupServices());
}

Future<void> _warmStartupServices() async {
  try {
    await NotificationService.instance.init();
  } catch (_) {}

  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      kDailySyncTask,
      kDailySyncTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (_) {}
}
