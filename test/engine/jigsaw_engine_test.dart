import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/engine/jigsaw_engine.dart';

void main() {
  test('all configured grids generate unique complete piece sets', () {
    for (final size in [3, 4, 5, 6]) {
      final engine = JigsawEngine(rows: size, columns: size, random: Random(7));
      expect(engine.pieces, hasLength(size * size));
      expect(
        engine.pieces.map((piece) => piece.id).toSet(),
        hasLength(size * size),
      );
      expect(engine.trayOrder.toSet(), hasLength(size * size));
      expect(
        engine.trayOrder,
        isNot(orderedEquals(List.generate(size * size, (i) => i))),
      );
    }
  });

  test('outer edges are flat and every neighboring edge is complementary', () {
    final engine = JigsawEngine(rows: 6, columns: 6, random: Random(11));
    for (final piece in engine.pieces) {
      if (piece.row == 0) expect(piece.top, JigsawEdge.flat);
      if (piece.row == 5) expect(piece.bottom, JigsawEdge.flat);
      if (piece.column == 0) expect(piece.left, JigsawEdge.flat);
      if (piece.column == 5) expect(piece.right, JigsawEdge.flat);
      if (piece.column < 5) {
        expect(
          engine.pieces[piece.id + 1].left,
          complementaryEdge(piece.right),
        );
      }
      if (piece.row < 5) {
        expect(
          engine.pieces[piece.id + 6].top,
          complementaryEdge(piece.bottom),
        );
      }
    }
    expect(complementaryEdge(JigsawEdge.tab), JigsawEdge.blank);
    expect(complementaryEdge(JigsawEdge.blank), JigsawEdge.tab);
  });

  test(
    'snap tolerance locks only nearby pieces and completion needs all pieces',
    () {
      final engine = JigsawEngine(rows: 3, columns: 3, random: Random(3));
      engine.updateBoardGeometry(100, 80);
      expect(engine.releasePiece(0, x: 21, y: 0, pieceWidth: 100), isFalse);
      expect(engine.pieces[0].isPlaced, isFalse);
      expect(engine.releasePiece(0, x: 19, y: 0, pieceWidth: 100), isTrue);
      expect(engine.pieces[0].isPlaced, isTrue);
      expect(engine.releasePiece(0, x: 50, y: 50, pieceWidth: 100), isFalse);
      expect(engine.isComplete, isFalse);
      for (final piece in engine.pieces.skip(1)) {
        expect(
          engine.releasePiece(
            piece.id,
            x: piece.correctX,
            y: piece.correctY,
            pieceWidth: 100,
          ),
          isTrue,
        );
      }
      expect(engine.isComplete, isTrue);
    },
  );

  test(
    'responsive layout preserves aspect ratio and reset clears game state',
    () {
      final wide = JigsawBoardLayout.fit(
        availableWidth: 360,
        availableHeight: 300,
        imageAspectRatio: 1.5,
        rows: 4,
        columns: 4,
      );
      expect(wide.width / wide.height, closeTo(1.5, .0001));
      final engine = JigsawEngine(rows: 4, columns: 4, random: Random(5));
      engine.updateBoardGeometry(wide.pieceWidth, wide.pieceHeight);
      engine.releasePiece(0, x: 0, y: 0, pieceWidth: wide.pieceWidth);
      engine.reset();
      expect(engine.placedPieces, 0);
      expect(engine.pieces.every((piece) => piece.isInTray), isTrue);
    },
  );
}
