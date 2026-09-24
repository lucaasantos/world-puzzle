import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../data/themes_data.dart';
import '../../data/jigsaw_levels_data.dart';
import '../../data/blocks_levels_data.dart';
import '../../models/game_mode.dart';
import '../../models/game_theme.dart';
import '../levels/levels_screen.dart';
import '../online/player_screens.dart';

class CountriesScreen extends StatelessWidget {
  const CountriesScreen({required this.mode, super.key});
  final GameModeConfig mode;

  GameTheme? _themeFor(GameCountryConfig country) {
    if (country.themeId == null) return null;
    for (final theme in gameThemes) {
      if (theme.id == country.themeId) return theme;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
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
                colors: [Color(0x9E2A160C), Color(0xAD2A160C)],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 5, 16, 20),
                    child: Row(
                      children: [
                        IconButton.filled(
                          tooltip: 'Voltar',
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xB54A2B19),
                            foregroundColor: const Color(0xFFFFE7B0),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mode.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFFFE7B0),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                'Escolha o país que quer explorar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const CurrentEnergyIndicator(
                          key: Key('countries_energy_indicator'),
                          light: true,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  sliver: SliverGrid.builder(
                    itemCount: mode.countries.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 12,
                          childAspectRatio: .80,
                        ),
                    itemBuilder: (context, index) {
                      final country = mode.countries[index];
                      final theme = _themeFor(country);
                      final available =
                          mode.enabled && country.enabled && theme != null;
                      final levelIds = switch (mode.kind) {
                        GameModeKind.jigsaw => jigsawLevelsFor(
                          country.id,
                        ).map((level) => level.id).toList(),
                        GameModeKind.blocks => blocksLevelsFor(
                          country.id,
                        ).map((level) => level.id).toList(),
                        GameModeKind.sliding => country.levelIds,
                      };
                      return _CountryCard(
                        country: country,
                        theme: theme,
                        completed: mode.kind != GameModeKind.sliding
                            ? levelIds
                                  .where(controller.progress.containsKey)
                                  .length
                            : theme == null
                            ? 0
                            : controller.statsFor(theme).completed,
                        total: mode.kind != GameModeKind.sliding
                            ? levelIds.length
                            : theme?.levels.length ?? country.levelIds.length,
                        onTap: available
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => LevelsScreen(
                                    theme: theme,
                                    mode: mode.kind,
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
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

class _CountryCard extends StatelessWidget {
  const _CountryCard({
    required this.country,
    required this.theme,
    required this.completed,
    required this.total,
    required this.onTap,
  });

  final GameCountryConfig country;
  final GameTheme? theme;
  final int completed;
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: enabled ? country.name : '${country.name}, em breve',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Material(
          color: enabled ? const Color(0xFFFFEDC2) : const Color(0xFF625F59),
          child: InkWell(
            key: Key('country_${country.id}'),
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (theme != null)
                        Image.asset(
                          theme!.thumbnail,
                          fit: BoxFit.cover,
                          color: enabled ? null : Colors.grey,
                          colorBlendMode: enabled ? null : BlendMode.saturation,
                        )
                      else
                        DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF595754), Color(0xFF1F1E1C)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              country.flag,
                              style: const TextStyle(fontSize: 50),
                            ),
                          ),
                        ),
                      if (theme != null)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                enabled
                                    ? Colors.transparent
                                    : Colors.black.withValues(alpha: .34),
                                const Color(0xA6000000),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: enabled
                            ? Text(
                                country.flag,
                                style: const TextStyle(fontSize: 25),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xCC3F3D39),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        country.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: enabled
                              ? const Color(0xFF4A2B18)
                              : const Color(0xFFE1DED7),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        enabled ? '$completed/$total desafios' : 'EM BREVE',
                        style: TextStyle(
                          color: enabled
                              ? const Color(0xFF76563B)
                              : const Color(0xFFC9C5BD),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
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
}
