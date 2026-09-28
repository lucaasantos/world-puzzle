import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/data/cards_data.dart';
import 'package:puzzle_journey/models/collectible_card.dart';
import 'package:puzzle_journey/widgets/collectible_card/card_artwork.dart';
import 'package:puzzle_journey/widgets/collectible_card/common_card_frame.dart';
import 'package:puzzle_journey/widgets/collectible_card/collectible_card_tile.dart';
import 'package:puzzle_journey/widgets/collectible_card/rare_card_frame.dart';

void main() {
  testWidgets('official card view exposes number, quantity, and all states', (
    tester,
  ) async {
    final card = CardCatalog.cardById('brazil_christ_redeemer')!;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final state in AlbumCardState.values)
                SizedBox(
                  width: 180,
                  child: AspectRatio(
                    aspectRatio: collectibleCardAspectRatio,
                    child: CollectibleCardView(
                      card: card,
                      state: state,
                      quantity: state == AlbumCardState.inCollection ? 2 : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('BR-013'), findsNWidgets(3));
    expect(find.text('🇧🇷  |  Brasil  |  BR-013'), findsNWidgets(3));
    expect(find.text('NA COLEÇÃO'), findsNothing);
    expect(find.text('COLADA'), findsNothing);
    expect(find.text('×2'), findsNothing);
    expect(find.text('NÃO OBTIDA'), findsNothing);
    final artworks = tester.widgetList<CardArtwork>(find.byType(CardArtwork));
    expect(artworks.map((artwork) => artwork.locked), [true, false, false]);
    final lockedFilter = tester.widget<ColorFiltered>(
      find.descendant(
        of: find.byType(CardArtwork).first,
        matching: find.byType(ColorFiltered),
      ),
    );
    expect(
      lockedFilter.colorFilter,
      const ColorFilter.mode(Color(0xFF6D7476), BlendMode.saturation),
    );
    expect(find.byKey(const Key('legendary-card-frame')), findsNWidgets(3));
    expect(find.byKey(const Key('legendary-card-artwork')), findsNWidgets(3));
    expect(find.byKey(const Key('legendary-frame-asset')), findsNWidgets(3));
    expect(find.byKey(const Key('legendary-card-metadata')), findsNWidgets(3));
    expect(find.text(card.description), findsNWidgets(3));
    expect(find.text('LENDÁRIA'), findsNWidgets(3));
    expect(find.byKey(const Key('collectible-card-frame')), findsNothing);

    final frame = tester.widget<DecoratedBox>(
      find.byKey(const Key('legendary-card-frame')).first,
    );
    final decoration = frame.decoration as BoxDecoration;
    expect(decoration.borderRadius, isNotNull);
  });

  testWidgets('every legendary card uses dynamic template content', (
    tester,
  ) async {
    final legendaryCards = collectibleCards
        .where((card) => card.rarity == CardRarity.legendary)
        .toList(growable: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: SingleChildScrollView(
          child: Column(
            children: [
              for (final card in legendaryCards)
                SizedBox(
                  width: 180,
                  child: AspectRatio(
                    aspectRatio: collectibleCardAspectRatio,
                    child: CollectibleCardView(
                      card: card,
                      state: AlbumCardState.inCollection,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(legendaryCards, hasLength(10));
    expect(
      find.byKey(const Key('legendary-card-frame')),
      findsNWidgets(legendaryCards.length),
    );
    expect(find.text('Grande Muralha da China'), findsOneWidget);
    for (final card in legendaryCards) {
      expect(card.description, isNotEmpty);
      expect(find.text(card.description), findsOneWidget);
    }
  });

  testWidgets('every epic card uses the purple dynamic template', (
    tester,
  ) async {
    final epicCards = collectibleCards
        .where((card) => card.rarity == CardRarity.epic)
        .toList(growable: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: SingleChildScrollView(
          child: Column(
            children: [
              for (final card in epicCards)
                SizedBox(
                  width: 180,
                  child: AspectRatio(
                    aspectRatio: collectibleCardAspectRatio,
                    child: CollectibleCardView(
                      card: card,
                      state: AlbumCardState.inCollection,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(epicCards, isNotEmpty);
    expect(
      find.byKey(const Key('epic-card-frame')),
      findsNWidgets(epicCards.length),
    );
    expect(
      find.byKey(const Key('epic-card-artwork')),
      findsNWidgets(epicCards.length),
    );
    expect(find.text('ÉPICA'), findsNWidgets(epicCards.length));
    expect(find.byKey(const Key('collectible-card-frame')), findsNothing);
    expect(find.byKey(const Key('legendary-card-frame')), findsNothing);
  });

  testWidgets('rare cards use the bright blue dynamic template', (
    tester,
  ) async {
    final rareCards = collectibleCards
        .where((card) => card.rarity == CardRarity.rare)
        .take(3)
        .toList(growable: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Row(
          children: [
            for (final card in rareCards)
              SizedBox(
                width: 180,
                child: AspectRatio(
                  aspectRatio: collectibleCardAspectRatio,
                  child: CollectibleCardView(
                    card: card,
                    state: AlbumCardState.inCollection,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    expect(rareCards, hasLength(3));
    expect(
      find.byKey(const Key('rare-card-frame')),
      findsNWidgets(rareCards.length),
    );
    expect(
      find.byKey(const Key('rare-card-artwork')),
      findsNWidgets(rareCards.length),
    );
    expect(find.byKey(const Key('rare-frame-asset')), findsNWidgets(3));
    expect(find.text('RARA'), findsNWidgets(rareCards.length));
    expect(find.byKey(const Key('collectible-card-frame')), findsNothing);
    expect(find.byKey(const Key('epic-card-frame')), findsNothing);
    expect(find.byType(RareCardFrame), findsNWidgets(rareCards.length));
  });

  testWidgets('shared frame renders dynamic card fields', (tester) async {
    final city = CardCatalog.cardById('brazil_rio_de_janeiro')!;
    final animal = CardCatalog.cardById('brazil_jaguar')!;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Row(
            children: [
              for (final card in [city, animal])
                SizedBox(
                  width: 180,
                  child: AspectRatio(
                    aspectRatio: collectibleCardAspectRatio,
                    child: CollectibleCardView(
                      card: card,
                      state: AlbumCardState.inCollection,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Rio de Janeiro'), findsOneWidget);
    expect(find.text('COMUM'), findsOneWidget);
    expect(find.text('CIDADE'), findsOneWidget);
    expect(find.text('Onça-pintada'), findsOneWidget);
    expect(find.text('ÉPICA'), findsOneWidget);
    expect(find.text('ANIMAL'), findsOneWidget);
    expect(find.byKey(const Key('common-card-frame')), findsOneWidget);
    expect(find.byKey(const Key('epic-card-frame')), findsOneWidget);
  });

  testWidgets('every common card uses the subtle gray dynamic template', (
    tester,
  ) async {
    final commonCards = collectibleCards
        .where((card) => card.rarity == CardRarity.common)
        .toList(growable: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                for (final card in commonCards)
                  SizedBox(
                    width: 180,
                    child: AspectRatio(
                      aspectRatio: collectibleCardAspectRatio,
                      child: CollectibleCardView(
                        card: card,
                        state: AlbumCardState.inCollection,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(commonCards, isNotEmpty);
    expect(
      find.byKey(const Key('common-card-frame')),
      findsNWidgets(commonCards.length),
    );
    expect(
      find.byKey(const Key('common-card-artwork')),
      findsNWidgets(commonCards.length),
    );
    expect(
      find.byKey(const Key('common-frame-asset')),
      findsNWidgets(commonCards.length),
    );
    expect(find.byType(CommonCardFrame), findsNWidgets(commonCards.length));
    expect(find.text('COMUM'), findsNWidgets(commonCards.length));
    expect(find.byKey(const Key('collectible-card-frame')), findsNothing);
    for (final card in commonCards) {
      expect(find.text(card.name), findsAtLeastNWidgets(1));
    }
  });
}
