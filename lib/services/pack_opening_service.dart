import 'dart:math' as math;

import '../models/card_inventory_entry.dart';
import '../models/card_pack.dart';
import '../models/collectible_card.dart';

class PackOpeningService {
  PackOpeningService({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  PackOpeningResult? generate({
    required PackDefinition pack,
    required List<CollectibleCard> catalog,
    required Map<String, CardInventoryEntry> inventory,
  }) {
    final uniqueActiveCards = <String, CollectibleCard>{
      for (final card in catalog.where(
        (card) => card.isActive && !card.isPlaceholderImage,
      ))
        card.id: card,
    }.values.toList(growable: false);
    if (uniqueActiveCards.length < pack.cardCount) return null;

    final pools = <String, List<CollectibleCard>>{};
    for (final card in uniqueActiveCards) {
      pools.putIfAbsent(card.rarity, () => []).add(card);
    }

    final workingQuantities = {
      for (final entry in inventory.entries) entry.key: entry.value.quantity,
    };
    final rewards = <PackCardReward>[];
    for (var index = 0; index < pack.cardCount; index++) {
      final availableWeights = {
        for (final entry in pack.rarityWeights.entries)
          if (entry.value > 0 && (pools[entry.key]?.isNotEmpty ?? false))
            entry.key: entry.value,
      };
      if (availableWeights.isEmpty) return null;
      final rarity = drawRarity(availableWeights);
      final pool = pools[rarity]!;
      final card = pool.removeAt(_random.nextInt(pool.length));
      final stored = inventory[card.id];
      final currentQuantity = workingQuantities[card.id] ?? 0;
      final wasAlreadyPasted = stored?.pastedInAlbum ?? false;
      final isNew = currentQuantity == 0 && !wasAlreadyPasted;
      final resultingQuantity = currentQuantity + 1;
      workingQuantities[card.id] = resultingQuantity;
      rewards.add(
        PackCardReward(
          card: card,
          isNew: isNew,
          resultingQuantity: resultingQuantity,
          wasAlreadyPasted: wasAlreadyPasted,
        ),
      );
    }
    return PackOpeningResult(
      packId: pack.id,
      cards: List.unmodifiable(rewards),
    );
  }

  String drawRarity(Map<String, double> availableWeights) {
    final total = availableWeights.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    if (total <= 0) {
      throw ArgumentError.value(availableWeights, 'availableWeights');
    }
    var roll = _random.nextDouble() * total;
    for (final entry in availableWeights.entries) {
      roll -= entry.value;
      if (roll < 0) return entry.key;
    }
    return availableWeights.keys.last;
  }
}
