# Arrow Challenge

**Arrow Challenge** is a Flutter puzzle game where players tap winding arrow paths on a board and slide them out in the direction they point. Clear every arrow before the timer runs out, avoid blocked moves, and progress through hundreds of procedurally generated levels.

Built with **Flutter**, **Flame**, and **Google AdMob**.

---

## Introduction

Each level is a dense maze of interlocking arrow snakes on a white game board. An arrow can only leave the board when its entire exit path is free. Most arrows look movable but are blocked — you must find the right order to clear the board.

The game includes a splash screen, menu, level select, timed gameplay, hearts, sound effects, and monetization through AdMob.

---



## Features

- **420+ levels** — procedurally generated, always solvable
- **Winding arrow snakes** — multi-cell paths with mixed directions
- **Countdown timer** — budget scales with each level's arrow count (estimated finish time), tightening per-arrow at higher levels
- **3 hearts per level** — wrong moves shake the board and cost a heart
- **Swipe sound** on successful moves
- **Progress saving** — unlocked levels and star ratings (SharedPreferences)
- **Splash screen** — logo, random tips, animated loading bar
- **Pastel UI** — cartoon logo, wooden-style controls, chunky buttons
- **Google AdMob**
  - Banner on menu screen
  - Interstitial before starting a level (Play or level select)
  - Rewarded video to retry after Time's Up / Out of Hearts
- **Cross-platform** — Android and iOS (ads require a real device)

---



## Requirements


| Requirement | Version                           |
| ----------- | --------------------------------- |
| Flutter SDK | 3.x+                              |
| Dart SDK    | ^3.12.2                           |
| Android     | API 21+ (for AdMob)               |
| iOS         | 13.0+                             |
| IDE         | Android Studio / VS Code / Cursor |


**For ads:** a physical Android or iOS device (ads do not show in desktop/web tests).

---



## How to Run

The Flutter project is **not nested**. After unzipping the package, `pubspec.yaml` is directly inside `Source-Code/`.

### 1. Open the project

```bash
# From the unzipped package
cd Source-Code

# Install dependencies
flutter pub get
```

If you cloned the Git repository instead:

```bash
cd arrow_challenge
flutter pub get
```

### 2. Run on a device or emulator

```bash
# List devices
flutter devices

# Run (debug)
flutter run

# Run release (recommended for ad testing)
flutter run --release
```



### 3. Run tests

```bash
dart analyze lib test
flutter test
```



### 4. Verify level generation (optional)

```bash
dart run tool/check_levels.dart
dart run tool/render_level.dart
```

---



## How to Play

1. **Splash** — wait for loading, read the tip, then enter the menu.
2. **Play** — tap **PLAY** to continue your current level, or **LEVELS** to pick a level.
3. **Goal** — remove every arrow from the board before the timer hits `0:00`.
4. **Tap an arrow** — if its path to the board edge is clear, it slides out with a swipe sound.
5. **Blocked move** — the board shakes, you lose a heart, and the arrow stays.
6. **Hearts** — you have 3 per level. At 0 hearts, the level fails.
7. **Timer** — shown below the hearts. Running out of time fails the level.
8. **Retry** — watch a rewarded ad to try again (Time's Up / Out of Hearts).
9. **Win** — clear the board in time to earn stars and unlock the next level.

---



## Project Structure

```
arrow_challenge/
├── lib/
│   ├── main.dart                 # App entry, AdMob + audio init
│   ├── game/
│   │   └── arrow_challenge_game.dart   # Flame board, arrows, animations
│   ├── logic/
│   │   └── puzzle_engine.dart          # Move rules, solvability
│   ├── models/
│   │   ├── direction.dart
│   │   └── level.dart                  # Level + timer config
│   ├── levels/
│   │   ├── level_repository.dart       # Cached access to 420 levels
│   │   ├── puzzle_difficulty.dart      # Progressive difficulty bands
│   │   ├── puzzle_shape.dart           # Geometric shape library
│   │   ├── puzzle_generator.dart       # Solvable shape-based generator
│   │   └── puzzle_validator.dart       # Solvability checker
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── menu_screen.dart
│   │   ├── level_select_screen.dart
│   │   ├── game_screen.dart
│   │   └── victory_screen.dart
│   ├── services/
│   │   ├── ad_config.dart              # AdMob unit IDs
│   │   ├── ad_service.dart             # Banner / interstitial / rewarded
│   │   ├── progress_service.dart       # Saves, stars, unlocks
│   │   └── sfx_service.dart            # Swipe sound
│   └── widgets/
│       ├── common_widgets.dart         # Theme, logo, buttons, dialogs
│       └── banner_ad_widget.dart
├── assets/
│   ├── audio/swipe.wav
│   └── images/app_logo.png
├── android/                          # Android manifest + AdMob App ID
├── ios/                              # Info.plist + AdMob App ID
├── test/widget_test.dart
└── tool/
    ├── check_levels.dart             # Solvability checker
    └── render_level.dart             # ASCII level preview
```

---



## Ads Setup (Google AdMob)

The project uses **Google test ad units** by default. Replace them before publishing to the Play Store or App Store.

### Step 1 — Create AdMob account and app

1. Go to [Google AdMob](https://admob.google.com/).
2. Register your Android and iOS apps.
3. Create ad units: **Banner**, **Interstitial**, **Rewarded**.



### Step 2 — Replace ad unit IDs

Edit `lib/services/ad_config.dart`:

```dart
static String get bannerAdUnitId => 'ca-app-pub-XXXXXXXX/YYYYYYYYYY';
static String get interstitialAdUnitId => 'ca-app-pub-XXXXXXXX/YYYYYYYYYY';
static String get rewardedAdUnitId => 'ca-app-pub-XXXXXXXX/YYYYYYYYYY';
```



### Step 3 — Replace App IDs

**Android** — `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXX~YYYYYYYYYY"/>
```

**iOS** — `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXX~YYYYYYYYYY</string>
```



### Ad placement summary


| Ad type      | Trigger                      | File                                           |
| ------------ | ---------------------------- | ---------------------------------------------- |
| Banner       | Menu screen bottom           | `menu_screen.dart`                             |
| Interstitial | Play button / level tile tap | `menu_screen.dart`, `level_select_screen.dart` |
| Rewarded     | Watch & Retry dialogs        | `game_screen.dart`                             |




### Policy notes

- Interstitials only show at natural breaks (before a level starts), with a 30s cooldown.
- Rewarded retries require the user to **complete** the video; closing early does not grant a retry.
- Banners collapse silently if they fail to load.
- Do **not** click your own production ads — use test IDs during development.

Docs: [AdMob Flutter guide](https://developers.google.com/admob/flutter/quick-start)

---



## Customization



### Timer per level

Edit `lib/models/level.dart` → `LevelTimeLimit`:

```dart
static const _maxSeconds = 20;  // Level 1
static const _minSeconds = 15;  // Level 420 floor
static const _lastLevel = 420;
```



### Level difficulty / board size

Edit difficulty bands in `lib/levels/puzzle_difficulty.dart`. Shape catalog lives in `lib/levels/puzzle_shape.dart`.

### Hearts per level

Change `_maxHearts` in `lib/screens/game_screen.dart`.

### Splash tips

Edit the `_tips` list in `lib/screens/splash_screen.dart`.

### UI theme colors

Edit `AppTheme` in `lib/widgets/common_widgets.dart`.

### Swipe sound

Replace `assets/audio/swipe.wav` (keep the same path; listed in `pubspec.yaml`).

### App icon

Replace `assets/images/app_logo.png`, then run:

```bash
dart run icons_launcher:create
```

---



## Tech Stack

- [Flutter](https://flutter.dev)
- [Flame](https://flame-engine.org) — game board rendering
- [google_mobile_ads](https://pub.dev/packages/google_mobile_ads) — AdMob
- [audioplayers](https://pub.dev/packages/audioplayers) — sound effects
- [shared_preferences](https://pub.dev/packages/shared_preferences) — progress
- [google_fonts](https://pub.dev/packages/google_fonts) — Fredoka, Luckiest Guy

---



## Build for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires Mac + Xcode)
# Select your Apple Development Team in Xcode first
# (Signing & Capabilities → Team). DEVELOPMENT_TEAM ships empty.
flutter build ios --release
```

---

