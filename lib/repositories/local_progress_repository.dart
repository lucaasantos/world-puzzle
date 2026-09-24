import 'dart:convert';

import '../models/puzzle_progress.dart';
import '../models/card_inventory_entry.dart';
import '../models/card_pack.dart';
import '../models/saved_game.dart';
import '../services/storage_service.dart';
import 'progress_repository.dart';

class LocalProgressRepository implements ProgressRepository {
  const LocalProgressRepository(
    this.storage, {
    this.key = 'puzzle_journey_progress_v1',
  });
  final StorageService storage;
  final String key;

  @override
  Future<ProgressSnapshot> load() async {
    final raw = storage.read(key);
    if (raw == null) return const ProgressSnapshot();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final levelsJson = json['levels'] as Map<String, dynamic>? ?? {};
      final inventoryJson =
          json['cardInventory'] as Map<String, dynamic>? ?? const {};
      final packInventoryJson =
          json['packInventory'] as Map<String, dynamic>? ?? const {};
      return ProgressSnapshot(
        levels: levelsJson.map(
          (key, value) => MapEntry(
            key,
            PuzzleProgress.fromJson(value as Map<String, dynamic>),
          ),
        ),
        unlockedWallpapers: (json['unlockedWallpapers'] as List? ?? [])
            .cast<String>()
            .toSet(),
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        musicEnabled: json['musicEnabled'] as bool? ?? true,
        hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
        onboardingSeen: json['onboardingSeen'] as bool? ?? false,
        savedGame: json['savedGame'] == null
            ? null
            : SavedGame.fromJson(json['savedGame'] as Map<String, dynamic>),
        cardInventory: inventoryJson.map(
          (key, value) => MapEntry(
            key,
            CardInventoryEntry.fromJson(value as Map<String, dynamic>),
          ),
        ),
        packInventory: packInventoryJson.map(
          (key, value) => MapEntry(
            key,
            PackInventoryEntry.fromJson(value as Map<String, dynamic>),
          ),
        ),
        processedCompletionIds:
            (json['processedCompletionIds'] as List? ?? const [])
                .cast<String>()
                .toSet(),
      );
    } catch (_) {
      return const ProgressSnapshot();
    }
  }

  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    final json = <String, Object?>{
      'levels': snapshot.levels.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'unlockedWallpapers': snapshot.unlockedWallpapers.toList(),
      'soundEnabled': snapshot.soundEnabled,
      'musicEnabled': snapshot.musicEnabled,
      'hapticsEnabled': snapshot.hapticsEnabled,
      'onboardingSeen': snapshot.onboardingSeen,
      'savedGame': snapshot.savedGame?.toJson(),
      'cardInventory': snapshot.cardInventory.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'packInventory': snapshot.packInventory.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'processedCompletionIds': snapshot.processedCompletionIds.toList(),
    };
    await storage.write(key, jsonEncode(json));
  }
}
