import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/engine/puzzle_engine.dart';

void main() {
  group('PuzzleEngine', () {
    test('identifies solved state and blank position', () {
      final engine = PuzzleEngine(
        gridSize: 3,
        board: List.generate(9, (index) => index),
      );
      expect(engine.isSolved, isTrue);
      expect(engine.blankIndex, 8);
    });

    test('allows only orthogonally adjacent moves', () {
      final engine = PuzzleEngine(
        gridSize: 3,
        board: [0, 1, 2, 3, 4, 5, 6, 8, 7],
      );
      expect(engine.canMove(6), isTrue);
      expect(engine.canMove(4), isTrue);
      expect(engine.canMove(5), isFalse);
      expect(engine.canMove(8), isTrue);
      expect(engine.canMove(0), isFalse);
    });

    test('valid move swaps tile and blank', () {
      final engine = PuzzleEngine(
        gridSize: 3,
        board: [0, 1, 2, 3, 4, 5, 6, 8, 7],
      );
      expect(engine.move(8), isTrue);
      expect(engine.board, List.generate(9, (index) => index));
      expect(engine.isSolved, isTrue);
    });

    test('invalid move leaves board unchanged', () {
      final initial = [0, 1, 2, 3, 4, 5, 6, 8, 7];
      final engine = PuzzleEngine(gridSize: 3, board: initial);
      expect(engine.move(5), isFalse);
      expect(engine.board, initial);
      expect(engine.isSolved, isFalse);
    });
  });
}
