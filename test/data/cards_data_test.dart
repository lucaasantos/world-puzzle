import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/data/cards_data.dart';
import 'package:puzzle_journey/models/album_country.dart';
import 'package:puzzle_journey/models/collectible_card.dart';

void main() {
  const expectedTotals = {
    'brazil': 28,
    'united_states': 29,
    'japan': 30,
    'france': 29,
    'italy': 30,
    'united_kingdom': 30,
    'china': 30,
    'india': 30,
    'egypt': 32,
    'greece': 36,
  };
  const reviewedExpansionTotals = {
    'canada': 20,
    'mexico': 22,
    'guatemala': 16,
    'belize': 12,
    'honduras': 14,
    'costa_rica': 16,
    'panama': 14,
    'bahamas': 12,
    'cuba': 18,
    'dominican_republic': 14,
    'haiti': 14,
    'jamaica': 16,
    'trinidad_and_tobago': 14,
    'argentina': 20,
    'bolivia': 16,
    'chile': 18,
    'colombia': 18,
    'ecuador': 16,
    'paraguay': 14,
    'peru': 20,
    'uruguay': 14,
    'venezuela': 16,
  };

  test('expanded edition contains 43 countries and 768 unique cards', () {
    expect(albumCountries, hasLength(43));
    expect(
      albumCountries.take(expectedTotals.length).map((country) => country.id),
      expectedTotals.keys,
    );
    expect(collectibleCards, hasLength(768));
    expect(collectibleCards.map((card) => card.id).toSet(), hasLength(768));

    for (final country in albumCountries) {
      final cards = CardCatalog.cardsForCountry(country.id);
      expect(
        cards,
        hasLength(
          expectedTotals[country.id] ??
              reviewedExpansionTotals[country.id] ??
              10,
        ),
      );
      expect(cards, hasLength(country.totalCards));
      expect(
        cards.map((card) => card.cardNumber),
        orderedEquals(List.generate(cards.length, (index) => index + 1)),
      );
      expect(
        cards.every((card) => card.id.startsWith('${country.id}_')),
        isTrue,
      );
      expect(cards.every((card) => card.description.isNotEmpty), isTrue);
    }
  });

  test('city counts follow the approved country lists', () {
    for (final country in albumCountries) {
      final cityCount = CardCatalog.cardsForCountry(
        country.id,
      ).where((card) => card.category == CardCategory.city).length;
      final originalCountry = expectedTotals.containsKey(country.id);
      if (originalCountry) {
        final expectedCities = country.id == 'egypt' || country.id == 'greece'
            ? 8
            : 10;
        expect(cityCount, expectedCities, reason: country.name);
      } else {
        expect(cityCount, greaterThanOrEqualTo(3), reason: country.name);
      }
    }
  });

  test('American chapter sizes reflect the country-by-country review', () {
    for (final entry in reviewedExpansionTotals.entries) {
      expect(
        CardCatalog.cardsForCountry(entry.key),
        hasLength(entry.value),
        reason: entry.key,
      );
    }

    final reviewedSizes = albumCountries
        .skip(expectedTotals.length)
        .map((country) => country.totalCards)
        .toSet();
    expect(reviewedSizes, containsAll(const {10, 12, 14, 16, 18, 20, 22}));
  });

  test('all 35 sovereign countries of the Americas are present', () {
    final americas = albumCountries
        .where(
          (country) =>
              country.continent == WorldContinent.northAmerica ||
              country.continent == WorldContinent.southAmerica,
        )
        .toList(growable: false);

    expect(americas, hasLength(35));
    expect(
      americas.map((country) => country.id).toSet(),
      containsAll(const {
        'canada',
        'mexico',
        'guatemala',
        'belize',
        'el_salvador',
        'honduras',
        'nicaragua',
        'costa_rica',
        'panama',
        'antigua_and_barbuda',
        'bahamas',
        'barbados',
        'cuba',
        'dominica',
        'dominican_republic',
        'grenada',
        'haiti',
        'jamaica',
        'saint_kitts_and_nevis',
        'saint_lucia',
        'saint_vincent_and_the_grenadines',
        'trinidad_and_tobago',
        'argentina',
        'bolivia',
        'chile',
        'colombia',
        'ecuador',
        'guyana',
        'paraguay',
        'peru',
        'suriname',
        'uruguay',
        'venezuela',
      }),
    );
  });

  test('every new American country has the complete starter layout', () {
    for (final country in albumCountries.skip(expectedTotals.length)) {
      final categories = CardCatalog.cardsForCountry(
        country.id,
      ).map((card) => card.category).toSet();
      expect(
        categories,
        containsAll(const {
          CardCategory.city,
          CardCategory.flag,
          CardCategory.currency,
          CardCategory.landmark,
          CardCategory.nature,
          CardCategory.animal,
          CardCategory.culture,
          CardCategory.person,
        }),
        reason: country.name,
      );
    }
  });

  test('animal cards never repeat between countries', () {
    final animals = collectibleCards
        .where((card) => card.category == CardCategory.animal)
        .toList(growable: false);
    final animalKeys = animals
        .map((card) => card.id.substring(card.countryId.length + 1))
        .toList(growable: false);

    expect(animalKeys.toSet(), hasLength(animalKeys.length));
    expect(animals.map((card) => card.name).toSet(), hasLength(animals.length));
  });

  test('marked icons are the ten legendary cards', () {
    expect(
      collectibleCards
          .where((card) => card.rarity == CardRarity.legendary)
          .map((card) => card.id),
      orderedEquals(const [
        'brazil_christ_redeemer',
        'united_states_statue_of_liberty',
        'japan_mount_fuji',
        'france_eiffel_tower',
        'italy_colosseum',
        'united_kingdom_stonehenge',
        'china_great_wall',
        'india_taj_mahal',
        'egypt_great_pyramid',
        'greece_acropolis',
      ]),
    );
  });

  test('mythology and personalities have dedicated album sections', () {
    final egypt = CardCatalog.cardsForCountry('egypt');
    final greece = CardCatalog.cardsForCountry('greece');
    final unitedKingdom = CardCatalog.cardsForCountry('united_kingdom');

    expect(
      egypt.where((card) => card.category == CardCategory.mythology),
      hasLength(7),
    );
    expect(
      greece.where((card) => card.category == CardCategory.mythology),
      hasLength(11),
    );
    expect(
      unitedKingdom.where((card) => card.category == CardCategory.person),
      hasLength(4),
    );
  });
}
