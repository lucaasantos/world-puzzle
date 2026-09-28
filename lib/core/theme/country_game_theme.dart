import 'package:flutter/material.dart';

/// Visual tokens shared by country-aware game screens.
class CountryGameTheme {
  const CountryGameTheme({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.surface,
    required this.board,
    required this.blockPalette,
  });

  final Color backgroundTop;
  final Color backgroundBottom;
  final Color surface;
  final Color board;
  final List<Color> blockPalette;

  static CountryGameTheme forCountry(String countryId, Color accent) =>
      _themes[countryId] ??
      CountryGameTheme(
        backgroundTop: Color.lerp(accent, Colors.black, .48)!,
        backgroundBottom: Color.lerp(accent, Colors.black, .78)!,
        surface: Color.lerp(accent, Colors.black, .64)!,
        board: const Color(0xFF10242A),
        blockPalette: [
          accent,
          Color.lerp(accent, const Color(0xFFFFD54F), .42)!,
          Color.lerp(accent, const Color(0xFF42A5F5), .42)!,
          Color.lerp(accent, const Color(0xFFEF5350), .42)!,
          Color.lerp(accent, const Color(0xFFAB47BC), .36)!,
          Color.lerp(accent, const Color(0xFF26A69A), .38)!,
          Color.lerp(accent, const Color(0xFFFF8A65), .38)!,
        ],
      );
}

const _themes = <String, CountryGameTheme>{
  'brazil': CountryGameTheme(
    backgroundTop: Color(0xFF174F35),
    backgroundBottom: Color(0xFF092A32),
    surface: Color(0xE01B4B3C),
    board: Color(0xFF092B35),
    blockPalette: [
      Color(0xFF22A447),
      Color(0xFFF2C230),
      Color(0xFF2468B4),
      Color(0xFF58B957),
      Color(0xFFE39B23),
      Color(0xFF2E8BB8),
      Color(0xFF6EBD45),
    ],
  ),
  'japan': CountryGameTheme(
    backgroundTop: Color(0xFF5A2025),
    backgroundBottom: Color(0xFF25141D),
    surface: Color(0xE048242B),
    board: Color(0xFF211820),
    blockPalette: [
      Color(0xFFD94B4B),
      Color(0xFFF0A3A8),
      Color(0xFF8C3D5C),
      Color(0xFFE4776F),
      Color(0xFFB88B59),
      Color(0xFF5D7891),
      Color(0xFF7D9B75),
    ],
  ),
  'united_states': CountryGameTheme(
    backgroundTop: Color(0xFF183D68),
    backgroundBottom: Color(0xFF151F3A),
    surface: Color(0xE0223858),
    board: Color(0xFF101D35),
    blockPalette: [
      Color(0xFF2D6DB2),
      Color(0xFFC83E45),
      Color(0xFFE5D9B6),
      Color(0xFF4C88C5),
      Color(0xFFA92F3B),
      Color(0xFF7387A1),
      Color(0xFFD69B42),
    ],
  ),
  'egypt': CountryGameTheme(
    backgroundTop: Color(0xFF73541F),
    backgroundBottom: Color(0xFF282617),
    surface: Color(0xE05B4725),
    board: Color(0xFF25251B),
    blockPalette: [
      Color(0xFFD7A83D),
      Color(0xFF2B9B91),
      Color(0xFFB95B38),
      Color(0xFFE0C06A),
      Color(0xFF467D8D),
      Color(0xFF8A6B32),
      Color(0xFF6D8C52),
    ],
  ),
  'greece': CountryGameTheme(
    backgroundTop: Color(0xFF25628A),
    backgroundBottom: Color(0xFF17354D),
    surface: Color(0xE02A5873),
    board: Color(0xFF102B3B),
    blockPalette: [
      Color(0xFF2F7EB5),
      Color(0xFFE8DDBD),
      Color(0xFF54A4C7),
      Color(0xFF3569A0),
      Color(0xFFCF9F48),
      Color(0xFF4A8B79),
      Color(0xFF8B79A8),
    ],
  ),
};
