import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class JapanTheme {
  const JapanTheme._();

  static const cream = Color(0xFFFFEED3);
  static const ink = Color(0xFF542725);
  static const vermilion = Color(0xFFC84A3E);
  static const gold = Color(0xFFF1B16E);

  static bool matches(String themeId) => themeId == 'japan';

  static ThemeData apply(BuildContext context, JapanPalette palette) {
    final base = Theme.of(context);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: palette.accent,
        onPrimary: palette.panel,
        surface: palette.panel,
        onSurface: palette.text,
        outline: palette.accent.withValues(alpha: .72),
      ),
      scaffoldBackgroundColor: palette.backgroundBottom,
      textTheme: base.textTheme.apply(
        fontFamily: 'serif',
        bodyColor: palette.text,
        displayColor: palette.text,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: 'serif',
        bodyColor: palette.text,
        displayColor: palette.text,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.panel,
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'serif',
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.text,
          side: BorderSide(color: palette.accent.withValues(alpha: .8)),
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'serif',
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.text),
      ),
    );
  }
}

class JapanPalette {
  const JapanPalette({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.panel,
    required this.accent,
    required this.text,
    required this.headerText,
  });

  final Color backgroundTop;
  final Color backgroundBottom;
  final Color panel;
  final Color accent;
  final Color text;
  final Color headerText;

  static JapanPalette forLevel(int levelNumber) => switch (levelNumber) {
    1 => const JapanPalette(
      backgroundTop: Color(0xFFF3D9CB),
      backgroundBottom: Color(0xFF9E625D),
      panel: Color(0xFF542725),
      accent: Color(0xFFF1B16E),
      text: Color(0xFFFFEED3),
      headerText: Color(0xFF592725),
    ),
    2 => const JapanPalette(
      backgroundTop: Color(0xFF4A241D),
      backgroundBottom: Color(0xFF160B09),
      panel: Color(0xFF321713),
      accent: Color(0xFFE0664F),
      text: Color(0xFFFFE8C8),
      headerText: Color(0xFFFFE8C8),
    ),
    3 => const JapanPalette(
      backgroundTop: Color(0xFF633A24),
      backgroundBottom: Color(0xFF1B100B),
      panel: Color(0xFF3B2116),
      accent: Color(0xFFE19A52),
      text: Color(0xFFFFE9C9),
      headerText: Color(0xFFFFE9C9),
    ),
    _ => const JapanPalette(
      backgroundTop: Color(0xFF5A2226),
      backgroundBottom: Color(0xFF170A0D),
      panel: Color(0xFF3E171B),
      accent: Color(0xFFE36B63),
      text: Color(0xFFFFE7D0),
      headerText: Color(0xFFFFE7D0),
    ),
  };
}

class JapanBackdrop extends StatelessWidget {
  const JapanBackdrop({
    required this.imagePath,
    required this.palette,
    this.imageOpacity = .22,
    super.key,
  });

  final String imagePath;
  final JapanPalette palette;
  final double imageOpacity;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Transform.scale(
        scale: 1.16,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Opacity(
            opacity: imageOpacity,
            child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.backgroundTop.withValues(alpha: .88),
              palette.backgroundBottom.withValues(alpha: .97),
            ],
          ),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -.35),
            radius: .85,
            colors: [palette.accent.withValues(alpha: .12), Colors.transparent],
          ),
        ),
      ),
    ],
  );
}

class JapanPanel extends StatelessWidget {
  const JapanPanel({
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 10,
    super.key,
  });

  final JapanPalette palette;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: palette.panel.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: palette.accent.withValues(alpha: .5)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 18,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: child,
  );
}
