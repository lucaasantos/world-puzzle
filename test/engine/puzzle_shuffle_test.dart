import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/engine/puzzle_shuffle.dart';
import 'package:puzzle_journey/engine/puzzle_validator.dart';

void main() {
  for (final size in [3, 4, 5]) {
    test('generated ${size}x$size boards are solvable and not solved', () {
      for (var seed = 0; seed < 80; seed++) {
        final board = PuzzleShuffle.generate(size, random: Random(seed));
        expect(PuzzleValidator.isSolvable(board, size), isTrue);
        expect(PuzzleValidator.isSolved(board), isFalse);
        expect(board.toSet().length, size * size);
      }
    });
  }
}
