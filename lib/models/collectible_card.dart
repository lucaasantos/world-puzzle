class CardRarity {
  const CardRarity._();

  static const common = 'COMMON';
  static const rare = 'RARE';
  static const epic = 'EPIC';
  static const legendary = 'LEGENDARY';

  static const initialValues = [common, rare, epic, legendary];
}

class CardCategory {
  const CardCategory._();

  static const city = 'CITY';
  static const flag = 'FLAG';
  static const currency = 'CURRENCY';
  static const animal = 'ANIMAL';
  static const nature = 'NATURE';
  static const landmark = 'LANDMARK';
  static const culture = 'CULTURE';
  static const food = 'FOOD';
  static const historical = 'HISTORICAL';
  static const person = 'PERSON';
  static const mythology = 'MYTHOLOGY';
  static const special = 'SPECIAL';
}

class CollectibleCard {
  const CollectibleCard({
    required this.id,
    required this.countryId,
    required this.name,
    required this.description,
    required this.rarity,
    required this.category,
    required this.imagePath,
    required this.cardNumber,
    required this.catalogNumber,
    required this.isActive,
    required this.sortOrder,
    this.localizedName,
    this.isPlaceholderImage = false,
    this.releaseSeason,
    this.limitedEdition = false,
    this.foil = false,
    this.eventId,
    this.collectionId = 'world_album',
    this.tradeable = true,
    this.sellable = true,
  });

  final String id;
  final String countryId;
  final String name;
  final String? localizedName;
  final String description;
  final String rarity;
  final String category;
  final String imagePath;
  final int cardNumber;

  /// Stable, player-facing number within the country catalog (for example,
  /// `BR-015`). This is stored with the definition so UI never has to infer it
  /// from a translated country name or another display string.
  final String catalogNumber;
  final bool isActive;
  final int sortOrder;
  final bool isPlaceholderImage;

  // Metadata reserved for future seasons, events, packs, and trading.
  final String? releaseSeason;
  final bool limitedEdition;
  final bool foil;
  final String? eventId;
  final String collectionId;
  final bool tradeable;
  final bool sellable;
}
