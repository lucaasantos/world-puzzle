import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../app/app_scope.dart';
import '../world_coin/world_coin_dialog.dart';
import '../../core/localization/daily_exploration_strings.dart';
import '../../data/cards_data.dart';
import '../../data/game_modes_data.dart';
import '../../data/packs_data.dart';
import '../../services/online_game_service.dart';
import '../../widgets/card_pack/pack_artwork.dart';
import '../packs/packs_screen.dart';

bool isOnlineConnectionError(Object error) =>
    error is SocketException ||
    error is TimeoutException ||
    (error is FirebaseException &&
        [
          'network-request-failed',
          'unavailable',
          'deadline-exceeded',
        ].contains(error.code));

String onlineError(Object error) {
  if (error is OnlineSetupException) return error.message;
  if (error is FirebaseException &&
      ['unauthenticated', 'permission-denied'].contains(error.code)) {
    return 'Não foi possível validar seu acesso ao jogo. Tente novamente. '
        'Se persistir, entre em contato com o suporte.';
  }
  if (isOnlineConnectionError(error)) {
    return 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente. Seu progresso foi preservado.';
  }
  if (error is FirebaseFunctionsException &&
      !['internal', 'unavailable', 'deadline-exceeded'].contains(error.code)) {
    return error.message ?? 'Não foi possível concluir. Tente novamente.';
  }
  return 'Não foi possível concluir o acesso ao serviço. Seu progresso foi preservado. Tente novamente.';
}

String countdown(int milliseconds) {
  final seconds = (milliseconds / 1000).ceil().clamp(0, 172800);
  if (seconds >= 3600) {
    return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}min';
  }
  return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}

const avatarIcons = {
  'globe': Icons.public,
  'compass': Icons.explore,
  'mountain': Icons.landscape,
  'plane': Icons.flight,
};
// Very Hard is isolated here (and in the server economy config) for balancing.
const dailyDifficultyPoints = {
  'easy': 10,
  'medium': 15,
  'hard': 20,
  'veryHard': 25,
};
const dailyRewardOdds = <int, List<int>>{
  40: [100, 0, 0, 0],
  60: [95, 5, 0, 0],
  70: [88, 8, 4, 0],
  80: [85, 9, 5, 1],
};

String? dailyDifficulty(dynamic value) => value is String
    ? value
    : value is Map
    ? value['bestDifficulty'] as String?
    : null;

int dailyScore(Map countries) => countries.values.fold(
  0,
  (score, value) =>
      score + (dailyDifficultyPoints[dailyDifficulty(value)] ?? 0),
);

int dailyRewardMilestone(int score) => score >= 80
    ? 80
    : score >= 70
    ? 70
    : score >= 60
    ? 60
    : 40;

int projectedTier(Map countries, Map config, {int remainingPoints = 10}) {
  final score =
      dailyScore(countries) + (4 - countries.length) * remainingPoints;
  return dailyRewardMilestone(score) == 80
      ? 4
      : dailyRewardMilestone(score) == 70
      ? 3
      : dailyRewardMilestone(score) == 60
      ? 2
      : 1;
}

class ProfileOnboarding extends StatefulWidget {
  const ProfileOnboarding({required this.onCompleted, super.key});
  final VoidCallback onCompleted;
  @override
  State<ProfileOnboarding> createState() => _ProfileOnboardingState();
}

class _ProfileOnboardingState extends State<ProfileOnboarding> {
  final _nickname = TextEditingController();
  String _avatar = 'globe';
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!RegExp(r'^[a-zA-Z0-9_]{3,18}$').hasMatch(_nickname.text.trim())) {
      setState(() => _error = 'Use de 3 a 18 letras, números ou _.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.of(
        context,
        listen: false,
      ).createOnlineProfile(_nickname.text.trim(), _avatar);
      if (mounted) widget.onCompleted();
    } catch (e) {
      if (mounted) setState(() => _error = onlineError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public, size: 56),
                const SizedBox(height: 24),
                const Text(
                  'Como devemos chamar você?',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nickname,
                  maxLength: 18,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Nickname',
                    helperText: 'Letras, números e _ • único no Puzzle World',
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [
                    for (final a in avatarIcons.entries)
                      ChoiceChip(
                        selected: _avatar == a.key,
                        label: Icon(a.value),
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _avatar = a.key),
                      ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? 'Criando perfil…' : 'Continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

const _explorerInk = Color(0xFF07394B);
const _explorerPaper = Color(0xFFFFE8A6);
const _explorerOrange = Color(0xFFF0A52E);

class _WoodenNicknamePlaque extends StatelessWidget {
  const _WoodenNicknamePlaque({required this.nickname});
  final String nickname;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _AviatorTagPainter(),
    child: SizedBox(
      height: 27,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 4),
        child: Center(
          child: Text(
            nickname.isEmpty ? 'Explorador' : nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _explorerInk,
              fontSize: 14,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ),
      ),
    ),
  );
}

class _AviatorTagPainter extends CustomPainter {
  const _AviatorTagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final tag = Path()
      ..moveTo(8, 1.5)
      ..lineTo(size.width - 8, 1.5)
      ..lineTo(size.width - 1.5, size.height / 2)
      ..lineTo(size.width - 8, size.height - 1.5)
      ..lineTo(8, size.height - 1.5)
      ..lineTo(1.5, size.height / 2)
      ..close();
    canvas.drawPath(
      tag.shift(const Offset(0, 2.5)),
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawPath(tag, Paint()..color = _explorerPaper);
    canvas.drawPath(
      tag,
      Paint()
        ..color = _explorerInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    final rivet = Paint()..color = _explorerOrange;
    canvas.drawCircle(Offset(8, size.height / 2), 2, rivet);
    canvas.drawCircle(Offset(size.width - 8, size.height / 2), 2, rivet);
  }

  @override
  bool shouldRepaint(covariant _AviatorTagPainter oldDelegate) => false;
}

class _HudLevelProgressBar extends StatelessWidget {
  const _HudLevelProgressBar({
    required this.level,
    required this.currentXp,
    required this.nextXp,
  });

  final int level;
  final num currentXp;
  final num? nextXp;

  @override
  Widget build(BuildContext context) {
    final fraction = nextXp == null || nextXp! <= 0
        ? 1.0
        : (currentXp / nextXp!).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Nível $level',
              style: const TextStyle(
                color: _explorerPaper,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
                shadows: [Shadow(color: _explorerInk, blurRadius: 3)],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  nextXp == null
                      ? 'MÁX.'
                      : '${currentXp.toInt()} / ${nextXp!.toInt()} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: _explorerInk, blurRadius: 3)],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xB3072E3C),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _explorerInk, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x77000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF08E28), Color(0xFFFFD65A)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PlayerLevelBar extends StatelessWidget {
  const PlayerLevelBar({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).online;
    if (s == null) return const SizedBox.shrink();
    final progression = s.user['progression'] as Map? ?? {};
    return _HudLevelProgressBar(
      level: (progression['level'] as num?)?.toInt() ?? 1,
      currentXp: progression['currentXp'] as num? ?? 0,
      nextXp: progression['nextXp'] as num?,
    );
  }
}

class EnergyIndicator extends StatelessWidget {
  const EnergyIndicator({
    required this.lives,
    required this.maxLives,
    this.onTap,
    this.light = false,
    super.key,
  });

  final int lives;
  final int maxLives;
  final VoidCallback? onTap;
  final bool light;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: onTap == null
        ? 'Energia: $lives de $maxLives.'
        : 'Energia: $lives de $maxLives. Toque para recuperar.',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: _explorerOrange,
                size: 34,
                shadows: [
                  Shadow(
                    color: _explorerInk,
                    blurRadius: 2,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              const SizedBox(width: 3),
              Text(
                '$lives',
                style: TextStyle(
                  color: light ? Colors.white : _explorerInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CurrentEnergyIndicator extends StatelessWidget {
  const CurrentEnergyIndicator({
    this.interactive = true,
    this.light = false,
    super.key,
  });

  final bool interactive;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).online;
    if (service == null) return const SizedBox.shrink();
    return EnergyIndicator(
      lives: service.lives,
      maxLives: service.maxLives,
      light: light,
      onTap: interactive ? () => showEnergy(context) : null,
    );
  }
}

class _CompassBadge extends StatelessWidget {
  const _CompassBadge();

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/home/nickname_badge.png',
    width: 58,
    height: 58,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
  );
}

class PlayerPanel extends StatefulWidget {
  const PlayerPanel({
    this.trailing,
    this.showEnergy = true,
    this.showProgress = true,
    super.key,
  });
  final Widget? trailing;
  final bool showEnergy;
  final bool showProgress;

  @override
  State<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends State<PlayerPanel> with WidgetsBindingObserver {
  Timer? _timer;
  bool _refreshing = false;
  int _ticks = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _ticks++);
      if (_ticks % 30 == 0) _refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      await AppScope.of(context, listen: false).refreshOnline();
    } catch (_) {
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).online!;
    final level = s.user['progression'] as Map? ?? {};
    final current = level['currentXp'] as num? ?? 0;
    final next = level['nextXp'] as num?;
    final lvl = (level['level'] as num?)?.toInt() ?? 1;

    void openProfile() => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const PlayerProfileScreen()),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: GestureDetector(
                onTap: openProfile,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topLeft,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _WoodenNicknamePlaque(
                                nickname: s.user['nickname']?.toString() ?? '',
                              ),
                              if (widget.showProgress) ...[
                                const SizedBox(height: 3),
                                _HudLevelProgressBar(
                                  level: lvl,
                                  currentXp: current,
                                  nextXp: next,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Positioned(
                          left: 0,
                          top: -4,
                          child: _CompassBadge(),
                        ),
                      ],
                    ),
                    SizedBox(height: widget.showProgress ? 8 : 31),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const WorldCoinBalanceChip(),
            if (widget.showEnergy) ...[
              const SizedBox(width: 12),
              EnergyIndicator(
                lives: s.lives,
                maxLives: s.maxLives,
                onTap: () => showEnergy(context),
              ),
            ],
            if (widget.trailing != null) ...[
              const SizedBox(width: 7),
              widget.trailing!,
            ],
          ],
        ),
        if (!s.connected)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 62, top: 4),
              child: Text(
                'Reconectando…',
                style: TextStyle(color: Colors.amber.shade200, fontSize: 9),
              ),
            ),
          ),
      ],
    );
  }
}

class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context), s = controller.online!;
    final album = controller.globalAlbumProgress();
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(avatarIcons[s.user['avatar']], size: 64),
          const SizedBox(height: 12),
          Text(
            '${s.user['nickname']}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const PlayerPanel(),
          ListTile(
            title: const Text('Puzzles concluídos'),
            trailing: Text('${s.user['puzzlesCompleted'] ?? 0}'),
          ),
          ListTile(
            title: const Text('Países explorados'),
            trailing: Text(
              '${(s.user['countriesExplored'] as List? ?? []).length}',
            ),
          ),
          ListTile(
            title: const Text('Cartas obtidas'),
            trailing: Text('${s.user['cardsReceived'] ?? 0}'),
          ),
          ListTile(
            title: const Text('Álbum geral'),
            subtitle: Text('${album.pasted}/${album.total} cartas coladas'),
            trailing: Text('${(album.fraction * 100).toStringAsFixed(1)}%'),
          ),
        ],
      ),
    );
  }
}

class DailyExplorationScreen extends StatefulWidget {
  const DailyExplorationScreen({super.key});
  @override
  State<DailyExplorationScreen> createState() => _DailyExplorationScreenState();
}

const _parchmentInk = Color(0xFF4A2D1A);
const _parchmentMuted = Color(0xFF795C3A);
const _parchmentPanel = Color(0x99FFF0C2);
const _parchmentAccent = Color(0xFF9A4F2E);

class _DailyExplorationScreenState extends State<DailyExplorationScreen> {
  Timer? _timer;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _claim(String day) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pack = await AppScope.of(context, listen: false).claimDaily(day);
      if (mounted) {
        final name = PackCatalog.byId(pack)?.name ?? pack;
        final copy = DailyExplorationStrings.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(copy.packReceived(name))));
      }
    } catch (e) {
      if (mounted) setState(() => _error = onlineError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = DailyExplorationStrings.of(context);
    final s = AppScope.of(context).online!,
        countries = s.daily['countries'] as Map? ?? {};
    final ids =
        (s.daily['countryIds'] as List?)?.cast<String>() ??
        dailyExplorationCountryIds;
    final gameCountries = gameModes.first.countries;
    final required = [
      for (final id in ids)
        if (gameCountries.where((country) => country.id == id).firstOrNull
            case final country?)
          country,
    ];
    final score =
        (s.daily['bestScore'] as num?)?.toInt() ?? dailyScore(countries);
    final milestone = dailyRewardMilestone(score);
    final odds = dailyRewardOdds[milestone]!;
    final completed = required
        .where((theme) => countries.containsKey(theme.id))
        .length;
    final claimed = s.daily['claimed'] == true;
    final ready = completed == required.length && score >= 40 && !claimed;
    final currentId = s.daily['id'] as String?;
    final baseTheme = Theme.of(context);
    return Theme(
      data: baseTheme.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: const Color(0xFF9A4F2E),
          onSurface: _parchmentInk,
          surface: const Color(0xFFF3D99A),
        ),
        dividerColor: const Color(0x55704A27),
        textTheme: baseTheme.textTheme.apply(
          bodyColor: _parchmentInk,
          displayColor: _parchmentInk,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFFFE1A3),
          iconTheme: IconThemeData(color: Color(0xFFFFE1A3)),
          titleTextStyle: TextStyle(
            color: Color(0xFFFFE1A3),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: Text(copy['title'])),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _ParchmentBackground(),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 64, 28, 42),
                children: [
                  Text(
                    copy['objective'],
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var index = 0; index < required.length; index++) ...[
                        if (index > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _DailyCountryCard(
                            themeId: required[index].id,
                            name: copy.countryName(
                              required[index].id,
                              required[index].name,
                            ),
                            value: countries[required[index].id],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _DailyInfoPanel(),
                  const SizedBox(height: 18),
                  _DailyScoreCard(score: score),
                  const SizedBox(height: 18),
                  _DailyRewardProgress(score: score),
                  const SizedBox(height: 18),
                  _DailyRewardChances(
                    odds: odds,
                    milestone: milestone,
                    unlocked: score >= 40,
                  ),
                  const SizedBox(height: 18),
                  if (ready && currentId != null) ...[
                    FilledButton.icon(
                      key: const Key('daily_claim_button'),
                      onPressed: _busy ? null : () => _claim(currentId),
                      icon: const Icon(Icons.redeem_rounded),
                      label: Text(
                        _busy ? copy['claiming'] : copy['readyToClaim'],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      copy.claimHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _parchmentMuted),
                    ),
                  ] else if (claimed)
                    _DailyStatusMessage(
                      icon: Icons.check_circle_rounded,
                      text: copy['rewardClaimed'],
                    )
                  else
                    _DailyStatusMessage(
                      icon: Icons.explore_rounded,
                      text: copy.objectiveStatus(completed),
                    ),
                  for (final day in s.unclaimedExplorations.where(
                    (day) => day['id'] != currentId,
                  )) ...[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _claim(day['id'] as String),
                      child: Text(copy.previousClaim(day['id'] as String)),
                    ),
                  ],
                  if (_error != null) Text(_error!),
                  const SizedBox(height: 14),
                  Text(copy.resetIn(countdown(s.resetsAt - s.serverNow))),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PacksScreen(),
                      ),
                    ),
                    child: Text(copy['openPacks']),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParchmentBackground extends StatelessWidget {
  const _ParchmentBackground();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF342013),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DecoratedBox(
          key: const Key('daily_parchment_background'),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE1B96F),
                Color(0xFFFFE9AD),
                Color(0xFFF3D28B),
                Color(0xFFD5A75C),
              ],
              stops: [0, .2, .78, 1],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8B572A), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
              BoxShadow(
                color: Color(0x66FFF0C2),
                blurRadius: 12,
                spreadRadius: -4,
              ),
            ],
          ),
          child: const CustomPaint(painter: _ParchmentPainter()),
        ),
      ),
    ),
  );
}

class _ParchmentPainter extends CustomPainter {
  const _ParchmentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final edge = Paint()
      ..color = const Color(0x44734824)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(16, 30), Offset(size.width - 16, 30), edge);
    canvas.drawLine(
      Offset(16, size.height - 30),
      Offset(size.width - 16, size.height - 30),
      edge,
    );

    final rollPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x886F421D), Color(0x22FFF0C2), Color(0x886F421D)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 22));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(13, 13, size.width - 26, 18),
        const Radius.circular(10),
      ),
      rollPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(13, size.height - 31, size.width - 26, 18),
        const Radius.circular(10),
      ),
      rollPaint,
    );

    final fleck = Paint()..color = const Color(0x24704A27);
    for (var i = 0; i < 34; i++) {
      final x = 18 + ((i * 73) % (size.width - 36));
      final y = 42 + ((i * 137) % (size.height - 84));
      canvas.drawCircle(Offset(x, y), i.isEven ? .8 : .45, fleck);
    }
  }

  @override
  bool shouldRepaint(_ParchmentPainter oldDelegate) => false;
}

class _DailyCountryCard extends StatelessWidget {
  const _DailyCountryCard({
    required this.themeId,
    required this.name,
    required this.value,
  });
  final String themeId;
  final String name;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final copy = DailyExplorationStrings.of(context);
    final difficulty = dailyDifficulty(value);
    final completed = difficulty != null;
    final country = CardCatalog.countryById(themeId);
    return Container(
      key: Key('daily_country_$themeId'),
      constraints: const BoxConstraints(minHeight: 130),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(
        color: completed ? const Color(0x55C98452) : _parchmentPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed ? _parchmentAccent : const Color(0x66704A27),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(country?.flag ?? '🌎', style: const TextStyle(fontSize: 25)),
          const SizedBox(height: 5),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 7),
          Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 21,
            color: completed ? _parchmentAccent : _parchmentMuted,
          ),
          const SizedBox(height: 4),
          Text(
            copy.difficultyName(difficulty),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: completed ? _parchmentInk : _parchmentMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyInfoPanel extends StatelessWidget {
  const _DailyInfoPanel();
  @override
  Widget build(BuildContext context) {
    final copy = DailyExplorationStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _parchmentPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x44704A27)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: _parchmentAccent),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  copy['higherDifficulty'],
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  copy['difficulty'],
                  style: const TextStyle(
                    color: _parchmentMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                copy['points'],
                style: const TextStyle(
                  color: _parchmentMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Divider(),
          for (final entry in dailyDifficultyPoints.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(copy.difficultyName(entry.key))),
                  Text(
                    '+${entry.value}',
                    style: const TextStyle(
                      color: _parchmentAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Text(
                  copy['maximum'],
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text('80', style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyScoreCard extends StatelessWidget {
  const _DailyScoreCard({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) {
    final copy = DailyExplorationStrings.of(context);
    return Column(
      children: [
        Text(
          copy['dailyScore'],
          style: const TextStyle(
            color: _parchmentMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '$score / 80',
          key: const Key('daily_score'),
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: _parchmentAccent,
          ),
        ),
      ],
    );
  }
}

class _DailyRewardProgress extends StatelessWidget {
  const _DailyRewardProgress({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) {
    final copy = DailyExplorationStrings.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 13),
      decoration: BoxDecoration(
        color: _parchmentPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x44704A27)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            copy['rewardProgress'],
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: score / 80,
              minHeight: 8,
              backgroundColor: const Color(0x33704A27),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final value in [0, 40, 60, 70, 80])
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        value == 0 ? Icons.circle : Icons.star_rounded,
                        size: value == 0 ? 9 : 18,
                        color: score >= value && value > 0
                            ? _parchmentAccent
                            : const Color(0x55704A27),
                      ),
                      Text(
                        '$value',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: score >= value
                              ? _parchmentInk
                              : _parchmentMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '$score / 80',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DailyRewardChances extends StatelessWidget {
  const _DailyRewardChances({
    required this.odds,
    required this.milestone,
    required this.unlocked,
  });
  final List<int> odds;
  final int milestone;
  final bool unlocked;
  @override
  Widget build(BuildContext context) {
    final copy = DailyExplorationStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          unlocked ? copy['currentRewardChances'] : copy['chancesAt40'],
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          copy.rewardTier(milestone),
          style: const TextStyle(color: _parchmentMuted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < packDefinitions.length; index++)
          Container(
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _parchmentPanel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x33704A27)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  height: 42,
                  child: PackArtwork(pack: packDefinitions[index]),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    packDefinitions[index].name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${odds[index]}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: odds[index] > 0 ? _parchmentAccent : _parchmentMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DailyStatusMessage extends StatelessWidget {
  const _DailyStatusMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _parchmentPanel,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x44704A27)),
    ),
    child: Row(
      children: [
        Icon(icon, color: _parchmentAccent),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

Future<void> showEnergy(BuildContext context, {bool depleted = false}) =>
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .78),
      builder: (_) => _EnergyDialog(depleted: depleted),
    );

Future<void> showLives(BuildContext context) =>
    showEnergy(context, depleted: true);

class _EnergyDialog extends StatefulWidget {
  const _EnergyDialog({required this.depleted});
  final bool depleted;
  @override
  State<_EnergyDialog> createState() => _EnergyDialogState();
}

class _EnergyDialogState extends State<_EnergyDialog> {
  bool _busy = false;
  String? _message;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _watch() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final ok = await AppScope.of(context, listen: false).recoverLives();
      if (mounted) {
        setState(
          () => _message = ok
              ? 'Energia recuperada!'
              : 'Anúncio indisponível ou confirmação pendente. Tente novamente.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _message = onlineError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).online!;
    final canRecover = !_busy && s.lives < s.maxLives;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            key: const Key('energy_battery_dialog'),
            width: 380,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF69757D),
                  Color(0xFF505C64),
                  Color(0xFF222A30),
                ],
                stops: [0, .48, 1],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF080B0D), width: 7),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.depleted && s.lives == 0
                            ? 'Você está sem Energia!'
                            : 'Sua Energia (${s.lives}/${s.maxLives})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('energy_close_button'),
                      tooltip: 'Fechar',
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF11171B),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white38,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 104,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD3D8DE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF090C0E),
                      width: 5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFFFBE2E),
                        size: 66,
                        shadows: [
                          Shadow(
                            color: Color(0xFF101417),
                            blurRadius: 0,
                            offset: Offset(3, 4),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${s.lives} / ${s.maxLives}',
                        style: const TextStyle(
                          color: Color(0xFF151A1E),
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.depleted && s.lives == 0) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Recarregue sua Energia para continuar jogando.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFE3E9ED),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (s.lives < s.maxLives) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Próxima energia em ${countdown(s.nextLifeAt - s.serverNow)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE3E9ED),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 68,
                  child: FilledButton.icon(
                    key: const Key('energy_watch_ad_button'),
                    onPressed: canRecover ? _watch : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFBE2E),
                      foregroundColor: const Color(0xFF181A1C),
                      disabledBackgroundColor: const Color(0xFFC8942A),
                      disabledForegroundColor: const Color(0xFF3A301F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(
                          color: Color(0xFF090C0E),
                          width: 4,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 29),
                    label: Text(
                      _busy
                          ? 'AGUARDANDO CONFIRMAÇÃO…'
                          : s.lives >= s.maxLives
                          ? 'ENERGIA COMPLETA'
                          : 'ASSISTIR ANÚNCIO  •  +1 ENERGIA',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final left in [48.0, 110.0, 172.0, 234.0])
            Positioned(
              top: -15,
              left: left,
              child: Container(
                width: 42,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF69757D),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                  border: Border.all(color: const Color(0xFF080B0D), width: 6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void showMarket(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Mercado de Cartas'),
    content: const Text(
      'O Mercado Mundial está sendo preparado!\n\nEm breve, você poderá negociar suas cartas duplicadas com outros exploradores.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Em breve'),
      ),
    ],
  ),
);
