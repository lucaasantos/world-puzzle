import '../models/jigsaw_level.dart';

class JigsawScoring {
  const JigsawScoring._();

  static int stars({
    required JigsawLevel level,
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

  static int score({
    required JigsawLevel level,
    required int elapsedSeconds,
    required int moves,
  }) {
    final base = level.pieces * 1000;
    return (base - elapsedSeconds * 2 - moves * 10).clamp(0, base);
  }
}
