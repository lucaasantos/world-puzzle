import 'puzzle_shuffle.dart';
import 'puzzle_validator.dart';

class PuzzleEngine {
  PuzzleEngine({required this.gridSize, List<int>? board})
    : board = List<int>.of(board ?? PuzzleShuffle.generate(gridSize)) {
    if (this.board.length != gridSize * gridSize) {
      throw ArgumentError('Board size does not match grid size.');
    }
  }

  final int gridSize;
  final List<int> board;
  int get blankTile => board.length - 1;
  int get blankIndex => board.indexOf(blankTile);
  bool get isSolved => PuzzleValidator.isSolved(board);

  bool canMove(int index) {
    if (index < 0 || index >= board.length || index == blankIndex) return false;
    final rowDistance = (index ~/ gridSize - blankIndex ~/ gridSize).abs();
    final columnDistance = (index % gridSize - blankIndex % gridSize).abs();
    return rowDistance + columnDistance == 1;
  }

  bool move(int index) {
    if (!canMove(index)) return false;
    final empty = blankIndex;
    board[empty] = board[index];
    board[index] = blankTile;
    return true;
  }

  List<int> movableIndices() => List<int>.generate(
    board.length,
    (i) => i,
  ).where(canMove).toList(growable: false);
}
