// ArrowFlow — economy defaults (PRD §7). Ported from src/game/economy.ts.

class Economy {
  static const int startingCoins = 100;
  static const int startingHints = 3;
  static const int startingErasers = 1;
  static const int startingExtraHearts = 1;
  static const int heartsPerLevel = 3;
  static const int maxRewardedHeartsPerLevel = 2;
  static const int maxInventory = 999;

  static const int priceHint = 50;
  static const int priceExtraHeart = 75;
  static const int priceEraser = 100;

  /// Coins for clearing level n. Flawless = no heart lost.
  static int coinReward(int level, bool flawless) =>
      10 + (level ~/ 10) + (flawless ? 5 : 0);

  static const int dailyRewardCoins = 25;
  static const int dailyRewardStars = 1;
}

class StarChest {
  final int stars;
  final String reward;
  const StarChest(this.stars, this.reward);
}

const starChests = [
  StarChest(5, '50 coins'),
  StarChest(10, 'Hint pack'),
  StarChest(20, '2 extra hearts'),
  StarChest(30, 'Theme + 200 coins'),
];
