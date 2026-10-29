import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

/// Bottom banner that collapses to zero height if the ad fails to load.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = AdService.instance.createBannerAd(
      onLoaded: (ad) {
        if (!mounted) return;
        setState(() {
          _bannerAd = ad;
          _loaded = true;
        });
      },
      onFailed: (_) {
        if (!mounted) return;
        setState(() => _loaded = false);
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final height = _bannerAd!.size.height.toDouble();
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Center(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: height,
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
