import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/data/themes_data.dart';
import 'package:puzzle_journey/engine/progression_rules.dart';
import 'package:puzzle_journey/models/puzzle_progress.dart';

PuzzleProgress completed(String id) => PuzzleProgress(
  levelId: id,
  bestTimeSeconds: 10,
  bestMoves: 10,
  stars: 3,
  completions: 1,
  firstCompletedAt: DateTime(2026),
  bestResultAt: DateTime(2026),
);

void main() {
  final theme = gameThemes.first;

  test('every theme has two 3x3, one 4x4 and one 5x5 level', () {
    for (final configuredTheme in gameThemes) {
      expect(
        configuredTheme.levels.map((level) => level.gridSize),
        orderedEquals([3, 3, 4, 5]),
      );
    }
  });

  test('first level starts unlocked and completion unlocks the next', () {
    expect(ProgressionRules.isLevelUnlocked(theme, 0, {}), isTrue);
    expect(ProgressionRules.isLevelUnlocked(theme, 1, {}), isFalse);
    final progress = {theme.levels.first.id: completed(theme.levels.first.id)};
    expect(ProgressionRules.isLevelUnlocked(theme, 1, progress), isTrue);
    expect(ProgressionRules.isLevelUnlocked(theme, 2, progress), isFalse);
  });

  test('wallpaper condition requires every configured level', () {
    final incomplete = {
      for (final level in theme.levels.take(theme.levels.length - 1))
        level.id: completed(level.id),
    };
    expect(ProgressionRules.isCollectionComplete(theme, incomplete), isFalse);
    final complete = {
      for (final level in theme.levels) level.id: completed(level.id),
    };
    expect(ProgressionRules.isCollectionComplete(theme, complete), isTrue);
  });
}
