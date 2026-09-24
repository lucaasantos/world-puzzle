import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../core/utils/formatters.dart';
import '../../engine/jigsaw_engine.dart';
import '../../engine/jigsaw_scoring.dart';
import '../../models/game_theme.dart';
import '../../models/jigsaw_level.dart';
import '../../models/puzzle_result.dart';
import '../../widgets/jigsaw/jigsaw_board.dart';
import '../online/player_screens.dart';
import '../victory/victory_screen.dart';

class JigsawGameScreen extends StatefulWidget {
  const JigsawGameScreen({required this.theme, required this.level, super.key});

  final GameTheme theme;
  final JigsawLevel level;

  @override
  State<JigsawGameScreen> createState() => _JigsawGameScreenState();
}

class _JigsawGameScreenState extends State<JigsawGameScreen>
    with WidgetsBindingObserver {
  late final JigsawEngine _engine;
  AppController? _controller;
  ui.Image? _image;
  Timer? _timer;
  int _seconds = 0;
  int _moves = 0;
  bool _paused = true;
  bool _completed = false;
  bool _finishing = false;
  String? _error;
  final _placements = <int>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = JigsawEngine(
      rows: widget.level.rows,
      columns: widget.level.columns,
      snapToleranceFactor: widget.level.snapToleranceFactor,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    _controller = AppScope.of(context, listen: false);
    try {
      final data = await rootBundle.load(widget.level.imagePath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (_controller!.isOnline) {
        await _controller!.online!.start(
          widget.theme.id,
          widget.level.id,
          widget.level.difficulty,
          gameMode: 'jigsaw',
        );
        unawaited(_controller!.refreshOnline().catchError((Object _) {}));
      }
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _image = frame.image;
        _paused = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && !_paused && !_completed) {
          setState(() => _seconds++);
        }
      });
    } catch (error) {
      if (mounted && _controller?.online?.lives == 0) {
        setState(() => _error = null);
        await showLives(context);
      } else if (mounted) {
        setState(() => _error = onlineError(error));
      }
    }
  }

  void _move(int _) => setState(() => _moves++);

  void _snap(int id) {
    _placements.add(id);
    _controller?.haptics.move();
    _controller?.audio.move();
  }

  Future<void> _finish() async {
    if (_finishing || _completed || !_engine.isComplete) return;
    _finishing = true;
    setState(() => _completed = true);
    _timer?.cancel();
    unawaited(_controller!.haptics.victory());
    unawaited(_controller!.audio.victory());
    final localStars = JigsawScoring.stars(
      level: widget.level,
      elapsedSeconds: _seconds,
      moves: _moves,
    );
    final localScore = JigsawScoring.score(
      level: widget.level,
      elapsedSeconds: _seconds,
      moves: _moves,
    );
    final result = _result(localStars, localScore);
    final outcomeFuture = _controller!.isOnline
        ? _finishOnlineInBackground()
        : _controller!.recordResult(widget.theme, result);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => VictoryScreen(
          theme: widget.theme,
          level: widget.level.puzzleLevel,
          result: result,
          outcomeFuture: outcomeFuture,
          jigsawLevel: widget.level,
        ),
      ),
    );
  }

  Future<CompletionOutcome> _finishOnlineInBackground() async {
    final outcome = await _controller!.finishOnline(
      moveCount: _moves,
      placements: _placements,
    );
    _controller!.online!.attempt = null;
    _controller!.online!.attemptMoves = [];
    await _controller!.online!.saveJournal();
    return outcome;
  }

  PuzzleResult _result(int stars, int score) => PuzzleResult(
    levelId: widget.level.id,
    themeId: widget.theme.id,
    gridSize: widget.level.rows,
    elapsedSeconds: _seconds,
    moves: _moves,
    stars: stars,
    completedAt: DateTime.now(),
    gameMode: 'jigsaw',
    difficulty: widget.level.difficulty,
    score: score,
  );

  Future<void> _preview() => showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Image.asset(widget.level.imagePath, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                tooltip: 'Fechar',
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<bool> _confirmExit() async {
    if (_completed) return true;
    final wasPaused = _paused;
    setState(() => _paused = true);
    final exit =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sair do quebra-cabeças?'),
            content: const Text('O progresso desta partida será perdido.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continuar jogando'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sair'),
              ),
            ],
          ),
        ) ??
        false;
    if (!exit && mounted) setState(() => _paused = wasPaused);
    if (exit && _controller?.isOnline == true) {
      await _controller!.online!.end('abandoned');
    }
    return exit;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) &&
        !_completed &&
        mounted) {
      setState(() => _paused = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _completed,
    onPopInvokedWithResult: (didPop, _) async {
      if (!didPop && await _confirmExit() && context.mounted) {
        Navigator.pop(context);
      }
    },
    child: Scaffold(
      backgroundColor: const Color(0xFF2C1810),
      appBar: AppBar(
        title: Text(
          '${widget.theme.name} • ${widget.level.puzzleLevel.difficultyLabel}',
        ),
        leading: IconButton(
          tooltip: 'Sair',
          onPressed: () async {
            if (await _confirmExit() && context.mounted) Navigator.pop(context);
          },
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          const CurrentEnergyIndicator(interactive: false, light: true),
          IconButton(
            key: const Key('jigsaw_preview_button'),
            tooltip: 'Ver imagem',
            onPressed: _image == null ? null : _preview,
            icon: const Icon(Icons.image_outlined),
          ),
          IconButton(
            tooltip: _paused ? 'Continuar' : 'Pausar',
            onPressed: _image == null
                ? null
                : () => setState(() => _paused = !_paused),
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _error != null
            ? _ErrorState(message: _error!, retry: _initialize)
            : _image == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final ratio = _image!.width / _image!.height;
                  final maxBoardHeight = (constraints.maxHeight - 174).clamp(
                    120.0,
                    520.0,
                  );
                  final layout = JigsawBoardLayout.fit(
                    availableWidth: constraints.maxWidth - 32,
                    availableHeight: maxBoardHeight,
                    imageAspectRatio: ratio,
                    rows: widget.level.rows,
                    columns: widget.level.columns,
                  );
                  return Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _Metric(
                                  icon: Icons.timer_outlined,
                                  value: formatDuration(_seconds),
                                ),
                                _Metric(
                                  icon: Icons.touch_app_outlined,
                                  value: '$_moves',
                                ),
                                _Metric(
                                  icon: Icons.extension_rounded,
                                  value:
                                      '${_engine.placedPieces}/${_engine.pieces.length}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            JigsawBoard(
                              engine: _engine,
                              image: _image!,
                              boardLayout: layout,
                              blocked: _paused || _completed,
                              onMove: _move,
                              onSnap: _snap,
                              onComplete: _finish,
                            ),
                          ],
                        ),
                      ),
                      if (_paused)
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: .62),
                            child: Center(
                              child: FilledButton.icon(
                                onPressed: () =>
                                    setState(() => _paused = false),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Continuar'),
                              ),
                            ),
                          ),
                        ),
                      if (_completed)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              opacity: 1,
                              duration: const Duration(milliseconds: 300),
                              child: ColoredBox(
                                color: const Color(0xDD2C1810),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Image.asset(
                                      widget.level.imagePath,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xD94A2B19),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(value)],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, size: 52),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: retry, child: const Text('Tentar novamente')),
        ],
      ),
    ),
  );
}
