import 'dart:math';

enum JigsawEdge { flat, tab, blank }

JigsawEdge complementaryEdge(JigsawEdge edge) => switch (edge) {
  JigsawEdge.tab => JigsawEdge.blank,
  JigsawEdge.blank => JigsawEdge.tab,
  JigsawEdge.flat => JigsawEdge.flat,
};

class JigsawPieceState {
  JigsawPieceState({
    required this.id,
    required this.row,
    required this.column,
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
    this.correctX = 0,
    this.correctY = 0,
    this.x = 0,
    this.y = 0,
    this.isPlaced = false,
    this.isInTray = true,
  });

  final int id;
  final int row;
  final int column;
  final JigsawEdge top;
  final JigsawEdge right;
  final JigsawEdge bottom;
  final JigsawEdge left;
  double correctX;
  double correctY;
  double x;
  double y;
  bool isPlaced;
  bool isInTray;
}

class JigsawEngine {
  JigsawEngine({
    required this.rows,
    required this.columns,
    this.snapToleranceFactor = .20,
    Random? random,
  }) : _random = random ?? Random.secure() {
    if (rows <= 0 || columns <= 0) {
      throw ArgumentError('Jigsaw rows and columns must be greater than zero.');
    }
    pieces = _generatePieces();
    trayOrder = _shuffleIds(pieces.map((piece) => piece.id).toList());
    if (_startsSolved(trayOrder)) {
      final first = trayOrder.removeAt(0);
      trayOrder.add(first);
    }
  }

  final int rows;
  final int columns;
  final double snapToleranceFactor;
  final Random _random;
  late final List<JigsawPieceState> pieces;
  late List<int> trayOrder;
  double? _lastPieceWidth;
  double? _lastPieceHeight;

  int get placedPieces => pieces.where((piece) => piece.isPlaced).length;
  bool get isComplete => placedPieces == pieces.length;

  List<JigsawPieceState> _generatePieces() {
    final result = <JigsawPieceState>[];
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final top = row == 0
            ? JigsawEdge.flat
            : complementaryEdge(result[(row - 1) * columns + column].bottom);
        final left = column == 0
            ? JigsawEdge.flat
            : complementaryEdge(result.last.right);
        result.add(
          JigsawPieceState(
            id: row * columns + column,
            row: row,
            column: column,
            top: top,
            right: column == columns - 1 ? JigsawEdge.flat : _randomEdge(),
            bottom: row == rows - 1 ? JigsawEdge.flat : _randomEdge(),
            left: left,
          ),
        );
      }
    }
    return result;
  }

  JigsawEdge _randomEdge() =>
      _random.nextBool() ? JigsawEdge.tab : JigsawEdge.blank;

  List<int> _shuffleIds(List<int> ids) {
    for (var index = ids.length - 1; index > 0; index--) {
      final other = _random.nextInt(index + 1);
      final value = ids[index];
      ids[index] = ids[other];
      ids[other] = value;
    }
    return ids;
  }

  bool _startsSolved(List<int> ids) {
    for (var index = 0; index < ids.length; index++) {
      if (ids[index] != index) return false;
    }
    return true;
  }

  void updateBoardGeometry(double pieceWidth, double pieceHeight) {
    for (final piece in pieces) {
      if (!piece.isPlaced && !piece.isInTray && _lastPieceWidth != null) {
        piece.x *= pieceWidth / _lastPieceWidth!;
        piece.y *= pieceHeight / _lastPieceHeight!;
      }
      piece.correctX = piece.column * pieceWidth;
      piece.correctY = piece.row * pieceHeight;
      if (piece.isPlaced) {
        piece.x = piece.correctX;
        piece.y = piece.correctY;
      }
    }
    _lastPieceWidth = pieceWidth;
    _lastPieceHeight = pieceHeight;
  }

  bool releasePiece(
    int id, {
    required double x,
    required double y,
    required double pieceWidth,
  }) {
    final piece = pieces[id];
    if (piece.isPlaced) return false;
    piece
      ..x = x
      ..y = y
      ..isInTray = false;
    trayOrder.remove(id);
    final dx = x - piece.correctX;
    final dy = y - piece.correctY;
    if (sqrt(dx * dx + dy * dy) > pieceWidth * snapToleranceFactor) {
      return false;
    }
    piece
      ..x = piece.correctX
      ..y = piece.correctY
      ..isPlaced = true;
    trayOrder.remove(id);
    return true;
  }

  void returnToTray(int id) {
    final piece = pieces[id];
    if (piece.isPlaced) return;
    piece.isInTray = true;
    if (!trayOrder.contains(id)) trayOrder.add(id);
  }

  void reset() {
    for (final piece in pieces) {
      piece
        ..x = 0
        ..y = 0
        ..isPlaced = false
        ..isInTray = true;
    }
    trayOrder = _shuffleIds(pieces.map((piece) => piece.id).toList());
    if (_startsSolved(trayOrder)) {
      final first = trayOrder.removeAt(0);
      trayOrder.add(first);
    }
  }
}

class JigsawBoardLayout {
  const JigsawBoardLayout({
    required this.width,
    required this.height,
    required this.pieceWidth,
    required this.pieceHeight,
  });

  final double width;
  final double height;
  final double pieceWidth;
  final double pieceHeight;

  static JigsawBoardLayout fit({
    required double availableWidth,
    required double availableHeight,
    required double imageAspectRatio,
    required int rows,
    required int columns,
  }) {
    if (availableWidth <= 0 || availableHeight <= 0 || imageAspectRatio <= 0) {
      throw ArgumentError(
        'Board dimensions and image aspect ratio must be positive.',
      );
    }
    var width = availableWidth;
    var height = width / imageAspectRatio;
    if (height > availableHeight) {
      height = availableHeight;
      width = height * imageAspectRatio;
    }
    return JigsawBoardLayout(
      width: width,
      height: height,
      pieceWidth: width / columns,
      pieceHeight: height / rows,
    );
  }
}
