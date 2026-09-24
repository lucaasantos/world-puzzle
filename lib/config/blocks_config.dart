enum BlocksDifficulty { easy, medium, hard, veryHard }

extension BlocksDifficultyName on BlocksDifficulty {
  String get id => switch (this) {
    BlocksDifficulty.easy => 'easy',
    BlocksDifficulty.medium => 'medium',
    BlocksDifficulty.hard => 'hard',
    BlocksDifficulty.veryHard => 'veryHard',
  };

  String get label => switch (this) {
    BlocksDifficulty.easy => 'FÁCIL',
    BlocksDifficulty.medium => 'MÉDIO',
    BlocksDifficulty.hard => 'DIFÍCIL',
    BlocksDifficulty.veryHard => 'MUITO DIFÍCIL',
  };
}

const blocksBoardWidth = 10;
const blocksBoardHeight = 20;
const blocksLinesPerSpeedLevel = 10;
const blocksLockDelay = Duration(milliseconds: 420);
const blocksLineClearDuration = Duration(milliseconds: 160);
const blocksMaxLockResets = 8;
const blocksWallKickOffsets = [0, -1, 1, -2, 2];
const blocksHoldEnabled = false;

class BlocksDifficultyConfig {
  const BlocksDifficultyConfig({
    required this.targetLines,
    required this.startingGameplayLevel,
    required this.startingGravityMs,
    required this.gravityStepMs,
    required this.minimumGravityMs,
    required this.twoStarsScore,
    required this.threeStarsScore,
    required this.oneStarMaxSeconds,
    required this.twoStarsMaxSeconds,
    required this.threeStarsMaxSeconds,
  });

  final int targetLines;
  final int startingGameplayLevel;
  final int startingGravityMs;
  final int gravityStepMs;
  final int minimumGravityMs;
  final int twoStarsScore;
  final int threeStarsScore;
  final int oneStarMaxSeconds;
  final int twoStarsMaxSeconds;
  final int threeStarsMaxSeconds;

  int gravityForLevel(int gameplayLevel) =>
      (startingGravityMs -
              (gameplayLevel - startingGameplayLevel) * gravityStepMs)
          .clamp(minimumGravityMs, startingGravityMs);

  int stars({required int score, required int elapsedSeconds}) {
    if (score >= threeStarsScore && elapsedSeconds <= threeStarsMaxSeconds) {
      return 3;
    }
    if (score >= twoStarsScore && elapsedSeconds <= twoStarsMaxSeconds) {
      return 2;
    }
    return 1;
  }
}

const blocksDifficultyConfig = <BlocksDifficulty, BlocksDifficultyConfig>{
  BlocksDifficulty.easy: BlocksDifficultyConfig(
    targetLines: 10,
    startingGameplayLevel: 1,
    startingGravityMs: 900,
    gravityStepMs: 65,
    minimumGravityMs: 120,
    twoStarsScore: 1800,
    threeStarsScore: 3200,
    oneStarMaxSeconds: 900,
    twoStarsMaxSeconds: 600,
    threeStarsMaxSeconds: 420,
  ),
  BlocksDifficulty.medium: BlocksDifficultyConfig(
    targetLines: 20,
    startingGameplayLevel: 3,
    startingGravityMs: 700,
    gravityStepMs: 55,
    minimumGravityMs: 105,
    twoStarsScore: 5000,
    threeStarsScore: 8500,
    oneStarMaxSeconds: 1200,
    twoStarsMaxSeconds: 900,
    threeStarsMaxSeconds: 660,
  ),
  BlocksDifficulty.hard: BlocksDifficultyConfig(
    targetLines: 30,
    startingGameplayLevel: 5,
    startingGravityMs: 500,
    gravityStepMs: 45,
    minimumGravityMs: 90,
    twoStarsScore: 9500,
    threeStarsScore: 15000,
    oneStarMaxSeconds: 1500,
    twoStarsMaxSeconds: 1140,
    threeStarsMaxSeconds: 840,
  ),
  BlocksDifficulty.veryHard: BlocksDifficultyConfig(
    targetLines: 40,
    startingGameplayLevel: 8,
    startingGravityMs: 300,
    gravityStepMs: 35,
    minimumGravityMs: 75,
    twoStarsScore: 15000,
    threeStarsScore: 23000,
    oneStarMaxSeconds: 1800,
    twoStarsMaxSeconds: 1380,
    threeStarsMaxSeconds: 1020,
  ),
};

const blocksLineScores = <int, int>{1: 100, 2: 300, 3: 500, 4: 800};
const blocksSoftDropPoints = 1;
const blocksHardDropPoints = 2;
const blocksComboPoints = 50;
