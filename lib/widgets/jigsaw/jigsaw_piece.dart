import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../engine/jigsaw_engine.dart';
import '../../engine/jigsaw_geometry.dart';

const double jigsawPiecePaddingFactor = .20;

double jigsawPiecePadding(double width, double height) =>
    jigsawPiecePaddingFactor * (width < height ? width : height);

class JigsawPieceView extends StatelessWidget {
  const JigsawPieceView({
    required this.piece,
    required this.image,
    required this.pieceWidth,
    required this.pieceHeight,
    required this.rows,
    required this.columns,
    this.active = false,
    super.key,
  });

  final JigsawPieceState piece;
  final ui.Image image;
  final double pieceWidth;
  final double pieceHeight;
  final int rows;
  final int columns;
  final bool active;

  double get padding => jigsawPiecePadding(pieceWidth, pieceHeight);
  Size get paintSize =>
      Size(pieceWidth + padding * 2, pieceHeight + padding * 2);

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: paintSize,
      painter: _JigsawPiecePainter(
        piece: piece,
        image: image,
        pieceWidth: pieceWidth,
        pieceHeight: pieceHeight,
        padding: padding,
        rows: rows,
        columns: columns,
        active: active,
      ),
    ),
  );
}

class _JigsawPiecePainter extends CustomPainter {
  const _JigsawPiecePainter({
    required this.piece,
    required this.image,
    required this.pieceWidth,
    required this.pieceHeight,
    required this.padding,
    required this.rows,
    required this.columns,
    required this.active,
  });

  final JigsawPieceState piece;
  final ui.Image image;
  final double pieceWidth;
  final double pieceHeight;
  final double padding;
  final int rows;
  final int columns;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final path = JigsawGeometry.pathFor(piece, size, padding: padding);
    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: active ? .52 : .30),
      active ? 7 : 3,
      false,
    );
    canvas.save();
    canvas
      ..clipPath(path)
      ..drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(
          padding - piece.column * pieceWidth,
          padding - piece.row * pieceHeight,
          columns * pieceWidth,
          rows * pieceHeight,
        ),
        Paint()..filterQuality = FilterQuality.medium,
      )
      ..drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: .035)
          ..blendMode = BlendMode.softLight,
      );
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .75
        ..color = Colors.white.withValues(alpha: .34),
    );
  }

  @override
  bool shouldRepaint(_JigsawPiecePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.piece != piece ||
      oldDelegate.pieceWidth != pieceWidth ||
      oldDelegate.pieceHeight != pieceHeight ||
      oldDelegate.padding != padding ||
      oldDelegate.rows != rows ||
      oldDelegate.columns != columns ||
      oldDelegate.active != active;
}
