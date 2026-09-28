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
import '../packs/debug_pack_sheet.dart';
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
  100: [84, 9, 5, 2],
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

int dailyRewardMilestone(int score) => score >= 100
    ? 100
    : score >= 80
    ? 80
    : score >= 70
    ? 70
    : score >= 60
    ? 60
    : 40;

int projectedTier(Map countries, Map config, {int remainingPoints = 10}) {
  final score =
      dailyScore(countries) + (4 - countries.length) * remainingPoints;
  return dailyRewardMilestone(score) == 100
      ? 5
      : dailyRewardMilestone(score) == 80
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
    this.onTap,
  });

  final int level;
  final num currentXp;
  final num? nextXp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = nextXp == null || nextXp! <= 0
        ? 1.0
        : (currentXp / nextXp!).clamp(0.0, 1.0).toDouble();

    final bar = Column(
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
    if (onTap == null) return bar;
    return Semantics(
      button: true,
      label: 'Abrir recompensas de nível',
      child: GestureDetector(
        key: const Key('level_progress_rewards_button'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: bar,
      ),
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const LevelRewardsScreen()),
      ),
    );
  }
}

const _levelRewards = <({int level, String packId, String bonus})>[
  (level: 5, packId: PackIds.world, bonus: '+1% de chance de carta rara'),
  (
    level: 10,
    packId: PackIds.explorer,
    bonus: '+0,5% de chance de carta épica',
  ),
  (
    level: 15,
    packId: PackIds.world,
    bonus: '+0,2% de chance de carta lendária',
  ),
  (level: 20, packId: PackIds.wonders, bonus: '+1% de chance de carta rara'),
  (
    level: 25,
    packId: PackIds.explorer,
    bonus: '+0,5% de chance de carta épica',
  ),
  (
    level: 30,
    packId: PackIds.legacy,
    bonus: '+0,3% de chance de carta lendária',
  ),
];

class LevelRewardsScreen extends StatelessWidget {
  const LevelRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final online = AppScope.of(context).online!;
    final progression = online.user['progression'] as Map? ?? {};
    final level = (progression['level'] as num?)?.toInt() ?? 1;
    return Scaffold(
      appBar: AppBar(title: const Text('Marcos de nível')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Nível atual: $level de 30',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text('Os bônus desbloqueados valem para todos os pacotes.'),
          const SizedBox(height: 18),
          for (final reward in _levelRewards)
            Card(
              key: Key('level_reward_${reward.level}'),
              child: ListTile(
                leading: CircleAvatar(
                  child: level >= reward.level
                      ? const Icon(Icons.check_rounded)
                      : Text('${reward.level}'),
                ),
                title: Text('Nível ${reward.level} • ${reward.bonus}'),
                subtitle: Text(
                  '${PackCatalog.byId(reward.packId)?.name ?? reward.packId} incluído',
                ),
                trailing: Icon(
                  level >= reward.level
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Valores provisórios para balanceamento.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
                    _WoodenNicknamePlaque(
                      nickname: s.user['nickname']?.toString() ?? '',
                    ),
                    if (widget.showProgress) ...[
                      const SizedBox(height: 3),
                      _HudLevelProgressBar(
                        level: lvl,
                        currentXp: current,
                        nextXp: next,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const LevelRewardsScreen(),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
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
              padding: const EdgeInsets.only(top: 4),
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
          if (controller.debugEconomyEnabled)
            ListTile(
              key: const Key('profile_debug_packs_button'),
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Gerar pacotes de teste'),
              subtitle: const Text('Ferramenta de debug desta conta'),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const DebugPackSheet(),
              ),
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
  bool _showWeekly = false;
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

  Future<void> _requestDailyClaim(String day, int score) async {
    if (score < 100) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          key: const Key('daily_claim_confirmation'),
          title: const Text('Resgatar recompensa?'),
          content: const Text(
            'Tem certeza que deseja coletar o seu prêmio agora? Você pode melhorar suas chances acumulando mais pontos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CONTINUAR ACUMULANDO'),
            ),
            FilledButton.icon(
              key: const Key('daily_claim_confirm_button'),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.card_giftcard_rounded),
              label: const Text('COLETAR AGORA'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await _claim(day);
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

  Future<void> _claimWeekly() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final packs = await AppScope.of(
        context,
        listen: false,
      ).claimWeeklyRewards();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              packs.isEmpty
                  ? 'Nenhum novo pacote semanal disponível.'
                  : '${packs.length} pacote(s) semanal(is) recebido(s)!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = onlineError(e);
        setState(() => _error = message);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
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
        backgroundColor: const Color(0xFF342013),
        appBar: AppBar(title: Text(copy['title'])),
        body: _ParchmentBackground(
          child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
              children: [
                _ExplorationTabs(
                  weeklySelected: _showWeekly,
                  onChanged: (weekly) => setState(() => _showWeekly = weekly),
                ),
                const SizedBox(height: 22),
                if (_showWeekly)
                  _WeeklyExplorationPanel(
                    points: s.weeklyPoints,
                    active: s.weeklyActive,
                    remaining: countdown(s.weeklyResetsAt - s.serverNow),
                    busy: _busy,
                    onClaim: _claimWeekly,
                    claimed: {
                      for (final value
                          in (s.weeklyStars['claimedRewards'] as List? ??
                              const []))
                        (value as num).toInt(),
                    },
                  )
                else ...[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      copy['objective'],
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
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
                    _DailyClaimButton(
                      busy: _busy,
                      label: _busy ? copy['claiming'] : copy['readyToClaim'],
                      onPressed: () => _requestDailyClaim(currentId, score),
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
                          : () => _requestDailyClaim(
                              day['id'] as String,
                              (day['bestScore'] as num?)?.toInt() ?? 40,
                            ),
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
                  const SizedBox(height: 12),
                  const _DailyInfoPanel(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplorationTabs extends StatelessWidget {
  const _ExplorationTabs({
    required this.weeklySelected,
    required this.onChanged,
  });
  final bool weeklySelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0x554A2D1A),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x66704A27)),
    ),
    child: Row(
      children: [
        Expanded(
          child: _ExplorationTabButton(
            key: const Key('daily_exploration_tab'),
            label: 'Exploração diária',
            selected: !weeklySelected,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _ExplorationTabButton(
            key: const Key('weekly_exploration_tab'),
            label: 'Exploração semanal',
            selected: weeklySelected,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    ),
  );
}

class _ExplorationTabButton extends StatelessWidget {
  const _ExplorationTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    duration: const Duration(milliseconds: 180),
    opacity: selected ? 1 : .48,
    child: Material(
      color: selected ? const Color(0xFFFFE3A2) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ),
    ),
  );
}

const _weeklyRewards = <({int points, String packId})>[
  (points: 300, packId: PackIds.world),
  (points: 450, packId: PackIds.explorer),
  (points: 600, packId: PackIds.wonders),
  (points: 700, packId: PackIds.legacy),
];

class _WeeklyExplorationPanel extends StatelessWidget {
  const _WeeklyExplorationPanel({
    required this.points,
    required this.active,
    required this.remaining,
    required this.claimed,
    required this.busy,
    required this.onClaim,
  });
  final int points;
  final bool active;
  final String remaining;
  final Set<int> claimed;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    const maximum = 700;
    final hasAvailableReward = _weeklyRewards.any(
      (reward) => points >= reward.points && !claimed.contains(reward.points),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Jornada da semana',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          active
              ? 'Segunda 00h até domingo 13h • encerra em $remaining'
              : 'Semana encerrada • próxima jornada em $remaining',
        ),
        const SizedBox(height: 4),
        const Text('Até 100 pontos da Exploração Diária por dia.'),
        const SizedBox(height: 12),
        Container(
          key: const Key('weekly_claim_schedule_notice'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x99FFF0C2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD68127), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                active ? Icons.lock_clock_rounded : Icons.lock_open_rounded,
                color: const Color(0xFF8C4D18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  active
                      ? 'Os pacotes só podem ser resgatados domingo após as 13h.'
                      : 'Resgate liberado: domingo após as 13h.',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _parchmentPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x66704A27)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.explore_rounded, color: Color(0xFFD68127)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$points / $maximum pontos',
                      key: const Key('weekly_score'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                minHeight: 12,
                borderRadius: BorderRadius.circular(99),
                value: (points / maximum).clamp(0, 1),
                color: const Color(0xFFD68127),
                backgroundColor: const Color(0x44704A27),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Recompensas semanais',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        for (final reward in _weeklyRewards)
          Card(
            color: points >= reward.points
                ? const Color(0x99E7C675)
                : const Color(0x66FFF0C2),
            child: ListTile(
              key: Key('weekly_reward_${reward.points}'),
              leading: Icon(
                claimed.contains(reward.points)
                    ? Icons.inventory_2_rounded
                    : points >= reward.points
                    ? Icons.redeem_rounded
                    : Icons.lock_outline_rounded,
              ),
              title: Text(
                PackCatalog.byId(reward.packId)?.name ?? reward.packId,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('${reward.points} pontos'),
              trailing: claimed.contains(reward.points)
                  ? const Text('RECEBIDO')
                  : !active && points >= reward.points
                  ? const Text('RESGATAR')
                  : null,
            ),
          ),
        if (!active && hasAvailableReward) ...[
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const Key('weekly_claim_button'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            onPressed: busy ? null : onClaim,
            icon: const Icon(Icons.card_giftcard_rounded, size: 26),
            label: Text(busy ? 'RESGATANDO…' : 'RESGATAR PACOTES'),
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          'A primeira recompensa é liberada com 300 pontos. Os pacotes são cumulativos; com 700 pontos, você pode resgatar um de cada.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _parchmentMuted),
        ),
      ],
    );
  }
}

class _ParchmentBackground extends StatelessWidget {
  const _ParchmentBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
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
    ),
    child: CustomPaint(painter: const _ParchmentPainter(), child: child),
  );
}

class _ParchmentPainter extends CustomPainter {
  const _ParchmentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fleck = Paint()..color = const Color(0x24704A27);
    for (var i = 0; i < 34; i++) {
      final x = 18 + ((i * 73) % (size.width - 36));
      final y = 18 + ((i * 137) % (size.height - 36));
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
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        key: Key('daily_country_$themeId'),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        decoration: BoxDecoration(
          color: completed ? const Color(0x55C98452) : _parchmentPanel,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: completed ? _parchmentAccent : const Color(0x66704A27),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(country?.flag ?? '🌎', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 15,
              color: completed ? _parchmentAccent : _parchmentMuted,
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                copy.difficultyName(difficulty),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: completed ? _parchmentInk : _parchmentMuted,
                ),
              ),
            ),
          ],
        ),
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
              Text('100', style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyClaimButton extends StatelessWidget {
  const _DailyClaimButton({
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 76,
    child: Material(
      color: const Color(0xFF8F4528),
      elevation: 4,
      shadowColor: const Color(0x8870381F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFFFC857), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('daily_claim_button'),
        onTap: busy ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/rewards/daily_claim_gift.png',
                key: const Key('daily_claim_gift'),
                width: 46,
                height: 46,
                cacheWidth: 138,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFF1C5),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
              key: const Key('daily_reward_progress_bar'),
              value: (score / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0x33704A27),
            ),
          ),
          const SizedBox(height: 8),
          _DailyProgressMilestones(score: score),
          const SizedBox(height: 5),
          Text(
            '$score / 100',
            key: const Key('daily_score'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DailyProgressMilestones extends StatelessWidget {
  const _DailyProgressMilestones({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const markerWidth = 32.0;
      const maximum = 100.0;
      return SizedBox(
        height: 31,
        child: Stack(
          children: [
            for (final value in const [0, 40, 60, 70, 80, 100])
              Positioned(
                key: Key('daily_progress_milestone_$value'),
                left: (constraints.maxWidth * value / maximum - markerWidth / 2)
                    .clamp(0.0, constraints.maxWidth - markerWidth),
                width: markerWidth,
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
                        color: score >= value ? _parchmentInk : _parchmentMuted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
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
                  child: FractionallySizedBox(
                    widthFactor: .6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _EnergyStat(
                          icon: Icons.bolt_rounded,
                          value: '${s.lives}',
                          label: 'ATUAL',
                        ),
                        _EnergyStat(
                          icon: Icons.battery_full_rounded,
                          value: '${s.maxLives}',
                          label: 'MÁXIMA',
                        ),
                      ],
                    ),
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

class _EnergyStat extends StatelessWidget {
  const _EnergyStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFFFFBE2E),
            size: 35,
            shadows: const [
              Shadow(
                color: Color(0xFF101417),
                blurRadius: 0,
                offset: Offset(2, 2),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF151A1E),
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF3F484E),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
    ],
  );
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
