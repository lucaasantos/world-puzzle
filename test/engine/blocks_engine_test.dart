import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/config/blocks_config.dart';
import 'package:puzzle_journey/engine/blocks_engine.dart';

void main() {
  test('board, seven shapes and 7-bag have the expected complete set', () {
    final board = createBoard();
    expect(board, hasLength(20));
    expect(board.every((row) => row.length == 10), isTrue);
    expect(TetrominoType.values, hasLength(7));
    for (final type in TetrominoType.values) {
      for (var rotation = 0; rotation < 4; rotation++) {
        expect(
          BlocksEngine.cellsFor(type, rotation).toSet(),
          hasLength(4),
          reason: '$type rotation $rotation',
        );
      }
    }
    final bag = SevenBag(random: Random(7));
    expect(
      List.generate(7, (_) => bag.draw()).toSet(),
      TetrominoType.values.toSet(),
    );
    expect(
      List.generate(7, (_) => bag.draw()).toSet(),
      TetrominoType.values.toSet(),
    );
  });

  test(
    'movement, collision, rotation, soft drop, ghost and hard drop agree',
    () {
      final engine = BlocksEngine(
        difficulty: BlocksDifficulty.easy,
        random: Random(1),
      );
      engine.start();
      engine.activePiece = const BlocksPiece(type: TetrominoType.t, x: 0, y: 0);
      expect(engine.move(-1), isFalse);
      expect(engine.rotate(), isTrue);
      while (engine.move(1)) {}
      expect(engine.move(1), isFalse);

      engine.activePiece = const BlocksPiece(
        type: TetrominoType.o,
        x: 4,
        y: 17,
      );
      engine.board[19][4] = TetrominoType.j;
      expect(engine.softDrop(), isFalse);
      engine.board[19][4] = null;
      final landing = engine.ghostY;
      final result = engine.hardDrop();
      expect(landing, 18);
      expect(result.lines, isEmpty);
      expect(engine.board[18][4], TetrominoType.o);
      expect(engine.board[19][5], TetrominoType.o);
    },
  );

  test(
    'locking clears multiple rows together, collapses and scores combos',
    () {
      final engine = BlocksEngine(
        difficulty: BlocksDifficulty.easy,
        random: Random(2),
      );
      engine.start();
      for (final row in [18, 19]) {
        for (var x = 2; x < engine.width; x++) {
          engine.board[row][x] = TetrominoType.j;
        }
      }
      engine.board[17][9] = TetrominoType.t;
      engine.activePiece = const BlocksPiece(
        type: TetrominoType.o,
        x: 0,
        y: 18,
      );
      final first = engine.lockPiece();
      expect(first.lines, [18, 19]);
      expect(engine.resolvePendingLines(), isFalse);
      expect(engine.clearedLines, 2);
      expect(engine.score, blocksLineScores[2]!);
      expect(engine.board[19][9], TetrominoType.t);

      for (var x = 4; x < engine.width; x++) {
        engine.board[19][x] = TetrominoType.s;
      }
      engine.activePiece = const BlocksPiece(
        type: TetrominoType.i,
        x: 0,
        y: 19,
      );
      expect(engine.lockPiece().lines, [19]);
      engine.resolvePendingLines();
      expect(engine.combo, 1);
      expect(
        engine.score,
        blocksLineScores[2]! + blocksLineScores[1]! + blocksComboPoints,
      );

      engine.activePiece = const BlocksPiece(
        type: TetrominoType.o,
        x: 0,
        y: 18,
      );
      engine.lockPiece();
      expect(engine.combo, -1);
    },
  );

  test(
    'objective completes once and difficulty controls target and gravity',
    () {
      final easy = BlocksEngine(
        difficulty: BlocksDifficulty.easy,
        random: Random(3),
      );
      final hard = BlocksEngine(
        difficulty: BlocksDifficulty.hard,
        random: Random(3),
      );
      expect(easy.targetLines, 10);
      expect(hard.targetLines, 30);
      expect(hard.gravityMs, lessThan(easy.gravityMs));
      easy.start();
      easy.clearedLines = easy.targetLines - 1;
      for (var x = 4; x < easy.width; x++) {
        easy.board[19][x] = TetrominoType.z;
      }
      easy.activePiece = const BlocksPiece(type: TetrominoType.i, x: 0, y: 19);
      easy.lockPiece();
      expect(easy.resolvePendingLines(), isTrue);
      expect(easy.status, BlocksStatus.completed);
      final score = easy.score;
      expect(easy.resolvePendingLines(), isFalse);
      expect(easy.score, score);
      easy.reset();
      expect(easy.status, BlocksStatus.ready);
      expect(easy.clearedLines, 0);
      expect(easy.score, 0);
    },
  );

  test(
    'pause, hold restrictions and blocked spawn enforce lifecycle rules',
    () {
      final engine = BlocksEngine(
        difficulty: BlocksDifficulty.easy,
        random: Random(4),
        holdEnabled: true,
      );
      engine.start();
      final original = engine.activePiece!.type;
      engine.pause();
      expect(engine.move(1), isFalse);
      engine.resume();
      expect(engine.hold(), isTrue);
      expect(engine.heldPiece, original);
      expect(engine.hold(), isFalse);

    for (var x = 0; x < engine.width - 1; x++) {
      engine.board[0][x] = TetrominoType.l;
    }
      engine.activePiece = const BlocksPiece(
        type: TetrominoType.o,
        x: 0,
        y: 18,
      );
      engine.lockPiece();
      expect(engine.status, BlocksStatus.gameOver);
      expect(engine.activePiece, isNull);
    },
  );
}
