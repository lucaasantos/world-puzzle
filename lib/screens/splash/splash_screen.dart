import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../home/home_screen.dart';
import '../online/player_screens.dart';
import '../../services/online_game_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Object? _error;
  bool _busy = false;
  bool _needsProfile = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final controller = AppScope.of(context, listen: false);
      await controller.initialize();
      if (!mounted) return;
      if (controller.online?.needsProfile == true) {
        setState(() => _needsProfile = true);
      } else {
        await _enter();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enter() async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_needsProfile) return ProfileOnboarding(onCompleted: _enter);
    if (_error != null) {
      final setup = _error is OnlineSetupException;
      final connection = isOnlineConnectionError(_error!);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  setup
                      ? Icons.settings_outlined
                      : connection
                      ? Icons.wifi_off
                      : Icons.error_outline,
                  size: 48,
                ),
                const SizedBox(height: 20),
                Text(
                  setup
                      ? 'Serviços online em preparação'
                      : connection
                      ? 'Conexão necessária'
                      : 'Não foi possível entrar',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(onlineError(_error!), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _start,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public_rounded, size: 48, color: Color(0xFFE8C886)),
            SizedBox(height: 18),
            Text(
              'PUZZLE WORLD',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: 5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'JOGUE • DESCUBRA • COLECIONE',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 2.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
