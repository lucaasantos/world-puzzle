import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/app/app_controller.dart';
import 'package:puzzle_journey/app/app_scope.dart';
import 'package:puzzle_journey/core/theme/app_theme.dart';
import 'package:puzzle_journey/core/utils/card_labels.dart';
import 'package:puzzle_journey/data/packs_data.dart';
import 'package:puzzle_journey/models/collectible_card.dart';
import 'package:puzzle_journey/repositories/progress_repository.dart';
import 'package:puzzle_journey/screens/packs/packs_screen.dart';
import 'package:puzzle_journey/services/ads_service.dart';
import 'package:puzzle_journey/services/audio_service.dart';
import 'package:puzzle_journey/services/haptics_service.dart';
import 'package:puzzle_journey/services/pack_opening_service.dart';
import 'package:puzzle_journey/services/wallpaper_service.dart';

class _MemoryRepository implements ProgressRepository {
  ProgressSnapshot value = const ProgressSnapshot();

  @override
  Future<ProgressSnapshot> load() async => value;

  @override
  Future<void> save(ProgressSnapshot snapshot) async => value = snapshot;
}

class _FakeWallpaper implements WallpaperService {
  @override
  Future<bool> save(String assetPath) async => true;
}

class _SilentHaptics extends HapticsService {
  @override
  Future<void> reward() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('World Pack confirms, tears open, and reveals four cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController(
      repository: _MemoryRepository(),
      ads: AdsService(),
      audio: AudioService(),
      haptics: _SilentHaptics(),
      wallpaper: _FakeWallpaper(),
      packOpeningService: PackOpeningService(random: math.Random(551)),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.debugGrantPack(PackIds.world);

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(theme: AppTheme.dark, home: const PacksScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WORLD PACK'), findsWidgets);
    expect(find.textContaining('×1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pack-artwork-world_pack')),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'ABRIR').first);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pack-preview-world_pack')),
      findsOneWidget,
    );
    expect(find.text('ABRIR'), findsOneWidget);
    expect(find.text('VOLTAR'), findsOneWidget);
    expect(controller.packInventoryFor(PackIds.world).quantity, 1);

    await tester.tap(find.byKey(const ValueKey('back-pack-button-world_pack')));
    await tester.pumpAndSettle();
    expect(controller.packInventoryFor(PackIds.world).quantity, 1);
    expect(find.text('Pacotes'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'ABRIR').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-pack-button-world_pack')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('pack-top-piece-world_pack')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('pack-body-piece-world_pack')),
      findsOneWidget,
    );
    expect(find.text('ABRINDO...'), findsOneWidget);
    await tester.pumpAndSettle();

    const cardCount = 4;
    expect(controller.packInventoryFor(PackIds.world).quantity, 0);
    expect(find.text('REVELAR'), findsNothing);
    expect(find.byKey(const ValueKey('deck-preview-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('deck-preview-2')), findsOneWidget);
    var previousRarity = -1;
    for (var index = 0; index < cardCount; index++) {
      expect(find.text('${index + 1} / $cardCount'), findsOneWidget);
      expect(find.textContaining('DUPLICADA'), findsNothing);
      expect(find.textContaining(RegExp(r'^×\d+$')), findsNothing);
      final currentRarity = CardRarity.initialValues.indexWhere(
        (rarity) =>
            find.text(rarityLabel(rarity).toUpperCase()).evaluate().isNotEmpty,
      );
      expect(currentRarity, greaterThanOrEqualTo(0));
      expect(currentRarity, greaterThanOrEqualTo(previousRarity));
      previousRarity = currentRarity;
      await tester.tap(
        find.text(index == cardCount - 1 ? 'VER RESUMO' : 'PRÓXIMA CARTA'),
      );
      if (index < cardCount - 1) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 180));
        expect(find.byKey(ValueKey('outgoing-card-$index')), findsOneWidget);
        expect(find.byKey(ValueKey('card-${index + 1}')), findsOneWidget);
      }
      await tester.pumpAndSettle();
      expect(find.text('REVELAR'), findsNothing);
    }

    expect(find.text('PACOTE ABERTO!'), findsOneWidget);
    expect(find.textContaining('DUPLICADA'), findsNothing);
    expect(find.text('NOVA'), findsNothing);
    expect(find.textContaining(RegExp(r'^×\d+$')), findsNothing);
    expect(
      controller.cardInventory.values.fold<int>(
        0,
        (sum, entry) => sum + entry.quantity,
      ),
      cardCount,
    );
    expect(
      controller.cardInventory.keys,
      hasLength(cardCount),
      reason: 'the four cards in one pack must be distinct',
    );
  });

  for (final pack in PackCatalog.active.skip(1)) {
    testWidgets('${pack.name} confirms and tears open before revealing cards', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = AppController(
        repository: _MemoryRepository(),
        ads: AdsService(),
        audio: AudioService(),
        haptics: _SilentHaptics(),
        wallpaper: _FakeWallpaper(),
        packOpeningService: PackOpeningService(random: math.Random(551)),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.debugGrantPack(pack.id);

      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: MaterialApp(theme: AppTheme.dark, home: const PacksScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final listButton = find.byKey(ValueKey('open-pack-list-${pack.id}'));
      await tester.scrollUntilVisible(
        listButton,
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(listButton);
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('pack-preview-${pack.id}')), findsOneWidget);
      expect(controller.packInventoryFor(pack.id).quantity, 1);

      await tester.tap(find.byKey(ValueKey('open-pack-button-${pack.id}')));
      await tester.pump();
      expect(find.byKey(ValueKey('pack-top-piece-${pack.id}')), findsOneWidget);
      expect(
        find.byKey(ValueKey('pack-body-piece-${pack.id}')),
        findsOneWidget,
      );
      expect(find.text('ABRINDO...'), findsOneWidget);
      await tester.pumpAndSettle();

      expect(controller.packInventoryFor(pack.id).quantity, 0);
      expect(find.text('1 / ${pack.cardCount}'), findsOneWidget);
    });
  }
}
