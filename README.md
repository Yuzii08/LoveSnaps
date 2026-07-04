# LoveSnaps 💕

A cross-platform Flutter app for couples with real OS home-screen widgets.

## Features

| Feature | Description |
|---|---|
| **Days Together** | Counts every day since your start date, detects milestones |
| **Streak** | Shared flame streak — both tap daily to keep it alive |
| **Distance / Miss You** | Live GPS distance or manual toggle + one-tap nudge |
| **Home-Screen Widget** | Small (streak + days) and Medium (+ distance + Miss You button) |
| **Push Notifications** | Milestones, miss-you nudges, monthly anniversaries |

## Tech Stack

- **Frontend**: Flutter (Dart) + Riverpod + GoRouter
- **Native Widgets**: Kotlin/RemoteViews (Android) + SwiftUI/WidgetKit (iOS)
- **Widget Bridge**: `home_widget` package
- **Backend**: Firebase (Auth, Firestore, Cloud Messaging)
- **Cloud Functions**: Node.js 20

---

## Getting Started

### 1. Install Flutter

```bash
# Follow the official guide for your OS:
# https://flutter.dev/docs/get-started/install/windows
```

### 2. Create a Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project: `lovesnaps`
3. Enable **Authentication** → Email/Password
4. Enable **Firestore** (start in test mode, then apply `firebase/firestore.rules`)
5. Enable **Cloud Messaging**

### 3. Configure FlutterFire

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# In project root — follow the prompts, select Android + iOS
flutterfire configure
```

This auto-generates `lib/firebase_options.dart` with your real credentials.

### 4. Android Setup

1. In `android/app/build.gradle`, ensure `applicationId = "com.lovesnaps.app"`
2. Register widget receivers in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Inside <application> -->
<receiver android:name=".LoveSnapWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/love_snap_widget_small_info" />
</receiver>

<receiver android:name=".LoveMediumWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/love_snap_widget_medium_info" />
</receiver>
```

3. Add widget drawable backgrounds in `android/app/src/main/res/drawable/`:
   - `widget_background_small.xml` — rounded rect, blush fill
   - `widget_background_medium.xml` — rounded rect, cream fill
   - `miss_you_button_bg.xml` — blush-light pill shape

### 5. iOS Setup (requires macOS + Xcode)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Add a **Widget Extension** target named `LoveSnapsWidget`
3. Replace the generated Swift file with `ios/LoveSnapsWidget/LoveSnapsWidget.swift`
4. In **Signing & Capabilities** for BOTH the Runner and Widget targets:
   - Add **App Groups** → `group.com.lovesnaps.app`
5. In **Runner** target: add a **URL Scheme**: `lovesnaps`

### 6. Install Dependencies & Run

```bash
flutter pub get
flutter run
```

### 7. Deploy Firebase

```bash
# Deploy Firestore rules and indexes
firebase deploy --only firestore

# Deploy Cloud Functions
cd firebase/functions
npm install
cd ../..
firebase deploy --only functions
```

---

## Project Structure

```
lib/
├── main.dart              # App entry + Firebase init + widget callback
├── app.dart               # MaterialApp + GoRouter
├── core/
│   ├── theme.dart         # Warm palette, Nunito typography
│   └── constants.dart     # Widget keys, collection names, deep links
├── models/
│   ├── user_model.dart
│   └── couple_model.dart  # Computed days, milestones, check-in state
├── services/
│   ├── auth_service.dart
│   ├── couple_service.dart    # Pairing, invite codes, miss you
│   ├── streak_service.dart    # Daily check-in + at-risk logic
│   ├── location_service.dart  # GPS + Haversine distance
│   ├── notification_service.dart (FCM + local)
│   └── widget_service.dart    # home_widget bridge
├── screens/
│   ├── onboarding/ (5 screens)
│   └── home/
│       ├── home_screen.dart   # Today dashboard
│       └── settings_screen.dart
└── widgets/               # Flutter UI cards
    ├── days_card.dart
    ├── streak_card.dart
    └── distance_card.dart

android/app/src/main/
├── kotlin/.../
│   ├── LoveSnapWidgetProvider.kt   # Small widget
│   └── LoveMediumWidgetProvider.kt # Medium widget
└── res/
    ├── layout/ (2 XML layouts)
    └── xml/ (2 widget info XMLs)

ios/LoveSnapsWidget/
├── LoveSnapsWidget.swift    # SwiftUI timeline + views
└── Info.plist

firebase/
├── firestore.rules
├── firestore.indexes.json
└── functions/index.js       # 4 Cloud Functions
```

---

## Widget Data Flow

```
Flutter App (Dart)
    │
    ▼ HomeWidget.saveWidgetData() — writes to App Group UserDefaults / SharedPrefs
    │
    ▼ HomeWidget.updateWidget() — triggers OS redraw
    │
    ├── Android: LoveSnapWidgetProvider reads SharedPrefs → RemoteViews → home screen
    └── iOS:    LoveSnapProvider reads UserDefaults → SwiftUI view → home screen
```

## Streak Logic

```
Both partners open app + tap "Check In" on the same calendar day
    → Firestore transaction sets both checkIn flags = true
    → streakCount incremented atomically
    → If missed a full day → nightly Cloud Function resets streak to 0
```

## Privacy

- Location: only the **most recent lat/lng** per partner is stored in Firestore. No history.
- Location is updated at most every 20 minutes and only when the app is foregrounded.
- Location sharing is completely opt-in; falls back to manual toggle if denied.

---

## Roadmap (Post-MVP)

- [ ] In-app photo sharing / love notes
- [ ] Animated widget themes (seasonal)
- [ ] Shared journal / memory timeline
- [ ] Apple Watch complication
