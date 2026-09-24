import 'package:flutter/material.dart';

import '../../core/utils/card_labels.dart';
import '../../data/cards_data.dart';
import '../../models/collectible_card.dart';
import 'card_artwork.dart';
import 'collectible_card_frame.dart';

enum AlbumCardState { notOwned, inCollection, pasted }

const double collectibleCardAspectRatio = 5 / 7;

/// Interactive wrapper used by album and collection grids.
class CollectibleCardTile extends StatelessWidget {
  const CollectibleCardTile({
    required this.card,
    required this.state,
    required this.onTap,
    this.quantity,
    super.key,
  });

  final CollectibleCard card;
  final AlbumCardState state;
  final int? quantity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${card.name}, ${_statusLabel(state)}',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(collectibleCardCornerRadius),
        child: CollectibleCardView(
          card: card,
          state: state,
          quantity: quantity,
        ),
      ),
    ),
  );
}

/// Definitive visual representation of a collectible card.
/// Artwork stays independent from the frame and labels remain dynamic.
class CollectibleCardView extends StatelessWidget {
  const CollectibleCardView({
    required this.card,
    required this.state,
    this.quantity,
    super.key,
  });

  final CollectibleCard card;
  final AlbumCardState state;
  final int? quantity;

  @override
  Widget build(BuildContext context) {
    final country = CardCatalog.countryById(card.countryId);
    final accent = rarityAccent(card.rarity);
    final locked = state == AlbumCardState.notOwned;
    final premium =
        card.rarity == CardRarity.epic || card.rarity == CardRarity.legendary;

    return CollectibleCardFrame(
      artwork: CardArtwork(
        card: card,
        locked: locked,
        borderRadius: BorderRadius.zero,
      ),
      countryFlag: country?.flag ?? '🌎',
      countryName: country?.name ?? card.countryId,
      cardName: card.localizedName ?? card.name,
      rarityLabel: rarityLabel(card.rarity),
      rarityAccent: accent,
      categoryLabel: categoryLabel(card.category),
      categoryIcon: categoryIcon(card.category),
      catalogNumber: card.catalogNumber,
      stateLabel: _statusLabel(state).toUpperCase(),
      stateColor: _stateColor(state),
      locked: locked,
      emphasized: state == AlbumCardState.pasted || premium,
      quantity: quantity,
    );
  }
}

String _statusLabel(AlbumCardState state) => switch (state) {
  AlbumCardState.notOwned => 'Não obtida',
  AlbumCardState.inCollection => 'Na coleção',
  AlbumCardState.pasted => 'Colada',
};

Color _stateColor(AlbumCardState state) => switch (state) {
  AlbumCardState.notOwned => Colors.white54,
  AlbumCardState.inCollection => const Color(0xFFC5E7DC),
  AlbumCardState.pasted => const Color(0xFFFFE1A1),
};
