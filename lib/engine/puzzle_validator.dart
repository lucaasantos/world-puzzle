class PuzzleValidator {
  const PuzzleValidator._();

  static bool isSolved(List<int> board) {
    for (var i = 0; i < board.length; i++) {
      if (board[i] != i) return false;
    }
    return true;
  }

  static bool isSolvable(List<int> board, int gridSize) {
    if (board.length != gridSize * gridSize) return false;
    final blank = board.length - 1;
    var inversions = 0;
    for (var i = 0; i < board.length; i++) {
      if (board[i] == blank) continue;
      for (var j = i + 1; j < board.length; j++) {
        if (board[j] != blank && board[i] > board[j]) inversions++;
      }
    }
    if (gridSize.isOdd) return inversions.isEven;
    final blankRowFromBottom = gridSize - (board.indexOf(blank) ~/ gridSize);
    return blankRowFromBottom.isEven ? inversions.isOdd : inversions.isEven;
  }
}
