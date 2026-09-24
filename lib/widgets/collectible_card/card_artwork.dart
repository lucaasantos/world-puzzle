import 'package:flutter/material.dart';

import '../../models/collectible_card.dart';

class CardArtwork extends StatelessWidget {
  const CardArtwork({
    required this.card,
    this.locked = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    super.key,
  });

  final CollectibleCard card;
  final bool locked;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius,
    child: ColorFiltered(
      colorFilter: locked
          ? const ColorFilter.mode(Color(0xFF6D7476), BlendMode.saturation)
          : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
      child: card.isPlaceholderImage
          ? _PlaceholderArtwork(card: card, locked: locked)
          : Image.asset(
              card.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _PlaceholderArtwork(card: card, locked: locked),
            ),
    ),
  );
}

class _PlaceholderArtwork extends StatelessWidget {
  const _PlaceholderArtwork({required this.card, required this.locked});

  final CollectibleCard card;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = rarityColors(card.rarity);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: locked
              ? const [Color(0xFF303537), Color(0xFF171A1B)]
              : [colors.first.withValues(alpha: .72), colors.last],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -18,
            bottom: -24,
            child: Icon(
              categoryIcon(card.category),
              size: 112,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  locked ? Icons.lock_rounded : categoryIcon(card.category),
                  size: 46,
                  color: locked
                      ? Colors.white38
                      : Colors.white.withValues(alpha: .92),
                ),
                const SizedBox(height: 8),
                Text(
                  locked ? 'NÃO OBTIDA' : 'ARTE TEMPORÁRIA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: locked ? Colors.white38 : Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<Color> rarityColors(String rarity) => switch (rarity) {
  CardRarity.rare => const [Color(0xFF2776A8), Color(0xFF142A43)],
  CardRarity.epic => const [Color(0xFF8250B6), Color(0xFF28183D)],
  CardRarity.legendary => const [Color(0xFFD79A2B), Color(0xFF4D2911)],
  _ => const [Color(0xFF607477), Color(0xFF253033)],
};

Color rarityAccent(String rarity) => switch (rarity) {
  CardRarity.rare => const Color(0xFF60B9E9),
  CardRarity.epic => const Color(0xFFC99BFF),
  CardRarity.legendary => const Color(0xFFFFD36D),
  _ => const Color(0xFFAAB7BA),
};

IconData categoryIcon(String category) => switch (category) {
  CardCategory.city => Icons.location_city_rounded,
  CardCategory.flag => Icons.flag_rounded,
  CardCategory.currency => Icons.payments_rounded,
  CardCategory.animal => Icons.pets_rounded,
  CardCategory.nature => Icons.forest_rounded,
  CardCategory.landmark => Icons.account_balance_rounded,
  CardCategory.culture => Icons.palette_rounded,
  CardCategory.food => Icons.restaurant_rounded,
  CardCategory.historical => Icons.history_edu_rounded,
  CardCategory.person => Icons.person_rounded,
  CardCategory.mythology => Icons.bolt_rounded,
  CardCategory.special => Icons.auto_awesome_rounded,
  _ => Icons.public_rounded,
};
