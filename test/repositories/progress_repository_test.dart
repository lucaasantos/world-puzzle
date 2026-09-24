import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/models/puzzle_result.dart';
import 'package:puzzle_journey/repositories/progress_repository.dart';

PuzzleResult result({
  required int time,
  required int moves,
  required int stars,
}) => PuzzleResult(
  levelId: 'japan_01',
  themeId: 'japan',
  gridSize: 3,
  elapsedSeconds: time,
  moves: moves,
  stars: stars,
  completedAt: DateTime(2026, 1, 2),
);

void main() {
  test('first result stores all records and stars', () {
    final update = ProgressRepository.mergeResult(
      null,
      result(time: 90, moves: 50, stars: 2),
    );
    expect(update.isNewRecord, isTrue);
    expect(update.progress.bestTimeSeconds, 90);
    expect(update.progress.bestMoves, 50);
    expect(update.progress.stars, 2);
    expect(update.progress.completions, 1);
  });

  test('worse result does not replace better records', () {
    final first = ProgressRepository.mergeResult(
      null,
      result(time: 80, moves: 40, stars: 3),
    ).progress;
    final update = ProgressRepository.mergeResult(
      first,
      result(time: 100, moves: 60, stars: 1),
    );
    expect(update.isNewRecord, isFalse);
    expect(update.progress.bestTimeSeconds, 80);
    expect(update.progress.bestMoves, 40);
    expect(update.progress.stars, 3);
    expect(update.progress.completions, 2);
  });

  test('independent records improve without lowering stars', () {
    final first = ProgressRepository.mergeResult(
      null,
      result(time: 100, moves: 30, stars: 2),
    ).progress;
    final update = ProgressRepository.mergeResult(
      first,
      result(time: 70, moves: 45, stars: 3),
    );
    expect(update.progress.bestTimeSeconds, 70);
    expect(update.progress.bestMoves, 30);
    expect(update.progress.stars, 3);
  });
}
