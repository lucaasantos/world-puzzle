import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/data/cards_data.dart';
import 'package:puzzle_journey/models/collectible_card.dart';
import 'package:puzzle_journey/widgets/collectible_card/card_artwork.dart';
import 'package:puzzle_journey/widgets/collectible_card/collectible_card_frame.dart';
import 'package:puzzle_journey/widgets/collectible_card/collectible_card_tile.dart';

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

    expect(find.text('BR-013'), findsNWidgets(3));
    expect(find.textContaining('BRASIL'), findsNWidgets(3));
    expect(find.text('NA COLEÇÃO'), findsOneWidget);
    expect(find.text('COLADA'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
    expect(find.text('NÃO OBTIDA'), findsAtLeastNWidgets(1));
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
    expect(find.byKey(const Key('collectible-card-frame')), findsNWidgets(3));
    expect(find.byKey(const Key('collectible-card-artwork')), findsNWidgets(3));

    final frame = tester.widget<DecoratedBox>(
      find.byKey(const Key('collectible-card-frame')).first,
    );
    final decoration = frame.decoration as BoxDecoration;
    expect(
      decoration.borderRadius,
      BorderRadius.circular(collectibleCardCornerRadius),
    );
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
    expect(find.byKey(const Key('collectible-card-frame')), findsNWidgets(2));
  });

  testWidgets('every common card uses the shared standard frame', (
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
      find.byKey(const Key('collectible-card-frame')),
      findsNWidgets(commonCards.length),
    );
    expect(
      tester
          .widgetList<CollectibleCardFrame>(find.byType(CollectibleCardFrame))
          .every(
            (frame) => frame.rarityAccent == rarityAccent(CardRarity.common),
          ),
      isTrue,
    );
    for (final card in commonCards) {
      expect(find.text(card.name), findsAtLeastNWidgets(1));
    }
  });
}
