import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/app/app_controller.dart';
import 'package:puzzle_journey/app/app_scope.dart';
import 'package:puzzle_journey/core/theme/app_theme.dart';
import 'package:puzzle_journey/repositories/progress_repository.dart';
import 'package:puzzle_journey/screens/home/home_screen.dart';
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

class _MockWallpaper implements WallpaperService {
  @override
  Future<bool> save(String assetPath) async => true;
}

class _TestOnline extends OnlineGameService {
  _TestOnline() {
    connected = true;
    user = {
      'nickname': 'LucasWorld',
      'avatar': 'globe',
      'lives': 3,
      'lifeAnchor': 0,
      'worldCoins': 0,
      'worldCoinRewardAds': {'cycleId': '2026-09-21', 'earnedToday': 0},
      'progression': {'level': 12, 'currentXp': 750, 'nextXp': 1000},
    };
    daily = {
      'id': '2026-09-17',
      'countries': {'japan': 'hard'},
      'claimed': false,
    };
    config = {
      'lives': {'maximum': 4, 'regenerationMs': 1800000},
      'worldCoin': {'rewardedAdAmount': 1, 'dailyAdLimit': 10},
    };
  }

  @override
  Future<void> sync() async {}
}

void main() {
  testWidgets(
    'completed daily exploration shows only a score-scaled gift glow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(411, 868));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final online = _TestOnline()
        ..unclaimedExplorations = [
          {'id': '2026-09-17', 'bestScore': 50, 'claimed': false},
        ];
      final controller = AppController(
        repository: _MemoryRepo(),
        ads: AdsService(),
        audio: AudioService(),
        haptics: HapticsService(),
        wallpaper: _MockWallpaper(),
        online: online,
      );

      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: MaterialApp(theme: AppTheme.dark, home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_daily_collect_gift')), findsOneWidget);
      expect(find.text('COLETAR'), findsNothing);
      final mediumGlow = tester.getSize(
        find.byKey(const Key('home_daily_collect_glow')),
      );

      online.unclaimedExplorations = [
        {'id': '2026-09-17', 'bestScore': 100, 'claimed': false},
      ];
      await controller.refreshOnline();
      await tester.pumpAndSettle();
      final maximumGlow = tester.getSize(
        find.byKey(const Key('home_daily_collect_glow')),
      );
      expect(maximumGlow.width, greaterThan(mediumGlow.width));
      expect(tester.takeException(), isNull);

      controller.dispose();
    },
  );

  testWidgets(
    'HomeScreen contains new HUD, Jogar button, and adventure shortcuts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final online = _TestOnline();
      final controller = AppController(
        repository: _MemoryRepo(),
        ads: AdsService(),
        audio: AudioService(),
        haptics: HapticsService(),
        wallpaper: _MockWallpaper(),
        online: online,
      );

      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: MaterialApp(theme: AppTheme.dark, home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Nickname in wooden plaque
      expect(find.text('LucasWorld'), findsOneWidget);

      // 2. Level and XP bar
      expect(find.text('Nível 12'), findsOneWidget);
      expect(find.text('750 / 1000 XP'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/home/nickname_badge.png',
        ),
        findsNothing,
      );
      expect(
        tester.getBottomLeft(find.text('LucasWorld')).dy,
        lessThan(tester.getTopLeft(find.text('Nível 12')).dy),
      );

      // 3. Energy indicator
      expect(find.text('3'), findsOneWidget);
      expect(find.byKey(const Key('home_energy_shortcut')), findsOneWidget);
      expect(find.text('ENERGIAS'), findsOneWidget);
      expect(find.byKey(const Key('home_title_art')), findsOneWidget);
      expect(find.text('PUZZLE\nWORLD'), findsNothing);
      expect(find.text('JOGUE  •  DESCUBRA  •  COLECIONE'), findsOneWidget);
      expect(
        tester.getBottomLeft(find.text('Nível 12')).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('home_primary_shortcuts'))).dy,
        ),
      );

      await tester.tap(find.byKey(const Key('home_energy_shortcut')));
      await tester.pump();
      expect(find.byKey(const Key('energy_battery_dialog')), findsOneWidget);
      expect(find.text('Sua Energia (3/4)'), findsOneWidget);
      expect(find.byKey(const Key('energy_close_button')), findsOneWidget);
      expect(find.text('Voltar'), findsNothing);
      expect(find.text('ASSISTIR ANÚNCIO  •  +1 ENERGIA'), findsOneWidget);
      await tester.tap(find.byKey(const Key('energy_close_button')));
      await tester.pumpAndSettle();

      // 4. Main CTA is "JOGAR", old "Explorar o mundo" is removed
      expect(find.text('JOGAR'), findsOneWidget);
      expect(find.text('Explorar o mundo'), findsNothing);

      // 5. "Sua aventura" is completely removed
      expect(find.text('Sua aventura'), findsNothing);

      // 6. Progression and reward shortcuts.
      expect(find.byKey(const Key('home_daily_shortcut')), findsOneWidget);
      expect(find.text('Exploração Diária'), findsOneWidget);
      expect(find.byKey(const Key('home_star_dust_shortcut')), findsOneWidget);
      expect(find.text('Star Dust'), findsOneWidget);
      expect(find.byKey(const Key('home_packs_shortcut')), findsOneWidget);
      expect(find.text('Pacotes'), findsOneWidget);
      expect(find.byKey(const Key('home_card_market_icon')), findsOneWidget);
      expect(find.byIcon(Icons.storefront_rounded), findsNothing);

      // Persistent, tappable World Coin balance opens the voluntary ad flow.
      expect(
        find.byKey(const Key('world_coin_balance_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('world_coin_header_balance')),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/currency/world_coin.png',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('world_coin_balance_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('world_coin_dialog')), findsOneWidget);
      expect(find.byKey(const Key('world_coin_modal_balance')), findsOneWidget);
      expect(find.text('Today: 0 / 10'), findsOneWidget);
      expect(find.text('WATCH AD  •  +1 World Coin'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      online.user['worldCoinRewardAds'] = {
        'cycleId': '2026-09-21',
        'earnedToday': 10,
      };
      await controller.refreshOnline();
      await tester.pump();
      await tester.tap(find.byKey(const Key('world_coin_balance_button')));
      await tester.pumpAndSettle();
      expect(find.text('Today: 10 / 10'), findsOneWidget);
      expect(find.text('DAILY LIMIT REACHED'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('world_coin_watch_ad_button')),
      );
      expect(button.onPressed, isNull);

      controller.dispose();
    },
  );
}
