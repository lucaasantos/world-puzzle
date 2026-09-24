import '../models/puzzle_level.dart';

class PuzzleScoring {
  const PuzzleScoring._();

  static int calculate({
    required PuzzleLevel level,
    required int elapsedSeconds,
    required int moves,
  }) {
    if (moves <= level.threeStarsMaxMoves &&
        elapsedSeconds <= level.threeStarsMaxTimeSeconds) {
      return 3;
    }
    if (moves <= level.twoStarsMaxMoves &&
        elapsedSeconds <= level.twoStarsMaxTimeSeconds) {
      return 2;
    }
    if (moves <= level.oneStarMaxMoves &&
        elapsedSeconds <= level.oneStarMaxTimeSeconds) {
      return 1;
    }
    return 0;
  }
}
