import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/japan_theme.dart';
import '../../data/themes_data.dart';
import '../../models/game_theme.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recompensas')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
        itemCount: gameThemes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final theme = gameThemes[index];
          final unlocked = controller.isWallpaperUnlocked(theme.id);
          final isJapan = JapanTheme.matches(theme.id);
          return InkWell(
            onTap: () => _open(context, theme, unlocked),
            borderRadius: BorderRadius.circular(isJapan ? 10 : 24),
            child: Ink(
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isJapan ? 10 : 24),
                border: isJapan
                    ? Border.all(color: JapanTheme.gold, width: 2)
                    : null,
                image: DecorationImage(
                  image: AssetImage(theme.wallpaper),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  colorFilter: unlocked
                      ? null
                      : const ColorFilter.mode(
                          Colors.black54,
                          BlendMode.darken,
                        ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isJapan ? 8 : 24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      isJapan
                          ? const Color(0xE6542725)
                          : const Color(0xE6080B0C),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (isJapan)
                      Positioned(
                        right: -6,
                        top: -20,
                        child: Image.asset(
                          'assets/images/home/jp_lantern.png',
                          width: 52,
                          height: 78,
                          fit: BoxFit.contain,
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  theme.name.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: isJapan ? 'serif' : null,
                                    fontSize: isJapan ? 24 : 21,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  unlocked
                                      ? 'Wallpaper disponível'
                                      : 'Complete a coleção para desbloquear',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            unlocked
                                ? Icons.lock_open_rounded
                                : Icons.lock_outline_rounded,
                            color: isJapan ? JapanTheme.gold : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    GameTheme theme,
    bool unlocked,
  ) async {
    if (!unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complete a coleção ${theme.name} para desbloquear.'),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => _WallpaperPreview(theme: theme)),
    );
  }
}

class _WallpaperPreview extends StatefulWidget {
  const _WallpaperPreview({required this.theme});
  final GameTheme theme;

  @override
  State<_WallpaperPreview> createState() => _WallpaperPreviewState();
}

class _WallpaperPreviewState extends State<_WallpaperPreview> {
  bool saving = false;

  Future<void> save() async {
    setState(() => saving = true);
    final ok = await AppScope.of(
      context,
      listen: false,
    ).wallpaper.save(widget.theme.wallpaper);
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Wallpaper salvo na galeria.'
              : 'Não foi possível salvar o wallpaper.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isJapan = JapanTheme.matches(widget.theme.id);
    final palette = isJapan ? JapanPalette.forLevel(4) : null;
    final scaffold = Scaffold(
      backgroundColor: palette?.backgroundBottom ?? Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            child: Image.asset(widget.theme.wallpaper, fit: BoxFit.cover),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Colors.transparent,
                  Color(0xBB000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton.filled(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  if (isJapan) ...[
                    Image.asset(
                      'assets/images/home/jp_lantern.png',
                      width: 48,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    widget.theme.name,
                    style: TextStyle(
                      fontFamily: isJapan ? 'serif' : null,
                      fontSize: isJapan ? 34 : 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: isJapan ? 1.4 : 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: const Text('Salvar wallpaper'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (palette == null) return scaffold;
    return Theme(data: JapanTheme.apply(context, palette), child: scaffold);
  }
}
