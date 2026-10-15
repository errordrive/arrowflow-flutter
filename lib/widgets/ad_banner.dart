// ArrowFlow — AdMob banner (graceful no-op when ads unavailable).

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../ads.dart';
import '../state/app_state.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!Ads.instance.available) return;
    final ad = BannerAd(
      adUnitId: AdUnits.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (a, _) => a.dispose(),
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final removed = context.select<AppState, bool>((s) => s.removedAds);
    if (removed || !_loaded || _ad == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
