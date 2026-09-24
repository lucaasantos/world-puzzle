import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/cards_data.dart';
import '../models/card_inventory_entry.dart';
import '../models/card_pack.dart';
import '../models/puzzle_progress.dart';
import '../core/config/world_coin_config.dart';

class OnlineSetupException implements Exception {
  const OnlineSetupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Firebase UID is the only account key. Native providers can be replaced on iOS.
abstract interface class PlayerIdentityProvider {
  Future<void> signIn();
}

class PlayGamesIdentityProvider implements PlayerIdentityProvider {
  @override
  Future<void> signIn() async {
    if (!Platform.isAndroid) {
      throw const OnlineSetupException(
        'O login desta plataforma ainda precisa ser configurado.',
      );
    }
    const clientId = String.fromEnvironment('PLAY_GAMES_WEB_CLIENT_ID');
    if (clientId.isEmpty) {
      throw const OnlineSetupException(
        'O acesso ao Play Games ainda não foi configurado nesta versão.',
      );
    }
    final code = await const MethodChannel(
      'puzzle_world/play_games',
    ).invokeMethod<String>('serverAuthCode', {'clientId': clientId});
    if (code == null || code.isEmpty) throw StateError('Login cancelado.');
    await FirebaseAuth.instance.signInWithCredential(
      PlayGamesAuthProvider.credential(serverAuthCode: code),
    );
  }
}

class OnlineGameService {
  OnlineGameService({PlayerIdentityProvider? identity})
    : identity = identity ?? PlayGamesIdentityProvider();
  final PlayerIdentityProvider identity;
  static const emulator = bool.fromEnvironment('FIREBASE_EMULATOR');
  static const emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '10.0.2.2',
  );
  bool _ready = false;
  bool connected = false;
  bool needsProfile = false;
  Map<String, dynamic> user = {}, daily = {}, weeklyStars = {}, config = {};
  Map<String, dynamic>? attempt;
  List<int> attemptMoves = [];
  Map<String, dynamic>? pendingStart;
  String? pendingPack;
  final Stopwatch _serverClock = Stopwatch();
  int _serverEpoch = 0, resetsAt = 0, weeklyResetsAt = 0;
  Map<String, CardInventoryEntry> cards = {};
  Map<String, PackInventoryEntry> packs = {};
  Map<String, PuzzleProgress> progress = {};
  Map<String, Map<String, dynamic>> packInstances = {};
  List<Map<String, dynamic>> unclaimedExplorations = [];
  Future<void> _journalWrite = Future.value();
  Future<void> _syncQueue = Future.value();
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'southamerica-east1');
  int get serverNow => _serverEpoch + _serverClock.elapsedMilliseconds;
  int get lives => (user['lives'] as num?)?.toInt() ?? 0;
  int get starDustBalance =>
      (user['starDustBalance'] as num?)?.toInt().clamp(0, 100) ?? 0;
  int get worldCoinBalance {
    final value = (user['worldCoins'] as num?)?.toInt() ?? 0;
    return value < 0 ? 0 : value;
  }

  int get worldCoinsEarnedToday {
    final rewards = user['worldCoinRewardAds'] as Map?;
    final value = (rewards?['earnedToday'] as num?)?.toInt() ?? 0;
    return value.clamp(0, worldCoinDailyLimit);
  }

  int get worldCoinDailyLimit =>
      (config['worldCoin']?['dailyAdLimit'] as num?)?.toInt() ??
      WorldCoinConfig.dailyRewardedAdLimit;
  int get worldCoinRewardAmount =>
      (config['worldCoin']?['rewardedAdAmount'] as num?)?.toInt() ??
      WorldCoinConfig.rewardedAdAmount;
  int get weeklyStarsCollected =>
      (weeklyStars['totalStars'] as num?)?.toInt() ?? 0;
  int get weeklyStagesCompleted =>
      (weeklyStars['stagesCompleted'] as num?)?.toInt() ??
      (weeklyStars['stages'] as Map? ?? {}).length;
  int get maxLives => (config['lives']?['maximum'] as num?)?.toInt() ?? 4;
  int get nextLifeAt => lives >= maxLives
      ? 0
      : ((user['lifeAnchor'] as num?)?.toInt() ?? serverNow) +
            ((config['lives']?['regenerationMs'] as num?)?.toInt() ?? 1800000);

  Future<void> initialize() async {
    if (!_ready) {
      if (emulator && !kDebugMode) {
        throw const OnlineSetupException(
          'Emuladores permitidos somente em desenvolvimento.',
        );
      }
      const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
      const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
      const appId = String.fromEnvironment('FIREBASE_APP_ID');
      if (!emulator && (project.isEmpty || apiKey.isEmpty || appId.isEmpty)) {
        throw const OnlineSetupException(
          'Os serviços online ainda não foram configurados nesta versão.',
        );
      }
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: emulator ? 'demo-api-key' : apiKey,
            appId: emulator ? '1:123456789:android:demo' : appId,
            messagingSenderId: const String.fromEnvironment(
              'FIREBASE_SENDER_ID',
              defaultValue: '123456789',
            ),
            projectId: emulator ? 'demo-puzzle-world' : project,
            iosBundleId: const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
          ),
        );
      }
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      if (emulator) {
        await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
        _functions.useFunctionsEmulator(emulatorHost, 5001);
      } else {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestProvider(),
        );
      }
      _ready = true;
    }
    if (!emulator) {
      await InternetAddress.lookup(
        'firebase.google.com',
      ).timeout(const Duration(seconds: 8));
    }
    if (FirebaseAuth.instance.currentUser == null) {
      if (emulator) {
        await FirebaseAuth.instance.signInAnonymously();
      } else {
        await identity.signIn();
      }
      event('login_completed');
    }
    await _loadJournal();
    await sync();
    if (!emulator) {
      try {
        final remote = FirebaseRemoteConfig.instance;
        await remote.setDefaults({'interstitial_every': 3});
        await remote.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(seconds: 5),
            minimumFetchInterval: const Duration(hours: 1),
          ),
        );
        await remote.fetchAndActivate();
        // Economic values always come from the validated server config in sync().
      } catch (_) {
        /* Safe defaults and server configuration remain available. */
      }
    }
  }

  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    try {
      final result = await _functions
          .httpsCallable(
            name,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
          )
          .call(data);
      connected = true;
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      if (['unavailable', 'deadline-exceeded', 'internal'].contains(e.code)) {
        connected = false;
      }
      rethrow;
    } catch (_) {
      connected = false;
      rethrow;
    }
  }

  Future<void> createProfile(String nickname, String avatar) async {
    await call('createProfile', {'nickname': nickname, 'avatar': avatar});
    event('profile_created');
    await sync();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _readAll(
    String collection,
  ) async {
    final result = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    Query<Map<String, dynamic>> base = FirebaseFirestore.instance
        .collection('users/$uid/$collection')
        .orderBy(FieldPath.documentId)
        .limit(250);
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      final page =
          await (cursor == null ? base : base.startAfterDocument(cursor)).get(
            const GetOptions(source: Source.server),
          );
      result.addAll(page.docs);
      if (page.docs.length < 250) return result;
      cursor = page.docs.last;
    }
  }

  Future<void> sync() {
    _syncQueue = _syncQueue.catchError((Object _) {}).then((_) => _sync());
    return _syncQueue;
  }

  Future<void> _sync() async {
    final state = await call('syncPlayer');
    _serverEpoch = (state['serverNow'] as num).toInt();
    _serverClock
      ..reset()
      ..start();
    needsProfile = state['needsProfile'] == true;
    config = Map<String, dynamic>.from(state['config'] as Map);
    if (needsProfile) return;
    try {
      final results = await Future.wait([
        _readAll('collection'),
        _readAll('packs'),
        _readAll('progress'),
        _readAll('dailyExploration'),
      ]);
      final newCards = {
        for (final d in results[0]) d.id: CardInventoryEntry.fromJson(d.data()),
      };
      final instances = {for (final d in results[1]) d.id: d.data()};
      final newPacks = <String, PackInventoryEntry>{};
      for (final p in instances.values.where((p) => p['opened'] != true)) {
        final type = p['packType'] as String;
        newPacks[type] = PackInventoryEntry(
          packId: type,
          quantity: (newPacks[type]?.quantity ?? 0) + 1,
        );
      }
      // A response lost after committing an opening must still be reachable in UI.
      if (pendingPack != null && instances[pendingPack]?['opened'] == true) {
        final type = instances[pendingPack]!['packType'] as String;
        newPacks[type] = PackInventoryEntry(
          packId: type,
          quantity: (newPacks[type]?.quantity ?? 0) + 1,
        );
      }
      user = Map<String, dynamic>.from(state['user'] as Map);
      daily = Map<String, dynamic>.from(state['daily'] as Map);
      weeklyStars = Map<String, dynamic>.from(state['weeklyStars'] as Map);
      resetsAt = (state['resetsAt'] as num).toInt();
      weeklyResetsAt = (state['weeklyResetsAt'] as num).toInt();
      cards = newCards;
      packs = newPacks;
      packInstances = instances;
      progress = {
        for (final d in results[2]) d.id: PuzzleProgress.fromJson(d.data()),
      };
      unclaimedExplorations = [
        for (final d in results[3])
          if (d.data()['claimed'] != true &&
              (d.data()['countries'] as Map).length == 4 &&
              ((d.data()['bestScore'] as num?)?.toInt() ?? 40) >= 40)
            d.data(),
      ];
      if ((state['regenerated'] as num? ?? 0) > 0) event('life_regenerated');
      connected = true;
    } catch (_) {
      connected = false;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> start(
    String country,
    String level,
    String difficulty, {
    String gameMode = 'sliding',
  }) async {
    if (attempt != null &&
        attempt!['state'] == 'active' &&
        attempt!['countryId'] == country &&
        attempt!['levelId'] == level &&
        attempt!['difficulty'] == difficulty &&
        attempt!['gameMode'] == gameMode) {
      return attempt!;
    }
    final previous = pendingStart;
    if (previous == null ||
        previous['countryId'] != country ||
        previous['levelId'] != level ||
        previous['difficulty'] != difficulty ||
        previous['gameMode'] != gameMode) {
      pendingStart = {
        'requestId': _requestId(),
        'countryId': country,
        'levelId': level,
        'difficulty': difficulty,
        'gameMode': gameMode,
      };
      await saveJournal();
    }
    attempt = await call('startAttempt', pendingStart!);
    attemptMoves = [];
    pendingStart = null;
    await saveJournal();
    event('game_started', {
      'country_id': country,
      'difficulty': difficulty,
      'game_mode': gameMode,
    });
    event('life_lost');
    return attempt!;
  }

  Future<Map<String, dynamic>> finish({
    int? moveCount,
    List<int>? placements,
    int? blocksLines,
    int? blocksScore,
  }) async {
    if (attempt == null) throw StateError('Nenhuma partida ativa.');
    await saveJournal();
    final result = await call('finishAttempt', {
      'attemptId': attempt!['id'],
      'moves': attemptMoves,
      if (moveCount != null) 'moveCount': moveCount,
      if (placements != null) 'placements': placements,
      if (blocksLines != null) 'blocksLines': blocksLines,
      if (blocksScore != null) 'blocksScore': blocksScore,
    });
    attempt!['state'] = 'completed';
    attempt!['result'] = result;
    await saveJournal();
    event('game_completed', {
      'country_id': attempt!['countryId'],
      'difficulty': attempt!['difficulty'],
      'game_mode': attempt!['gameMode'] as String? ?? 'sliding',
      'player_level': result['level'],
    });
    event('daily_exploration_progress');
    if (result['levelUp'] == true) {
      event('level_up', {'player_level': result['level']});
    }
    return result;
  }

  Future<void> end(String reason) async {
    if (attempt == null) return;
    await call('endAttempt', {'attemptId': attempt!['id'], 'reason': reason});
    event(reason == 'failed' ? 'game_failed' : 'game_abandoned');
    attempt = null;
    attemptMoves = [];
    await saveJournal();
  }

  Future<String> claim(String dailyId) async {
    final reward = await call('claimExploration', {'dailyId': dailyId});
    event('daily_exploration_completed', {'exploration_tier': reward['tier']});
    event('pack_earned', {'pack_type': reward['packType']});
    return reward['packType'] as String;
  }

  Future<int> spendStarDust(int amount, {String? requestId}) async {
    final result = await call('spendStarDust', {
      'amount': amount,
      'requestId': requestId ?? _requestId(),
    });
    final balance = (result['balance'] as num).toInt();
    user['starDustBalance'] = balance;
    return balance;
  }

  Future<void> debugGrantPack(String packId, {int quantity = 1}) async {
    await call('debugGrantPack', {'packType': packId, 'quantity': quantity});
    await sync();
  }

  Future<PackOpenOutcome> open(String type) async {
    String? instance = pendingPack;
    if (instance != null && packInstances[instance]?['packType'] != type) {
      instance = null;
    }
    instance ??= packInstances.entries
        .where((e) => e.value['packType'] == type && e.value['opened'] != true)
        .firstOrNull
        ?.key;
    if (instance == null) {
      return const PackOpenOutcome(status: PackOpenStatus.notOwned);
    }
    pendingPack = instance;
    await saveJournal();
    final result = await call('openPack', {'packInstanceId': instance});
    final rewards = (result['cards'] as List).map((raw) {
      final r = Map<String, dynamic>.from(raw as Map);
      final card = CardCatalog.cardById(r['cardId'] as String);
      if (card == null) {
        throw StateError('Atualize o jogo para visualizar esta carta.');
      }
      return PackCardReward(
        card: card,
        isNew: r['isNew'] == true,
        resultingQuantity: (r['resultingQuantity'] as num).toInt(),
        wasAlreadyPasted: r['wasAlreadyPasted'] == true,
      );
    }).toList();
    // Keep the pending instance until the result can be presented, including after restart.
    await sync();
    pendingPack = null;
    await saveJournal();
    final count = packs[type]?.quantity ?? 0;
    if (count > 0) {
      packs[type] = PackInventoryEntry(packId: type, quantity: count - 1);
    }
    event('pack_opened', {'pack_type': type});
    for (final r in rewards) {
      event('card_received', {'card_rarity': r.card.rarity, 'pack_type': type});
    }
    return PackOpenOutcome(
      status: PackOpenStatus.success,
      result: PackOpeningResult(packId: type, cards: rewards),
    );
  }

  void event(String name, [Map<String, Object>? parameters]) {
    if (!_ready || emulator) return;
    unawaited(
      FirebaseAnalytics.instance
          .logEvent(name: name, parameters: parameters)
          .catchError((Object _) {}),
    );
  }

  String _requestId() => List.generate(
    24,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  Future<void> _loadJournal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('online_attempt_$uid');
    if (raw == null) return;
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      attempt = value['attempt'] as Map<String, dynamic>?;
      attemptMoves = (value['moves'] as List? ?? []).cast<int>();
      pendingStart = value['pendingStart'] as Map<String, dynamic>?;
      pendingPack = value['pendingPack'] as String?;
    } catch (_) {
      /* Invalid local journals cannot grant any economic value. */
    }
  }

  Future<void> saveJournal() {
    final account = uid;
    final value = jsonEncode({
      'attempt': attempt,
      'moves': attemptMoves,
      'pendingStart': pendingStart,
      'pendingPack': pendingPack,
    });
    _journalWrite = _journalWrite.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('online_attempt_$account', value);
    });
    return _journalWrite;
  }
}
