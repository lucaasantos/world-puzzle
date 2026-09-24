import 'puzzle_level.dart';

class GameTheme {
  const GameTheme({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.thumbnail,
    required this.wallpaper,
    required this.accent,
    required this.levels,
  });

  final String id;
  final String name;
  final String subtitle;
  final String thumbnail;
  final String wallpaper;
  final int accent;
  final List<PuzzleLevel> levels;
}
