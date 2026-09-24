import 'dart:convert';
import '../../../lib/data/cards_data.dart';

// Execute the real catalog: no duplicate seeds, regex parsing, or Flutter runtime.
void main() {
  print(
    jsonEncode([
      for (final card in collectibleCards.where((card) => card.isActive))
        {
          'id': card.id,
          'name': card.name,
          'country': CardCatalog.countryById(card.countryId)!.name,
          'countryId': card.countryId,
          'category': card.category,
          'rarity': card.rarity,
          'description': card.description,
          'catalogNumber': card.catalogNumber,
          'imagePath': card.imagePath,
          'isPlaceholderImage': card.isPlaceholderImage,
      'temporaryArtPath': null,
          'placeholderRenderer': card.isPlaceholderImage
              ? 'lib/widgets/collectible_card/card_artwork.dart'
              : null,
          'finalArtPath': card.isPlaceholderImage ? null : card.imagePath,
        },
    ]),
  );
}
