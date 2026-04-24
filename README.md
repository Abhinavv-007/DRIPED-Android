# Driped Android

Flutter 3.22+ Android app for Driped V2 with **Playful Neo-Brutal + Dark** design.

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
All API calls go to the production Worker at `https://api.driped.in`.
Override via `--dart-define=WORKER_URL=http://localhost:8787` for local dev.
