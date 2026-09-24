import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/models/puzzle_progress.dart';
import 'package:puzzle_journey/models/card_inventory_entry.dart';
import 'package:puzzle_journey/models/card_pack.dart';
import 'package:puzzle_journey/repositories/local_progress_repository.dart';
import 'package:puzzle_journey/repositories/progress_repository.dart';
import 'package:puzzle_journey/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('progress survives repository recreation', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final repository = LocalProgressRepository(storage);
    final date = DateTime(2026, 3, 4);
    final progress = PuzzleProgress(
      levelId: 'japan_01',
      bestTimeSeconds: 72,
      bestMoves: 38,
      stars: 3,
      completions: 2,
      firstCompletedAt: date,
      bestResultAt: date,
    );
    await repository.save(
      ProgressSnapshot(
        levels: {'japan_01': progress},
        unlockedWallpapers: const {'japan'},
        soundEnabled: false,
        cardInventory: const {
          'brazil_flag': CardInventoryEntry(
            cardId: 'brazil_flag',
            quantity: 3,
            pastedInAlbum: true,
          ),
        },
        packInventory: const {
          'world_pack': PackInventoryEntry(packId: 'world_pack', quantity: 2),
        },
        processedCompletionIds: const {'japan_01:123'},
      ),
    );

    final reopened = LocalProgressRepository(await StorageService.create());
    final loaded = await reopened.load();
    expect(loaded.levels['japan_01']?.bestMoves, 38);
    expect(loaded.levels['japan_01']?.stars, 3);
    expect(loaded.unlockedWallpapers, contains('japan'));
    expect(loaded.soundEnabled, isFalse);
    expect(loaded.cardInventory['brazil_flag']?.quantity, 3);
    expect(loaded.cardInventory['brazil_flag']?.pastedInAlbum, isTrue);
    expect(loaded.packInventory['world_pack']?.quantity, 2);
    expect(loaded.processedCompletionIds, contains('japan_01:123'));
  });
}
