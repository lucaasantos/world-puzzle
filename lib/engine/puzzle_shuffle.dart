import 'dart:math';

import 'puzzle_validator.dart';

class PuzzleShuffle {
  const PuzzleShuffle._();

  static List<int> generate(int gridSize, {Random? random}) {
    assert(gridSize >= 2);
    final rng = random ?? Random.secure();
    final board = List<int>.generate(gridSize * gridSize, (index) => index);
    var blankIndex = board.length - 1;
    int? previousBlank;
    final steps = gridSize * gridSize * 35;

    for (var step = 0; step < steps; step++) {
      final candidates = _neighbors(
        blankIndex,
        gridSize,
      ).where((index) => index != previousBlank).toList();
      final next = candidates[rng.nextInt(candidates.length)];
      previousBlank = blankIndex;
      board[blankIndex] = board[next];
      board[next] = board.length - 1;
      blankIndex = next;
    }

    if (PuzzleValidator.isSolved(board)) {
      final next = _neighbors(blankIndex, gridSize).first;
      board[blankIndex] = board[next];
      board[next] = board.length - 1;
    }
    return board;
  }

  static List<int> _neighbors(int index, int size) {
    final row = index ~/ size;
    final column = index % size;
    return [
      if (row > 0) index - size,
      if (row < size - 1) index + size,
      if (column > 0) index - 1,
      if (column < size - 1) index + 1,
    ];
  }
}
