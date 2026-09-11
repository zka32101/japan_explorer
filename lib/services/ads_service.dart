import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google's official test ad unit IDs. Swap these for the real AdMob unit
/// IDs (https://apps.admob.com) before a release build — using test IDs in
/// production returns no fill, and using real IDs in debug risks invalid
/// traffic flags on the AdMob account.
class AdUnitIds {
  AdUnitIds._();

  static String get banner => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get interstitial => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';
}

/// Wraps the Google Mobile Ads SDK: init, banner creation, and interstitial
/// load/show with a minimum-gap frequency cap so ads never fire back-to-back.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;
  DateTime? _lastInterstitialShownAt;

  /// Minimum time between interstitials, regardless of how often
  /// [maybeShowInterstitial] is called.
  static const _minGapBetweenInterstitials = Duration(minutes: 3);

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    if (kDebugMode) {
      // Route test-device ads only — avoids polluting real AdMob metrics
      // and reduces risk of accidental invalid-click flags during dev.
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: <String>[]),
      );
    }
    _initialized = true;
    _preloadInterstitial();
  }

  BannerAd createBannerAd({required void Function() onAdLoaded}) {
    final ad = BannerAd(
      adUnitId: AdUnitIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onAdLoaded(),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    ad.load();
    return ad;
  }

  void _preloadInterstitial() {
    if (_interstitialLoading || _interstitialAd != null) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
        },
        onAdFailedToLoad: (_) {
          _interstitialLoading = false;
        },
      ),
    );
  }

  /// Shows a preloaded interstitial if one is ready AND the minimum gap
  /// since the last one has elapsed. No-op (silently) for premium users,
  /// or if no ad is preloaded yet — callers don't need to check readiness
  /// themselves, just pass the caller's current premium status.
  Future<void> maybeShowInterstitial({required bool isPremium}) async {
    if (isPremium) return;

    final ad = _interstitialAd;
    if (ad == null) {
      _preloadInterstitial();
      return;
    }
    final last = _lastInterstitialShownAt;
    if (last != null &&
        DateTime.now().difference(last) < _minGapBetweenInterstitials) {
      return;
    }

    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _preloadInterstitial();
      },
    );
    _lastInterstitialShownAt = DateTime.now();
    await ad.show();
  }
}

final adsService = AdsService.instance;
