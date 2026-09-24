import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/data/cards_data.dart';
import 'package:puzzle_journey/data/packs_data.dart';
import 'package:puzzle_journey/models/card_inventory_entry.dart';
import 'package:puzzle_journey/models/card_pack.dart';
import 'package:puzzle_journey/models/collectible_card.dart';
import 'package:puzzle_journey/services/pack_opening_service.dart';

void main() {
  test('pack definitions have configured sizes and normalized weights', () {
    expect(packDefinitions.map((pack) => pack.id), [
      PackIds.world,
      PackIds.explorer,
      PackIds.wonders,
      PackIds.legacy,
    ]);
    expect(PackCatalog.byId(PackIds.world)!.cardCount, 4);
    expect(PackCatalog.byId(PackIds.explorer)!.cardCount, 5);
    expect(PackCatalog.byId(PackIds.wonders)!.cardCount, 6);
    expect(PackCatalog.byId(PackIds.legacy)!.cardCount, 7);
    for (final pack in packDefinitions) {
      expect(
        pack.rarityWeights.values.fold<double>(0, (sum, value) => sum + value),
        100,
      );
      expect(pack.rarityWeights.keys, containsAll(CardRarity.initialValues));
    }
  });

  test('100,000 World Pack rolls stay close to configured weights', () {
    final service = PackOpeningService(random: math.Random(87234));
    final weights = PackCatalog.byId(PackIds.world)!.rarityWeights;
    final counts = <String, int>{};

    for (var index = 0; index < 100000; index++) {
      final rarity = service.drawRarity(weights);
      counts[rarity] = (counts[rarity] ?? 0) + 1;
    }

    expect(counts[CardRarity.common]! / 100000, closeTo(.72, .01));
    expect(counts[CardRarity.rare]! / 100000, closeTo(.23, .01));
    expect(counts[CardRarity.epic]! / 100000, closeTo(.045, .005));
    expect(counts[CardRarity.legendary]! / 100000, closeTo(.005, .002));
  });

  test('rarity weights are normalized to pools that actually exist', () {
    final service = PackOpeningService(random: math.Random(12));
    final pack = PackCatalog.byId(PackIds.legacy)!;
    final onlyCommon = collectibleCards
        .where((card) => card.rarity == CardRarity.common)
        .take(pack.cardCount)
        .toList();

    final result = service.generate(
      pack: pack,
      catalog: onlyCommon,
      inventory: const {},
    );

    expect(result, isNotNull);
    expect(
      result!.cards.every((reward) => reward.card.rarity == CardRarity.common),
      isTrue,
    );
    expect(
      result.cards.map((reward) => reward.card.id).toSet(),
      hasLength(pack.cardCount),
    );
  });

  test('new and duplicate status accounts for this pack and pasted cards', () {
    final service = PackOpeningService(random: math.Random(3));
    final cards = collectibleCards
        .where((card) => card.rarity == CardRarity.common)
        .take(3)
        .toList();
    const pack = PackDefinition(
      id: 'test_pack',
      name: 'Test',
      description: 'Test',
      cardCount: 3,
      rarityWeights: {CardRarity.common: 1},
      isActive: true,
      sourceType: PackSourceType.gameplay,
      iconName: 'public',
      sortOrder: 1,
    );

    final result = service.generate(
      pack: pack,
      catalog: cards,
      inventory: {
        cards[0].id: CardInventoryEntry(cardId: cards[0].id, quantity: 1),
        cards[1].id: CardInventoryEntry(
          cardId: cards[1].id,
          pastedInAlbum: true,
        ),
      },
    )!;
    final byId = {for (final reward in result.cards) reward.card.id: reward};

    expect(byId, hasLength(3));
    expect(byId[cards[0].id]!.isNew, isFalse);
    expect(byId[cards[0].id]!.resultingQuantity, 2);
    expect(byId[cards[1].id]!.isNew, isFalse);
    expect(byId[cards[1].id]!.wasAlreadyPasted, isTrue);
    expect(byId[cards[2].id]!.isNew, isTrue);
    expect(byId[cards[2].id]!.resultingQuantity, 1);
  });
}
