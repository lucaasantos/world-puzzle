class WorldContinent {
  const WorldContinent._();

  static const africa = 'africa';
  static const northAmerica = 'north_america';
  static const southAmerica = 'south_america';
  static const asia = 'asia';
  static const europe = 'europe';
  static const oceania = 'oceania';

  static const all = [
    africa,
    northAmerica,
    southAmerica,
    asia,
    europe,
    oceania,
  ];
}

class AlbumCountry {
  const AlbumCountry({
    required this.id,
    required this.name,
    required this.code,
    required this.continent,
    required this.flag,
    required this.subtitle,
    required this.intro,
    required this.sortOrder,
    required this.isActive,
    required this.totalCards,
  });

  final String id;
  final String name;
  final String code;
  final String continent;
  final String flag;
  final String subtitle;
  final String intro;
  final int sortOrder;
  final bool isActive;
  final int totalCards;
}
