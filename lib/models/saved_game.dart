class SavedGame {
  const SavedGame({
    required this.themeId,
    required this.levelId,
    required this.board,
    required this.elapsedSeconds,
    required this.moves,
    this.livesRemaining = 4,
    this.currentMoveLimit = 0,
    this.currentTimeLimitSeconds = 0,
  });

  final String themeId;
  final String levelId;
  final List<int> board;
  final int elapsedSeconds;
  final int moves;
  final int livesRemaining;
  final int currentMoveLimit;
  final int currentTimeLimitSeconds;

  Map<String, Object> toJson() => {
    'themeId': themeId,
    'levelId': levelId,
    'board': board,
    'elapsedSeconds': elapsedSeconds,
    'moves': moves,
    'livesRemaining': livesRemaining,
    'currentMoveLimit': currentMoveLimit,
    'currentTimeLimitSeconds': currentTimeLimitSeconds,
  };

  factory SavedGame.fromJson(Map<String, dynamic> json) => SavedGame(
    themeId: json['themeId'] as String,
    levelId: json['levelId'] as String,
    board: (json['board'] as List).cast<int>(),
    elapsedSeconds: json['elapsedSeconds'] as int,
    moves: json['moves'] as int,
    livesRemaining: json['livesRemaining'] as int? ?? 4,
    currentMoveLimit: json['currentMoveLimit'] as int? ?? 0,
    currentTimeLimitSeconds: json['currentTimeLimitSeconds'] as int? ?? 0,
  );
}
