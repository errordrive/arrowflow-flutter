// ArrowFlow — AdMob wrapper (Google test IDs until real IDs are configured).
// Every call degrades gracefully when ads are unavailable.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Google's official test IDs — replace with real unit IDs before release.
class AdUnits {
  static const banner = 'ca-app-pub-3940256099942544/6300978111';
  static const interstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const rewarded = 'ca-app-pub-3940256099942544/5224354917';
}

class Ads {
  Ads._();
  static final Ads instance = Ads._();

  bool _ready = false;
  bool removedAds = false;
  int _completionsSinceInterstitial = 0;

  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      _ready = true;
    } catch (e) {
      debugPrint('ads init failed: $e');
      _ready = false;
    }
  }

  bool get available => _ready && !removedAds;

  /// Maybe show an interstitial after a level completion.
  /// At most every 3 completions, never in the first 5 levels.
  Future<void> maybeShowInterstitial(int level) async {
    if (!available || level <= 5) return;
    _completionsSinceInterstitial++;
    if (_completionsSinceInterstitial < 3) return;
    _completionsSinceInterstitial = 0;
    try {
      await InterstitialAd.load(
        adUnitId: AdUnits.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (a) => a.dispose(),
              onAdFailedToShowFullScreenContent: (a, _) => a.dispose(),
            );
            ad.show();
          },
          onAdFailedToLoad: (_) {},
        ),
      );
    } catch (e) {
      debugPrint('interstitial failed: $e');
    }
  }

  /// Show a rewarded ad. Resolves true if the user earned the reward.
  Future<bool> showRewarded() async {
    if (!available) return false;
    try {
      final completer = Completer<bool>();
      await RewardedAd.load(
        adUnitId: AdUnits.rewarded,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            bool earned = false;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (a) {
                a.dispose();
                if (!completer.isCompleted) completer.complete(earned);
              },
              onAdFailedToShowFullScreenContent: (a, _) {
                a.dispose();
                if (!completer.isCompleted) completer.complete(false);
              },
            );
            ad.show(
              onUserEarnedReward: (_, __) {
                earned = true;
              },
            );
          },
          onAdFailedToLoad: (_) {
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );
      return await completer.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () => false,
      );
    } catch (e) {
      debugPrint('rewarded failed: $e');
      return false;
    }
  }
}
