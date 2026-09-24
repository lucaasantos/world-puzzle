import '../../models/album_country.dart';
import '../../models/collectible_card.dart';

String continentLabel(String value) => switch (value) {
  WorldContinent.africa => 'África',
  WorldContinent.northAmerica => 'América do Norte',
  WorldContinent.southAmerica => 'América do Sul',
  WorldContinent.asia => 'Ásia',
  WorldContinent.europe => 'Europa',
  WorldContinent.oceania => 'Oceania',
  _ => value,
};

String rarityLabel(String value) => switch (value) {
  CardRarity.common => 'Comum',
  CardRarity.rare => 'Rara',
  CardRarity.epic => 'Épica',
  CardRarity.legendary => 'Lendária',
  _ => value,
};

String categoryLabel(String value) => switch (value) {
  CardCategory.city => 'Cidade',
  CardCategory.flag => 'Bandeira',
  CardCategory.currency => 'Moeda',
  CardCategory.animal => 'Animal',
  CardCategory.nature => 'Natureza',
  CardCategory.landmark => 'Monumento',
  CardCategory.culture => 'Cultura',
  CardCategory.food => 'Comida',
  CardCategory.historical => 'Histórica',
  CardCategory.person => 'Personalidade',
  CardCategory.mythology => 'Mitologia',
  CardCategory.special => 'Especial',
  _ => value,
};
