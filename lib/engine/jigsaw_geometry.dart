import 'package:flutter/material.dart';

import 'jigsaw_engine.dart';

class JigsawGeometry {
  const JigsawGeometry._();

  static Path pathFor(
    JigsawPieceState piece,
    Size size, {
    required double padding,
  }) {
    final width = size.width - padding * 2;
    final height = size.height - padding * 2;
    final path = Path()..moveTo(padding, padding);
    _horizontal(path, padding, padding, width, piece.top, outward: -1);
    _vertical(path, padding + width, padding, height, piece.right, outward: 1);
    _horizontal(
      path,
      padding + width,
      padding + height,
      -width,
      piece.bottom,
      outward: 1,
    );
    _vertical(
      path,
      padding,
      padding + height,
      -height,
      piece.left,
      outward: -1,
    );
    return path..close();
  }

  static void _horizontal(
    Path path,
    double x,
    double y,
    double length,
    JigsawEdge edge, {
    required double outward,
  }) {
    if (edge == JigsawEdge.flat) {
      path.lineTo(x + length, y);
      return;
    }
    final direction = edge == JigsawEdge.tab ? outward : -outward;
    final unit = length.abs();
    final sign = length.sign;
    final depth = unit * .22 * direction;
    path
      ..lineTo(x + length * .34, y)
      ..cubicTo(
        x + length * .39,
        y,
        x + sign * unit * .37,
        y + depth,
        x + length * .50,
        y + depth,
      )
      ..cubicTo(
        x + sign * unit * .63,
        y + depth,
        x + length * .61,
        y,
        x + length * .66,
        y,
      )
      ..lineTo(x + length, y);
  }

  static void _vertical(
    Path path,
    double x,
    double y,
    double length,
    JigsawEdge edge, {
    required double outward,
  }) {
    if (edge == JigsawEdge.flat) {
      path.lineTo(x, y + length);
      return;
    }
    final direction = edge == JigsawEdge.tab ? outward : -outward;
    final unit = length.abs();
    final sign = length.sign;
    final depth = unit * .22 * direction;
    path
      ..lineTo(x, y + length * .34)
      ..cubicTo(
        x,
        y + length * .39,
        x + depth,
        y + sign * unit * .37,
        x + depth,
        y + length * .50,
      )
      ..cubicTo(
        x + depth,
        y + sign * unit * .63,
        x,
        y + length * .61,
        x,
        y + length * .66,
      )
      ..lineTo(x, y + length);
  }
}
