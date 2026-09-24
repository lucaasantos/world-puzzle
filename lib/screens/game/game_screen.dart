import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/japan_theme.dart';
import '../../core/utils/formatters.dart';
import '../../engine/puzzle_engine.dart';
import '../../engine/puzzle_scoring.dart';
import '../../models/game_theme.dart';
import '../../models/puzzle_level.dart';
import '../../models/puzzle_result.dart';
import '../../models/saved_game.dart';
import '../../widgets/puzzle_board/puzzle_board.dart';
import '../victory/victory_screen.dart';
import '../online/player_screens.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({required this.theme, required this.level, super.key});
  final GameTheme theme;
  final PuzzleLevel level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late PuzzleEngine _engine;
  AppController? _controller;
  Timer? _timer;
  int _seconds = 0;
  int _moves = 0;
  late int _livesRemaining;
  late int _currentMoveLimit;
  late int _currentTimeLimitSeconds;
  bool _paused = false;
  bool _completed = false;
  bool _configured = false;
  bool _handlingLimit = false;
  bool _openingReference = false;
  PuzzleLevel get _level => widget.level;
  bool _starting = false;
  String? _onlineError;
  bool _pendingFinish = false;
  bool _finishing = false;
  bool _journalBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = PuzzleEngine(gridSize: _level.gridSize);
    _livesRemaining = _level.maxLives;
    _currentMoveLimit = _level.oneStarMaxMoves;
    _currentTimeLimitSeconds = _level.oneStarMaxTimeSeconds;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configured) return;
    _configured = true;
    _controller = AppScope.of(context, listen: false);
    unawaited(_controller!.ads.initialize());
    if (_controller!.isOnline) {
      _paused = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _beginOnline());
      return;
    }
    final saved = _controller!.savedGame;
    if (saved != null &&
        saved.themeId == widget.theme.id &&
        saved.levelId == _level.id &&
        saved.board.length == _level.gridSize * _level.gridSize) {
      _engine = PuzzleEngine(gridSize: _level.gridSize, board: saved.board);
      _seconds = saved.elapsedSeconds;
      _moves = saved.moves;
      _livesRemaining = saved.livesRemaining.clamp(1, _level.maxLives);
      _currentMoveLimit = saved.currentMoveLimit > _moves
          ? saved.currentMoveLimit
          : _moves + _level.oneStarMaxMoves;
      _currentTimeLimitSeconds = saved.currentTimeLimitSeconds > _seconds
          ? saved.currentTimeLimitSeconds
          : _seconds + _level.oneStarMaxTimeSeconds;
    }
    if (!_controller!.snapshot.onboardingSeen && _level.number == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFirstTip());
    }
    _startTimer();
    precacheImage(AssetImage(_level.imagePath), context);
  }

  Future<void> _beginOnline() async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _onlineError = null;
    });
    final service = _controller!.online!;
    try {
      final difficulty = widget.level.difficultyId;
      final current = service.attempt;
      if (current != null &&
          current['countryId'] == widget.theme.id &&
          current['levelId'] == widget.level.id &&
          current['difficulty'] == difficulty &&
          ['active', 'completed'].contains(current['state'])) {
        _pendingFinish = current['state'] == 'completed';
      }
      final attempt = _pendingFinish
          ? current!
          : await service.start(widget.theme.id, widget.level.id, difficulty);
      _engine = PuzzleEngine(
        gridSize: _level.gridSize,
        board: (attempt['board'] as List).cast<int>(),
      );
      for (final position in service.attemptMoves) {
        if (!_engine.move(position)) {
          throw StateError('Partida salva inválida.');
        }
      }
      _moves = service.attemptMoves.length;
      _seconds =
          ((service.serverNow - (attempt['startedAt'] as num).toInt()) ~/ 1000)
              .clamp(0, 172800);
      _livesRemaining = 1;
      _currentMoveLimit = _level.oneStarMaxMoves;
      _currentTimeLimitSeconds = _level.oneStarMaxTimeSeconds;
      if (mounted) setState(() => _paused = false);
      _startTimer();
      if (_engine.isSolved || _pendingFinish) await _finish();
      unawaited(_controller!.refreshOnline().catchError((Object _) {}));
    } catch (e) {
      if (mounted && service.lives == 0) {
        setState(() => _onlineError = null);
        await showLives(context);
      } else if (mounted) {
        setState(() => _onlineError = onlineError(e));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted ||
          _completed ||
          _handlingLimit ||
          (_paused && !_controller!.isOnline)) {
        return;
      }
      setState(() {
        final online = _controller!.online;
        _seconds = online == null
            ? _seconds + 1
            : ((online.serverNow -
                          (online.attempt!['startedAt'] as num).toInt()) ~/
                      1000)
                  .clamp(0, 172800);
      });
      if (_seconds > _currentTimeLimitSeconds) {
        await _handleExceededLimit('tempo');
      }
    });
  }

  Future<void> _showFirstTip() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.swipe_rounded),
        title: const Text('Como jogar'),
        content: const Text(
          'Toque em uma peça ao lado do espaço vazio para movê-la.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
    await _controller?.markOnboardingSeen();
  }

  void _move(int position) {
    if (_paused ||
        _completed ||
        _starting ||
        _journalBusy ||
        _onlineError != null ||
        (_controller!.isOnline && _controller!.online!.attempt == null) ||
        !_engine.canMove(position)) {
      return;
    }
    setState(() {
      _engine.move(position);
      _moves++;
    });
    if (_controller!.isOnline) {
      _controller!.online!.attemptMoves.add(position);
      // Serialize the local move journal before accepting another move.
      _journalBusy = true;
      unawaited(
        _controller!.online!.saveJournal().whenComplete(
          () => _journalBusy = false,
        ),
      );
    }
    _controller?.haptics.move();
    _controller?.audio.move();
    if (_engine.isSolved) {
      _finish();
      return;
    }
    _persist();
    if (_moves > _currentMoveLimit) {
      unawaited(_handleExceededLimit('movimentos'));
    }
  }

  Future<void> _handleExceededLimit(String reason) async {
    if (_handlingLimit || _completed || !mounted) return;
    _handlingLimit = true;
    if (_controller!.isOnline) {
      _timer?.cancel();
      setState(() => _paused = true);
      try {
        await _controller!.online!.end('failed');
        await _controller!.refreshOnline();
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Tentativa encerrada'),
              content: Text(
                'O limite de $reason foi atingido. Inicie outra tentativa para continuar.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          );
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) setState(() => _onlineError = onlineError(e));
      }
      _handlingLimit = false;
      return;
    }
    if (_livesRemaining > 1) {
      setState(() {
        _livesRemaining--;
        _currentMoveLimit = _moves + _level.oneStarMaxMoves;
        _currentTimeLimitSeconds = _seconds + _level.oneStarMaxTimeSeconds;
      });
      await _persist();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Limite de $reason excedido. Você perdeu 1 de energia.',
              ),
            ),
          );
      }
      _handlingLimit = false;
      return;
    }

    setState(() {
      _livesRemaining = 0;
      _paused = true;
    });
    _timer?.cancel();
    await _controller?.clearSavedGame();
    if (!mounted) return;
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.bolt_rounded,
          color: Color(0xFFFFD54F),
          size: 36,
        ),
        title: const Text('Sua energia acabou'),
        content: Text(
          'Você excedeu o limite de $reason. Tente a fase novamente para recuperar sua energia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar às fases'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (retry == true) {
      _resetAfterGameOver();
    } else {
      _completed = true;
      Navigator.pop(context);
    }
    _handlingLimit = false;
  }

  void _resetAfterGameOver() {
    setState(() {
      _engine = PuzzleEngine(gridSize: _level.gridSize);
      _seconds = 0;
      _moves = 0;
      _livesRemaining = _level.maxLives;
      _currentMoveLimit = _level.oneStarMaxMoves;
      _currentTimeLimitSeconds = _level.oneStarMaxTimeSeconds;
      _paused = false;
    });
    _startTimer();
    _persist();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _completed = true;
    _timer?.cancel();
    unawaited(_controller!.haptics.victory());
    unawaited(_controller!.audio.victory());
    final result = PuzzleResult(
      levelId: _level.id,
      themeId: widget.theme.id,
      gridSize: _level.gridSize,
      elapsedSeconds: _seconds,
      moves: _moves,
      stars: PuzzleScoring.calculate(
        level: _level,
        elapsedSeconds: _seconds,
        moves: _moves,
      ),
      completedAt: DateTime.now(),
    );
    final outcomeFuture = _controller!.isOnline
        ? _finishOnlineInBackground()
        : _controller!.recordResult(widget.theme, result);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => VictoryScreen(
          theme: widget.theme,
          level: _level,
          result: result,
          outcomeFuture: outcomeFuture,
        ),
      ),
    );
  }

  Future<CompletionOutcome> _finishOnlineInBackground() async {
    final outcome = await _controller!.finishOnline();
    _controller!.online!.attempt = null;
    _controller!.online!.attemptMoves = [];
    await _controller!.online!.saveJournal();
    return outcome;
  }

  void _togglePause() {
    if (_starting || _completed || _onlineError != null) return;
    setState(() => _paused = !_paused);
    if (_paused) _persist();
  }

  Future<void> _showReference() => showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Hero(
                  tag: 'reference-${_level.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(_level.imagePath, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 8,
              child: IconButton.filled(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _showReferenceAfterAd() async {
    if (_paused || _completed || _openingReference) return;
    setState(() {
      _openingReference = true;
      _paused = true;
    });
    await _persist();
    try {
      final watchedAd = await _controller?.ads.showRewarded() ?? false;
      if (!mounted) return;
      if (!watchedAd) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'O anúncio ainda não está disponível. Tente novamente em instantes.',
              ),
            ),
          );
        return;
      }
      await _showReference();
    } finally {
      if (mounted && !_completed) {
        setState(() {
          _openingReference = false;
          _paused = false;
        });
      }
    }
  }

  Future<void> _showLevelInfo() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Requisitos da fase ${_level.number}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${_level.gridSize}×${_level.gridSize} • ${_level.maxLives} de energia por tentativa',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            _StarRequirement(
              stars: 3,
              moves: _level.threeStarsMaxMoves,
              seconds: _level.threeStarsMaxTimeSeconds,
            ),
            const SizedBox(height: 10),
            _StarRequirement(
              stars: 2,
              moves: _level.twoStarsMaxMoves,
              seconds: _level.twoStarsMaxTimeSeconds,
            ),
            const SizedBox(height: 10),
            _StarRequirement(
              stars: 1,
              moves: _level.oneStarMaxMoves,
              seconds: _level.oneStarMaxTimeSeconds,
            ),
            const SizedBox(height: 16),
            const Text(
              'É preciso cumprir os dois requisitos: movimentos e tempo. Ao exceder o limite principal, você perde energia.',
              style: TextStyle(color: AppTheme.textMuted, height: 1.35),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _persist() async {
    if (_controller?.isOnline == true) {
      await _controller!.online!.saveJournal();
      return;
    }
    if (_completed) return;
    await _controller?.saveGame(
      SavedGame(
        themeId: widget.theme.id,
        levelId: _level.id,
        board: List<int>.of(_engine.board),
        elapsedSeconds: _seconds,
        moves: _moves,
        livesRemaining: _livesRemaining,
        currentMoveLimit: _currentMoveLimit,
        currentTimeLimitSeconds: _currentTimeLimitSeconds,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) &&
        !_completed) {
      if (mounted) setState(() => _paused = true);
      _persist();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (!_completed) _persist();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isJapan = widget.theme.id == 'japan';
    final japanPalette = isJapan ? JapanPalette.forLevel(_level.number) : null;
    final scaffold = Scaffold(
      backgroundColor: japanPalette?.backgroundBottom,
      appBar: AppBar(
        backgroundColor: japanPalette?.backgroundTop,
        foregroundColor: japanPalette?.headerText,
        flexibleSpace: japanPalette == null
            ? null
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      japanPalette.backgroundTop,
                      japanPalette.backgroundBottom,
                    ],
                  ),
                ),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.theme.name,
              style: TextStyle(
                fontFamily: isJapan ? 'serif' : null,
                fontSize: isJapan ? 19 : 16,
                fontWeight: FontWeight.w900,
                letterSpacing: isJapan ? 1 : 0,
              ),
            ),
            Text(
              'FASE ${_level.number}  •  ${_level.gridSize}×${_level.gridSize}',
              style: TextStyle(
                fontFamily: isJapan ? 'serif' : null,
                fontSize: 10,
                color:
                    japanPalette?.headerText.withValues(alpha: .72) ??
                    Colors.white54,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        actions: [
          const CurrentEnergyIndicator(interactive: false, light: true),
          if (_controller?.isOnline == true)
            IconButton(
              tooltip: 'Abandonar tentativa',
              icon: const Icon(Icons.exit_to_app),
              onPressed: () async {
                try {
                  await _controller!.online!.end('abandoned');
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) setState(() => _onlineError = onlineError(e));
                }
              },
            ),
          IconButton(
            tooltip: 'Informações da fase',
            onPressed: _showLevelInfo,
            icon: const Icon(Icons.info_outline_rounded),
          ),
          IconButton(
            tooltip: _paused ? 'Continuar' : 'Pausar',
            onPressed: _togglePause,
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (japanPalette != null)
            JapanBackdrop(imagePath: _level.imagePath, palette: japanPalette),
          SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = math
                    .min(constraints.maxWidth - 32, constraints.maxHeight - 290)
                    .clamp(220.0, 620.0);
                final puzzleBoard = PuzzleBoard(
                  board: _engine.board,
                  gridSize: _level.gridSize,
                  imagePath: _level.imagePath,
                  blocked: _paused || _completed,
                  squareCorners: isJapan,
                  onTileTap: _move,
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    children: [
                      if (_starting) const LinearProgressIndicator(),
                      if (_onlineError != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  _onlineError!,
                                  textAlign: TextAlign.center,
                                ),
                                TextButton(
                                  onPressed: () => _pendingFinish
                                      ? _finish()
                                      : _beginOnline(),
                                  child: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: _GameMetric(
                              icon: Icons.schedule_rounded,
                              label: 'TEMPO',
                              value:
                                  '${formatDuration(_seconds)} / ${formatDuration(_currentTimeLimitSeconds)}',
                              japanPalette: japanPalette,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _GameMetric(
                              icon: Icons.touch_app_outlined,
                              label: 'MOVIMENTOS',
                              value: '$_moves / $_currentMoveLimit',
                              japanPalette: japanPalette,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _LivesIndicator(
                        remaining: _livesRemaining,
                        maximum: _level.maxLives,
                        japanPalette: japanPalette,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: boardSize,
                        height: boardSize,
                        child: Stack(
                          children: [
                            Positioned.fill(child: puzzleBoard),
                            if (_paused)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color:
                                        japanPalette?.backgroundBottom
                                            .withValues(alpha: .94) ??
                                        const Color(0xF2181C1D),
                                    borderRadius: BorderRadius.circular(
                                      japanPalette == null ? 18 : 0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.pause_circle_outline_rounded,
                                          size: 50,
                                          color:
                                              japanPalette?.accent ??
                                              AppTheme.primary,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'JOGO PAUSADO',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        FilledButton.tonal(
                                          onPressed: _openingReference
                                              ? null
                                              : _togglePause,
                                          child: Text(
                                            _openingReference
                                                ? 'Carregando anúncio…'
                                                : 'Continuar',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ReferencePreview(
                        imagePath: _level.imagePath,
                        loading: _openingReference,
                        japanPalette: japanPalette,
                        onTap: _paused ? null : _showReferenceAfterAd,
                      ),
                    ],
                  ),
                );
              },
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

class _GameMetric extends StatelessWidget {
  const _GameMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.japanPalette,
  });
  final IconData icon;
  final String label;
  final String value;
  final JapanPalette? japanPalette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: japanPalette?.panel.withValues(alpha: .92) ?? AppTheme.surface,
      borderRadius: BorderRadius.circular(17),
      border: japanPalette == null
          ? null
          : Border.all(color: japanPalette!.accent.withValues(alpha: .45)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: japanPalette?.accent ?? AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 9, letterSpacing: 1).copyWith(
                  color:
                      japanPalette?.text.withValues(alpha: .68) ??
                      AppTheme.textMuted,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ).copyWith(color: japanPalette?.text),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EnergyIndicator extends StatelessWidget {
  const _EnergyIndicator({
    required this.remaining,
    required this.maximum,
    this.japanPalette,
  });
  final int remaining;
  final int maximum;
  final JapanPalette? japanPalette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: japanPalette?.panel.withValues(alpha: .92) ?? AppTheme.surface,
      borderRadius: BorderRadius.circular(17),
      border: japanPalette == null
          ? null
          : Border.all(color: japanPalette!.accent.withValues(alpha: .45)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ENERGIA',
          style: TextStyle(
            fontSize: 9,
            color:
                japanPalette?.text.withValues(alpha: .68) ?? AppTheme.textMuted,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        for (var index = 0; index < maximum; index++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              index < remaining ? Icons.bolt_rounded : Icons.bolt_outlined,
              size: 20,
              color: index < remaining
                  ? (japanPalette?.accent ?? const Color(0xFFFFD54F))
                  : (japanPalette?.text.withValues(alpha: .24) ??
                        Colors.white24),
            ),
          ),
      ],
    ),
  );
}

typedef _LivesIndicator = _EnergyIndicator;

class _ReferencePreview extends StatelessWidget {
  const _ReferencePreview({
    required this.imagePath,
    required this.loading,
    required this.onTap,
    this.japanPalette,
  });

  final String imagePath;
  final bool loading;
  final VoidCallback? onTap;
  final JapanPalette? japanPalette;

  @override
  Widget build(BuildContext context) {
    final panel = japanPalette?.panel ?? AppTheme.surface;
    final accent = japanPalette?.accent ?? AppTheme.primary;
    final text = japanPalette?.text ?? Colors.white;
    return Semantics(
      button: true,
      label: 'Assistir anúncio para visualizar a imagem completa',
      child: Material(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 94,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  color: Colors.black.withValues(alpha: .25),
                  colorBlendMode: BlendMode.darken,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: accent.withValues(alpha: .75),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        panel.withValues(alpha: .96),
                        panel.withValues(alpha: .72),
                        Colors.transparent,
                      ],
                      stops: const [0, .56, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRÉVIA DA IMAGEM',
                              style: TextStyle(
                                color: accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Ver imagem completa',
                              style: TextStyle(
                                color: text,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Disponível após um anúncio',
                              style: TextStyle(
                                color: text.withValues(alpha: .68),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 8),
                          ],
                        ),
                        child: loading
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: panel,
                                ),
                              )
                            : Icon(
                                Icons.fullscreen_rounded,
                                color: panel,
                                size: 27,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRequirement extends StatelessWidget {
  const _StarRequirement({
    required this.stars,
    required this.moves,
    required this.seconds,
  });
  final int stars;
  final int moves;
  final int seconds;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            stars,
            (_) => const Icon(
              Icons.star_rounded,
              color: Color(0xFFF4CD6A),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Até $moves movimentos e ${formatDuration(seconds)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
