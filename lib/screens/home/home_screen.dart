import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/localization/star_dust_strings.dart';
import '../album/album_screen.dart';
import '../collection/collection_screen.dart';
import '../packs/packs_screen.dart';
import '../settings/settings_screen.dart';
import '../star_dust/star_dust_screen.dart';
import '../themes/themes_screen.dart';
import '../online/player_screens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final s = controller.online;
    final starDustCopy = StarDustStrings.of(context);

    final hasDailyUnclaimed = s?.unclaimedExplorations.isNotEmpty == true;
    final dailyCountries = s?.daily['countries'] as Map? ?? {};
    final hasDailyPending =
        s != null && (s.daily['claimed'] != true || dailyCountries.length < 4);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home/puzzle_world_home.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .2, .58, 1],
                colors: [
                  Color(0x4D071A20),
                  Color(0x00071A20),
                  Color(0x140A1114),
                  Color(0xF20D1113),
                ],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.hasBoundedHeight &&
                            constraints.maxHeight > 28
                        ? constraints.maxHeight - 28
                        : 0,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // TOPO: HUD do Jogador (Avatar, Nickname, Nível, XP, Energia ⚡) + Configurações
                        if (controller.isOnline)
                          const PlayerPanel(
                            trailing: _SettingsButton(),
                            showEnergy: false,
                            showProgress: false,
                          )
                        else
                          const Align(
                            alignment: Alignment.topRight,
                            child: _SettingsButton(),
                          ),

                        const SizedBox(height: 16),

                        // CENTRO: Título e Identidade Visual do Puzzle World
                        const Text(
                          'PUZZLE\nWORLD',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFFF4DE),
                            fontSize: 47,
                            height: .82,
                            fontFamily: 'SuperBouncer',
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Color(0xAA6B351B),
                                offset: Offset(0, 4),
                                blurRadius: 1,
                              ),
                              Shadow(
                                color: Color(0x99000000),
                                offset: Offset(0, 7),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),
                        const Text(
                          'JOGUE  •  DESCUBRA  •  COLECIONE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Spacer(),

                        Row(
                          key: const Key('home_primary_shortcuts'),
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (s != null)
                              _HomeEnergyShortcut(
                                lives: s.lives,
                                maxLives: s.maxLives,
                                onPressed: () => showEnergy(context),
                              )
                            else
                              const SizedBox(width: 76),
                            _HomeImageShortcut(
                              shortcutKey: const Key(
                                'home_collection_shortcut',
                              ),
                              assetPath:
                                  'assets/images/home/collection_icon.png',
                              label: 'COLEÇÃO',
                              semanticLabel: 'Abrir coleção de cartinhas',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const CollectionScreen(),
                                ),
                              ),
                            ),
                            _HomeImageShortcut(
                              shortcutKey: const Key('home_album_shortcut'),
                              assetPath: 'assets/images/home/album_icon.png',
                              label: 'ÁLBUM',
                              semanticLabel: 'Abrir álbum de figurinhas',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const AlbumScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),

                        const FractionallySizedBox(
                          widthFactor: .82,
                          child: PlayerLevelBar(),
                        ),
                        const SizedBox(height: 7),

                        // CENTRO: Botão Principal de Ação "JOGAR"
                        FractionallySizedBox(
                          widthFactor: .82,
                          child: _PlayButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const ThemesScreen(),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Atalhos de progressão e recompensas.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: _AdventureShortcutTile(
                                shortcutKey: const Key('home_daily_shortcut'),
                                icon: Image.asset(
                                  'assets/images/home/daily_exploration_icon.png',
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.contain,
                                  cacheWidth: 192,
                                  excludeFromSemantics: true,
                                ),
                                label: 'Exploração Diária',
                                hasNotification:
                                    hasDailyPending || hasDailyUnclaimed,
                                notificationColor: hasDailyUnclaimed
                                    ? const Color(0xFFFFD54F)
                                    : const Color(0xFFFF5252),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const DailyExplorationScreen(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (s != null) ...[
                              Flexible(
                                child: _AdventureShortcutTile(
                                  shortcutKey: const Key(
                                    'home_star_dust_shortcut',
                                  ),
                                  icon: const StarDustHomeIcon(),
                                  label: starDustCopy['title'],
                                  badgeText: '${s.starDustBalance}',
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => const StarDustScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: _AdventureShortcutTile(
                                shortcutKey: const Key('home_packs_shortcut'),
                                icon: Image.asset(
                                  'assets/images/home/packs_chest_icon.png',
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.contain,
                                  cacheWidth: 192,
                                  excludeFromSemantics: true,
                                ),
                                label: 'Pacotes',
                                badgeText: controller.totalUnopenedPacks > 0
                                    ? '${controller.totalUnopenedPacks}'
                                    : null,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => const PacksScreen(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Configurações',
    style: IconButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: EdgeInsets.zero,
    ),
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    ),
    icon: Image.asset(
      'assets/images/home/settings_wrench.png',
      width: 48,
      height: 48,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      cacheWidth: 144,
      excludeFromSemantics: true,
    ),
  );
}

class _HomeEnergyShortcut extends StatelessWidget {
  const _HomeEnergyShortcut({
    required this.lives,
    required this.maxLives,
    required this.onPressed,
  });

  final int lives;
  final int maxLives;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Energias: $lives de $maxLives',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('home_energy_shortcut'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(
          width: 76,
          height: 82,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/home/energy_bolt.png',
                    width: 40,
                    height: 48,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    cacheWidth: 120,
                    excludeFromSemantics: true,
                  ),
                  Text(
                    '$lives',
                    style: const TextStyle(
                      color: Color(0xFFFFF4DE),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
              const Text(
                'ENERGIAS',
                style: TextStyle(
                  color: Color(0xFFFFF4DE),
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.15,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 5),
                    Shadow(
                      color: Color(0xAA6B351B),
                      offset: Offset(0, 2),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AdventureShortcutTile extends StatelessWidget {
  const _AdventureShortcutTile({
    required this.shortcutKey,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.badgeText,
    this.hasNotification = false,
    this.notificationColor,
  });

  final Key shortcutKey;
  final Widget icon;
  final String label;
  final VoidCallback onPressed;
  final String? badgeText;
  final bool hasNotification;
  final Color? notificationColor;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: shortcutKey,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 165),
          child: Ink(
            height: 110,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xD9161B1D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x40E8C886), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    icon,
                    if (badgeText != null)
                      Positioned(
                        top: -6,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFFD54F),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            badgeText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                    else if (hasNotification)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: notificationColor ?? const Color(0xFFFFD54F),
                            border: Border.all(
                              color: Colors.black87,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (notificationColor ??
                                            const Color(0xFFFFD54F))
                                        .withValues(alpha: 0.8),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '!',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFFFF4DE),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                        Shadow(
                          color: Color(0xAA6B351B),
                          offset: Offset(0, 1),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _HomeImageShortcut extends StatelessWidget {
  const _HomeImageShortcut({
    required this.shortcutKey,
    required this.assetPath,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final Key shortcutKey;
  final String assetPath;
  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: shortcutKey,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 76,
          height: 82,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                image: AssetImage(assetPath),
                width: 68,
                height: 59,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFFFF4DE),
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.15,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 5),
                    Shadow(
                      color: Color(0xAA6B351B),
                      offset: Offset(0, 2),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Jogar',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFE3A0), Color(0xFFE7B85E)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFF2C8), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(left: 12, right: 92),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'JOGAR',
                        maxLines: 1,
                        style: TextStyle(
                          color: Color(0xFF392310),
                          fontSize: 24,
                          fontFamily: 'SuperBouncer',
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              color: Color(0x40FFFFFF),
                              offset: Offset(0, 1),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -12,
                top: -30,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/home/explore_plane_v2.png',
                    width: 116,
                    height: 88,
                    fit: BoxFit.contain,
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
