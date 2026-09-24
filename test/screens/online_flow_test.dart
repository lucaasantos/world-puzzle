import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_journey/app/app_controller.dart';
import 'package:puzzle_journey/app/app_scope.dart';
import 'package:puzzle_journey/core/theme/app_theme.dart';
import 'package:puzzle_journey/models/card_pack.dart';
import 'package:puzzle_journey/repositories/progress_repository.dart';
import 'package:puzzle_journey/screens/home/home_screen.dart';
import 'package:puzzle_journey/screens/online/player_screens.dart';
import 'package:puzzle_journey/screens/splash/splash_screen.dart';
import 'package:puzzle_journey/screens/star_dust/star_dust_screen.dart';
import 'package:puzzle_journey/services/ads_service.dart';
import 'package:puzzle_journey/services/audio_service.dart';
import 'package:puzzle_journey/services/haptics_service.dart';
import 'package:puzzle_journey/services/online_game_service.dart';
import 'package:puzzle_journey/services/wallpaper_service.dart';

class MemoryProgress implements ProgressRepository {
  @override
  Future<ProgressSnapshot> load() async => const ProgressSnapshot();
  @override
  Future<void> save(ProgressSnapshot snapshot) async {}
}

class WallpaperStub implements WallpaperService {
  @override
  Future<bool> save(String assetPath) async => true;
}

class FakeOnline extends OnlineGameService {
  FakeOnline() {
    connected = true;
    user = {
      'nickname': 'Explorador',
      'avatar': 'globe',
      'lives': 3,
      'lifeAnchor': 0,
      'progression': {'level': 4, 'currentXp': 85, 'nextXp': 205},
      'puzzlesCompleted': 7,
      'countriesExplored': ['japan'],
      'cardsReceived': 4,
    };
    daily = {
      'id': '2026-09-16',
      'countryIds': ['brazil', 'japan', 'united_states', 'egypt'],
      'countries': {
        'japan': {
          'completed': true,
          'bestDifficulty': 'hard',
          'bestPoints': 20,
        },
        'egypt': {
          'completed': true,
          'bestDifficulty': 'medium',
          'bestPoints': 15,
        },
        'united_states': {
          'completed': true,
          'bestDifficulty': 'easy',
          'bestPoints': 10,
        },
      },
      'bestScore': 45,
      'claimed': false,
    };
    config = {
      'lives': {'maximum': 4, 'regenerationMs': 1800000},
      'thresholds': [1.5, 2, 2.5],
    };
    weeklyStars = {
      'id': '2026-09-13',
      'totalStars': 8,
      'stagesCompleted': 3,
      'stages': {'sliding:japan:japan_01': 3},
    };
    weeklyResetsAt = 604800000;
    resetsAt = 30000000;
  }
  bool unavailable = false, duplicate = false;
  int debugPacksGranted = 0;
  Object? initializationError;
  @override
  Future<void> initialize() async {
    if (initializationError != null) throw initializationError!;
    if (unavailable) {
      throw const OnlineSetupException(
        'Os serviços online ainda não foram configurados nesta versão.',
      );
    }
  }

  @override
  Future<void> sync() async {}
  @override
  Future<void> createProfile(String nickname, String avatar) async {
    if (duplicate) {
      throw FirebaseFunctionsException(
        code: 'already-exists',
        message: 'Este nickname já está em uso.',
      );
    }
    needsProfile = false;
    user['nickname'] = nickname;
    user['avatar'] = avatar;
  }

  @override
  Future<void> debugGrantPack(String packId, {int quantity = 1}) async {
    debugPacksGranted += quantity;
    packs[packId] = PackInventoryEntry(
      packId: packId,
      quantity: (packs[packId]?.quantity ?? 0) + quantity,
    );
  }
}

AppController controller(FakeOnline online) => AppController(
  repository: MemoryProgress(),
  ads: AdsService(),
  audio: AudioService(),
  haptics: HapticsService(),
  wallpaper: WallpaperStub(),
  online: online,
);
Widget host(AppController controller, Widget screen) => AppScope(
  controller: controller,
  child: MaterialApp(
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
    theme: AppTheme.dark,
    home: screen,
  ),
);

void main() {
  for (final code in ['unauthenticated', 'permission-denied', 'unavailable']) {
    testWidgets(
      'startup failure $code shows the appropriate recovery message',
      (tester) async {
        final online = FakeOnline()
          ..initializationError = FirebaseFunctionsException(
            code: code,
            message: code,
          );
        final c = controller(online);
        await tester.pumpWidget(host(c, const SplashScreen()));
        await tester.pumpAndSettle();
        expect(
          find.text(
            code == 'unavailable'
                ? 'Conexão necessária'
                : 'Não foi possível entrar',
          ),
          findsOneWidget,
        );
        if (code != 'unavailable') {
          expect(find.textContaining('validar seu acesso'), findsOneWidget);
          expect(find.text('Conexão necessária'), findsNothing);
        }
        online.initializationError = null;
        online.needsProfile = true;
        await tester.tap(find.text('Tentar novamente'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileOnboarding), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      },
    );
  }
  test('daily score uses only the best difficulty recorded per country', () {
    const countries = {'a': 'hard', 'b': 'medium', 'c': 'easy'};
    expect(dailyScore(countries), 45);
    expect(projectedTier(countries, {}), 1);
    expect(projectedTier(countries, {}, remainingPoints: 15), 2);
    expect(
      projectedTier({'a': 'hard', 'b': 'hard', 'c': 'hard', 'd': 'hard'}, {}),
      4,
    );
  });
  test('online accounts reject all local debug grants', () async {
    final c = controller(FakeOnline());
    await c.initialize();
    expect(c.debugEconomyEnabled, false);
    await expectLater(c.debugGrantPack('world_pack'), throwsStateError);
    await expectLater(c.debugGrantCard('brazil_flag'), throwsStateError);
    c.dispose();
  });
  testWidgets('enabled online account can generate test packs from profile', (
    tester,
  ) async {
    final online = FakeOnline()..user['debugToolsEnabled'] = true;
    final c = controller(online);
    await c.initialize();
    await tester.pumpWidget(host(c, const PlayerProfileScreen()));
    await tester.pumpAndSettle();
    expect(c.debugEconomyEnabled, true);
    await tester.tap(find.byKey(const Key('profile_debug_packs_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '+1').first);
    await tester.pumpAndSettle();
    expect(online.debugPacksGranted, 1);
    expect(c.packInventoryFor('world_pack').quantity, 1);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('missing configuration gates home without a fake login', (
    tester,
  ) async {
    final c = controller(FakeOnline()..unavailable = true);
    await tester.pumpWidget(host(c, const SplashScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Serviços online em preparação'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
    'nickname validation and server uniqueness keep onboarding recoverable',
    (tester) async {
      final s = FakeOnline()..duplicate = true, c = controller(s);
      var completed = false;
      await tester.pumpWidget(
        host(c, ProfileOnboarding(onCompleted: () => completed = true)),
      );
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(find.text('Use de 3 a 18 letras, números ou _.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Explorer');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Este nickname já está em uso.'), findsOneWidget);
      expect(completed, false);
      s.duplicate = false;
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(completed, true);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets('online home, profile, daily and market fit a small phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = controller(FakeOnline());
    await c.initialize();
    await tester.pumpWidget(host(c, const HomeScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(PlayerPanel), findsOneWidget);
    await tester.pumpWidget(host(c, const DailyExplorationScreen()));
    await tester.pumpAndSettle();
    expect(find.text('45 / 80'), findsOneWidget);
    expect(find.byKey(const Key('daily_country_brazil')), findsOneWidget);
    expect(
      find.byKey(const Key('daily_country_united_states')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('daily_parchment_background')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Chances da Recompensa Atual'),
      350,
    );
    expect(find.text('Chances da Recompensa Atual'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(host(c, const StarDustScreen()));
    await tester.pump();
    expect(find.text('0 / 100'), findsOneWidget);
    expect(find.text('8 estrelas'), findsOneWidget);
    expect(find.byKey(const Key('star_dust_space_background')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(host(c, const PlayerProfileScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Puzzles concluídos'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
