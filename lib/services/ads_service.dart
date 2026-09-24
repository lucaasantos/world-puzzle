import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/config/ads_config.dart';

enum RewardedAdOutcome { earned, notEarned, unavailable, failedToShow }

class AdsService {
  RewardedAd? _rewarded;
  Future<bool>? _rewardedLoad;
  InterstitialAd? _interstitial;
  Future<void>? _initialization;
  bool _initialized = false;
  int _completedSinceInterstitial = 0;
  int interstitialEvery = AdsConfig.interstitialEveryCompletions;
  void Function(String, [Map<String, Object>?])? onEvent;

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    if (!AdsConfig.enabled) return;
    try {
      await MobileAds.instance.initialize().timeout(const Duration(seconds: 8));
      _initialized = true;
      unawaited(_loadRewarded());
      _loadInterstitial();
    } catch (_) {
      // Advertising availability never determines economic grants.
      _initialization = null;
    }
  }

  String get _rewardedId => Platform.isAndroid
      ? AdsConfig.androidRewardedId
      : AdsConfig.iosRewardedId;
  String get _interstitialId => Platform.isAndroid
      ? AdsConfig.androidInterstitialId
      : AdsConfig.iosInterstitialId;

  bool get isRewardedReady => _rewarded != null;

  Future<bool> prepareRewarded() async {
    if (!_initialized) await initialize();
    if (_rewarded != null) return true;
    return _loadRewarded();
  }

  Future<bool> _loadRewarded() {
    if (!_initialized || _rewardedId.isEmpty) return Future.value(false);
    if (_rewarded != null) return Future.value(true);
    final pending = _rewardedLoad;
    if (pending != null) return pending;
    final completer = Completer<bool>();
    _rewardedLoad = completer.future;
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedLoad = null;
          completer.complete(true);
        },
        onAdFailedToLoad: (_) {
          _rewarded = null;
          _rewardedLoad = null;
          completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  void _loadInterstitial() {
    if (!_initialized || _interstitialId.isEmpty) return;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  Future<bool> showRewarded() async {
    return (await _showRewarded()) == RewardedAdOutcome.earned;
  }

  Future<bool> showRewardedVerified({
    required String userId,
    required String customData,
  }) async =>
      (await _showRewarded(userId: userId, customData: customData)) ==
      RewardedAdOutcome.earned;

  Future<RewardedAdOutcome> showRewardedVerifiedOutcome({
    required String userId,
    required String customData,
  }) => _showRewarded(userId: userId, customData: customData);

  Future<RewardedAdOutcome> _showRewarded({
    String? userId,
    String? customData,
  }) async {
    if (!_initialized) await initialize();
    final ad = _rewarded;
    if (ad == null) {
      unawaited(_loadRewarded());
      return RewardedAdOutcome.unavailable;
    }
    var earned = false;
    final result = Completer<RewardedAdOutcome>();
    _rewarded = null;
    if (userId != null && customData != null) {
      await ad.setServerSideOptions(
        ServerSideVerificationOptions(userId: userId, customData: customData),
      );
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(_loadRewarded());
        if (!result.isCompleted) {
          result.complete(
            earned ? RewardedAdOutcome.earned : RewardedAdOutcome.notEarned,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        unawaited(_loadRewarded());
        if (!result.isCompleted) {
          result.complete(RewardedAdOutcome.failedToShow);
        }
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, __) => earned = true);
    } catch (_) {
      ad.dispose();
      unawaited(_loadRewarded());
      return RewardedAdOutcome.failedToShow;
    }
    return result.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => RewardedAdOutcome.failedToShow,
    );
  }

  Future<void> onLevelCompleted() async {
    _completedSinceInterstitial++;
    if (interstitialEvery <= 0 ||
        _completedSinceInterstitial < interstitialEvery) {
      return;
    }
    if (!_initialized) {
      unawaited(initialize());
      return;
    }
    await _showInterstitialIfReady();
  }

  Future<void> _showInterstitialIfReady() async {
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    final dismissed = Completer<void>();
    _completedSinceInterstitial = 0;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => onEvent?.call('interstitial_shown'),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        if (!dismissed.isCompleted) dismissed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );
    try {
      await ad.show();
      await dismissed.future.timeout(const Duration(seconds: 45));
    } catch (_) {
      ad.dispose();
    }
  }

  void dispose() {
    _rewarded?.dispose();
    _interstitial?.dispose();
  }
}
