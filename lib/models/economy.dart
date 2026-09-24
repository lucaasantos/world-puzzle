enum CurrencyType { worldCoin }

enum EconomyTransactionType {
  rewardedAd,
  packPurchase,
  marketPurchase,
  marketSale,
  marketFee,
  coinPurchase,
  adminAdjustment,
}

enum WorldCoinEarnStatus {
  granted,
  adUnavailable,
  rewardNotEarned,
  confirmationPending,
}

class WorldCoinEarnResult {
  const WorldCoinEarnResult(this.status, {this.amount = 0});

  final WorldCoinEarnStatus status;
  final int amount;
}
