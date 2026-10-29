import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Store and web links used by Settings. Replace before publishing.
class AppLinks {
  AppLinks._();

  static const androidPackage = 'com.arrowchallenge.game';

  /// App Store numeric ID. Leave empty until the iOS app is published.
  static const iosAppId = '';

  static Uri get rateUsUri {
    if (!kIsWeb && Platform.isIOS && iosAppId.isNotEmpty) {
      return Uri.parse(
        'https://apps.apple.com/app/id$iosAppId?action=write-review',
      );
    }
    return Uri.parse(
      'https://play.google.com/store/apps/details?id=$androidPackage',
    );
  }

  static Future<bool> openRateUs() => _open(rateUsUri);

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
