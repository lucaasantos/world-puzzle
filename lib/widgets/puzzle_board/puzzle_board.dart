import 'package:flutter/material.dart';

class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    required this.board,
    required this.gridSize,
    required this.imagePath,
    required this.onTileTap,
    this.highlightedTile,
    this.blocked = false,
    this.squareCorners = false,
    super.key,
  });

  final List<int> board;
  final int gridSize;
  final String imagePath;
  final ValueChanged<int> onTileTap;
  final int? highlightedTile;
  final bool blocked;
  final bool squareCorners;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth;
        final tileSize = boardSize / gridSize;
        final blank = board.length - 1;
        return ClipRRect(
          borderRadius: BorderRadius.circular(squareCorners ? 0 : 18),
          child: ColoredBox(
            color: const Color(0xFF0A0D0E),
            child: Stack(
              children: [
                for (var position = 0; position < board.length; position++)
                  if (board[position] != blank)
                    AnimatedPositioned(
                      key: ValueKey(board[position]),
                      duration: const Duration(milliseconds: 190),
                      curve: Curves.easeOutCubic,
                      left: (position % gridSize) * tileSize,
                      top: (position ~/ gridSize) * tileSize,
                      width: tileSize,
                      height: tileSize,
                      child: _Tile(
                        value: board[position],
                        gridSize: gridSize,
                        tileSize: tileSize,
                        boardSize: boardSize,
                        imagePath: imagePath,
                        highlighted: highlightedTile == board[position],
                        squareCorners: squareCorners,
                        onTap: blocked ? null : () => onTileTap(position),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.gridSize,
    required this.tileSize,
    required this.boardSize,
    required this.imagePath,
    required this.highlighted,
    required this.squareCorners,
    required this.onTap,
  });

  final int value;
  final int gridSize;
  final double tileSize;
  final double boardSize;
  final String imagePath;
  final bool highlighted;
  final bool squareCorners;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = value ~/ gridSize;
    final column = value % gridSize;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.all(1.2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(squareCorners ? 0 : 5),
          border: Border.all(
            color: highlighted
                ? Theme.of(context).colorScheme.primary
                : Colors.white24,
            width: highlighted ? 3 : 0.7,
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .5),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: boardSize,
            maxWidth: boardSize,
            minHeight: boardSize,
            maxHeight: boardSize,
            child: Transform.translate(
              offset: Offset(-column * tileSize, -row * tileSize),
              child: Image.asset(
                imagePath,
                width: boardSize,
                height: boardSize,
                fit: BoxFit.cover,
                alignment: Alignment.topLeft,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
