class PuzzleProgress {
  const PuzzleProgress({
    required this.levelId,
    required this.bestTimeSeconds,
    required this.bestMoves,
    required this.stars,
    required this.completions,
    required this.firstCompletedAt,
    required this.bestResultAt,
    this.gameMode = 'sliding',
    this.difficulty,
    this.bestScore = 0,
  });

  final String levelId;
  final int bestTimeSeconds;
  final int bestMoves;
  final int stars;
  final int completions;
  final DateTime firstCompletedAt;
  final DateTime bestResultAt;
  final String gameMode;
  final String? difficulty;
  final int bestScore;

  Map<String, Object> toJson() => {
    'levelId': levelId,
    'bestTimeSeconds': bestTimeSeconds,
    'bestMoves': bestMoves,
    'stars': stars,
    'completions': completions,
    'firstCompletedAt': firstCompletedAt.toIso8601String(),
    'bestResultAt': bestResultAt.toIso8601String(),
    'gameMode': gameMode,
    if (difficulty != null) 'difficulty': difficulty!,
    'bestScore': bestScore,
  };

  factory PuzzleProgress.fromJson(Map<String, dynamic> json) => PuzzleProgress(
    levelId: json['levelId'] as String,
    bestTimeSeconds: json['bestTimeSeconds'] as int,
    bestMoves: json['bestMoves'] as int,
    stars: json['stars'] as int,
    completions: json['completions'] as int,
    firstCompletedAt: DateTime.parse(json['firstCompletedAt'] as String),
    bestResultAt: DateTime.parse(json['bestResultAt'] as String),
    gameMode: json['gameMode'] as String? ?? 'sliding',
    difficulty: json['difficulty'] as String?,
    bestScore: json['bestScore'] as int? ?? 0,
  );
}
