import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/engine/puzzle_scoring.dart';
import 'package:puzzle_journey/models/puzzle_level.dart';

void main() {
  const level = PuzzleLevel(
    id: 'test',
    number: 1,
    imagePath: 'test.webp',
    gridSize: 3,
    oneStarMaxMoves: 700,
    oneStarMaxTimeSeconds: 900,
    twoStarsMaxMoves: 500,
    twoStarsMaxTimeSeconds: 780,
    threeStarsMaxMoves: 400,
    threeStarsMaxTimeSeconds: 600,
  );

  test('awards no star when either base requirement is exceeded', () {
    expect(
      PuzzleScoring.calculate(level: level, elapsedSeconds: 901, moves: 600),
      0,
    );
    expect(
      PuzzleScoring.calculate(level: level, elapsedSeconds: 800, moves: 701),
      0,
    );
  });

  test('requires both time and move goals for every star tier', () {
    expect(
      PuzzleScoring.calculate(level: level, elapsedSeconds: 900, moves: 700),
      1,
    );
    expect(
      PuzzleScoring.calculate(level: level, elapsedSeconds: 780, moves: 500),
      2,
    );
    expect(
      PuzzleScoring.calculate(level: level, elapsedSeconds: 600, moves: 400),
      3,
    );
    expect(
      PuzzleScoring.calculate(level: level, elapsedSeconds: 600, moves: 501),
      1,
    );
  });
}
