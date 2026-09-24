import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/app/app_controller.dart';
import 'package:puzzle_journey/app/app_scope.dart';
import 'package:puzzle_journey/core/theme/app_theme.dart';
import 'package:puzzle_journey/repositories/progress_repository.dart';
import 'package:puzzle_journey/screens/album/album_screen.dart';
import 'package:puzzle_journey/services/ads_service.dart';
import 'package:puzzle_journey/services/audio_service.dart';
import 'package:puzzle_journey/services/haptics_service.dart';
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

  testWidgets('book mode opens Brazil and turns to its next sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController(
      repository: _MemoryRepository(),
      ads: AdsService(),
      audio: AudioService(),
      haptics: _SilentHaptics(),
      wallpaper: _FakeWallpaper(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(theme: AppTheme.dark, home: const AlbumScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('album-view-book')), findsOneWidget);
    await tester.tap(find.byKey(const Key('album-view-book')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('book-album-screen')), findsOneWidget);
    expect(find.byKey(const Key('country-book-page-brazil-1')), findsOneWidget);
    expect(
      find.text('CAP. 1/43  •  FOLHA 1/2  •  deslize para virar'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('book-next-page')));
    await tester.pumpAndSettle();

    expect(
      find.text('CAP. 1/43  •  FOLHA 2/2  •  deslize para virar'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('country-book-page-brazil-2')), findsOneWidget);
  });
}
