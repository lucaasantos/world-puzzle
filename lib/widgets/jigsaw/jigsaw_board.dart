import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../engine/jigsaw_engine.dart';
import 'jigsaw_piece.dart';

class JigsawBoard extends StatefulWidget {
  const JigsawBoard({
    required this.engine,
    required this.image,
    required this.boardLayout,
    required this.blocked,
    required this.onMove,
    required this.onSnap,
    required this.onComplete,
    super.key,
  });

  final JigsawEngine engine;
  final ui.Image image;
  final JigsawBoardLayout boardLayout;
  final bool blocked;
  final ValueChanged<int> onMove;
  final ValueChanged<int> onSnap;
  final VoidCallback onComplete;

  @override
  State<JigsawBoard> createState() => _JigsawBoardState();
}

class _JigsawBoardState extends State<JigsawBoard> {
  final _boardKey = GlobalKey();
  late List<int> _zOrder;
  int? _active;

  @override
  void initState() {
    super.initState();
    _zOrder = List.generate(widget.engine.pieces.length, (index) => index);
  }

  @override
  void didUpdateWidget(covariant JigsawBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.engine.updateBoardGeometry(
      widget.boardLayout.pieceWidth,
      widget.boardLayout.pieceHeight,
    );
  }

  Offset _anchor(Draggable<Object> _, BuildContext __, Offset ___) {
    final padding =
        .24 *
        (widget.boardLayout.pieceWidth < widget.boardLayout.pieceHeight
            ? widget.boardLayout.pieceWidth
            : widget.boardLayout.pieceHeight);
    return Offset(
      widget.boardLayout.pieceWidth * .5 + padding,
      widget.boardLayout.pieceHeight * .5 + padding,
    );
  }

  void _start(int id) {
    if (widget.blocked || widget.engine.pieces[id].isPlaced) return;
    setState(() {
      _active = id;
      _zOrder
        ..remove(id)
        ..add(id);
    });
  }

  void _end(int id, DraggableDetails details) {
    if (widget.blocked) return;
    final piece = widget.engine.pieces[id];
    final wasInTray = piece.isInTray;
    final oldX = piece.x;
    final oldY = piece.y;
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final padding =
        .24 *
        (widget.boardLayout.pieceWidth < widget.boardLayout.pieceHeight
            ? widget.boardLayout.pieceWidth
            : widget.boardLayout.pieceHeight);
    final local = box.globalToLocal(details.offset) + Offset(padding, padding);
    final x = local.dx;
    final y = local.dy;
    final valid =
        x >= -widget.boardLayout.pieceWidth * .25 &&
        y >= -widget.boardLayout.pieceHeight * .25 &&
        x <= widget.boardLayout.width - widget.boardLayout.pieceWidth * .75 &&
        y <= widget.boardLayout.height - widget.boardLayout.pieceHeight * .75;
    widget.onMove(id);
    if (valid) {
      final snapped = widget.engine.releasePiece(
        id,
        x: x.clamp(0, widget.boardLayout.width - widget.boardLayout.pieceWidth),
        y: y.clamp(
          0,
          widget.boardLayout.height - widget.boardLayout.pieceHeight,
        ),
        pieceWidth: widget.boardLayout.pieceWidth,
      );
      if (snapped) widget.onSnap(id);
    } else if (wasInTray) {
      widget.engine.returnToTray(id);
    } else {
      piece
        ..x = oldX
        ..y = oldY
        ..isInTray = false;
    }
    setState(() => _active = null);
    if (widget.engine.isComplete) {
      Timer(const Duration(milliseconds: 190), widget.onComplete);
    }
  }

  Widget _piece(int id, {required bool tray, bool active = false}) {
    final piece = widget.engine.pieces[id];
    final width = tray ? 68.0 : widget.boardLayout.pieceWidth;
    final height = tray
        ? 68.0 * widget.boardLayout.pieceHeight / widget.boardLayout.pieceWidth
        : widget.boardLayout.pieceHeight;
    final view = JigsawPieceView(
      piece: piece,
      image: widget.image,
      pieceWidth: width,
      pieceHeight: height,
      rows: widget.engine.rows,
      columns: widget.engine.columns,
      active: active,
    );
    if (widget.blocked || piece.isPlaced) return view;
    return Draggable<int>(
      data: id,
      dragAnchorStrategy: _anchor,
      onDragStarted: () => _start(id),
      onDragEnd: (details) => _end(id, details),
      feedback: Material(color: Colors.transparent, child: _pieceFeedback(id)),
      childWhenDragging: tray
          ? Opacity(opacity: .18, child: view)
          : const SizedBox.shrink(),
      child: view,
    );
  }

  Widget _pieceFeedback(int id) => JigsawPieceView(
    piece: widget.engine.pieces[id],
    image: widget.image,
    pieceWidth: widget.boardLayout.pieceWidth,
    pieceHeight: widget.boardLayout.pieceHeight,
    rows: widget.engine.rows,
    columns: widget.engine.columns,
    active: true,
  );

  @override
  Widget build(BuildContext context) {
    widget.engine.updateBoardGeometry(
      widget.boardLayout.pieceWidth,
      widget.boardLayout.pieceHeight,
    );
    final pad = widget.boardLayout.pieceWidth * .24;
    return Column(
      children: [
        Center(
          child: Container(
            key: _boardKey,
            width: widget.boardLayout.width,
            height: widget.boardLayout.height,
            decoration: BoxDecoration(
              color: const Color(0x73351D13),
              border: Border.all(color: const Color(0xFFFFD58A), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final id in _zOrder)
                  if (!widget.engine.pieces[id].isInTray)
                    AnimatedPositioned(
                      key: ValueKey('board_piece_$id'),
                      duration: widget.engine.pieces[id].isPlaced
                          ? const Duration(milliseconds: 160)
                          : Duration.zero,
                      curve: Curves.easeOutBack,
                      left: widget.engine.pieces[id].x - pad,
                      top: widget.engine.pieces[id].y - pad,
                      child: _piece(id, tray: false, active: _active == id),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 104,
          decoration: BoxDecoration(
            color: const Color(0xD94A2B19),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x99FFE7B0)),
          ),
          child: widget.engine.trayOrder.isEmpty
              ? const Center(child: Text('Todas as peças estão no tabuleiro'))
              : ListView.separated(
                  key: const Key('jigsaw_piece_tray'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: widget.engine.trayOrder.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final id = widget.engine.trayOrder[index];
                    return Center(
                      child: _piece(id, tray: true, active: _active == id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
