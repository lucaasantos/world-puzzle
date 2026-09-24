class PuzzleResult {
  const PuzzleResult({
    required this.levelId,
    required this.themeId,
    required this.gridSize,
    required this.elapsedSeconds,
    required this.moves,
    required this.stars,
    required this.completedAt,
    this.gameMode = 'sliding',
    this.difficulty,
    this.score = 0,
  });

  final String levelId;
  final String themeId;
  final int gridSize;
  final int elapsedSeconds;
  final int moves;
  final int stars;
  final DateTime completedAt;
  final String gameMode;
  final String? difficulty;
  final int score;

  String get completionId => '$levelId:${completedAt.microsecondsSinceEpoch}';
}
