import '../models/puzzle_level.dart';
import 'themes_data.dart';

final allLevels = <PuzzleLevel>[
  for (final theme in gameThemes) ...theme.levels,
];
