import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../core/localization/daily_exploration_strings.dart';
import '../../core/localization/star_dust_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/japan_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/packs_data.dart';
import '../../data/jigsaw_levels_data.dart';
import '../../models/game_theme.dart';
import '../../models/jigsaw_level.dart';
import '../../models/puzzle_level.dart';
import '../../models/puzzle_result.dart';
import '../game/game_screen.dart';
import '../jigsaw/jigsaw_game_screen.dart';
import '../packs/packs_screen.dart';
import '../star_dust/star_dust_screen.dart';

class VictoryScreen extends StatefulWidget {
  const VictoryScreen({
    required this.theme,
    required this.level,
    required this.result,
    this.outcome = const CompletionOutcome(),
    this.outcomeFuture,
    this.jigsawLevel,
    this.replayBuilder,
    this.metricLabel = 'MOVIMENTOS',
    this.metricValue,
    this.score,
    super.key,
  });
  final GameTheme theme;
  final PuzzleLevel level;
  final PuzzleResult result;
  final CompletionOutcome outcome;
  final Future<CompletionOutcome>? outcomeFuture;
  final JigsawLevel? jigsawLevel;
  final WidgetBuilder? replayBuilder;
  final String metricLabel;
  final String? metricValue;
  final int? score;

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen> {
  bool _saving = false;
  late CompletionOutcome _outcome;
  bool _processingOutcome = false;
  String? _outcomeError;

  @override
  void initState() {
    super.initState();
    _outcome = widget.outcome;
    final future = widget.outcomeFuture;
    if (future != null) {
      _processingOutcome = true;
      future.then<void>(
        (outcome) {
          if (!mounted) return;
          setState(() {
            _outcome = outcome;
            _processingOutcome = false;
          });
        },
        onError: (Object _, StackTrace __) {
          if (!mounted) return;
          setState(() {
            _processingOutcome = false;
            _outcomeError =
                'Não foi possível sincronizar a conclusão. Seu progresso foi preservado para nova tentativa.';
          });
        },
      );
    }
  }

  Future<void> _saveWallpaper() async {
    setState(() => _saving = true);
    final ok = await AppScope.of(
      context,
      listen: false,
    ).wallpaper.save(widget.theme.wallpaper);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Wallpaper salvo na galeria.'
              : 'Não foi possível salvar. Verifique a permissão da galeria.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isJapan = JapanTheme.matches(widget.theme.id);
    final japanPalette = isJapan
        ? JapanPalette.forLevel(widget.level.number)
        : null;
    final current = widget.theme.levels.indexWhere(
      (level) => level.id == widget.level.id,
    );
    final next = current >= 0 && current < widget.theme.levels.length - 1
        ? widget.theme.levels[current + 1]
        : null;
    final jigsawLevels = jigsawLevelsFor(widget.theme.id);
    final jigsawIndex = widget.jigsawLevel == null
        ? -1
        : jigsawLevels.indexWhere(
            (level) => level.id == widget.jigsawLevel!.id,
          );
    final nextJigsaw = jigsawIndex >= 0 && jigsawIndex < jigsawLevels.length - 1
        ? jigsawLevels[jigsawIndex + 1]
        : null;
    final scaffold = Scaffold(
      backgroundColor: japanPalette?.backgroundBottom,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (japanPalette != null)
            JapanBackdrop(
              imagePath: widget.level.imagePath,
              palette: japanPalette,
              imageOpacity: .28,
            ),
          if (japanPalette != null) ...[
            Positioned(
              left: 8,
              top: 12,
              child: Image.asset(
                'assets/images/home/jp_lantern.png',
                width: 54,
                height: 82,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 8,
              top: 12,
              child: Transform.flip(
                flipX: true,
                child: Image.asset(
                  'assets/images/home/jp_lantern.png',
                  width: 54,
                  height: 82,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 34),
              children: [
                if (_outcome.xpEarned > 0)
                  Text(
                    '+${_outcome.xpEarned} XP',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .7, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (_, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: japanPalette == null
                      ? const Icon(
                          Icons.check_circle_rounded,
                          size: 78,
                          color: AppTheme.primary,
                        )
                      : _JapanCompletionMark(palette: japanPalette),
                ),
                SizedBox(height: japanPalette == null ? 22 : 14),
                if (japanPalette != null) ...[
                  Text(
                    'JORNADA PELO JAPÃO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: japanPalette.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                ],
                Text(
                  'FASE CONCLUÍDA',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                _StarDustRewardAnimation(
                  key: ValueKey(
                    '${_outcome.starDustEarned}:${_outcome.starDustBalance}',
                  ),
                  stars: widget.result.stars,
                  outcome: _outcome,
                ),
                if (_processingOutcome) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: 6),
                  const Text(
                    'Salvando recompensas…',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
                if (_outcomeError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _outcomeError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.orangeAccent),
                  ),
                ],
                if (_outcome.isNewRecord) ...[
                  const SizedBox(height: 10),
                  Text(
                    'NOVO RECORDE!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: japanPalette?.accent ?? AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _ResultMetric(
                        label: 'TEMPO',
                        value: formatDuration(widget.result.elapsedSeconds),
                        japanPalette: japanPalette,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResultMetric(
                        label: widget.metricLabel,
                        value: widget.metricValue ?? '${widget.result.moves}',
                        japanPalette: japanPalette,
                      ),
                    ),
                  ],
                ),
                if (_outcome.packRewardId != null) ...[
                  const SizedBox(height: 24),
                  _PackRewardPanel(packId: _outcome.packRewardId!),
                ],
                if (_outcome.dailyPointsEarned > 0) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: .35),
                      ),
                    ),
                    child: Text(
                      DailyExplorationStrings.of(context).dailyFeedback(
                        _outcome.dailyPointsEarned,
                        _outcome.dailyScore,
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (widget.score != null) ...[
                    const SizedBox(height: 12),
                    _ResultMetric(
                      label: 'PONTOS',
                      value: '${widget.score}',
                      japanPalette: japanPalette,
                    ),
                  ],
                ],
                if (_outcome.wallpaperJustUnlocked) ...[
                  const SizedBox(height: 26),
                  Container(
                    decoration: BoxDecoration(
                      color:
                          japanPalette?.panel.withValues(alpha: .94) ??
                          AppTheme.surface,
                      borderRadius: BorderRadius.circular(
                        japanPalette == null ? 24 : 10,
                      ),
                      border: japanPalette == null
                          ? null
                          : Border.all(
                              color: japanPalette.accent.withValues(alpha: .55),
                            ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 230,
                          child: Image.asset(
                            widget.theme.wallpaper,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              const Text(
                                'COLEÇÃO CONCLUÍDA',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Wallpaper de ${widget.theme.name} desbloqueado',
                                style: TextStyle(
                                  color:
                                      japanPalette?.text.withValues(
                                        alpha: .72,
                                      ) ??
                                      AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: _saving ? null : _saveWallpaper,
                                icon: _saving
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.download_rounded),
                                label: const Text('Salvar wallpaper'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                if (nextJigsaw != null)
                  FilledButton.icon(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => JigsawGameScreen(
                          theme: widget.theme,
                          level: nextJigsaw,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Próxima dificuldade'),
                  )
                else if (widget.jigsawLevel == null && next != null)
                  FilledButton.icon(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            GameScreen(theme: widget.theme, level: next),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Próxima fase'),
                  ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (routeContext) => widget.replayBuilder != null
                          ? widget.replayBuilder!(routeContext)
                          : widget.jigsawLevel == null
                          ? GameScreen(theme: widget.theme, level: widget.level)
                          : JigsawGameScreen(
                              theme: widget.theme,
                              level: widget.jigsawLevel!,
                            ),
                    ),
                  ),
                  child: const Text('Jogar novamente'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Voltar às fases'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (japanPalette == null) return scaffold;
    return Theme(
      data: JapanTheme.apply(context, japanPalette),
      child: scaffold,
    );
  }
}

class _PackRewardPanel extends StatelessWidget {
  const _PackRewardPanel({required this.packId});
  final String packId;

  @override
  Widget build(BuildContext context) {
    final pack = PackCatalog.byId(packId);
    if (pack == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF24465B), Color(0xFF182B36)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF82CFF4).withValues(alpha: .4),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_rounded,
            size: 42,
            color: Color(0xFF82CFF4),
          ),
          const SizedBox(height: 10),
          Text(
            'Você ganhou um ${pack.name}!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'O pacote foi salvo e pode ser aberto quando você quiser.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const PacksScreen()),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('VER PACOTES'),
          ),
        ],
      ),
    );
  }
}

class _StarDustRewardAnimation extends StatefulWidget {
  const _StarDustRewardAnimation({
    required this.stars,
    required this.outcome,
    super.key,
  });
  final int stars;
  final CompletionOutcome outcome;

  @override
  State<_StarDustRewardAnimation> createState() =>
      _StarDustRewardAnimationState();
}

class _StarDustRewardAnimationState extends State<_StarDustRewardAnimation> {
  final _timers = <Timer>[];
  late final List<int> _particlePhases;
  int _revealedStars = 0;
  late int _balance;
  bool _jarGlowing = false;

  @override
  void initState() {
    super.initState();
    _balance = widget.outcome.starDustBefore;
    _particlePhases = List.filled(widget.outcome.starDustEarned, 0);
    for (var index = 0; index < widget.stars; index++) {
      _timers.add(
        Timer(Duration(milliseconds: 180 + index * 210), () {
          if (mounted) setState(() => _revealedStars = index + 1);
        }),
      );
    }
    for (var index = 0; index < _particlePhases.length; index++) {
      final start = 850 + index * 230;
      _timers.add(
        Timer(Duration(milliseconds: start), () {
          if (mounted) setState(() => _particlePhases[index] = 1);
        }),
      );
      _timers.add(
        Timer(Duration(milliseconds: start + 430), () {
          if (!mounted) return;
          setState(() {
            _particlePhases[index] = 2;
            _balance = (widget.outcome.starDustBefore + index + 1).clamp(
              0,
              100,
            );
            _jarGlowing = true;
          });
        }),
      );
      _timers.add(
        Timer(Duration(milliseconds: start + 610), () {
          if (mounted) setState(() => _jarGlowing = false);
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = StarDustStrings.of(context);
    if (!widget.outcome.starDustTracked) {
      return SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Icon(
              index < widget.stars
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: index < widget.stars
                  ? const Color(0xFFF4CD6A)
                  : Colors.white24,
              size: 38,
            ),
          ),
        ),
      );
    }
    final message = widget.outcome.starDustEarned > 0
        ? '${copy['newWeeklyRecord']}  ${copy.earned(widget.outcome.starDustEarned)}'
        : widget.outcome.newWeeklyRecord && widget.outcome.starDustFull
        ? copy['full']
        : copy['alreadyCollected'];
    return Column(
      children: [
        SizedBox(
          height: 144,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final center = constraints.maxWidth / 2;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    left: center - 64,
                    child: Row(
                      children: List.generate(3, (index) {
                        final earned = index < widget.stars;
                        final visible = index < _revealedStars;
                        return AnimatedScale(
                          scale: visible ? 1 : .25,
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.elasticOut,
                          child: AnimatedOpacity(
                            opacity: visible ? 1 : 0,
                            duration: const Duration(milliseconds: 150),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Icon(
                                earned
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: earned
                                    ? const Color(0xFFF4CD6A)
                                    : Colors.white24,
                                size: 38,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  for (var index = 0; index < _particlePhases.length; index++)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 430),
                      curve: Curves.easeInBack,
                      top: _particlePhases[index] == 0 ? 15 : 82,
                      left: _particlePhases[index] == 0
                          ? center - 51 + index * 38
                          : center - 11,
                      child: AnimatedOpacity(
                        opacity: _particlePhases[index] == 2 ? 0 : 1,
                        duration: const Duration(milliseconds: 100),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFE27D),
                          size: 22,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: center - 38,
                    child: StarDustJar(size: 76, glowing: _jarGlowing),
                  ),
                  Positioned(
                    bottom: 3,
                    left: center + 37,
                    child: Text(
                      '$_balance / 100',
                      style: const TextStyle(
                        color: Color(0xFFFFDF85),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.outcome.starDustEarned > 0
                ? const Color(0xFFFFDF85)
                : AppTheme.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (widget.outcome.starDustFull &&
            widget.outcome.starDustPotential > widget.outcome.starDustEarned)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              copy['full'],
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.label,
    required this.value,
    this.japanPalette,
  });
  final String label;
  final String value;
  final JapanPalette? japanPalette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      color: japanPalette?.panel.withValues(alpha: .92) ?? AppTheme.surface,
      borderRadius: BorderRadius.circular(japanPalette == null ? 18 : 8),
      border: japanPalette == null
          ? null
          : Border.all(color: japanPalette!.accent.withValues(alpha: .5)),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color:
                japanPalette?.text.withValues(alpha: .68) ?? AppTheme.textMuted,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _JapanCompletionMark extends StatelessWidget {
  const _JapanCompletionMark({required this.palette});
  final JapanPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    width: 82,
    height: 82,
    decoration: BoxDecoration(
      color: palette.panel.withValues(alpha: .9),
      shape: BoxShape.circle,
      border: Border.all(color: palette.accent, width: 3),
      boxShadow: [
        BoxShadow(
          color: palette.accent.withValues(alpha: .24),
          blurRadius: 24,
          spreadRadius: 4,
        ),
      ],
    ),
    child: Icon(Icons.check_rounded, size: 48, color: palette.accent),
  );
}
