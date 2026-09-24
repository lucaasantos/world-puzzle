import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SettingsGroup(
            children: [
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Som'),
                subtitle: const Text('Efeitos do jogo'),
                value: controller.soundEnabled,
                onChanged: controller.setSound,
              ),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.music_note_outlined),
                title: const Text('Música'),
                subtitle: const Text('Trilha ambiente'),
                value: controller.musicEnabled,
                onChanged: controller.setMusic,
              ),
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.vibration_rounded),
                title: const Text('Vibração'),
                subtitle: const Text('Resposta tátil durante a partida'),
                value: controller.hapticsEnabled,
                onChanged: controller.setHaptics,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'EM BREVE',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const _SettingsGroup(
            children: [
              ListTile(
                enabled: false,
                leading: Icon(Icons.language_rounded),
                title: Text('Idioma'),
                trailing: Text('Português'),
              ),
              ListTile(
                enabled: false,
                leading: Icon(Icons.restore_rounded),
                title: Text('Restaurar progresso'),
              ),
              ListTile(
                enabled: false,
                leading: Icon(Icons.info_outline_rounded),
                title: Text('Sobre'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              'Puzzle World • versão 1.0.0',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(children: children),
  );
}
