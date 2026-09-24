import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_controller.dart';
import 'app/app_scope.dart';
import 'core/theme/app_theme.dart';
import 'repositories/local_progress_repository.dart';
import 'screens/splash/splash_screen.dart';
import 'services/ads_service.dart';
import 'services/audio_service.dart';
import 'services/haptics_service.dart';
import 'services/storage_service.dart';
import 'services/wallpaper_service.dart';
import 'services/online_game_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  final controller = AppController(
    repository: LocalProgressRepository(
      storage,
      key: 'puzzle_world_online_preferences_v1',
    ),
    ads: AdsService(),
    audio: AudioService(),
    haptics: HapticsService(),
    wallpaper: GalleryWallpaperService(),
    online: OnlineGameService(),
  );
  runApp(PuzzleWorldApp(controller: controller));
}

class PuzzleWorldApp extends StatelessWidget {
  const PuzzleWorldApp({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) => AppScope(
    controller: controller,
    child: MaterialApp(
      title: 'Puzzle World',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
      home: const SplashScreen(),
    ),
  );
}
