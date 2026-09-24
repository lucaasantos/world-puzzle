import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/cards_data.dart';
import '../data/packs_data.dart';
import '../data/themes_data.dart';
import '../engine/progression_rules.dart';
import '../models/game_theme.dart';
import '../models/economy.dart';
import '../models/card_inventory_entry.dart';
import '../models/card_pack.dart';
import '../models/collectible_card.dart';
import '../models/collection_progress.dart';
import '../models/puzzle_level.dart';
import '../models/puzzle_progress.dart';
import '../models/puzzle_result.dart';
import '../models/saved_game.dart';
import '../repositories/progress_repository.dart';
import '../services/ads_service.dart';
import '../services/audio_service.dart';
import '../services/haptics_service.dart';
import '../services/pack_opening_service.dart';
import '../services/puzzle_reward_service.dart';
import '../services/wallpaper_service.dart';
import '../services/online_game_service.dart';
import '../services/world_coin_service.dart';

class CompletionOutcome {
  const CompletionOutcome({
    this.isNewRecord = false,
    this.wallpaperJustUnlocked = false,
    this.packRewardId,
    this.xpEarned = 0,
    this.dailyPointsEarned = 0,
    this.dailyScore = 0,
    this.starDustEarned = 0,
    this.starDustPotential = 0,
    this.starDustBefore = 0,
    this.starDustBalance = 0,
    this.weeklyBestStars = 0,
    this.newWeeklyRecord = false,
    this.starDustFull = false,
    this.starDustTracked = false,
  });
  final bool isNewRecord;
  final bool wallpaperJustUnlocked;
  final String? packRewardId;
  final int xpEarned;
  final int dailyPointsEarned;
  final int dailyScore;
  final int starDustEarned;
  final int starDustPotential;
  final int starDustBefore;
  final int starDustBalance;
  final int weeklyBestStars;
  final bool newWeeklyRecord;
  final bool starDustFull;
  final bool starDustTracked;
}

class ThemeStats {
  const ThemeStats({
    required this.completed,
    required this.stars,
    required this.total,
  });
  final int completed;
  final int stars;
  final int total;
  double get fraction => total == 0 ? 0 : completed / total;
}

enum PasteCardResult { success, cardNotFound, notOwned, alreadyPasted }

class AppController extends ChangeNotifier {
  AppController({
    required this.repository,
    required this.ads,
    required this.audio,
    required this.haptics,
    required this.wallpaper,
    PackOpeningService? packOpeningService,
    PuzzleRewardService? puzzleRewardService,
    this.online,
  }) : packOpeningService = packOpeningService ?? PackOpeningService(),
       puzzleRewardService = puzzleRewardService ?? PuzzleRewardService();

  final ProgressRepository repository;
  final AdsService ads;
  final AudioService audio;
  final HapticsService haptics;
  final WallpaperService wallpaper;
  final PackOpeningService packOpeningService;
  final PuzzleRewardService puzzleRewardService;
  final OnlineGameService? online;
  late final WorldCoinService? worldCoins = online == null
      ? null
      : WorldCoinService(online: online!, ads: ads);
  bool get isOnline => online != null;
  bool get debugEconomyEnabled => kDebugMode && !isOnline;

  ProgressSnapshot _snapshot = const ProgressSnapshot();
  ProgressSnapshot get snapshot => _snapshot;
  Map<String, PuzzleProgress> get progress => _snapshot.levels;
  bool get soundEnabled => _snapshot.soundEnabled;
  bool get musicEnabled => _snapshot.musicEnabled;
  bool get hapticsEnabled => _snapshot.hapticsEnabled;
  SavedGame? get savedGame => _snapshot.savedGame;
  Map<String, CardInventoryEntry> get cardInventory =>
      Map.unmodifiable(_snapshot.cardInventory);
  Map<String, PackInventoryEntry> get packInventory =>
      Map.unmodifiable(_snapshot.packInventory);

  Future<void> _stateMutation = Future.value();

  Future<void> initialize() async {
    _snapshot = await repository.load();
    if (online != null) {
      // Legacy local grants are never uploaded or trusted as account inventory.
      _snapshot = _snapshot.copyWith(
        levels: {},
        cardInventory: {},
        packInventory: {},
        unlockedWallpapers: {},
        clearSavedGame: true,
      );
      await online!.initialize();
      _applyOnline();
    }
    audio.soundEnabled = soundEnabled;
    audio.musicEnabled = musicEnabled;
    haptics.enabled = hapticsEnabled;
    notifyListeners();
  }

  void _applyOnline() {
    final service = online!;
    _snapshot = _snapshot.copyWith(
      levels: service.progress,
      cardInventory: service.cards,
      packInventory: service.packs,
      unlockedWallpapers: {
        for (final t in gameThemes)
          if (t.levels.every((l) => service.progress.containsKey(l.id))) t.id,
      },
    );
    ads.interstitialEvery =
        (service.config['interstitialEvery'] as num?)?.toInt() ?? 3;
    ads.onEvent = service.event;
    notifyListeners();
  }

  Future<void> refreshOnline() async {
    try {
      await online!.sync();
      _applyOnline();
    } finally {
      notifyListeners();
    }
  }

  Future<void> createOnlineProfile(String nickname, String avatar) async {
    await online!.createProfile(nickname, avatar);
    _applyOnline();
  }

  Future<String> claimDaily(String dailyId) => _runStateMutation(() async {
    final type = await online!.claim(dailyId);
    await refreshOnline();
    return type;
  });

  Future<int> spendStarDust(int amount) => _runStateMutation(() async {
    final balance = await online!.spendStarDust(amount);
    notifyListeners();
    return balance;
  });

  Future<WorldCoinEarnResult> earnWorldCoin() => _runStateMutation(() async {
    final result = await worldCoins!.earnFromRewardedAd();
    _applyOnline();
    return result;
  });

  Future<CompletionOutcome> finishOnline({
    int? moveCount,
    List<int>? placements,
    int? blocksLines,
    int? blocksScore,
  }) => _runStateMutation(() async {
    final country = online!.attempt?['countryId'] as String?;
    final levelId = online!.attempt?['levelId'] as String?;
    final wasUnlocked = country != null && isWallpaperUnlocked(country);
    GameTheme? theme;
    if (country != null) {
      for (final candidate in gameThemes) {
        if (candidate.id == country) {
          theme = candidate;
          break;
        }
      }
    }
    final unlocksWallpaper =
        theme != null &&
        theme.levels.every(
          (level) => level.id == levelId || progress.containsKey(level.id),
        );
    final result = await online!.finish(
      moveCount: moveCount,
      placements: placements,
      blocksLines: blocksLines,
      blocksScore: blocksScore,
    );
    unawaited(refreshOnline().catchError((Object _) {}));
    unawaited(ads.onLevelCompleted().catchError((Object _) {}));
    return CompletionOutcome(
      isNewRecord: result['isNewRecord'] == true,
      wallpaperJustUnlocked:
          country != null && !wasUnlocked && unlocksWallpaper,
      xpEarned: (result['xp'] as num).toInt(),
      dailyPointsEarned: (result['dailyPointsEarned'] as num?)?.toInt() ?? 0,
      dailyScore: (result['dailyScore'] as num?)?.toInt() ?? 0,
      starDustEarned: (result['starDustEarned'] as num?)?.toInt() ?? 0,
      starDustPotential: (result['starDustPotential'] as num?)?.toInt() ?? 0,
      starDustBefore: (result['starDustBefore'] as num?)?.toInt() ?? 0,
      starDustBalance: (result['starDustBalance'] as num?)?.toInt() ?? 0,
      weeklyBestStars: (result['weeklyBestStars'] as num?)?.toInt() ?? 0,
      newWeeklyRecord: result['newWeeklyRecord'] == true,
      starDustFull: result['starDustFull'] == true,
      starDustTracked: true,
    );
  });

  Future<bool> recoverLives() => _runStateMutation(() async {
    final s = online!;
    final ticket = await s.call('prepareLifeAd');
    s.event('rewarded_ad_started');
    final earned = await ads.showRewardedVerified(
      userId: s.uid,
      customData: ticket['ticket'] as String,
    );
    if (!earned) return false;
    s.event('rewarded_ad_completed');
    // SSV is asynchronous. A local SDK reward callback never grants lives.
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      await refreshOnline();
      if (s.lives > 0) return true;
    }
    return false;
  });

  ThemeStats statsFor(GameTheme theme) {
    final completed = theme.levels
        .where((level) => progress.containsKey(level.id))
        .length;
    final stars = theme.levels.fold<int>(
      0,
      (sum, level) => sum + (progress[level.id]?.stars ?? 0),
    );
    return ThemeStats(
      completed: completed,
      stars: stars,
      total: theme.levels.length,
    );
  }

  int get totalStars =>
      gameThemes.fold(0, (sum, theme) => sum + statsFor(theme).stars);
  int get totalAvailableStars =>
      gameThemes.fold(0, (sum, theme) => sum + theme.levels.length * 3);
  int get totalCompleted => progress.length;
  int get totalLevels =>
      gameThemes.fold(0, (sum, theme) => sum + theme.levels.length);

  bool isLevelUnlocked(GameTheme theme, int index) {
    return ProgressionRules.isLevelUnlocked(theme, index, progress);
  }

  bool isWallpaperUnlocked(String themeId) =>
      _snapshot.unlockedWallpapers.contains(themeId);

  Future<CompletionOutcome> recordResult(
    GameTheme theme,
    PuzzleResult result,
  ) => _runStateMutation(() async {
    if (isOnline) throw StateError('Use a tentativa validada pelo servidor.');
    if (_snapshot.processedCompletionIds.contains(result.completionId)) {
      return const CompletionOutcome(
        isNewRecord: false,
        wallpaperJustUnlocked: false,
      );
    }

    final isFirstCompletion = progress[result.levelId] == null;
    final update = ProgressRepository.mergeResult(
      progress[result.levelId],
      result,
    );
    final newLevels = Map<String, PuzzleProgress>.of(progress)
      ..[result.levelId] = update.progress;
    final completedCollection = ProgressionRules.isCollectionComplete(
      theme,
      newLevels,
    );
    final wasUnlocked = isWallpaperUnlocked(theme.id);
    final wallpaperRewards = Set<String>.of(_snapshot.unlockedWallpapers);
    if (completedCollection) wallpaperRewards.add(theme.id);

    final packDecision = puzzleRewardService.evaluate(
      isFirstCompletion: isFirstCompletion,
    );
    final packs = Map<String, PackInventoryEntry>.of(_snapshot.packInventory);
    String? rewardedPackId;
    if (packDecision != null &&
        (PackCatalog.byId(packDecision.packId)?.isActive ?? false)) {
      final current =
          packs[packDecision.packId] ??
          PackInventoryEntry(packId: packDecision.packId);
      packs[packDecision.packId] = current.copyWith(
        quantity: current.quantity + 1,
      );
      rewardedPackId = packDecision.packId;
    }

    final processed = Set<String>.of(_snapshot.processedCompletionIds)
      ..add(result.completionId);
    final boundedProcessed = processed.length <= 100
        ? processed
        : processed.skip(processed.length - 100).toSet();
    _snapshot = _snapshot.copyWith(
      levels: newLevels,
      unlockedWallpapers: wallpaperRewards,
      packInventory: packs,
      processedCompletionIds: boundedProcessed,
      clearSavedGame: true,
    );
    await repository.save(_snapshot);
    notifyListeners();
    unawaited(ads.onLevelCompleted().catchError((Object _) {}));
    return CompletionOutcome(
      isNewRecord: update.isNewRecord,
      wallpaperJustUnlocked: completedCollection && !wasUnlocked,
      packRewardId: rewardedPackId,
    );
  });

  Future<void> saveGame(SavedGame game) async {
    _snapshot = _snapshot.copyWith(savedGame: game);
    await repository.save(_snapshot);
  }

  Future<void> clearSavedGame() async {
    _snapshot = _snapshot.copyWith(clearSavedGame: true);
    await repository.save(_snapshot);
  }

  Future<void> markOnboardingSeen() async {
    if (_snapshot.onboardingSeen) return;
    _snapshot = _snapshot.copyWith(onboardingSeen: true);
    await repository.save(_snapshot);
  }

  Future<void> setSound(bool value) => _setSettings(sound: value);
  Future<void> setMusic(bool value) => _setSettings(music: value);
  Future<void> setHaptics(bool value) => _setSettings(hapticsValue: value);

  Future<void> _setSettings({
    bool? sound,
    bool? music,
    bool? hapticsValue,
  }) async {
    _snapshot = _snapshot.copyWith(
      soundEnabled: sound,
      musicEnabled: music,
      hapticsEnabled: hapticsValue,
    );
    audio.soundEnabled = soundEnabled;
    audio.musicEnabled = musicEnabled;
    haptics.enabled = hapticsEnabled;
    await repository.save(_snapshot);
    notifyListeners();
  }

  PuzzleLevel? levelById(String id) {
    for (final theme in gameThemes) {
      for (final level in theme.levels) {
        if (level.id == id) return level;
      }
    }
    return null;
  }

  GameTheme? themeById(String id) {
    for (final theme in gameThemes) {
      if (theme.id == id) return theme;
    }
    return null;
  }

  CardInventoryEntry inventoryFor(String cardId) =>
      _snapshot.cardInventory[cardId] ?? CardInventoryEntry(cardId: cardId);

  CollectionProgress globalAlbumProgress() => CollectionProgress(
    pasted: collectibleCards
        .where((card) => card.isActive && inventoryFor(card.id).pastedInAlbum)
        .length,
    total: collectibleCards.where((card) => card.isActive).length,
  );

  CollectionProgress continentAlbumProgress(String continent) {
    final countryIds = CardCatalog.countriesForContinent(
      continent,
    ).map((country) => country.id).toSet();
    final cards = collectibleCards.where(
      (card) => card.isActive && countryIds.contains(card.countryId),
    );
    return CollectionProgress(
      pasted: cards.where((card) => inventoryFor(card.id).pastedInAlbum).length,
      total: cards.length,
    );
  }

  CollectionProgress countryAlbumProgress(String countryId) {
    final cards = CardCatalog.cardsForCountry(countryId);
    return CollectionProgress(
      pasted: cards.where((card) => inventoryFor(card.id).pastedInAlbum).length,
      total: cards.length,
    );
  }

  List<CollectibleCard> get availableCollectionCards => collectibleCards
      .where((card) => card.isActive && inventoryFor(card.id).quantity > 0)
      .toList(growable: false);

  PackInventoryEntry packInventoryFor(String packId) =>
      _snapshot.packInventory[packId] ?? PackInventoryEntry(packId: packId);

  int get totalUnopenedPacks => _snapshot.packInventory.values.fold<int>(
    0,
    (sum, entry) => sum + entry.quantity,
  );

  Future<PasteCardResult> pasteCardInAlbum(String cardId) =>
      _runStateMutation(() async {
        if (online != null) {
          await online!.call('pasteCard', {'cardId': cardId});
          await refreshOnline();
          online!.event('card_placed_in_album');
          return PasteCardResult.success;
        }
        final card = CardCatalog.cardById(cardId);
        if (card == null || !card.isActive) {
          return PasteCardResult.cardNotFound;
        }
        final current = inventoryFor(cardId);
        if (current.pastedInAlbum) return PasteCardResult.alreadyPasted;
        if (current.quantity < 1) return PasteCardResult.notOwned;

        final inventory =
            Map<String, CardInventoryEntry>.of(_snapshot.cardInventory)
              ..[cardId] = current.copyWith(
                quantity: current.quantity - 1,
                pastedInAlbum: true,
              );
        _snapshot = _snapshot.copyWith(cardInventory: inventory);
        await repository.save(_snapshot);
        notifyListeners();
        await haptics.reward();
        return PasteCardResult.success;
      });

  Future<PackOpenOutcome> openPack(String packId) =>
      _runStateMutation(() => _openPack(packId));

  Future<PackOpenOutcome> _openPack(String packId) async {
    if (online != null) {
      final result = await online!.open(packId);
      _applyOnline();
      return result;
    }
    final definition = PackCatalog.byId(packId);
    if (definition == null || !definition.isActive) {
      return const PackOpenOutcome(status: PackOpenStatus.packNotFound);
    }
    final ownedPack = packInventoryFor(packId);
    if (ownedPack.quantity < 1) {
      return const PackOpenOutcome(status: PackOpenStatus.notOwned);
    }
    final result = packOpeningService.generate(
      pack: definition,
      catalog: collectibleCards,
      inventory: _snapshot.cardInventory,
    );
    if (result == null) {
      return const PackOpenOutcome(status: PackOpenStatus.noCardsAvailable);
    }

    final packs = Map<String, PackInventoryEntry>.of(_snapshot.packInventory)
      ..[packId] = ownedPack.copyWith(quantity: ownedPack.quantity - 1);
    final cards = Map<String, CardInventoryEntry>.of(_snapshot.cardInventory);
    for (final reward in result.cards) {
      final current =
          cards[reward.card.id] ?? CardInventoryEntry(cardId: reward.card.id);
      cards[reward.card.id] = current.copyWith(quantity: current.quantity + 1);
    }
    _snapshot = _snapshot.copyWith(packInventory: packs, cardInventory: cards);
    await repository.save(_snapshot);
    notifyListeners();
    await haptics.reward();
    return PackOpenOutcome(status: PackOpenStatus.success, result: result);
  }

  Future<void> debugGrantPack(String packId, {int quantity = 1}) async {
    if (!debugEconomyEnabled) {
      throw StateError('Debug pack grants are disabled in production.');
    }
    if (quantity < 1 || PackCatalog.byId(packId) == null) return;
    await _runStateMutation(() async {
      final current = packInventoryFor(packId);
      final packs = Map<String, PackInventoryEntry>.of(_snapshot.packInventory)
        ..[packId] = current.copyWith(quantity: current.quantity + quantity);
      _snapshot = _snapshot.copyWith(packInventory: packs);
      await repository.save(_snapshot);
      notifyListeners();
    });
  }

  Future<List<PackOpenOutcome>> debugOpenPacks(
    String packId, {
    int quantity = 20,
  }) async {
    if (!debugEconomyEnabled) {
      throw StateError('Debug pack opening is disabled in production.');
    }
    await debugGrantPack(packId, quantity: quantity);
    final results = <PackOpenOutcome>[];
    for (var index = 0; index < quantity; index++) {
      results.add(await openPack(packId));
    }
    return List.unmodifiable(results);
  }

  Future<void> debugResetPackInventory() async {
    if (!debugEconomyEnabled) {
      throw StateError('Debug pack reset is disabled in production.');
    }
    await _runStateMutation(() async {
      _snapshot = _snapshot.copyWith(packInventory: const {});
      await repository.save(_snapshot);
      notifyListeners();
    });
  }

  /// Development-only bridge for direct collection testing.
  Future<void> debugGrantCard(String cardId, {int quantity = 1}) async {
    if (!debugEconomyEnabled) {
      throw StateError('Debug card grants are disabled in production.');
    }
    if (quantity < 1 || CardCatalog.cardById(cardId) == null) return;
    await _runStateMutation(() async {
      final current = inventoryFor(cardId);
      final inventory = Map<String, CardInventoryEntry>.of(
        _snapshot.cardInventory,
      )..[cardId] = current.copyWith(quantity: current.quantity + quantity);
      _snapshot = _snapshot.copyWith(cardInventory: inventory);
      await repository.save(_snapshot);
      notifyListeners();
    });
  }

  Future<void> debugGrantAllCards({int quantity = 1}) async {
    if (!debugEconomyEnabled) {
      throw StateError('Debug card grants are disabled in production.');
    }
    if (quantity < 1) return;
    await _runStateMutation(() async {
      final inventory = Map<String, CardInventoryEntry>.of(
        _snapshot.cardInventory,
      );
      for (final card in collectibleCards.where((card) => card.isActive)) {
        final current =
            inventory[card.id] ?? CardInventoryEntry(cardId: card.id);
        inventory[card.id] = current.copyWith(
          quantity: current.quantity + quantity,
        );
      }
      _snapshot = _snapshot.copyWith(cardInventory: inventory);
      await repository.save(_snapshot);
      notifyListeners();
    });
  }

  Future<T> _runStateMutation<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _stateMutation = _stateMutation.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  @override
  void dispose() {
    ads.dispose();
    audio.dispose();
    super.dispose();
  }
}
