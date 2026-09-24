import 'package:flutter/material.dart';

import '../../data/game_modes_data.dart';
import '../../models/game_mode.dart';
import '../countries/countries_screen.dart';
import '../online/player_screens.dart';

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final availableModes = gameModes.where((mode) => mode.enabled).toList();
    final comingSoonModes = gameModes.where((mode) => !mode.enabled).toList();
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home/exploration_map_table_v2.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .3, 1],
                colors: [
                  Color(0x982A160C),
                  Color(0x3D2A160C),
                  Color(0xE62A160C),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _Header(onBack: () => Navigator.pop(context)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 15, 14, 14),
                        decoration: BoxDecoration(
                          color: const Color(0xE63C2415),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0x80FFE7B0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'ESCOLHA O JOGO',
                              style: TextStyle(
                                color: Color(0xFFFFE7B0),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 11),
                            for (
                              var index = 0;
                              index < availableModes.length;
                              index++
                            ) ...[
                              _GameModeCard(
                                mode: availableModes[index],
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => CountriesScreen(
                                      mode: availableModes[index],
                                    ),
                                  ),
                                ),
                              ),
                              if (index != availableModes.length - 1)
                                const SizedBox(height: 9),
                            ],
                          ],
                        ),
                      ),
                      if (comingSoonModes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Color(0x66FFE7B0))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'MAIS JOGOS EM BREVE',
                                style: TextStyle(
                                  color: Color(0xFFFFE7B0),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0x66FFE7B0))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (
                          var index = 0;
                          index < comingSoonModes.length;
                          index++
                        ) ...[
                          _GameModeCard(
                            mode: comingSoonModes[index],
                            onTap: null,
                          ),
                          if (index != comingSoonModes.length - 1)
                            const SizedBox(height: 9),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 5, 16, 4),
    child: Row(
      children: [
        IconButton.filled(
          tooltip: 'Voltar',
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xB54A2B19),
            foregroundColor: const Color(0xFFFFE7B0),
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MAPA DE EXPLORAÇÃO',
                style: TextStyle(
                  color: Color(0xFFFFE7B0),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
              ),
              Text(
                'Primeiro, escolha como quer jogar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
        const CurrentEnergyIndicator(
          key: Key('game_modes_energy_indicator'),
          light: true,
        ),
      ],
    ),
  );
}

class _GameModeCard extends StatelessWidget {
  const _GameModeCard({required this.mode, required this.onTap});
  final GameModeConfig mode;
  final VoidCallback? onTap;

  String get iconAsset => switch (mode.kind) {
    GameModeKind.sliding => 'assets/images/home/sliding_mode_icon.png',
    GameModeKind.jigsaw => 'assets/images/home/jigsaw_puzzle_icon.png',
    GameModeKind.blocks => 'assets/images/home/blocks_mode_icon.png',
  };

  Widget modeIcon(bool enabled) => Image.asset(
    iconAsset,
    key: Key('${mode.id}_mode_icon'),
    width: 52,
    height: 52,
    fit: BoxFit.contain,
    color: enabled ? null : const Color(0xFFB6B3AD),
    colorBlendMode: enabled ? null : BlendMode.saturation,
    filterQuality: FilterQuality.high,
    cacheWidth: 160,
  );

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: enabled ? mode.name : '${mode.name}, em breve',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('game_mode_${mode.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFFFFEDC2)
                  : const Color(0xFF77736A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: enabled
                    ? const Color(0xFFF4C06C)
                    : const Color(0xFFA6A198),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 52, height: 52, child: modeIcon(enabled)),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.name,
                        style: TextStyle(
                          color: enabled
                              ? const Color(0xFF4A2B18)
                              : const Color(0xFFE1DED7),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: enabled
                              ? const Color(0xFF76563B)
                              : const Color(0xFFC9C5BD),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                enabled
                    ? const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF8A432E),
                      )
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, color: Colors.white70),
                          SizedBox(height: 2),
                          Text(
                            'EM BREVE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
