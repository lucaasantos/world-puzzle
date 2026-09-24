import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/data/packs_data.dart';
import 'package:puzzle_journey/services/puzzle_reward_service.dart';

void main() {
  test('default puzzle reward configuration is 25% first and 5% replay', () {
    expect(puzzleRewardConfig.firstCompletionPackChance, .25);
    expect(puzzleRewardConfig.replayPackChance, .05);
    expect(puzzleRewardConfig.rewardPackId, PackIds.world);
  });

  test('first completion and replay use independent configured chances', () {
    const config = PuzzleRewardConfig(
      firstCompletionPackChance: 1,
      replayPackChance: 0,
      rewardPackId: PackIds.world,
    );
    final service = PuzzleRewardService(config: config, random: math.Random(4));

    expect(service.evaluate(isFirstCompletion: true)?.packId, PackIds.world);
    expect(service.evaluate(isFirstCompletion: false), isNull);
  });

  test('future modifiers are added and clamped safely', () {
    const config = PuzzleRewardConfig(
      firstCompletionPackChance: .25,
      replayPackChance: .05,
      rewardPackId: PackIds.world,
    );
    final service = PuzzleRewardService(config: config, random: math.Random(1));

    final decision = service.evaluate(
      isFirstCompletion: false,
      difficultyModifier: 2,
    );
    expect(decision, isNotNull);
    expect(decision!.chance, 1);
  });
}
