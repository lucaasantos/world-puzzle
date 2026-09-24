import 'dart:async';

import '../models/economy.dart';
import 'ads_service.dart';
import 'online_game_service.dart';

class WorldCoinOfflineException implements Exception {
  const WorldCoinOfflineException();
}

class WorldCoinService {
  WorldCoinService({required this.online, required this.ads});

  final OnlineGameService online;
  final AdsService ads;

  int get balance => online.worldCoinBalance;
  int get earnedToday => online.worldCoinsEarnedToday;
  int get dailyLimit => online.worldCoinDailyLimit;
  int get rewardAmount => online.worldCoinRewardAmount;
  bool get dailyLimitReached => earnedToday >= dailyLimit;

  Future<bool> prepareRewardedAd() => ads.prepareRewarded();

  Future<WorldCoinEarnResult> earnFromRewardedAd() async {
    if (!online.connected) throw const WorldCoinOfflineException();
    final balanceBefore = balance;
    final ticket = await online.call('prepareWorldCoinAd');
    online.event('world_coin_rewarded_ad_started');
    final ad = await ads.showRewardedVerifiedOutcome(
      userId: online.uid,
      customData: ticket['ticket'] as String,
    );
    if (ad != RewardedAdOutcome.earned) {
      online.event('world_coin_reward_claim_failed', {'reason': ad.name});
      return WorldCoinEarnResult(
        ad == RewardedAdOutcome.notEarned
            ? WorldCoinEarnStatus.rewardNotEarned
            : WorldCoinEarnStatus.adUnavailable,
      );
    }
    online.event('world_coin_rewarded_ad_completed');

    // The local reward callback authorizes only this confirmation request.
    // Production credit still requires the separately signed AdMob SSV callback.
    for (var attempt = 0; attempt < 6; attempt++) {
      if (attempt > 0) await Future<void>.delayed(const Duration(seconds: 2));
      final result = await online.call('claimRewardedWorldCoin', {
        'ticket': ticket['ticket'],
      });
      if (result['status'] == 'granted') {
        await online.sync();
        online.event('world_coin_reward_claim_success', {
          'amount': online.worldCoinRewardAmount,
        });
        if (dailyLimitReached) {
          online.event('world_coin_daily_limit_reached');
        }
        return WorldCoinEarnResult(
          WorldCoinEarnStatus.granted,
          amount: (result['amount'] as num?)?.toInt() ?? rewardAmount,
        );
      }
    }
    // A delayed SSV callback will be reflected by the normal authoritative sync.
    await online.sync();
    if (balance >= balanceBefore + rewardAmount) {
      online.event('world_coin_reward_claim_success', {'amount': rewardAmount});
      return WorldCoinEarnResult(
        WorldCoinEarnStatus.granted,
        amount: rewardAmount,
      );
    }
    online.event('world_coin_reward_claim_failed', {
      'reason': 'confirmation_pending',
    });
    return const WorldCoinEarnResult(WorldCoinEarnStatus.confirmationPending);
  }
}
