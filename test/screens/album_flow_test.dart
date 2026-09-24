import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/app/app_controller.dart';
import 'package:puzzle_journey/app/app_scope.dart';
import 'package:puzzle_journey/core/theme/app_theme.dart';
import 'package:puzzle_journey/data/cards_data.dart';
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

  testWidgets('player can navigate to Brazil and paste an owned card', (
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
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.debugGrantCard('brazil_sao_paulo', quantity: 2);

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(theme: AppTheme.dark, home: const AlbumScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('0 de ${collectibleCards.length} figurinhas coladas'),
      findsOneWidget,
    );
    expect(find.text('Brasil'), findsOneWidget);

    await tester.tap(find.text('Brasil'));
    await tester.pumpAndSettle();
    expect(find.text('São Paulo'), findsOneWidget);

    await tester.tap(find.text('São Paulo'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('COLAR NO ÁLBUM'),
      find.byType(Scrollable).last,
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
    expect(find.text('COLAR NO ÁLBUM'), findsOneWidget);
    await tester.tap(find.text('COLAR NO ÁLBUM'));
    await tester.pumpAndSettle();
    expect(find.text('Colar esta carta no álbum?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Colar'));
    await tester.pumpAndSettle();

    expect(controller.inventoryFor('brazil_sao_paulo').quantity, 1);
    expect(controller.inventoryFor('brazil_sao_paulo').pastedInAlbum, isTrue);
    expect(find.text('NO ÁLBUM'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Coleção'));
    await tester.pumpAndSettle();

    expect(find.text('×1'), findsOneWidget);
    expect(find.text('COLADA'), findsOneWidget);
  });
}
