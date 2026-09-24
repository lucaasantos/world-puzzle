import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/app/app_controller.dart';
import 'package:puzzle_journey/data/packs_data.dart';
import 'package:puzzle_journey/data/themes_data.dart';
import 'package:puzzle_journey/models/card_pack.dart';
import 'package:puzzle_journey/models/puzzle_result.dart';
import 'package:puzzle_journey/repositories/local_progress_repository.dart';
import 'package:puzzle_journey/repositories/progress_repository.dart';
import 'package:puzzle_journey/services/ads_service.dart';
import 'package:puzzle_journey/services/audio_service.dart';
import 'package:puzzle_journey/services/haptics_service.dart';
import 'package:puzzle_journey/services/pack_opening_service.dart';
import 'package:puzzle_journey/services/puzzle_reward_service.dart';
import 'package:puzzle_journey/services/storage_service.dart';
import 'package:puzzle_journey/services/wallpaper_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeWallpaper implements WallpaperService {
  @override
  Future<bool> save(String assetPath) async => true;
}

class _SilentHaptics extends HapticsService {
  @override
  Future<void> reward() async {}
}

class _SilentAds extends AdsService {
  @override
  Future<void> onLevelCompleted() async {}

  @override
  void dispose() {}
}

class _MemoryRepository implements ProgressRepository {
  ProgressSnapshot value = const ProgressSnapshot();

  @override
  Future<ProgressSnapshot> load() async => value;

  @override
  Future<void> save(ProgressSnapshot snapshot) async => value = snapshot;
}

AppController controllerFor(
  ProgressRepository repository, {
  PuzzleRewardService? rewardService,
}) => AppController(
  repository: repository,
  ads: _SilentAds(),
  audio: AudioService(),
  haptics: _SilentHaptics(),
  wallpaper: _FakeWallpaper(),
  packOpeningService: PackOpeningService(random: math.Random(991)),
  puzzleRewardService: rewardService,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pack opening is serialized, atomic, and persistent', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalProgressRepository(await StorageService.create());
    final controller = controllerFor(repository);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.debugGrantPack(PackIds.world);

    final outcomes = await Future.wait([
      controller.openPack(PackIds.world),
      controller.openPack(PackIds.world),
    ]);

    expect(
      outcomes.map((outcome) => outcome.status),
      containsAll([PackOpenStatus.success, PackOpenStatus.notOwned]),
    );
    expect(controller.packInventoryFor(PackIds.world).quantity, 0);
    expect(
      controller.cardInventory.values.fold<int>(
        0,
        (sum, entry) => sum + entry.quantity,
      ),
      4,
    );

    final reopened = await repository.load();
    expect(reopened.packInventory[PackIds.world]?.quantity, 0);
    expect(
      reopened.cardInventory.values.fold<int>(
        0,
        (sum, entry) => sum + entry.quantity,
      ),
      4,
    );
  });

  test(
    'puzzle reward distinguishes first completion, replay, and duplicate call',
    () async {
      const config = PuzzleRewardConfig(
        firstCompletionPackChance: 1,
        replayPackChance: 0,
        rewardPackId: PackIds.world,
      );
      final repository = _MemoryRepository();
      final controller = controllerFor(
        repository,
        rewardService: PuzzleRewardService(
          config: config,
          random: math.Random(2),
        ),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      final theme = gameThemes.first;
      final level = theme.levels.first;
      final first = PuzzleResult(
        levelId: level.id,
        themeId: theme.id,
        gridSize: level.gridSize,
        elapsedSeconds: 50,
        moves: 30,
        stars: 3,
        completedAt: DateTime(2026, 8, 27, 10),
      );

      final firstOutcome = await controller.recordResult(theme, first);
      final duplicateOutcome = await controller.recordResult(theme, first);
      final replayOutcome = await controller.recordResult(
        theme,
        PuzzleResult(
          levelId: level.id,
          themeId: theme.id,
          gridSize: level.gridSize,
          elapsedSeconds: 60,
          moves: 40,
          stars: 2,
          completedAt: DateTime(2026, 8, 27, 11),
        ),
      );

      expect(firstOutcome.packRewardId, PackIds.world);
      expect(duplicateOutcome.packRewardId, isNull);
      expect(replayOutcome.packRewardId, isNull);
      expect(controller.packInventoryFor(PackIds.world).quantity, 1);
      expect(controller.progress[level.id]?.completions, 2);
      expect(repository.value.processedCompletionIds, hasLength(2));
    },
  );
}
