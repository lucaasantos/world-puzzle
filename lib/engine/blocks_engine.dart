import 'dart:math';

import '../config/blocks_config.dart';

enum TetrominoType { i, o, t, s, z, j, l }

enum BlocksStatus { ready, playing, paused, completed, gameOver }

class BlockPoint {
  const BlockPoint(this.x, this.y);
  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is BlockPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class BlocksPiece {
  const BlocksPiece({
    required this.type,
    required this.x,
    required this.y,
    this.rotation = 0,
  });

  final TetrominoType type;
  final int x;
  final int y;
  final int rotation;

  BlocksPiece copyWith({int? x, int? y, int? rotation}) => BlocksPiece(
    type: type,
    x: x ?? this.x,
    y: y ?? this.y,
    rotation: rotation ?? this.rotation,
  );
}

class SevenBag {
  SevenBag({Random? random}) : _random = random ?? Random();
  final Random _random;
  final List<TetrominoType> _bag = [];

  TetrominoType draw() {
    if (_bag.isEmpty) {
      _bag.addAll(TetrominoType.values);
      for (var i = _bag.length - 1; i > 0; i--) {
        final j = _random.nextInt(i + 1);
        final value = _bag[i];
        _bag[i] = _bag[j];
        _bag[j] = value;
      }
    }
    return _bag.removeLast();
  }
}

class BlocksLockResult {
  const BlocksLockResult({this.lines = const [], this.spawned = false});
  final List<int> lines;
  final bool spawned;
}

class BlocksEngine {
  BlocksEngine({
    required this.difficulty,
    Random? random,
    this.width = blocksBoardWidth,
    this.height = blocksBoardHeight,
    this.holdEnabled = blocksHoldEnabled,
  }) : config = blocksDifficultyConfig[difficulty]!,
       _bag = SevenBag(random: random) {
    reset();
  }

  final BlocksDifficulty difficulty;
  final BlocksDifficultyConfig config;
  final int width;
  final int height;
  final bool holdEnabled;
  final SevenBag _bag;

  late List<List<TetrominoType?>> board;
  BlocksPiece? activePiece;
  final List<TetrominoType> nextPieces = [];
  TetrominoType? heldPiece;
  bool canHold = true;
  int score = 0;
  int clearedLines = 0;
  int gameplayLevel = 1;
  int combo = -1;
  int piecesLocked = 0;
  int lockResets = 0;
  List<int> pendingLines = const [];
  BlocksStatus status = BlocksStatus.ready;

  int get targetLines => config.targetLines;
  int get gravityMs => config.gravityForLevel(gameplayLevel);
  TetrominoType get nextPiece => nextPieces.first;
  int get ghostY {
    final piece = activePiece;
    if (piece == null) return 0;
    var y = piece.y;
    while (canPlace(piece, x: piece.x, y: y + 1)) {
      y++;
    }
    return y;
  }

  static List<BlockPoint> cellsFor(TetrominoType type, int rotation) {
    final turns = type == TetrominoType.o ? 0 : rotation % 4;
    var points = _baseShapes[type]!.toList();
    for (var turn = 0; turn < turns; turn++) {
      points = points.map((point) => BlockPoint(-point.y, point.x)).toList();
      final minX = points.map((p) => p.x).reduce(min);
      final minY = points.map((p) => p.y).reduce(min);
      points = points.map((p) => BlockPoint(p.x - minX, p.y - minY)).toList();
    }
    return points;
  }

  void reset() {
    board = createBoard(width: width, height: height);
    activePiece = null;
    nextPieces
      ..clear()
      ..addAll(List.generate(5, (_) => _bag.draw()));
    heldPiece = null;
    canHold = true;
    score = 0;
    clearedLines = 0;
    gameplayLevel = config.startingGameplayLevel;
    combo = -1;
    piecesLocked = 0;
    lockResets = 0;
    pendingLines = const [];
    status = BlocksStatus.ready;
  }

  void start() {
    if (status != BlocksStatus.ready) return;
    status = BlocksStatus.playing;
    _spawnNext();
  }

  void pause() {
    if (status == BlocksStatus.playing) status = BlocksStatus.paused;
  }

  void resume() {
    if (status == BlocksStatus.paused) status = BlocksStatus.playing;
  }

  bool canPlace(BlocksPiece piece, {int? x, int? y, int? rotation}) {
    final testX = x ?? piece.x;
    final testY = y ?? piece.y;
    final testRotation = rotation ?? piece.rotation;
    for (final cell in cellsFor(piece.type, testRotation)) {
      final boardX = testX + cell.x;
      final boardY = testY + cell.y;
      if (boardX < 0 || boardX >= width || boardY >= height) return false;
      if (boardY >= 0 && board[boardY][boardX] != null) return false;
    }
    return true;
  }

  bool move(int dx) {
    final piece = activePiece;
    if (!_acceptsInput || piece == null) return false;
    if (!canPlace(piece, x: piece.x + dx)) return false;
    activePiece = piece.copyWith(x: piece.x + dx);
    return true;
  }

  bool rotate() {
    final piece = activePiece;
    if (!_acceptsInput || piece == null) return false;
    final nextRotation = (piece.rotation + 1) % 4;
    for (final offset in blocksWallKickOffsets) {
      if (canPlace(piece, x: piece.x + offset, rotation: nextRotation)) {
        activePiece = piece.copyWith(
          x: piece.x + offset,
          rotation: nextRotation,
        );
        return true;
      }
    }
    return false;
  }

  bool gravityStep() => _stepDown(awardPoints: false);

  bool softDrop() => _stepDown(awardPoints: true);

  bool _stepDown({required bool awardPoints}) {
    final piece = activePiece;
    if (!_acceptsInput || piece == null) return false;
    if (!canPlace(piece, y: piece.y + 1)) return false;
    activePiece = piece.copyWith(y: piece.y + 1);
    if (awardPoints) score += blocksSoftDropPoints;
    return true;
  }

  BlocksLockResult hardDrop() {
    final piece = activePiece;
    if (!_acceptsInput || piece == null) return const BlocksLockResult();
    final destination = ghostY;
    score += (destination - piece.y) * blocksHardDropPoints;
    activePiece = piece.copyWith(y: destination);
    return lockPiece();
  }

  BlocksLockResult lockPiece() {
    final piece = activePiece;
    if (status != BlocksStatus.playing || piece == null) {
      return const BlocksLockResult();
    }
    for (final cell in cellsFor(piece.type, piece.rotation)) {
      final x = piece.x + cell.x;
      final y = piece.y + cell.y;
      if (y >= 0) board[y][x] = piece.type;
    }
    piecesLocked++;
    activePiece = null;
    canHold = true;
    lockResets = 0;
    final lines = completedLines();
    if (lines.isNotEmpty) {
      pendingLines = lines;
      return BlocksLockResult(lines: lines);
    }
    combo = -1;
    final spawned = _spawnNext();
    return BlocksLockResult(spawned: spawned);
  }

  bool resolvePendingLines() {
    if (pendingLines.isEmpty || status != BlocksStatus.playing) return false;
    final count = pendingLines.length;
    final removed = pendingLines.toSet();
    final remaining = <List<TetrominoType?>>[
      for (var row = 0; row < height; row++)
        if (!removed.contains(row)) List<TetrominoType?>.of(board[row]),
    ];
    board = [
      ...List.generate(count, (_) => List<TetrominoType?>.filled(width, null)),
      ...remaining,
    ];
    combo++;
    score +=
        (blocksLineScores[count] ?? 0) * gameplayLevel +
        max(0, combo) * blocksComboPoints * gameplayLevel;
    clearedLines += count;
    gameplayLevel =
        config.startingGameplayLevel + clearedLines ~/ blocksLinesPerSpeedLevel;
    pendingLines = const [];
    if (clearedLines >= targetLines) {
      status = BlocksStatus.completed;
      return true;
    }
    _spawnNext();
    return false;
  }

  List<int> completedLines() => [
    for (var row = 0; row < height; row++)
      if (board[row].every((cell) => cell != null)) row,
  ];

  bool hold() {
    final piece = activePiece;
    if (!holdEnabled || !_acceptsInput || !canHold || piece == null) {
      return false;
    }
    final previous = heldPiece;
    heldPiece = piece.type;
    activePiece = null;
    canHold = false;
    if (previous == null) {
      _spawnNext();
    } else {
      _spawn(previous);
    }
    return true;
  }

  bool get _acceptsInput =>
      status == BlocksStatus.playing && pendingLines.isEmpty;

  bool _spawnNext() {
    final type = nextPieces.removeAt(0);
    nextPieces.add(_bag.draw());
    return _spawn(type);
  }

  bool _spawn(TetrominoType type) {
    final widthOfPiece = cellsFor(type, 0).map((p) => p.x).reduce(max) + 1;
    final piece = BlocksPiece(
      type: type,
      x: (width - widthOfPiece) ~/ 2,
      y: -cellsFor(type, 0).map((p) => p.y).reduce(max),
    );
    if (!canPlace(piece)) {
      activePiece = null;
      status = BlocksStatus.gameOver;
      return false;
    }
    activePiece = piece;
    return true;
  }
}

List<List<TetrominoType?>> createBoard({
  int width = blocksBoardWidth,
  int height = blocksBoardHeight,
}) => List.generate(height, (_) => List<TetrominoType?>.filled(width, null));

const _baseShapes = <TetrominoType, List<BlockPoint>>{
  TetrominoType.i: [
    BlockPoint(0, 0),
    BlockPoint(1, 0),
    BlockPoint(2, 0),
    BlockPoint(3, 0),
  ],
  TetrominoType.o: [
    BlockPoint(0, 0),
    BlockPoint(1, 0),
    BlockPoint(0, 1),
    BlockPoint(1, 1),
  ],
  TetrominoType.t: [
    BlockPoint(0, 0),
    BlockPoint(1, 0),
    BlockPoint(2, 0),
    BlockPoint(1, 1),
  ],
  TetrominoType.s: [
    BlockPoint(1, 0),
    BlockPoint(2, 0),
    BlockPoint(0, 1),
    BlockPoint(1, 1),
  ],
  TetrominoType.z: [
    BlockPoint(0, 0),
    BlockPoint(1, 0),
    BlockPoint(1, 1),
    BlockPoint(2, 1),
  ],
  TetrominoType.j: [
    BlockPoint(0, 0),
    BlockPoint(0, 1),
    BlockPoint(1, 1),
    BlockPoint(2, 1),
  ],
  TetrominoType.l: [
    BlockPoint(2, 0),
    BlockPoint(0, 1),
    BlockPoint(1, 1),
    BlockPoint(2, 1),
  ],
};
