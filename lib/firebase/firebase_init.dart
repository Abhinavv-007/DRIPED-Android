import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Phase A: minimal init — no FirebaseOptions file yet.
/// On Android, Firebase.initializeApp() reads google-services.json
/// automatically at build time via the google-services Gradle plugin.
/// Phase C swaps in flutterfire_cli generated DefaultFirebaseOptions.
Future<void> initFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Firebase init skipped: $e');
      debugPrint('$st');
    }
  }
}
