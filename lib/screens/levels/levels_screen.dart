import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../config/blocks_config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/jigsaw_levels_data.dart';
import '../../data/blocks_levels_data.dart';
import '../../models/game_mode.dart';
import '../../models/game_theme.dart';
import '../../models/puzzle_level.dart';
import '../../widgets/star_rating/star_rating.dart';
import '../game/game_screen.dart';
import '../jigsaw/jigsaw_game_screen.dart';
import '../blocks/blocks_game_screen.dart';
import '../online/player_screens.dart';

Future<void> _openGame(BuildContext context, WidgetBuilder builder) async {
  final controller = AppScope.of(context, listen: false);
  if (controller.online?.lives == 0) {
    await showEnergy(context, depleted: true);
    return;
  }
  if (!context.mounted) return;
  await Navigator.push(context, MaterialPageRoute<void>(builder: builder));
}

class LevelsScreen extends StatelessWidget {
  const LevelsScreen({
    required this.theme,
    this.mode = GameModeKind.sliding,
    super.key,
  });
  final GameTheme theme;
  final GameModeKind mode;

  @override
  Widget build(BuildContext context) {
    if (mode == GameModeKind.jigsaw) {
      return _JigsawLevelsScreen(theme: theme);
    }
    if (mode == GameModeKind.blocks) {
      return _BlocksLevelsScreen(theme: theme);
    }
    if (theme.id == 'japan') return _JapanLevelsScreen(theme: theme);
    final controller = AppScope.of(context);
    final stats = controller.statsFor(theme);
    return Scaffold(
      appBar: AppBar(
        title: Text(theme.name),
        actions: const [
          CurrentEnergyIndicator(
            key: Key('levels_energy_indicator'),
            light: true,
          ),
          SizedBox(width: 12),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${stats.completed}/${stats.total} fases  •  ${stats.stars}/${stats.total * 3} estrelas',
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverGrid.builder(
              itemCount: theme.levels.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: .9,
              ),
              itemBuilder: (context, index) {
                final level = theme.levels[index];
                final unlocked = controller.isLevelUnlocked(theme, index);
                final progress = controller.progress[level.id];
                return InkWell(
                  onTap: unlocked
                      ? () => _openGame(
                          context,
                          (_) => GameScreen(theme: theme, level: level),
                        )
                      : null,
                  borderRadius: BorderRadius.circular(22),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      image: DecorationImage(
                        image: AssetImage(level.imagePath),
                        fit: BoxFit.cover,
                        colorFilter: unlocked
                            ? null
                            : const ColorFilter.mode(
                                Colors.black54,
                                BlendMode.darken,
                              ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xE6101314)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!unlocked)
                            const Icon(Icons.lock_outline_rounded, size: 20),
                          const Spacer(),
                          Text(
                            level.difficultyLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${level.gridSize}×${level.gridSize}',
                                style: const TextStyle(color: Colors.white60),
                              ),
                              const Spacer(),
                              StarRating(stars: progress?.stars ?? 0, size: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BlocksLevelsScreen extends StatelessWidget {
  const _BlocksLevelsScreen({required this.theme});
  final GameTheme theme;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final levels = blocksLevelsFor(theme.id);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            theme.id == 'japan'
                ? 'assets/images/home/gate_jp.png'
                : theme.wallpaper,
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xB02C1710), Color(0xED24150F)],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 18, 22),
                    child: Row(
                      children: [
                        IconButton.filled(
                          tooltip: 'Voltar',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${theme.name.toUpperCase()} • BLOCOS',
                                style: const TextStyle(
                                  color: Color(0xFFFFF4D9),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'Escolha a dificuldade',
                                style: TextStyle(color: Color(0xFFFFE0A8)),
                              ),
                            ],
                          ),
                        ),
                        const CurrentEnergyIndicator(
                          key: Key('levels_energy_indicator'),
                          light: true,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
                  sliver: SliverGrid.builder(
                    itemCount: levels.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 14,
                          childAspectRatio: .86,
                        ),
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final progress = controller.progress[level.id];
                      return Material(
                        borderRadius: BorderRadius.circular(22),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: Key('blocks_difficulty_${level.difficulty.id}'),
                          onTap: () => _openGame(
                            context,
                            (_) => BlocksGameScreen(theme: theme, level: level),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(level.imagePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(13),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color(0xF02A1710),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    level.difficulty.label,
                                    style: const TextStyle(
                                      color: Color(0xFFFFF0CF),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Meta: ${level.config.targetLines} linhas',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      StarRating(
                                        stars: progress?.stars ?? 0,
                                        size: 13,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JigsawLevelsScreen extends StatelessWidget {
  const _JigsawLevelsScreen({required this.theme});
  final GameTheme theme;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final levels = jigsawLevelsFor(theme.id);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            theme.id == 'japan'
                ? 'assets/images/home/gate_jp.png'
                : theme.wallpaper,
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xA65C2D27), Color(0xE6FFF3DB)],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 18, 22),
                    child: Row(
                      children: [
                        IconButton.filled(
                          tooltip: 'Voltar',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${theme.name.toUpperCase()} • QUEBRA-CABEÇAS',
                                style: const TextStyle(
                                  color: Color(0xFFFFF4D9),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'Escolha a dificuldade',
                                style: TextStyle(color: Color(0xFFFFE0A8)),
                              ),
                            ],
                          ),
                        ),
                        const CurrentEnergyIndicator(
                          key: Key('levels_energy_indicator'),
                          light: true,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
                  sliver: SliverGrid.builder(
                    itemCount: levels.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 14,
                          childAspectRatio: .86,
                        ),
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final progress = controller.progress[level.id];
                      final unlocked =
                          index == 0 ||
                          controller.progress.containsKey(levels[index - 1].id);
                      return Material(
                        borderRadius: BorderRadius.circular(22),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: Key('jigsaw_difficulty_${level.difficulty}'),
                          onTap: unlocked
                              ? () => _openGame(
                                  context,
                                  (_) => JigsawGameScreen(
                                    theme: theme,
                                    level: level,
                                  ),
                                )
                              : null,
                          child: Ink(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(level.imagePath),
                                fit: BoxFit.cover,
                                colorFilter: unlocked
                                    ? null
                                    : const ColorFilter.mode(
                                        Colors.black54,
                                        BlendMode.darken,
                                      ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(13),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color(0xEA35150F),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!unlocked) ...[
                                    const Icon(
                                      Icons.lock_rounded,
                                      color: Color(0xFFFFF0CF),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                  Text(
                                    level.puzzleLevel.difficultyLabel,
                                    style: const TextStyle(
                                      color: Color(0xFFFFF0CF),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${level.rows}×${level.columns} • ${level.pieces}',
                                          style: const TextStyle(fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      StarRating(
                                        stars: progress?.stars ?? 0,
                                        size: 13,
                                      ),
                                    ],
                                  ),
                                  if (!unlocked) ...[
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Conclua a dificuldade anterior',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFFFFD99B),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JapanLevelsScreen extends StatelessWidget {
  const _JapanLevelsScreen({required this.theme});
  final GameTheme theme;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final stats = controller.statsFor(theme);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home/gate_jp.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .20, .62, 1],
                colors: [
                  Color(0xA65C2D27),
                  Color(0x22FFF4DF),
                  Color(0x33FFF4DF),
                  Color(0xE6FFF3DB),
                ],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 18, 22),
                    child: Row(
                      children: [
                        IconButton.filled(
                          tooltip: 'Voltar',
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xC99A4034),
                            foregroundColor: const Color(0xFFFFF0CD),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _JapanTitle(),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xC9FFF0CF),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: const Color(0x999A4034),
                                  ),
                                ),
                                child: Text(
                                  '${stats.completed}/${stats.total} fases  •  ${stats.stars}/${stats.total * 3} estrelas',
                                  style: const TextStyle(
                                    color: Color(0xFF71352C),
                                    fontFamily: 'serif',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const CurrentEnergyIndicator(
                          key: Key('levels_energy_indicator'),
                          light: true,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 5, 18, 34),
                  sliver: SliverGrid.builder(
                    itemCount: theme.levels.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 14,
                          childAspectRatio: .86,
                        ),
                    itemBuilder: (context, index) {
                      final level = theme.levels[index];
                      final unlocked = controller.isLevelUnlocked(theme, index);
                      final progress = controller.progress[level.id];
                      return _JapanLevelCard(
                        level: level,
                        unlocked: unlocked,
                        stars: progress?.stars ?? 0,
                        lanternOnLeft: index.isEven,
                        onTap: unlocked
                            ? () => _openGame(
                                context,
                                (_) => GameScreen(theme: theme, level: level),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JapanTitle extends StatelessWidget {
  const _JapanTitle();

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Text(
        'JAPÃO',
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: 36,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = const Color(0xFF7C3028),
        ),
      ),
      const Text(
        'JAPÃO',
        style: TextStyle(
          color: Color(0xFFFFF4D9),
          fontFamily: 'serif',
          fontSize: 36,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [Shadow(color: Colors.black45, offset: Offset(0, 3))],
        ),
      ),
    ],
  );
}

class _JapanLevelCard extends StatelessWidget {
  const _JapanLevelCard({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.lanternOnLeft,
    required this.onTap,
  });

  final PuzzleLevel level;
  final bool unlocked;
  final int stars;
  final bool lanternOnLeft;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x663F1F18),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECCA),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF4C06C), width: 3),
                  image: DecorationImage(
                    image: AssetImage(level.imagePath),
                    fit: BoxFit.cover,
                    colorFilter: unlocked
                        ? null
                        : const ColorFilter.mode(
                            Colors.black54,
                            BlendMode.darken,
                          ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xDF4D211C)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!unlocked)
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFFFFE7B0),
                          size: 21,
                        ),
                      const Spacer(),
                      Text(
                        level.difficultyLabel,
                        style: const TextStyle(
                          color: Color(0xFFFFF0CF),
                          fontFamily: 'serif',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${level.gridSize}×${level.gridSize}',
                            style: const TextStyle(
                              color: Color(0xFFFFDDA0),
                              fontFamily: 'serif',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          StarRating(stars: stars, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: lanternOnLeft ? -12 : null,
        right: lanternOnLeft ? null : -12,
        top: -23,
        child: IgnorePointer(
          child: Image.asset(
            'assets/images/home/jp_lantern.png',
            width: 44,
            height: 66,
            fit: BoxFit.contain,
          ),
        ),
      ),
    ],
  );
}
