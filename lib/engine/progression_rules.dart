import '../models/game_theme.dart';
import '../models/puzzle_progress.dart';

class ProgressionRules {
  const ProgressionRules._();

  static bool isLevelUnlocked(
    GameTheme theme,
    int index,
    Map<String, PuzzleProgress> progress,
  ) {
    if (index == 0) return true;
    return progress.containsKey(theme.levels[index - 1].id);
  }

  static bool isCollectionComplete(
    GameTheme theme,
    Map<String, PuzzleProgress> progress,
  ) => theme.levels.every((level) => progress.containsKey(level.id));
}
