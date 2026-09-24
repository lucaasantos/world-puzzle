import '../models/card_inventory_entry.dart';
import '../models/card_pack.dart';
import '../models/puzzle_progress.dart';
import '../models/puzzle_result.dart';
import '../models/saved_game.dart';

class ProgressSnapshot {
  const ProgressSnapshot({
    this.levels = const {},
    this.unlockedWallpapers = const {},
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
    this.onboardingSeen = false,
    this.savedGame,
    this.cardInventory = const {},
    this.packInventory = const {},
    this.processedCompletionIds = const {},
  });

  final Map<String, PuzzleProgress> levels;
  final Set<String> unlockedWallpapers;
  final bool soundEnabled;
  final bool musicEnabled;
  final bool hapticsEnabled;
  final bool onboardingSeen;
  final SavedGame? savedGame;
  final Map<String, CardInventoryEntry> cardInventory;
  final Map<String, PackInventoryEntry> packInventory;
  final Set<String> processedCompletionIds;

  ProgressSnapshot copyWith({
    Map<String, PuzzleProgress>? levels,
    Set<String>? unlockedWallpapers,
    bool? soundEnabled,
    bool? musicEnabled,
    bool? hapticsEnabled,
    bool? onboardingSeen,
    SavedGame? savedGame,
    bool clearSavedGame = false,
    Map<String, CardInventoryEntry>? cardInventory,
    Map<String, PackInventoryEntry>? packInventory,
    Set<String>? processedCompletionIds,
  }) => ProgressSnapshot(
    levels: levels ?? this.levels,
    unlockedWallpapers: unlockedWallpapers ?? this.unlockedWallpapers,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    musicEnabled: musicEnabled ?? this.musicEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    savedGame: clearSavedGame ? null : (savedGame ?? this.savedGame),
    cardInventory: cardInventory ?? this.cardInventory,
    packInventory: packInventory ?? this.packInventory,
    processedCompletionIds:
        processedCompletionIds ?? this.processedCompletionIds,
  );
}

class RecordUpdate {
  const RecordUpdate({required this.progress, required this.isNewRecord});
  final PuzzleProgress progress;
  final bool isNewRecord;
}

abstract interface class ProgressRepository {
  Future<ProgressSnapshot> load();
  Future<void> save(ProgressSnapshot snapshot);

  static RecordUpdate mergeResult(PuzzleProgress? old, PuzzleResult result) {
    if (old == null) {
      return RecordUpdate(
        progress: PuzzleProgress(
          levelId: result.levelId,
          bestTimeSeconds: result.elapsedSeconds,
          bestMoves: result.moves,
          stars: result.stars,
          completions: 1,
          firstCompletedAt: result.completedAt,
          bestResultAt: result.completedAt,
          gameMode: result.gameMode,
          difficulty: result.difficulty,
          bestScore: result.score,
        ),
        isNewRecord: true,
      );
    }
    final betterTime = result.elapsedSeconds < old.bestTimeSeconds;
    final betterMoves = result.moves < old.bestMoves;
    final betterStars = result.stars > old.stars;
    final betterScore = result.score > old.bestScore;
    return RecordUpdate(
      progress: PuzzleProgress(
        levelId: old.levelId,
        bestTimeSeconds: betterTime
            ? result.elapsedSeconds
            : old.bestTimeSeconds,
        bestMoves: betterMoves ? result.moves : old.bestMoves,
        stars: betterStars ? result.stars : old.stars,
        completions: old.completions + 1,
        firstCompletedAt: old.firstCompletedAt,
        bestResultAt: betterTime || betterMoves || betterStars || betterScore
            ? result.completedAt
            : old.bestResultAt,
        gameMode: result.gameMode,
        difficulty: result.difficulty ?? old.difficulty,
        bestScore: betterScore ? result.score : old.bestScore,
      ),
      isNewRecord: betterTime || betterMoves || betterStars || betterScore,
    );
  }
}
