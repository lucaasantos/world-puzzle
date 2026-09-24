import '../models/game_theme.dart';
import '../models/puzzle_level.dart';

List<PuzzleLevel> _levels(String id) {
  const grids = [3, 3, 4, 5];
  return List.generate(grids.length, (index) {
    final number = index + 1;
    final gridSize = grids[index];
    final limits = _limitsByGrid[gridSize]!;
    return PuzzleLevel(
      id: '${id}_${number.toString().padLeft(2, '0')}',
      number: number,
      imagePath:
          'assets/images/themes/$id/${id}_${number.toString().padLeft(2, '0')}.webp',
      gridSize: gridSize,
      oneStarMaxMoves: limits.oneStarMoves,
      oneStarMaxTimeSeconds: limits.oneStarSeconds,
      twoStarsMaxMoves: limits.twoStarsMoves,
      twoStarsMaxTimeSeconds: limits.twoStarsSeconds,
      threeStarsMaxMoves: limits.threeStarsMoves,
      threeStarsMaxTimeSeconds: limits.threeStarsSeconds,
    );
  });
}

const _limitsByGrid = <int, _LevelLimits>{
  3: _LevelLimits(
    oneStarMoves: 700,
    oneStarSeconds: 15 * 60,
    twoStarsMoves: 500,
    twoStarsSeconds: 13 * 60,
    threeStarsMoves: 400,
    threeStarsSeconds: 10 * 60,
  ),
  4: _LevelLimits(
    oneStarMoves: 1000,
    oneStarSeconds: 20 * 60,
    twoStarsMoves: 750,
    twoStarsSeconds: 17 * 60,
    threeStarsMoves: 600,
    threeStarsSeconds: 14 * 60,
  ),
  5: _LevelLimits(
    oneStarMoves: 2000,
    oneStarSeconds: 30 * 60,
    twoStarsMoves: 1500,
    twoStarsSeconds: 26 * 60,
    threeStarsMoves: 1200,
    threeStarsSeconds: 20 * 60,
  ),
};

class _LevelLimits {
  const _LevelLimits({
    required this.oneStarMoves,
    required this.oneStarSeconds,
    required this.twoStarsMoves,
    required this.twoStarsSeconds,
    required this.threeStarsMoves,
    required this.threeStarsSeconds,
  });

  final int oneStarMoves;
  final int oneStarSeconds;
  final int twoStarsMoves;
  final int twoStarsSeconds;
  final int threeStarsMoves;
  final int threeStarsSeconds;
}

final gameThemes = <GameTheme>[
  GameTheme(
    id: 'brazil',
    name: 'Brasil',
    subtitle: 'Uma viagem pelas cores do Brasil',
    // Temporary theme assets are isolated here for straightforward replacement.
    thumbnail: 'assets/images/themes/brazil/brazil_thumbnail.webp',
    wallpaper: 'assets/images/themes/brazil/brazil_wallpaper.webp',
    accent: 0xFF65B877,
    levels: _levels('brazil'),
  ),
  GameTheme(
    id: 'japan',
    name: 'Japão',
    subtitle: 'Tradição entre flores e lanternas',
    thumbnail: 'assets/images/themes/japan/japan_01.webp',
    wallpaper: 'assets/images/themes/japan/japan_wallpaper.webp',
    accent: 0xFFE86B62,
    levels: _levels('japan'),
  ),
  GameTheme(
    id: 'united_states',
    name: 'Estados Unidos',
    subtitle: 'Ícones entre cidades e natureza',
    thumbnail:
        'assets/images/themes/united_states/united_states_thumbnail.webp',
    wallpaper:
        'assets/images/themes/united_states/united_states_wallpaper.webp',
    accent: 0xFF3C6FAE,
    levels: _levels('united_states'),
  ),
  GameTheme(
    id: 'egypt',
    name: 'Egito',
    subtitle: 'Mistérios gravados no tempo',
    thumbnail: 'assets/images/themes/egypt/egypt_thumbnail.webp',
    wallpaper: 'assets/images/themes/egypt/egypt_wallpaper.webp',
    accent: 0xFFD6A84E,
    levels: _levels('egypt'),
  ),
  GameTheme(
    id: 'greece',
    name: 'Grécia',
    subtitle: 'Luz entre mármore e mar',
    thumbnail: 'assets/images/themes/greece/greece_thumbnail.webp',
    wallpaper: 'assets/images/themes/greece/greece_wallpaper.webp',
    accent: 0xFF68A9D8,
    levels: _levels('greece'),
  ),
];
