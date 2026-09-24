import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/app/app_controller.dart';
import 'package:puzzle_journey/repositories/local_progress_repository.dart';
import 'package:puzzle_journey/services/ads_service.dart';
import 'package:puzzle_journey/services/audio_service.dart';
import 'package:puzzle_journey/services/haptics_service.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('grants and paste are serialized, safe, and persistent', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final repository = LocalProgressRepository(storage);
    final controller = AppController(
      repository: repository,
      ads: AdsService(),
      audio: AudioService(),
      haptics: _SilentHaptics(),
      wallpaper: _FakeWallpaper(),
    );
    await controller.initialize();

    await Future.wait(
      List.generate(
        10,
        (_) => controller.debugGrantCard('brazil_christ_redeemer'),
      ),
    );
    expect(controller.inventoryFor('brazil_christ_redeemer').quantity, 10);

    final results = await Future.wait([
      controller.pasteCardInAlbum('brazil_christ_redeemer'),
      controller.pasteCardInAlbum('brazil_christ_redeemer'),
    ]);
    expect(results, contains(PasteCardResult.success));
    expect(results, contains(PasteCardResult.alreadyPasted));
    expect(controller.inventoryFor('brazil_christ_redeemer').quantity, 9);
    expect(
      controller.inventoryFor('brazil_christ_redeemer').pastedInAlbum,
      isTrue,
    );

    final reopened = await repository.load();
    expect(reopened.cardInventory['brazil_christ_redeemer']?.quantity, 9);
    expect(
      reopened.cardInventory['brazil_christ_redeemer']?.pastedInAlbum,
      isTrue,
    );
    controller.dispose();
  });
}
