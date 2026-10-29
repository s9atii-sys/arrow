import 'dart:io';

import 'package:flutter/foundation.dart';

/// Replace these with your real AdMob unit IDs before publishing.
/// Test IDs below are Google's official sample units for development.
class AdConfig {
  AdConfig._();

  static bool get adsSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    return 'ca-app-pub-6687779687898901/5222998863';
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    return 'ca-app-pub-6687779687898901/8918701293';
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    }
    return 'ca-app-pub-6687779687898901/7639736651';
  }
}
