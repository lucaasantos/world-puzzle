import 'package:flutter/foundation.dart';

class AdsConfig {
  const AdsConfig._();

  static const bool enabled = true;
  static const int interstitialEveryCompletions = 3;
  static const androidRewardedId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ID',
    defaultValue: kDebugMode ? androidRewardedTestId : '',
  );
  static const androidInterstitialId = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
    defaultValue: kDebugMode ? androidInterstitialTestId : '',
  );
  static const iosRewardedId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_ID',
    defaultValue: kDebugMode ? iosRewardedTestId : '',
  );
  static const iosInterstitialId = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_ID',
    defaultValue: kDebugMode ? iosInterstitialTestId : '',
  );
  static const androidRewardedTestId = 'ca-app-pub-3940256099942544/5224354917';
  static const androidInterstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';
  static const iosRewardedTestId = 'ca-app-pub-3940256099942544/1712485313';
  static const iosInterstitialTestId = 'ca-app-pub-3940256099942544/4411468910';
}
