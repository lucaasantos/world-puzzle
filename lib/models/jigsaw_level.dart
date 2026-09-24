import 'puzzle_level.dart';

class JigsawLevel {
  const JigsawLevel({
    required this.countryId,
    required this.difficulty,
    required this.rows,
    required this.columns,
    required this.imagePath,
    required this.oneStarMaxMoves,
    required this.oneStarMaxTimeSeconds,
    required this.twoStarsMaxMoves,
    required this.twoStarsMaxTimeSeconds,
    required this.threeStarsMaxMoves,
    required this.threeStarsMaxTimeSeconds,
    this.snapToleranceFactor = .20,
  });

  final String countryId;
  final String difficulty;
  final int rows;
  final int columns;
  final String imagePath;
  final int oneStarMaxMoves;
  final int oneStarMaxTimeSeconds;
  final int twoStarsMaxMoves;
  final int twoStarsMaxTimeSeconds;
  final int threeStarsMaxMoves;
  final int threeStarsMaxTimeSeconds;
  final double snapToleranceFactor;

  String get id => 'jigsaw_${countryId}_$difficulty';
  int get pieces => rows * columns;

  PuzzleLevel get puzzleLevel => PuzzleLevel(
    id: id,
    number:
        const ['easy', 'medium', 'hard', 'veryHard'].indexOf(difficulty) + 1,
    imagePath: imagePath,
    gridSize: rows,
    oneStarMaxMoves: oneStarMaxMoves,
    oneStarMaxTimeSeconds: oneStarMaxTimeSeconds,
    twoStarsMaxMoves: twoStarsMaxMoves,
    twoStarsMaxTimeSeconds: twoStarsMaxTimeSeconds,
    threeStarsMaxMoves: threeStarsMaxMoves,
    threeStarsMaxTimeSeconds: threeStarsMaxTimeSeconds,
  );
}
