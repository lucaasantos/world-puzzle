import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/data/packs_data.dart';
import 'package:puzzle_journey/widgets/card_pack/pack_artwork.dart';

void main() {
  testWidgets('pack artwork shows one, two, or three overlapping packs', (
    tester,
  ) async {
    final pack = PackCatalog.byId(PackIds.world)!;

    Future<void> pumpQuantity(int quantity) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 140,
              height: 210,
              child: PackArtwork(pack: pack, quantity: quantity),
            ),
          ),
        ),
      ),
    );

    await pumpQuantity(1);
    expect(
      find.byKey(const ValueKey('pack-layer-world_pack-0')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pack-layer-world_pack-1')), findsNothing);

    await pumpQuantity(2);
    expect(
      find.byKey(const ValueKey('pack-layer-world_pack-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pack-layer-world_pack-1')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pack-layer-world_pack-2')), findsNothing);

    await pumpQuantity(8);
    expect(
      find.byKey(const ValueKey('pack-layer-world_pack-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pack-layer-world_pack-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pack-layer-world_pack-2')),
      findsOneWidget,
    );
  });
}
