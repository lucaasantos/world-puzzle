import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../engine/jigsaw_engine.dart';
import '../../engine/jigsaw_geometry.dart';

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

  double get padding =>
      .24 * (pieceWidth < pieceHeight ? pieceWidth : pieceHeight);
  Size get paintSize =>
      Size(pieceWidth + padding * 2, pieceHeight + padding * 2);

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: active ? .48 : .28),
            blurRadius: active ? 10 : 5,
            offset: Offset(0, active ? 5 : 2),
          ),
        ],
      ),
      child: ClipPath(
        clipper: _JigsawClipper(piece, padding),
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
          ),
        ),
      ),
    ),
  );
}

class _JigsawClipper extends CustomClipper<Path> {
  const _JigsawClipper(this.piece, this.padding);
  final JigsawPieceState piece;
  final double padding;

  @override
  Path getClip(Size size) =>
      JigsawGeometry.pathFor(piece, size, padding: padding);

  @override
  bool shouldReclip(_JigsawClipper oldClipper) =>
      oldClipper.piece != piece || oldClipper.padding != padding;
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
  });

  final JigsawPieceState piece;
  final ui.Image image;
  final double pieceWidth;
  final double pieceHeight;
  final double padding;
  final int rows;
  final int columns;

  @override
  void paint(Canvas canvas, Size size) {
    final path = JigsawGeometry.pathFor(piece, size, padding: padding);
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
        Paint()..filterQuality = FilterQuality.high,
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = Colors.white.withValues(alpha: .72),
      );
  }

  @override
  bool shouldRepaint(_JigsawPiecePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.piece != piece ||
      oldDelegate.pieceWidth != pieceWidth ||
      oldDelegate.pieceHeight != pieceHeight;
}
