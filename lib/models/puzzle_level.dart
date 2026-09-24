class PuzzleLevel {
  const PuzzleLevel({
    required this.id,
    required this.number,
    required this.imagePath,
    required this.gridSize,
    required this.oneStarMaxMoves,
    required this.oneStarMaxTimeSeconds,
    required this.twoStarsMaxMoves,
    required this.twoStarsMaxTimeSeconds,
    required this.threeStarsMaxMoves,
    required this.threeStarsMaxTimeSeconds,
    this.maxLives = 4,
  });

  final String id;
  final int number;
  final String imagePath;
  final int gridSize;
  final int oneStarMaxMoves;
  final int oneStarMaxTimeSeconds;
  final int twoStarsMaxMoves;
  final int twoStarsMaxTimeSeconds;
  final int threeStarsMaxMoves;
  final int threeStarsMaxTimeSeconds;
  final int maxLives;

  String get difficultyId => switch (gridSize) {
    3 => 'easy',
    4 => 'medium',
    5 => 'hard',
    6 => 'veryHard',
    _ => 'custom',
  };

  String get difficultyLabel => switch (gridSize) {
    3 => 'FÁCIL',
    4 => 'MÉDIO',
    5 => 'DIFÍCIL',
    6 => 'MUITO DIFÍCIL',
    _ => '$gridSize×$gridSize',
  };
}
