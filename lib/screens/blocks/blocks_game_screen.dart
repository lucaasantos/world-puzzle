import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../config/blocks_config.dart';
import '../../core/utils/formatters.dart';
import '../../engine/blocks_engine.dart';
import '../../models/blocks_level.dart';
import '../../models/game_theme.dart';
import '../../models/puzzle_result.dart';
import '../online/player_screens.dart';
import '../victory/victory_screen.dart';

class BlocksGameScreen extends StatefulWidget {
  const BlocksGameScreen({required this.theme, required this.level, super.key});

  final GameTheme theme;
  final BlocksLevel level;

  @override
  State<BlocksGameScreen> createState() => _BlocksGameScreenState();
}

class _BlocksGameScreenState extends State<BlocksGameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late BlocksEngine _engine;
  late final Ticker _ticker;
  AppController? _controller;
  Duration _lastFrame = Duration.zero;
  int _gravityMicros = 0;
  int _lockMicros = 0;
  int _clearMicros = 0;
  int _elapsedMicros = 0;
  int _displaySeconds = 0;
  bool _loading = true;
  bool _finishing = false;
  bool _failureSent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = BlocksEngine(difficulty: widget.level.difficulty);
    _ticker = createTicker(_onFrame)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    _controller ??= AppScope.of(context, listen: false);
    try {
      if (_controller!.isOnline) {
        await _controller!.online!.start(
          widget.theme.id,
          widget.level.id,
          widget.level.difficulty.id,
          gameMode: 'blocks',
        );
        unawaited(_controller!.refreshOnline().catchError((Object _) {}));
      }
      if (!mounted) return;
      _engine.start();
      setState(() => _loading = false);
    } catch (error) {
      if (mounted && _controller?.online?.lives == 0) {
        setState(() {
          _loading = false;
          _error = null;
        });
        await showLives(context);
      } else if (mounted) {
        setState(() {
          _loading = false;
          _error = onlineError(error);
        });
      }
    }
  }

  void _onFrame(Duration elapsed) {
    final delta = _lastFrame == Duration.zero
        ? Duration.zero
        : elapsed - _lastFrame;
    _lastFrame = elapsed;
    if (!mounted || _engine.status != BlocksStatus.playing || _loading) return;
    final micros = delta.inMicroseconds.clamp(0, 100000);
    var changed = false;
    _elapsedMicros += micros;
    final seconds = _elapsedMicros ~/ Duration.microsecondsPerSecond;
    if (seconds != _displaySeconds) {
      _displaySeconds = seconds;
      changed = true;
    }

    if (_engine.pendingLines.isNotEmpty) {
      _clearMicros += micros;
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion ||
          _clearMicros >= blocksLineClearDuration.inMicroseconds) {
        _clearMicros = 0;
        final completed = _engine.resolvePendingLines();
        changed = true;
        if (completed) unawaited(_finish());
        if (_engine.status == BlocksStatus.gameOver) _handleGameOver();
      }
    } else {
      _gravityMicros += micros;
      if (_gravityMicros >= _engine.gravityMs * 1000) {
        _gravityMicros %= _engine.gravityMs * 1000;
        if (_engine.gravityStep()) {
          _lockMicros = 0;
          changed = true;
        }
      }
      final piece = _engine.activePiece;
      if (piece != null && !_engine.canPlace(piece, y: piece.y + 1)) {
        _lockMicros += micros;
        if (_lockMicros >= blocksLockDelay.inMicroseconds) {
          _lockMicros = 0;
          _afterLock(_engine.lockPiece());
          changed = true;
        }
      } else {
        _lockMicros = 0;
      }
    }
    if (changed && mounted) setState(() {});
  }

  void _afterLock(BlocksLockResult result) {
    _gravityMicros = 0;
    _clearMicros = 0;
    if (_engine.status == BlocksStatus.gameOver) _handleGameOver();
  }

  void _handleGameOver() {
    if (_failureSent) return;
    _failureSent = true;
    if (_controller?.isOnline == true) {
      unawaited(_controller!.online!.end('failed').catchError((Object _) {}));
    }
  }

  bool get _acceptsInput =>
      !_loading &&
      !_finishing &&
      _error == null &&
      _engine.status == BlocksStatus.playing &&
      _engine.pendingLines.isEmpty;

  void _move(int dx) => _input(() => _engine.move(dx), resetLock: true);

  void _rotate() => _input(_engine.rotate, resetLock: true);

  void _softDrop() => _input(_engine.softDrop);

  void _hardDrop() {
    if (!_acceptsInput) return;
    setState(() => _afterLock(_engine.hardDrop()));
    _controller?.haptics.move();
  }

  void _input(bool Function() action, {bool resetLock = false}) {
    if (!_acceptsInput || !action()) return;
    if (resetLock && _engine.lockResets < blocksMaxLockResets) {
      _engine.lockResets++;
      _lockMicros = 0;
    }
    setState(() {});
    _controller?.haptics.move();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_acceptsInput) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _move(-1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _move(1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _softDrop();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _rotate();
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      _hardDrop();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _togglePause() {
    if (_engine.status == BlocksStatus.playing) {
      _engine.pause();
    } else if (_engine.status == BlocksStatus.paused) {
      _engine.resume();
      _lastFrame = Duration.zero;
    }
    setState(() {});
  }

  Future<void> _finish() async {
    if (_finishing || _engine.status != BlocksStatus.completed) return;
    _finishing = true;
    unawaited(_controller!.haptics.victory());
    unawaited(_controller!.audio.victory());
    final localStars = widget.level.config.stars(
      score: _engine.score,
      elapsedSeconds: _displaySeconds,
    );
    final result = _result(localStars, _engine.score);
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
          metricLabel: 'LINHAS',
          metricValue: '${_engine.clearedLines}',
          score: _engine.score,
          replayBuilder: (_) =>
              BlocksGameScreen(theme: widget.theme, level: widget.level),
        ),
      ),
    );
  }

  Future<CompletionOutcome> _finishOnlineInBackground() async {
    final outcome = await _controller!.finishOnline(
      moveCount: _engine.piecesLocked,
      blocksLines: _engine.clearedLines,
      blocksScore: _engine.score,
    );
    _controller!.online!.attempt = null;
    _controller!.online!.attemptMoves = [];
    await _controller!.online!.saveJournal();
    return outcome;
  }

  PuzzleResult _result(int stars, int score) => PuzzleResult(
    levelId: widget.level.id,
    themeId: widget.theme.id,
    gridSize: blocksBoardWidth,
    elapsedSeconds: _displaySeconds,
    moves: _engine.piecesLocked,
    stars: stars,
    completedAt: DateTime.now(),
    gameMode: 'blocks',
    difficulty: widget.level.difficulty.id,
    score: score,
  );

  Future<void> _retry() async {
    setState(() => _loading = true);
    if (_controller?.isOnline == true && _controller!.online!.attempt != null) {
      await _controller!.online!.end('failed');
    }
    _engine = BlocksEngine(difficulty: widget.level.difficulty);
    _elapsedMicros = 0;
    _displaySeconds = 0;
    _gravityMicros = 0;
    _lockMicros = 0;
    _clearMicros = 0;
    _failureSent = false;
    await _initialize();
  }

  Future<bool> _confirmExit() async {
    if (_engine.status == BlocksStatus.completed) return true;
    final wasPlaying = _engine.status == BlocksStatus.playing;
    if (wasPlaying) _engine.pause();
    if (mounted) setState(() {});
    final exit =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sair de Blocos?'),
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
    if (!exit && wasPlaying) _engine.resume();
    if (exit && _controller?.isOnline == true && !_failureSent) {
      await _controller!.online!.end('abandoned');
    }
    if (mounted) setState(() {});
    return exit;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) &&
        _engine.status == BlocksStatus.playing) {
      _engine.pause();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _engine.status == BlocksStatus.completed,
    onPopInvokedWithResult: (didPop, _) async {
      if (!didPop && await _confirmExit() && context.mounted) {
        Navigator.pop(context);
      }
    },
    child: Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF24150F),
        appBar: AppBar(
          title: Text(
            '${widget.theme.name} • ${widget.level.difficulty.label}',
          ),
          leading: IconButton(
            tooltip: 'Sair',
            onPressed: () async {
              final exit = await _confirmExit();
              if (exit && context.mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.close_rounded),
          ),
          actions: [
            const CurrentEnergyIndicator(interactive: false, light: true),
            IconButton(
              tooltip: _engine.status == BlocksStatus.paused
                  ? 'Continuar'
                  : 'Pausar',
              onPressed:
                  _loading ||
                      ![
                        BlocksStatus.playing,
                        BlocksStatus.paused,
                      ].contains(_engine.status)
                  ? null
                  : _togglePause,
              icon: Icon(
                _engine.status == BlocksStatus.paused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
              ),
            ),
          ],
        ),
        body: SafeArea(child: _body()),
      ),
    ),
  );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 52),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _initialize,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellByWidth = (constraints.maxWidth - 126) / blocksBoardWidth;
        final cellByHeight = (constraints.maxHeight - 154) / blocksBoardHeight;
        final cell =
            cellByWidth.clamp(12.0, 32.0) < cellByHeight.clamp(12.0, 32.0)
            ? cellByWidth.clamp(12.0, 32.0)
            : cellByHeight.clamp(12.0, 32.0);
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Hud(label: 'PONTOS', value: '${_engine.score}'),
                      _Hud(
                        label: 'LINHAS',
                        value: '${_engine.clearedLines}/${_engine.targetLines}',
                      ),
                      _Hud(label: 'NÍVEL', value: '${_engine.gameplayLevel}'),
                      _Hud(
                        label: 'TEMPO',
                        value: formatDuration(_displaySeconds),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomPaint(
                        size: Size(
                          cell * blocksBoardWidth,
                          cell * blocksBoardHeight,
                        ),
                        painter: BlocksBoardPainter(
                          engine: _engine,
                          flashing: _engine.pendingLines.isNotEmpty,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 82,
                        child: Column(
                          children: [
                            const Text(
                              'PRÓXIMA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            CustomPaint(
                              size: const Size(72, 72),
                              painter: BlocksPreviewPainter(
                                type: _engine.nextPiece,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Meta\n${_engine.targetLines} linhas',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFFD998),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  _Controls(
                    enabled: _acceptsInput,
                    onLeft: () => _move(-1),
                    onRight: () => _move(1),
                    onRotate: _rotate,
                    onSoftDrop: _softDrop,
                    onHardDrop: _hardDrop,
                  ),
                  if (_engine.combo > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'COMBO ×${_engine.combo + 1}',
                        style: const TextStyle(
                          color: Color(0xFFFFD36B),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_engine.status == BlocksStatus.paused)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: .72),
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: _togglePause,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Continuar'),
                    ),
                  ),
                ),
              ),
            if (_engine.status == BlocksStatus.gameOver)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: .78),
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.all(28),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'FIM DE JOGO',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_engine.clearedLines}/${_engine.targetLines} linhas',
                            ),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: _retry,
                              child: const Text('Tentar novamente'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Sair'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.white60)),
      Text(
        value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.enabled,
    required this.onLeft,
    required this.onRight,
    required this.onRotate,
    required this.onSoftDrop,
    required this.onHardDrop,
  });
  final bool enabled;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onRotate;
  final VoidCallback onSoftDrop;
  final VoidCallback onHardDrop;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _Control(
        icon: Icons.arrow_left_rounded,
        label: 'Esq.',
        onTap: enabled ? onLeft : null,
      ),
      _Control(
        icon: Icons.rotate_right_rounded,
        label: 'Girar',
        onTap: enabled ? onRotate : null,
      ),
      _Control(
        icon: Icons.arrow_downward_rounded,
        label: 'Descer',
        onTap: enabled ? onSoftDrop : null,
      ),
      _Control(
        icon: Icons.vertical_align_bottom_rounded,
        label: 'Soltar',
        onTap: enabled ? onHardDrop : null,
      ),
      _Control(
        icon: Icons.arrow_right_rounded,
        label: 'Dir.',
        onTap: enabled ? onRight : null,
      ),
    ],
  );
}

class _Control extends StatelessWidget {
  const _Control({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: 54,
        height: 50,
        child: FilledButton(
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          onPressed: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 23),
              Text(label, style: const TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ),
    ),
  );
}

class BlocksBoardPainter extends CustomPainter {
  const BlocksBoardPainter({required this.engine, required this.flashing});
  final BlocksEngine engine;
  final bool flashing;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / engine.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      Paint()..color = const Color(0xFF10242A),
    );
    for (var y = 0; y < engine.height; y++) {
      for (var x = 0; x < engine.width; x++) {
        final type = engine.board[y][x];
        if (type != null) {
          _paintCell(canvas, x, y, cell, type);
        }
      }
    }
    final piece = engine.activePiece;
    if (piece != null) {
      for (final point in BlocksEngine.cellsFor(piece.type, piece.rotation)) {
        final y = engine.ghostY + point.y;
        if (y >= 0) {
          _paintCell(
            canvas,
            piece.x + point.x,
            y,
            cell,
            piece.type,
            ghost: true,
          );
        }
      }
      for (final point in BlocksEngine.cellsFor(piece.type, piece.rotation)) {
        final y = piece.y + point.y;
        if (y >= 0) _paintCell(canvas, piece.x + point.x, y, cell, piece.type);
      }
    }
    if (flashing) {
      final paint = Paint()..color = Colors.white.withValues(alpha: .68);
      for (final row in engine.pendingLines) {
        canvas.drawRect(Rect.fromLTWH(0, row * cell, size.width, cell), paint);
      }
    }
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .075)
      ..strokeWidth = .6;
    for (var x = 0; x <= engine.width; x++) {
      canvas.drawLine(Offset(x * cell, 0), Offset(x * cell, size.height), grid);
    }
    for (var y = 0; y <= engine.height; y++) {
      canvas.drawLine(Offset(0, y * cell), Offset(size.width, y * cell), grid);
    }
  }

  @override
  bool shouldRepaint(covariant BlocksBoardPainter oldDelegate) => true;
}

class BlocksPreviewPainter extends CustomPainter {
  const BlocksPreviewPainter({required this.type});
  final TetrominoType type;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      Paint()..color = const Color(0xFF10242A),
    );
    const cell = 14.0;
    final cells = BlocksEngine.cellsFor(type, 0);
    final maxX = cells.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    final maxY = cells.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final offsetX = (size.width - (maxX + 1) * cell) / 2 / cell;
    final offsetY = (size.height - (maxY + 1) * cell) / 2 / cell;
    for (final point in cells) {
      _paintCell(canvas, point.x + offsetX, point.y + offsetY, cell, type);
    }
  }

  @override
  bool shouldRepaint(covariant BlocksPreviewPainter oldDelegate) =>
      oldDelegate.type != type;
}

void _paintCell(
  Canvas canvas,
  num x,
  num y,
  double cell,
  TetrominoType type, {
  bool ghost = false,
}) {
  final rect = Rect.fromLTWH(x * cell + 1, y * cell + 1, cell - 2, cell - 2);
  final color = _pieceColors[type]!;
  final fill = Paint()
    ..color = ghost ? color.withValues(alpha: .17) : color
    ..style = ghost ? PaintingStyle.stroke : PaintingStyle.fill
    ..strokeWidth = 2;
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(cell * .16)),
    fill,
  );
  if (!ghost) {
    final pattern = Paint()
      ..color = Colors.white.withValues(alpha: .48)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    switch (type) {
      case TetrominoType.i:
        canvas.drawLine(
          rect.centerLeft + const Offset(3, 0),
          rect.centerRight - const Offset(3, 0),
          pattern,
        );
      case TetrominoType.o:
        canvas.drawCircle(rect.center, cell * .16, pattern);
      case TetrominoType.t:
        canvas.drawLine(
          rect.topCenter + const Offset(0, 3),
          rect.bottomCenter - const Offset(0, 3),
          pattern,
        );
        canvas.drawLine(
          rect.centerLeft + const Offset(3, 0),
          rect.centerRight - const Offset(3, 0),
          pattern,
        );
      case TetrominoType.s:
        canvas.drawLine(
          rect.bottomLeft + const Offset(3, -3),
          rect.topRight + const Offset(-3, 3),
          pattern,
        );
      case TetrominoType.z:
        canvas.drawLine(
          rect.topLeft + const Offset(3, 3),
          rect.bottomRight + const Offset(-3, -3),
          pattern,
        );
      case TetrominoType.j:
        canvas.drawRect(
          Rect.fromCenter(
            center: rect.center,
            width: cell * .28,
            height: cell * .28,
          ),
          pattern,
        );
      case TetrominoType.l:
        canvas.drawCircle(
          rect.center,
          cell * .08,
          pattern..style = PaintingStyle.fill,
        );
    }
    canvas.drawLine(
      rect.topLeft + Offset(cell * .20, cell * .20),
      rect.bottomRight - Offset(cell * .20, cell * .20),
      Paint()
        ..color = Colors.white.withValues(alpha: .32)
        ..strokeWidth = 1.2,
    );
  }
}

const _pieceColors = <TetrominoType, Color>{
  TetrominoType.i: Color(0xFF49C8CF),
  TetrominoType.o: Color(0xFFF0C75E),
  TetrominoType.t: Color(0xFFA47BD5),
  TetrominoType.s: Color(0xFF68B875),
  TetrominoType.z: Color(0xFFD8665C),
  TetrominoType.j: Color(0xFF638DD4),
  TetrominoType.l: Color(0xFFE69A55),
};
