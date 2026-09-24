import '../config/blocks_config.dart';
import 'puzzle_level.dart';

class BlocksLevel {
  const BlocksLevel({
    required this.countryId,
    required this.difficulty,
    required this.imagePath,
  });

  final String countryId;
  final BlocksDifficulty difficulty;
  final String imagePath;

  BlocksDifficultyConfig get config => blocksDifficultyConfig[difficulty]!;
  String get id => 'blocks_${countryId}_${difficulty.id}';

  PuzzleLevel get puzzleLevel => PuzzleLevel(
    id: id,
    number: difficulty.index + 1,
    imagePath: imagePath,
    gridSize: blocksBoardWidth,
    oneStarMaxMoves: 99999,
    oneStarMaxTimeSeconds: config.oneStarMaxSeconds,
    twoStarsMaxMoves: 99999,
    twoStarsMaxTimeSeconds: config.twoStarsMaxSeconds,
    threeStarsMaxMoves: 99999,
    threeStarsMaxTimeSeconds: config.threeStarsMaxSeconds,
  );
}
