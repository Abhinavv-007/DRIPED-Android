# Driped Android

Flutter 3.22+ Android app for Driped V2 with **Playful Neo-Brutal + Dark** design.

## One-time setup
Two assets are kept out of git (see `.gitignore`). Pull them down before your first build:

```bash
# 1. Firebase Android config. Download from Firebase Console
#    (Project Settings \u2192 Your apps \u2192 Android) and save as:
#    android/app/google-services.json
#    \u2014 template: android/app/google-services.json.example

# 2. LiteRT-LM model weights (~270 MB) for the on-device Gmail scanner.
bash scripts/download_local_ai_model.sh
```

## Quick start
```bash
flutter pub get
flutter run
```

## Features
- Firebase Auth (Google Sign-In) \u2014 same account as web
- Gmail scanning \u2014 on-device LiteRT-LM AI + shared regex pipeline
- Workmanager daily sync + local renewal notifications
- Savings / Forecast / Receipt Locker screens
- Shared Neo design tokens via `packages/driped_neo`

## Backend
API calls resolve to `https://api.driped.in` in release builds by default.
For local development override via:

```bash
flutter run --dart-define=WORKER_URL=http://10.0.2.2:8787
```

(`10.0.2.2` is the Android emulator alias for the host machine's localhost.)

## Release APK
```bash
flutter build apk --release --dart-define=WORKER_URL=https://api.driped.in
```

Artifact lands at `build/app/outputs/flutter-apk/app-release.apk`. The
`.github/workflows/android-build.yml` workflow builds it on every tag push.
