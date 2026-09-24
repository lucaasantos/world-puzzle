import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/data/approved_card_art.dart';
import 'package:puzzle_journey/data/cards_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'approved artwork is registered and decodable from the game bundle',
    () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final bundledAssets = manifest.listAssets().toSet();
      final catalogIds = collectibleCards.map((card) => card.id).toSet();
      expect(catalogIds.containsAll(approvedCardArtIds), isTrue);

      for (final card in collectibleCards) {
        final approved = approvedCardArtIds.contains(card.id);
        expect(card.isPlaceholderImage, !approved, reason: card.id);
        if (!approved) continue;

        expect(bundledAssets, contains(card.imagePath), reason: card.id);
        final data = await rootBundle.load(card.imagePath);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        try {
          final frame = await codec.getNextFrame();
          expect(frame.image.width, 1000, reason: card.id);
          expect(frame.image.height, 1024, reason: card.id);
          frame.image.dispose();
        } finally {
          codec.dispose();
        }
      }
    },
  );
}
