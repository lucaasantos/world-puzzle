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
    final depth = (width < height ? width : height) * .20;
    final path = Path()..moveTo(padding, padding);
    _horizontal(
      path,
      padding,
      padding,
      width,
      piece.top,
      depth: depth,
      outward: -1,
    );
    _vertical(
      path,
      padding + width,
      padding,
      height,
      piece.right,
      depth: depth,
      outward: 1,
    );
    _horizontal(
      path,
      padding + width,
      padding + height,
      -width,
      piece.bottom,
      depth: depth,
      outward: 1,
    );
    _vertical(
      path,
      padding,
      padding + height,
      -height,
      piece.left,
      depth: depth,
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
    required double depth,
    required double outward,
  }) {
    if (edge == JigsawEdge.flat) {
      path.lineTo(x + length, y);
      return;
    }
    final direction = edge == JigsawEdge.tab ? outward : -outward;
    final unit = length.abs();
    final sign = length.sign;
    final signedDepth = depth * direction;
    path
      // A short neck and a broad circular bulb produce the classic
      // die-cut silhouette from the supplied reference.
      ..lineTo(x + length * .38, y)
      ..cubicTo(
        x + length * .41,
        y,
        x + sign * unit * .42,
        y + signedDepth * .10,
        x + length * .42,
        y + signedDepth * .27,
      )
      ..cubicTo(
        x + length * .33,
        y + signedDepth * .36,
        x + length * .36,
        y + signedDepth * .88,
        x + length * .50,
        y + signedDepth,
      )
      ..cubicTo(
        x + length * .64,
        y + signedDepth * .88,
        x + length * .67,
        y + signedDepth * .36,
        x + length * .58,
        y + signedDepth * .27,
      )
      ..cubicTo(
        x + sign * unit * .58,
        y + signedDepth * .10,
        x + length * .59,
        y,
        x + length * .62,
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
    required double depth,
    required double outward,
  }) {
    if (edge == JigsawEdge.flat) {
      path.lineTo(x, y + length);
      return;
    }
    final direction = edge == JigsawEdge.tab ? outward : -outward;
    final unit = length.abs();
    final sign = length.sign;
    final signedDepth = depth * direction;
    path
      // The same round profile, rotated by 90 degrees.
      ..lineTo(x, y + length * .38)
      ..cubicTo(
        x,
        y + length * .41,
        x + signedDepth * .10,
        y + sign * unit * .42,
        x + signedDepth * .27,
        y + length * .42,
      )
      ..cubicTo(
        x + signedDepth * .36,
        y + length * .33,
        x + signedDepth * .88,
        y + length * .36,
        x + signedDepth,
        y + length * .50,
      )
      ..cubicTo(
        x + signedDepth * .88,
        y + length * .64,
        x + signedDepth * .36,
        y + length * .67,
        x + signedDepth * .27,
        y + length * .58,
      )
      ..cubicTo(
        x + signedDepth * .10,
        y + sign * unit * .58,
        x,
        y + length * .59,
        x,
        y + length * .62,
      )
      ..lineTo(x, y + length);
  }
}
