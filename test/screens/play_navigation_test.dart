import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/app/app_controller.dart';
import 'package:puzzle_journey/app/app_scope.dart';
import 'package:puzzle_journey/core/theme/app_theme.dart';
import 'package:puzzle_journey/data/blocks_levels_data.dart';
import 'package:puzzle_journey/data/game_modes_data.dart';
import 'package:puzzle_journey/data/jigsaw_levels_data.dart';
import 'package:puzzle_journey/data/themes_data.dart';
import 'package:puzzle_journey/repositories/progress_repository.dart';
import 'package:puzzle_journey/screens/countries/countries_screen.dart';
import 'package:puzzle_journey/screens/levels/levels_screen.dart';
import 'package:puzzle_journey/screens/themes/themes_screen.dart';
import 'package:puzzle_journey/services/ads_service.dart';
import 'package:puzzle_journey/services/audio_service.dart';
import 'package:puzzle_journey/services/haptics_service.dart';
import 'package:puzzle_journey/services/online_game_service.dart';
import 'package:puzzle_journey/services/wallpaper_service.dart';

class _MemoryRepo implements ProgressRepository {
  @override
  Future<ProgressSnapshot> load() async => const ProgressSnapshot();

  @override
  Future<void> save(ProgressSnapshot snapshot) async {}
}

class _WallpaperStub implements WallpaperService {
  @override
  Future<bool> save(String assetPath) async => true;
}

class _ZeroEnergyOnline extends OnlineGameService {
  _ZeroEnergyOnline() {
    connected = true;
    user = {'lives': 0, 'lifeAnchor': 0};
    config = {
      'lives': {'maximum': 4, 'regenerationMs': 1800000},
    };
  }

  @override
  Future<void> sync() async {}
}

AppController _controller() => AppController(
  repository: _MemoryRepo(),
  ads: AdsService(),
  audio: AudioService(),
  haptics: HapticsService(),
  wallpaper: _WallpaperStub(),
);

Widget _host(AppController controller) => AppScope(
  controller: controller,
  child: MaterialApp(theme: AppTheme.dark, home: const ThemesScreen()),
);

AppController _onlineController(OnlineGameService online) => AppController(
  repository: _MemoryRepo(),
  ads: AdsService(),
  audio: AudioService(),
  haptics: HapticsService(),
  wallpaper: _WallpaperStub(),
  online: online,
);

void main() {
  test('mode and country catalog is ready for the shared future flow', () {
    expect(gameModes.map((mode) => mode.id), ['sliding', 'jigsaw', 'blocks']);
    expect(gameModes.where((mode) => mode.enabled).map((mode) => mode.id), [
      'sliding',
      'jigsaw',
      'blocks',
    ]);
    expect(dailyExplorationCountryIds, [
      'brazil',
      'japan',
      'united_states',
      'egypt',
    ]);
    for (final mode in gameModes) {
      expect(mode.countries.map((country) => country.id), [
        'brazil',
        'japan',
        'united_states',
        'egypt',
      ]);
      expect(
        mode.countries.where((country) => country.enabled).map((c) => c.id),
        ['brazil', 'japan', 'united_states', 'egypt'],
      );
    }
  });

  test('United States and Egypt provide four phases in every game mode', () {
    for (final countryId in ['united_states', 'egypt']) {
      final theme = gameThemes.singleWhere((theme) => theme.id == countryId);
      expect(theme.levels, hasLength(4));
      expect(theme.levels.map((level) => level.id), [
        '${countryId}_01',
        '${countryId}_02',
        '${countryId}_03',
        '${countryId}_04',
      ]);
      expect(
        theme.levels.map((level) => level.imagePath),
        List.generate(
          4,
          (index) =>
              'assets/images/themes/$countryId/${countryId}_${(index + 1).toString().padLeft(2, '0')}.webp',
        ),
      );

      final jigsaw = jigsawLevelsFor(countryId);
      expect(jigsaw, hasLength(4));
      expect(jigsaw.map((level) => level.id), [
        'jigsaw_${countryId}_easy',
        'jigsaw_${countryId}_medium',
        'jigsaw_${countryId}_hard',
        'jigsaw_${countryId}_veryHard',
      ]);

      final blocks = blocksLevelsFor(countryId);
      expect(blocks, hasLength(4));
      expect(blocks.map((level) => level.id), [
        'blocks_${countryId}_easy',
        'blocks_${countryId}_medium',
        'blocks_${countryId}_hard',
        'blocks_${countryId}_veryHard',
      ]);
    }
  });

  test('Brazil provides four block phases', () {
    final levels = blocksLevelsFor('brazil');
    expect(levels, hasLength(4));
    expect(levels.map((level) => level.id), [
      'blocks_brazil_easy',
      'blocks_brazil_medium',
      'blocks_brazil_hard',
      'blocks_brazil_veryHard',
    ]);
  });

  testWidgets('Brazil, United States and Egypt open in every game mode', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(controller));
    await tester.pumpAndSettle();
    for (final modeId in ['sliding', 'jigsaw', 'blocks']) {
      await tester.ensureVisible(find.byKey(Key('game_mode_$modeId')));
      await tester.tap(find.byKey(Key('game_mode_$modeId')));
      await tester.pumpAndSettle();

      for (final entry in {
        'brazil': 'Brasil',
        'united_states': 'Estados Unidos',
        'egypt': 'Egito',
      }.entries) {
        await tester.ensureVisible(find.byKey(Key('country_${entry.key}')));
        await tester.tap(find.byKey(Key('country_${entry.key}')));
        await tester.pumpAndSettle();
        expect(find.byType(LevelsScreen), findsOneWidget);
        if (modeId == 'sliding') {
          expect(find.text(entry.value), findsOneWidget);
          expect(find.text('FÁCIL'), findsNWidgets(2));
          expect(find.text('MÉDIO'), findsOneWidget);
          expect(find.text('DIFÍCIL'), findsOneWidget);
        } else {
          final prefix = modeId == 'jigsaw'
              ? 'jigsaw_difficulty'
              : 'blocks_difficulty';
          for (final difficulty in ['easy', 'medium', 'hard', 'veryHard']) {
            expect(find.byKey(Key('${prefix}_$difficulty')), findsOneWidget);
          }
        }
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.byType(LevelsScreen))).pop();
        await tester.pumpAndSettle();
      }

      Navigator.of(tester.element(find.byType(CountriesScreen))).pop();
      await tester.pumpAndSettle();
    }
  });

  test('Japan levels derive their fixed difficulty from puzzle size', () {
    final japan = gameThemes.singleWhere((theme) => theme.id == 'japan');
    expect(japan.levels.map((level) => level.gridSize), [3, 3, 4, 5]);
    expect(japan.levels.map((level) => level.difficultyId), [
      'easy',
      'easy',
      'medium',
      'hard',
    ]);
    expect(japan.levels.map((level) => level.difficultyLabel), [
      'FÁCIL',
      'FÁCIL',
      'MÉDIO',
      'DIFÍCIL',
    ]);
  });

  testWidgets('play flow chooses mode, country, then a fixed challenge', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(controller));
    await tester.pumpAndSettle();
    expect(find.text('Puzzle Deslizante'), findsOneWidget);
    expect(find.text('Quebra-Cabeças'), findsOneWidget);
    expect(find.text('Blocos'), findsOneWidget);
    expect(find.text('MAIS JOGOS EM BREVE'), findsNothing);
    expect(find.byKey(const Key('jigsaw_mode_icon')), findsOneWidget);
    expect(find.byKey(const Key('sliding_mode_icon')), findsOneWidget);
    expect(find.byKey(const Key('blocks_mode_icon')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('game_mode_sliding'))).dy,
      lessThan(350),
    );

    await tester.ensureVisible(find.byKey(const Key('game_mode_jigsaw')));
    await tester.tap(find.byKey(const Key('game_mode_jigsaw')));
    await tester.pumpAndSettle();
    expect(find.byType(CountriesScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('country_brazil')));
    await tester.pumpAndSettle();
    expect(find.byType(LevelsScreen), findsOneWidget);
    expect(find.byKey(const Key('jigsaw_difficulty_easy')), findsOneWidget);
    expect(find.byKey(const Key('jigsaw_difficulty_veryHard')), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(find.byKey(const Key('jigsaw_difficulty_easy')))
          .onTap,
      isNotNull,
    );
    expect(
      tester
          .widget<InkWell>(find.byKey(const Key('jigsaw_difficulty_medium')))
          .onTap,
      isNull,
    );
    expect(find.text('Conclua a dificuldade anterior'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(LevelsScreen))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('country_japan')));
    await tester.pumpAndSettle();
    expect(find.byType(LevelsScreen), findsOneWidget);
    expect(find.byKey(const Key('jigsaw_difficulty_easy')), findsOneWidget);
    expect(find.byKey(const Key('jigsaw_difficulty_medium')), findsOneWidget);
    expect(find.byKey(const Key('jigsaw_difficulty_hard')), findsOneWidget);
    expect(find.byKey(const Key('jigsaw_difficulty_veryHard')), findsOneWidget);
    Navigator.of(tester.element(find.byType(LevelsScreen))).pop();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(CountriesScreen))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('game_mode_blocks')));
    await tester.tap(find.byKey(const Key('game_mode_blocks')));
    await tester.pumpAndSettle();
    expect(find.byType(CountriesScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('country_japan')));
    await tester.pumpAndSettle();
    expect(find.byType(LevelsScreen), findsOneWidget);
    expect(find.byKey(const Key('blocks_difficulty_easy')), findsOneWidget);
    expect(find.byKey(const Key('blocks_difficulty_medium')), findsOneWidget);
    expect(find.byKey(const Key('blocks_difficulty_hard')), findsOneWidget);
    expect(find.byKey(const Key('blocks_difficulty_veryHard')), findsOneWidget);
    Navigator.of(tester.element(find.byType(LevelsScreen))).pop();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(CountriesScreen))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('game_mode_sliding')));
    await tester.pumpAndSettle();
    expect(find.byType(CountriesScreen), findsOneWidget);
    expect(find.text('BRASIL'), findsOneWidget);
    expect(find.text('JAPÃO'), findsOneWidget);
    expect(find.text('ESTADOS UNIDOS'), findsOneWidget);
    expect(find.text('EGITO'), findsOneWidget);

    await tester.tap(find.byKey(const Key('country_brazil')));
    await tester.pumpAndSettle();
    expect(find.byType(LevelsScreen), findsOneWidget);
    expect(find.text('FÁCIL'), findsNWidgets(2));
    expect(find.text('MÉDIO'), findsOneWidget);
    expect(find.text('DIFÍCIL'), findsOneWidget);
    expect(find.text('FASE 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Energy stays visible and zero Energy opens recharge flow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = _onlineController(_ZeroEnergyOnline());
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(controller));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('game_modes_energy_indicator')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('game_mode_jigsaw')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('countries_energy_indicator')), findsOneWidget);

    await tester.tap(find.byKey(const Key('country_brazil')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('levels_energy_indicator')), findsOneWidget);

    await tester.tap(find.byKey(const Key('jigsaw_difficulty_easy')));
    await tester.pump();
    expect(find.text('Você está sem Energia!'), findsOneWidget);
    expect(
      find.text('Recarregue sua Energia para continuar jogando.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('energy_watch_ad_button')), findsOneWidget);
  });
}
