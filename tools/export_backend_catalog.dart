import 'dart:convert';
import 'dart:io';
import 'package:puzzle_journey/data/cards_data.dart';
import 'package:puzzle_journey/data/packs_data.dart';
import 'package:puzzle_journey/data/themes_data.dart';
import 'package:puzzle_journey/data/game_modes_data.dart';

// Export identifiers from the existing catalog; never create a second catalog.
void main() {
  final data = {
    'cards': [
      for (final c in collectibleCards.where((c) => c.isActive))
        {
          'id': c.id,
          'countryId': c.countryId,
          'rarity': c.rarity,
          'collectionId': c.collectionId,
          'category': c.category,
        },
    ],
    'packs': {
      for (final p in packDefinitions.where((p) => p.isActive))
        p.id: {'count': p.cardCount, 'weights': p.rarityWeights},
    },
    'countries': {
      for (final t in gameThemes)
        t.id: [
          ...{
            for (final l in t.levels) l.id,
            for (final mode in gameModes)
              for (final country in mode.countries)
                if (country.id == t.id) ...country.levelIds,
          },
        ],
    },
  };
  File(
    'functions/src/catalog.json',
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(data)}\n');
}
