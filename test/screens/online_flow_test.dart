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
      'totalPoints': 80,
      'stagesCompleted': 3,
      'stages': {'sliding:japan:japan_01': 3},
    };
    weeklyResetsAt = 604800000;
    resetsAt = 30000000;
  }
  bool unavailable = false, duplicate = false;
  int debugPacksGranted = 0, dailyClaims = 0;
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
  Future<String> claim(String dailyId) async {
    dailyClaims++;
    daily['claimed'] = true;
    return 'world_pack';
  }

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
    expect(
      projectedTier({
        'a': 'veryHard',
        'b': 'veryHard',
        'c': 'veryHard',
        'd': 'veryHard',
      }, {}),
      5,
    );
  });
  testWidgets('daily reward milestones follow the same 0 to 100 scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final online = FakeOnline()..daily['bestScore'] = 50;
    final c = controller(online);
    await tester.pumpWidget(host(c, const DailyExplorationScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('daily_reward_progress_bar')),
      300,
    );

    final progressFinder = find.byKey(const Key('daily_reward_progress_bar'));
    final progress = tester.widget<LinearProgressIndicator>(progressFinder);
    final barRect = tester.getRect(progressFinder);
    final forty = tester.getCenter(
      find.byKey(const Key('daily_progress_milestone_40')),
    );
    final sixty = tester.getCenter(
      find.byKey(const Key('daily_progress_milestone_60')),
    );

    expect(progress.value, closeTo(.5, .001));
    expect((forty.dx - barRect.left) / barRect.width, closeTo(.4, .01));
    expect((sixty.dx - barRect.left) / barRect.width, closeTo(.6, .01));
    expect(forty.dx, lessThan(barRect.left + barRect.width * .5));
    expect(sixty.dx, greaterThan(barRect.left + barRect.width * .5));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('daily exploration uses compact cards and a large gift claim', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final online = FakeOnline();
    online.daily['countries'] = {
      for (final id in const ['brazil', 'japan', 'united_states', 'egypt'])
        id: {'completed': true, 'bestDifficulty': 'veryHard', 'bestPoints': 25},
    };
    online.daily['bestScore'] = 100;
    final c = controller(online);
    await tester.pumpWidget(host(c, const DailyExplorationScreen()));
    await tester.pumpAndSettle();

    final objective = tester.widget<Text>(
      find.text('Complete uma fase em 4 países diferentes.'),
    );
    final countryRect = tester.getRect(
      find.byKey(const Key('daily_country_brazil')),
    );
    expect(objective.maxLines, 1);
    expect(countryRect.width / countryRect.height, closeTo(1, .02));
    expect(find.text('Pontuação da Exploração'), findsNothing);
    expect(find.text('100 / 100'), findsOneWidget);
    expect(find.text('2%'), findsOneWidget);

    expect(find.byKey(const Key('daily_exploration_tab')), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('daily_exploration_tab')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('daily_claim_button')),
      300,
    );
    expect(
      tester.getSize(find.byKey(const Key('daily_claim_button'))).height,
      greaterThanOrEqualTo(74),
    );
    expect(find.byKey(const Key('daily_claim_gift')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Máximo'), 300);
    expect(
      tester.getTopLeft(find.text('Máximo')).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const Key('daily_claim_button'))).dy,
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('daily claim confirms below 100 and skips confirmation at 100', (
    tester,
  ) async {
    final online = FakeOnline();
    online.daily['countries'] = {
      'brazil': 'hard',
      'japan': 'easy',
      'united_states': 'easy',
      'egypt': 'easy',
    };
    online.daily['bestScore'] = 50;
    final c = controller(online);
    await tester.pumpWidget(host(c, const DailyExplorationScreen()));
    await tester.scrollUntilVisible(
      find.byKey(const Key('daily_claim_button')),
      300,
    );
    await tester.tap(find.byKey(const Key('daily_claim_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('daily_claim_confirmation')), findsOneWidget);
    expect(
      find.text(
        'Tem certeza que deseja coletar o seu prêmio agora? Você pode melhorar suas chances acumulando mais pontos.',
      ),
      findsOneWidget,
    );
    expect(online.dailyClaims, 0);
    await tester.tap(find.text('CONTINUAR ACUMULANDO'));
    await tester.pumpAndSettle();

    online.daily['bestScore'] = 100;
    online.daily['claimed'] = false;
    await c.refreshOnline();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('daily_claim_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('daily_claim_confirmation')), findsNothing);
    expect(online.dailyClaims, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('weekly packages unlock only after Sunday at 13h', (
    tester,
  ) async {
    final online = FakeOnline();
    online.weeklyStars['totalPoints'] = 300;
    final c = controller(online);
    await tester.pumpWidget(host(c, const DailyExplorationScreen()));
    await tester.tap(find.byKey(const Key('weekly_exploration_tab')));
    await tester.pumpAndSettle();

    expect(
      find.text('Os pacotes só podem ser resgatados domingo após as 13h.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('weekly_claim_button')), findsNothing);

    online.weeklyActive = false;
    await c.refreshOnline();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weekly_claim_button')), findsOneWidget);
    expect(find.text('RESGATAR PACOTES'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
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
    expect(find.text('Exploração diária'), findsOneWidget);
    expect(find.text('Exploração semanal'), findsOneWidget);
    await tester.tap(find.byKey(const Key('weekly_exploration_tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weekly_score')), findsOneWidget);
    expect(find.text('80 / 700 pontos'), findsOneWidget);
    expect(find.byKey(const Key('weekly_reward_300')), findsOneWidget);
    expect(
      find.byKey(const Key('weekly_claim_schedule_notice')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('daily_exploration_tab')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('daily_score')), 220);
    expect(find.text('45 / 100'), findsOneWidget);
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
    await tester.pumpWidget(host(c, const PlayerLevelBar()));
    await tester.tap(find.byKey(const Key('level_progress_rewards_button')));
    await tester.pumpAndSettle();
    expect(find.text('Marcos de nível'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('level_reward_30')),
      250,
    );
    expect(find.byKey(const Key('level_reward_30')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
