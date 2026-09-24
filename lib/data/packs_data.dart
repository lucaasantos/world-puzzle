import '../models/card_pack.dart';
import '../models/collectible_card.dart';

class PackIds {
  const PackIds._();

  static const world = 'world_pack';
  static const explorer = 'explorer_pack';
  static const wonders = 'tier3_pack';
  static const legacy = 'tier4_pack';
}

const packDefinitions = <PackDefinition>[
  PackDefinition(
    id: PackIds.world,
    name: 'World Pack',
    description: 'O pacote clássico conquistado durante suas viagens.',
    cardCount: 4,
    rarityWeights: {
      CardRarity.common: 72,
      CardRarity.rare: 23,
      CardRarity.epic: 4.5,
      CardRarity.legendary: .5,
    },
    isActive: true,
    sourceType: PackSourceType.gameplay,
    iconName: 'public',
    sortOrder: 10,
    artworkPath: 'assets/images/packs/world_pack.png',
  ),
  PackDefinition(
    id: PackIds.explorer,
    name: 'Explorer Pack',
    description: 'Uma recompensa especial com chances maiores de raridades.',
    cardCount: 5,
    rarityWeights: {
      CardRarity.common: 50,
      CardRarity.rare: 35,
      CardRarity.epic: 13,
      CardRarity.legendary: 2,
    },
    isActive: true,
    sourceType: PackSourceType.achievement,
    iconName: 'explore',
    sortOrder: 20,
    artworkPath: 'assets/images/packs/explorer_pack.png',
  ),
  PackDefinition(
    id: PackIds.wonders,
    name: 'Wonders Pack',
    description: 'Grandes monumentos em um pacote de raridade épica.',
    cardCount: 6,
    rarityWeights: {
      CardRarity.common: 38,
      CardRarity.rare: 38,
      CardRarity.epic: 20,
      CardRarity.legendary: 4,
    },
    isActive: true,
    sourceType: PackSourceType.achievement,
    iconName: 'account_balance',
    sortOrder: 30,
    artworkPath: 'assets/images/packs/wonders_pack.png',
  ),
  PackDefinition(
    id: PackIds.legacy,
    name: 'Legacy Pack',
    description: 'Pacote máximo reservado para grandes conquistas.',
    cardCount: 7,
    rarityWeights: {
      CardRarity.common: 25,
      CardRarity.rare: 40,
      CardRarity.epic: 28,
      CardRarity.legendary: 7,
    },
    isActive: true,
    sourceType: PackSourceType.specialProgression,
    iconName: 'auto_awesome',
    sortOrder: 40,
    artworkPath: 'assets/images/packs/legacy_pack.png',
  ),
];

class PackCatalog {
  const PackCatalog._();

  static final Map<String, PackDefinition> _byId = {
    for (final pack in packDefinitions) pack.id: pack,
  };

  static PackDefinition? byId(String id) => _byId[id];

  static final List<PackDefinition> active = List.unmodifiable(
    packDefinitions.where((pack) => pack.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
  );
}

class PuzzleRewardConfig {
  const PuzzleRewardConfig({
    required this.firstCompletionPackChance,
    required this.replayPackChance,
    required this.rewardPackId,
  });

  final double firstCompletionPackChance;
  final double replayPackChance;
  final String rewardPackId;
}

const puzzleRewardConfig = PuzzleRewardConfig(
  firstCompletionPackChance: .25,
  replayPackChance: .05,
  rewardPackId: PackIds.world,
);
