import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../models/game_theme.dart';
import '../progress_bar/collection_progress_bar.dart';

class ThemeCard extends StatelessWidget {
  const ThemeCard({
    required this.theme,
    required this.stats,
    required this.onTap,
    super.key,
  });

  final GameTheme theme;
  final ThemeStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Color(theme.accent);
    return Semantics(
      button: true,
      label:
          '${theme.name}, ${stats.completed} de ${stats.total} fases concluídas',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          height: 238,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            image: DecorationImage(
              image: AssetImage(theme.thumbnail),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xEA080B0C)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  theme.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  theme.subtitle,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('${stats.completed}/${stats.total} concluídos'),
                    const Spacer(),
                    Text('${stats.stars}/${stats.total * 3} estrelas'),
                  ],
                ),
                const SizedBox(height: 9),
                CollectionProgressBar(value: stats.fraction, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
