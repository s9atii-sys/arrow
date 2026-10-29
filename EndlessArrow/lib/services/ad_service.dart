import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Central AdMob helper: preloads ads, enforces spacing, and fails gracefully
/// so gameplay never crashes when an ad is unavailable.
class AdService {
  AdService._();
  static final instance = AdService._();

  static const _minInterstitialGap = Duration(seconds: 30);

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;
  RewardedAd? _rewardedAd;
  bool _rewardedLoading = false;
  DateTime? _lastInterstitialShown;

  bool get isReady => _initialized && AdConfig.adsSupported;

  Future<void> initialize() async {
    if (_initialized || !AdConfig.adsSupported) return;

    try {
      await MobileAds.instance.initialize().timeout(
        const Duration(seconds: 4),
      );
      _initialized = true;
      unawaited(_loadInterstitial());
      unawaited(_loadRewarded());
    } on TimeoutException {
      // SDK can keep initializing in the background; do not hold the UI.
      debugPrint('AdMob init timed out');
      _initialized = true;
      unawaited(_loadInterstitial());
      unawaited(_loadRewarded());
    } catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  BannerAd? createBannerAd({
    required void Function(BannerAd ad) onLoaded,
    void Function(LoadAdError error)? onFailed,
  }) {
    if (!isReady) return null;

    final banner = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(ad as BannerAd),
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: $error');
          ad.dispose();
          onFailed?.call(error);
        },
      ),
    );
    banner.load();
    return banner;
  }

  /// Shows an interstitial at a natural break, then runs [onComplete].
  /// Skips silently if no ad is ready or the cooldown has not elapsed.
  Future<void> showInterstitialThen(VoidCallback onComplete) async {
    if (!isReady || _interstitialAd == null || !_canShowInterstitial()) {
      onComplete();
      unawaited(_loadInterstitial());
      return;
    }

    final ad = _interstitialAd!;
    _interstitialAd = null;
    var completed = false;

    void finish() {
      if (completed) return;
      completed = true;
      ad.dispose();
      _lastInterstitialShown = DateTime.now();
      unawaited(_loadInterstitial());
      onComplete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, error) {
        debugPrint('Interstitial show failed: $error');
        finish();
      },
    );

    try {
      await ad.show();
    } catch (e) {
      debugPrint('Interstitial show error: $e');
      finish();
    }
  }

  /// Rewarded retry: returns true only when the user earns the reward.
  Future<bool> showRewardedForRetry() async {
    if (!isReady || _rewardedAd == null) {
      unawaited(_loadRewarded());
      return false;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null;
    var earned = false;
    final completer = Completer<bool>();
    var finished = false;

    void finish() {
      if (finished) return;
      finished = true;
      ad.dispose();
      unawaited(_loadRewarded());
      if (!completer.isCompleted) completer.complete(earned);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, error) {
        debugPrint('Rewarded show failed: $error');
        finish();
      },
    );

    try {
      ad.show(
        onUserEarnedReward: (_, _) => earned = true,
      );
    } catch (e) {
      debugPrint('Rewarded show error: $e');
      finish();
      return false;
    }

    return completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        finish();
        return false;
      },
    );
  }

  bool _canShowInterstitial() {
    final last = _lastInterstitialShown;
    if (last == null) return true;
    return DateTime.now().difference(last) >= _minInterstitialGap;
  }

  Future<void> _loadInterstitial() async {
    if (!isReady || _interstitialLoading || _interstitialAd != null) return;
    _interstitialLoading = true;

    await InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial load failed: $error');
          _interstitialLoading = false;
        },
      ),
    );
  }

  Future<void> _loadRewarded() async {
    if (!isReady || _rewardedLoading || _rewardedAd != null) return;
    _rewardedLoading = true;

    await RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded load failed: $error');
          _rewardedLoading = false;
        },
      ),
    );
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
  }
}
