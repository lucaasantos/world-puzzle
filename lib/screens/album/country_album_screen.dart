import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/utils/card_labels.dart';
import '../../data/cards_data.dart';
import '../../models/album_country.dart';
import '../../models/collectible_card.dart';
import '../../widgets/collectible_card/card_artwork.dart';
import '../../widgets/collectible_card/collectible_card_tile.dart';
import 'card_detail_screen.dart';

class CountryAlbumScreen extends StatelessWidget {
  const CountryAlbumScreen({required this.country, super.key});

  static const _ink = Color(0xFF3D2D22);
  static const _mutedInk = Color(0xFF806D59);
  static const _paper = Color(0xFFF5E8C9);

  final AlbumCountry country;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final cards = CardCatalog.cardsForCountry(country.id);
    final progress = controller.countryAlbumProgress(country.id);
    final groupedCards = _groupByCategory(cards);
    final chapter =
        albumCountries.indexWhere((item) => item.id == country.id) + 1;

    return Scaffold(
      backgroundColor: const Color(0xFF1B120E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B14),
        title: Text('${country.flag}  ${country.name}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          Container(
            key: Key('country-album-page-${country.id}'),
            padding: const EdgeInsets.fromLTRB(21, 24, 21, 18),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1B982)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _AlbumPagePainter(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CountryPageHeader(
                    chapter: chapter,
                    country: country,
                    pasted: progress.pasted,
                    total: progress.total,
                    fraction: progress.fraction,
                  ),
                  const SizedBox(height: 24),
                  for (final entry in groupedCards.entries) ...[
                    _CategorySection(
                      category: entry.key,
                      cards: entry.value,
                      stateFor: (card) {
                        final inventory = controller.inventoryFor(card.id);
                        return inventory.pastedInAlbum
                            ? AlbumCardState.pasted
                            : inventory.quantity > 0
                            ? AlbumCardState.inCollection
                            : AlbumCardState.notOwned;
                      },
                      onCard: (card) => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => CardDetailScreen(card: card),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0x55806D59))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'CAPÍTULO ${chapter.toString().padLeft(2, '0')}  •  ${country.code}',
                          style: const TextStyle(
                            color: _mutedInk,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0x55806D59))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<CollectibleCard>> _groupByCategory(
    List<CollectibleCard> cards,
  ) {
    const order = [
      CardCategory.city,
      CardCategory.landmark,
      CardCategory.historical,
      CardCategory.person,
      CardCategory.mythology,
      CardCategory.culture,
      CardCategory.food,
      CardCategory.nature,
      CardCategory.animal,
      CardCategory.flag,
      CardCategory.currency,
      CardCategory.special,
    ];
    final result = <String, List<CollectibleCard>>{};
    for (final category in order) {
      final matches = cards
          .where((card) => card.category == category)
          .toList(growable: false);
      if (matches.isNotEmpty) result[category] = matches;
    }
    return result;
  }
}

class _CountryPageHeader extends StatelessWidget {
  const _CountryPageHeader({
    required this.chapter,
    required this.country,
    required this.pasted,
    required this.total,
    required this.fraction,
  });

  final int chapter;
  final AlbumCountry country;
  final int pasted;
  final int total;
  final double fraction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFA171), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x22806A49), blurRadius: 5),
              ],
            ),
            child: Text(country.flag, style: const TextStyle(fontSize: 42)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CAPÍTULO ${chapter.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFF9A6744),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  country.name,
                  style: const TextStyle(
                    color: CountryAlbumScreen._ink,
                    fontFamily: 'serif',
                    fontSize: 29,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  country.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9A6744),
                    fontFamily: 'serif',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        country.intro,
        style: const TextStyle(
          color: CountryAlbumScreen._mutedInk,
          fontSize: 12,
          height: 1.45,
        ),
      ),
      const SizedBox(height: 15),
      Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 7,
                backgroundColor: const Color(0xFFE0CDA5),
                color: const Color(0xFF9C573A),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$pasted de $total',
            style: const TextStyle(
              color: CountryAlbumScreen._ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ],
  );
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.cards,
    required this.stateFor,
    required this.onCard,
  });

  final String category;
  final List<CollectibleCard> cards;
  final AlbumCardState Function(CollectibleCard card) stateFor;
  final ValueChanged<CollectibleCard> onCard;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF8B4F35),
              shape: BoxShape.circle,
            ),
            child: Icon(categoryIcon(category), size: 16, color: Colors.white),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sectionTitle(category).toUpperCase(),
                  style: const TextStyle(
                    color: CountryAlbumScreen._ink,
                    fontFamily: 'serif',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                Text(
                  '${cards.length} ${cards.length == 1 ? 'figurinha' : 'figurinhas'}',
                  style: const TextStyle(
                    color: CountryAlbumScreen._mutedInk,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: Divider(color: Color(0x66806D59))),
        ],
      ),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: .76,
          crossAxisSpacing: 13,
          mainAxisSpacing: 13,
        ),
        itemBuilder: (context, index) {
          final card = cards[index];
          return _AlbumStickerSlot(
            card: card,
            state: stateFor(card),
            onTap: () => onCard(card),
          );
        },
      ),
    ],
  );

  String _sectionTitle(String category) => switch (category) {
    CardCategory.city => 'Cidades essenciais',
    CardCategory.landmark => 'Monumentos & ícones',
    CardCategory.historical => 'História preservada',
    CardCategory.person => 'Grandes personalidades',
    CardCategory.mythology => 'Lendas & mitologia',
    CardCategory.culture => 'Cultura & tradições',
    CardCategory.food => 'Sabores do país',
    CardCategory.nature => 'Natureza',
    CardCategory.animal => 'Fauna',
    CardCategory.flag => 'Símbolos nacionais',
    CardCategory.currency => 'Moedas & símbolos',
    CardCategory.special => 'Engenharia & inovação',
    _ => categoryLabel(category),
  };
}

class _AlbumStickerSlot extends StatelessWidget {
  const _AlbumStickerSlot({
    required this.card,
    required this.state,
    required this.onTap,
  });

  final CollectibleCard card;
  final AlbumCardState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pasted = state == AlbumCardState.pasted;
    final ready = state == AlbumCardState.inCollection;
    final colors = _stickerColors(card.category);

    return Semantics(
      button: true,
      label:
          '${card.name}, ${pasted
              ? 'colada'
              : ready
              ? 'na coleção'
              : 'não obtida'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            painter: _StickerBorderPainter(
              color: pasted
                  ? const Color(0xFF8B4F35)
                  : ready
                  ? const Color(0xFFC18432)
                  : const Color(0xFFAD9672),
              dashed: !pasted,
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: pasted
                      ? colors
                      : ready
                      ? const [Color(0xFFFFE7A8), Color(0xFFE9C677)]
                      : const [Color(0xFFEADBBB), Color(0xFFE1CEAA)],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -12,
                    top: 23,
                    child: Icon(
                      categoryIcon(card.category),
                      size: 82,
                      color: (pasted ? Colors.white : const Color(0xFF6F604E))
                          .withValues(alpha: .10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                card.catalogNumber,
                                style: TextStyle(
                                  color: pasted
                                      ? Colors.white70
                                      : const Color(0xFF796550),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .7,
                                ),
                              ),
                            ),
                            if (pasted)
                              const _StickerStatus(
                                label: 'COLADA',
                                color: Colors.white,
                              )
                            else if (ready)
                              const _StickerStatus(
                                label: 'COLAR',
                                color: Color(0xFF704018),
                              ),
                          ],
                        ),
                        Expanded(
                          child: Center(
                            child: Icon(
                              state == AlbumCardState.notOwned
                                  ? Icons.add_photo_alternate_outlined
                                  : categoryIcon(card.category),
                              size: 43,
                              color: pasted
                                  ? Colors.white.withValues(alpha: .88)
                                  : ready
                                  ? const Color(0xFF704018)
                                  : const Color(0xFF9C896A),
                            ),
                          ),
                        ),
                        Text(
                          card.localizedName ?? card.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: pasted
                                ? Colors.white
                                : CountryAlbumScreen._ink,
                            fontFamily: 'serif',
                            fontSize: 13,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state == AlbumCardState.notOwned
                              ? 'ESPAÇO RESERVADO'
                              : categoryLabel(card.category).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: pasted
                                ? Colors.white70
                                : const Color(0xFF88735A),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _stickerColors(String category) => switch (category) {
    CardCategory.city => const [Color(0xFF447C8C), Color(0xFF234552)],
    CardCategory.landmark => const [Color(0xFFB06B3C), Color(0xFF6A3828)],
    CardCategory.historical => const [Color(0xFF8A6545), Color(0xFF4A3427)],
    CardCategory.person => const [Color(0xFF526F8E), Color(0xFF2C3D59)],
    CardCategory.mythology => const [Color(0xFF75528F), Color(0xFF402D59)],
    CardCategory.culture => const [Color(0xFFA04D61), Color(0xFF592D49)],
    CardCategory.food => const [Color(0xFFC17C36), Color(0xFF754126)],
    CardCategory.nature => const [Color(0xFF5D8B58), Color(0xFF31523B)],
    CardCategory.animal => const [Color(0xFF7C7350), Color(0xFF46442C)],
    CardCategory.flag => const [Color(0xFF5D6D95), Color(0xFF343A62)],
    CardCategory.currency => const [Color(0xFF6C8665), Color(0xFF3C5039)],
    _ => const [Color(0xFF725E8D), Color(0xFF413451)],
  };
}

class _StickerStatus extends StatelessWidget {
  const _StickerStatus({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: .7)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w900),
    ),
  );
}

class _StickerBorderPainter extends CustomPainter {
  const _StickerBorderPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StickerBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}

class _AlbumPagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x109A7B4F)
      ..strokeWidth = 1;
    for (double y = 44; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final edge = Paint()
      ..color = const Color(0x208B6745)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(7, 0), Offset(7, size.height), edge);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
