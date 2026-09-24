import 'collectible_card.dart';

class PackSourceType {
  const PackSourceType._();

  static const gameplay = 'GAMEPLAY';
  static const achievement = 'ACHIEVEMENT';
  static const specialProgression = 'SPECIAL_PROGRESSION';
}

class PackDefinition {
  const PackDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.cardCount,
    required this.rarityWeights,
    required this.isActive,
    required this.sourceType,
    required this.iconName,
    required this.sortOrder,
    this.artworkPath,
    this.purchasable = false,
    this.price,
    this.eventOnly = false,
    this.validFrom,
    this.validUntil,
    this.guaranteedRarity,
    this.countryRestriction,
    this.continentRestriction,
    this.limitedEdition = false,
  });

  final String id;
  final String name;
  final String description;
  final int cardCount;
  final Map<String, double> rarityWeights;
  final bool isActive;
  final String sourceType;
  final String iconName;
  final int sortOrder;
  final String? artworkPath;

  // Reserved configuration for future store, event, and restricted packs.
  final bool purchasable;
  final double? price;
  final bool eventOnly;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? guaranteedRarity;
  final String? countryRestriction;
  final String? continentRestriction;
  final bool limitedEdition;
}

class PackInventoryEntry {
  const PackInventoryEntry({required this.packId, this.quantity = 0})
    : assert(quantity >= 0);

  final String packId;
  final int quantity;

  PackInventoryEntry copyWith({int? quantity}) =>
      PackInventoryEntry(packId: packId, quantity: quantity ?? this.quantity);

  Map<String, Object> toJson() => {'packId': packId, 'quantity': quantity};

  factory PackInventoryEntry.fromJson(Map<String, dynamic> json) {
    final quantity = json['quantity'] as int? ?? 0;
    return PackInventoryEntry(
      packId: json['packId'] as String,
      quantity: quantity < 0 ? 0 : quantity,
    );
  }
}

class PackCardReward {
  const PackCardReward({
    required this.card,
    required this.isNew,
    required this.resultingQuantity,
    required this.wasAlreadyPasted,
  });

  final CollectibleCard card;
  final bool isNew;
  final int resultingQuantity;
  final bool wasAlreadyPasted;
}

class PackOpeningResult {
  const PackOpeningResult({required this.packId, required this.cards});

  final String packId;
  final List<PackCardReward> cards;
}

enum PackOpenStatus { success, packNotFound, notOwned, noCardsAvailable }

class PackOpenOutcome {
  const PackOpenOutcome({required this.status, this.result});

  final PackOpenStatus status;
  final PackOpeningResult? result;
}
