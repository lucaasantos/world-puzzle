import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/data/cards_data.dart';
import 'package:puzzle_journey/models/collectible_card.dart';
import 'package:puzzle_journey/widgets/collectible_card/card_artwork.dart';

class _FixtureAssets extends CachingAssetBundle {
  _FixtureAssets(this.path, this.bytes);
  final String path;
  final Uint8List bytes;

  @override
  Future<ByteData> load(String key) async {
    if (key == path) return ByteData.sublistView(bytes);
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object>{})!;
    }
    throw StateError('Unexpected asset: $key');
  }
}

void main() {
  testWidgets('CardArtwork decodes WebP at the existing catalog path', (
    tester,
  ) async {
    final seed = collectibleCards.first;
    final card = CollectibleCard(
      id: seed.id,
      countryId: seed.countryId,
      name: seed.name,
      description: seed.description,
      rarity: seed.rarity,
      category: seed.category,
      imagePath: seed.imagePath,
      cardNumber: seed.cardNumber,
      catalogNumber: seed.catalogNumber,
      isActive: seed.isActive,
      sortOrder: seed.sortOrder,
      isPlaceholderImage: false,
    );
    final bytes = File(
      'assets/images/themes/japan/japan_01.webp',
    ).readAsBytesSync();
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _FixtureAssets(card.imagePath, bytes),
        child: MaterialApp(
          home: SizedBox(
            width: 164,
            height: 168,
            child: CardArtwork(card: card),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final codec = await tester.binding.instantiateImageCodecFromBuffer(
        await ui.ImmutableBuffer.fromUint8List(bytes),
      );
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0));
      frame.image.dispose();
      codec.dispose();
    });
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('ARTE TEMPORÁRIA'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
