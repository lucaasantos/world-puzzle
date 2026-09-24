enum GameModeKind { sliding, jigsaw, blocks }

class GameCountryConfig {
  const GameCountryConfig({
    required this.id,
    required this.name,
    required this.flag,
    required this.enabled,
    this.themeId,
    this.levelIds = const [],
  });

  final String id;
  final String name;
  final String flag;
  final bool enabled;
  final String? themeId;
  final List<String> levelIds;
}

class GameModeConfig {
  const GameModeConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.enabled,
    required this.countries,
  });

  final String id;
  final String name;
  final String description;
  final GameModeKind kind;
  final bool enabled;
  final List<GameCountryConfig> countries;
}
