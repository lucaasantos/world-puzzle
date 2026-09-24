import 'package:flutter/material.dart';

import '../../data/packs_data.dart';
import '../../models/card_pack.dart';

class PackArtwork extends StatelessWidget {
  const PackArtwork({required this.pack, this.quantity = 1, super.key});

  final PackDefinition pack;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    if (pack.artworkPath case final artworkPath?) {
      return _PackStack(
        pack: pack,
        artworkPath: artworkPath,
        quantity: quantity,
      );
    }
    return _FallbackPackArtwork(pack: pack);
  }
}

class _PackStack extends StatelessWidget {
  const _PackStack({
    required this.pack,
    required this.artworkPath,
    required this.quantity,
  });

  final PackDefinition pack;
  final String artworkPath;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final visibleCount = quantity <= 1 ? 1 : (quantity == 2 ? 2 : 3);
    final angles = switch (visibleCount) {
      1 => const [-.045],
      2 => const [-.075, .025],
      _ => const [-.10, -.045, .025],
    };
    final offsets = switch (visibleCount) {
      1 => const [Offset(-2, 1)],
      2 => const [Offset(-10, 8), Offset(4, -3)],
      _ => const [Offset(-14, 12), Offset(-7, 6), Offset(4, -4)],
    };

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        for (var index = 0; index < visibleCount; index++)
          Transform.translate(
            key: ValueKey('pack-layer-${pack.id}-$index'),
            offset: offsets[index],
            child: Transform.rotate(
              angle: angles[index],
              child: Transform.scale(
                scale: visibleCount == 1 ? 1.22 : 1.12,
                child: PhysicalShape(
                  key: ValueKey('pack-silhouette-${pack.id}-$index'),
                  clipper: const PackSilhouetteClipper(),
                  clipBehavior: Clip.antiAlias,
                  color: Colors.transparent,
                  elevation: index == visibleCount - 1 ? 7 : 3,
                  shadowColor: Colors.black54,
                  child: Image.asset(
                    artworkPath,
                    key: index == visibleCount - 1
                        ? ValueKey('pack-artwork-${pack.id}')
                        : null,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _FallbackPackArtwork(pack: pack),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PackSilhouetteClipper extends CustomClipper<Path> {
  const PackSilhouetteClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * .136, size.height * .024)
    ..lineTo(size.width * .868, size.height * .024)
    ..lineTo(size.width * .868, size.height * .062)
    ..cubicTo(
      size.width * .86,
      size.height * .105,
      size.width * .842,
      size.height * .14,
      size.width * .84,
      size.height * .24,
    )
    ..cubicTo(
      size.width * .836,
      size.height * .52,
      size.width * .846,
      size.height * .78,
      size.width * .86,
      size.height * .91,
    )
    ..lineTo(size.width * .87, size.height * .954)
    ..lineTo(size.width * .137, size.height * .954)
    ..lineTo(size.width * .145, size.height * .91)
    ..cubicTo(
      size.width * .158,
      size.height * .76,
      size.width * .164,
      size.height * .46,
      size.width * .157,
      size.height * .24,
    )
    ..cubicTo(
      size.width * .154,
      size.height * .14,
      size.width * .138,
      size.height * .105,
      size.width * .136,
      size.height * .062,
    )
    ..close();

  @override
  bool shouldReclip(PackSilhouetteClipper oldClipper) => false;
}

class _FallbackPackArtwork extends StatelessWidget {
  const _FallbackPackArtwork({required this.pack});

  final PackDefinition pack;

  @override
  Widget build(BuildContext context) {
    final colors = packColors(pack.id);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: packAccent(pack.id), width: 2),
        boxShadow: [
          BoxShadow(
            color: packAccent(pack.id).withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -24,
            bottom: -30,
            child: Icon(
              packIcon(pack.iconName),
              size: 130,
              color: Colors.white.withValues(alpha: .07),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 110,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        packIcon(pack.iconName),
                        size: 45,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        pack.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${pack.cardCount} CARTAS',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Color> packColors(String packId) => switch (packId) {
  PackIds.explorer => const [Color(0xFF285C56), Color(0xFF132B2B)],
  PackIds.wonders => const [Color(0xFF8250B6), Color(0xFF28183D)],
  PackIds.legacy => const [Color(0xFF6D4518), Color(0xFF28170D)],
  _ => const [Color(0xFF285371), Color(0xFF152837)],
};

Color packAccent(String packId) => switch (packId) {
  PackIds.explorer => const Color(0xFF7DDFC8),
  PackIds.wonders => const Color(0xFFC99BFF),
  PackIds.legacy => const Color(0xFFFFCE68),
  _ => const Color(0xFF82CFF4),
};

IconData packIcon(String iconName) => switch (iconName) {
  'explore' => Icons.explore_rounded,
  'account_balance' => Icons.account_balance_rounded,
  'auto_awesome' => Icons.auto_awesome_rounded,
  _ => Icons.public_rounded,
};
