import 'dart:math' as math;

import '../data/packs_data.dart';

class PuzzleRewardDecision {
  const PuzzleRewardDecision({
    required this.packId,
    required this.chance,
    required this.isFirstCompletion,
  });

  final String packId;
  final double chance;
  final bool isFirstCompletion;
}

class PuzzleRewardService {
  PuzzleRewardService({this.config = puzzleRewardConfig, math.Random? random})
    : _random = random ?? math.Random();

  final PuzzleRewardConfig config;
  final math.Random _random;

  PuzzleRewardDecision? evaluate({
    required bool isFirstCompletion,
    double difficultyModifier = 0,
    double eventModifier = 0,
  }) {
    final baseChance = isFirstCompletion
        ? config.firstCompletionPackChance
        : config.replayPackChance;
    final chance = (baseChance + difficultyModifier + eventModifier).clamp(
      0.0,
      1.0,
    );
    if (_random.nextDouble() >= chance) return null;
    return PuzzleRewardDecision(
      packId: config.rewardPackId,
      chance: chance,
      isFirstCompletion: isFirstCompletion,
    );
  }
}
