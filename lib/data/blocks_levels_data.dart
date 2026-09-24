import '../config/blocks_config.dart';
import '../models/blocks_level.dart';

const blocksLevels = <BlocksLevel>[
  BlocksLevel(
    countryId: 'brazil',
    difficulty: BlocksDifficulty.easy,
    imagePath: 'assets/images/themes/brazil/brazil_01.webp',
  ),
  BlocksLevel(
    countryId: 'brazil',
    difficulty: BlocksDifficulty.medium,
    imagePath: 'assets/images/themes/brazil/brazil_02.webp',
  ),
  BlocksLevel(
    countryId: 'brazil',
    difficulty: BlocksDifficulty.hard,
    imagePath: 'assets/images/themes/brazil/brazil_03.webp',
  ),
  BlocksLevel(
    countryId: 'brazil',
    difficulty: BlocksDifficulty.veryHard,
    imagePath: 'assets/images/themes/brazil/brazil_04.webp',
  ),
  BlocksLevel(
    countryId: 'japan',
    difficulty: BlocksDifficulty.easy,
    imagePath: 'assets/images/themes/japan/japan_01.webp',
  ),
  BlocksLevel(
    countryId: 'japan',
    difficulty: BlocksDifficulty.medium,
    imagePath: 'assets/images/themes/japan/japan_02.webp',
  ),
  BlocksLevel(
    countryId: 'japan',
    difficulty: BlocksDifficulty.hard,
    imagePath: 'assets/images/themes/japan/japan_03.webp',
  ),
  BlocksLevel(
    countryId: 'japan',
    difficulty: BlocksDifficulty.veryHard,
    imagePath: 'assets/images/themes/japan/japan_04.webp',
  ),
  BlocksLevel(
    countryId: 'united_states',
    difficulty: BlocksDifficulty.easy,
    imagePath: 'assets/images/themes/united_states/united_states_01.webp',
  ),
  BlocksLevel(
    countryId: 'united_states',
    difficulty: BlocksDifficulty.medium,
    imagePath: 'assets/images/themes/united_states/united_states_02.webp',
  ),
  BlocksLevel(
    countryId: 'united_states',
    difficulty: BlocksDifficulty.hard,
    imagePath: 'assets/images/themes/united_states/united_states_03.webp',
  ),
  BlocksLevel(
    countryId: 'united_states',
    difficulty: BlocksDifficulty.veryHard,
    imagePath: 'assets/images/themes/united_states/united_states_04.webp',
  ),
  BlocksLevel(
    countryId: 'egypt',
    difficulty: BlocksDifficulty.easy,
    imagePath: 'assets/images/themes/egypt/egypt_01.webp',
  ),
  BlocksLevel(
    countryId: 'egypt',
    difficulty: BlocksDifficulty.medium,
    imagePath: 'assets/images/themes/egypt/egypt_02.webp',
  ),
  BlocksLevel(
    countryId: 'egypt',
    difficulty: BlocksDifficulty.hard,
    imagePath: 'assets/images/themes/egypt/egypt_03.webp',
  ),
  BlocksLevel(
    countryId: 'egypt',
    difficulty: BlocksDifficulty.veryHard,
    imagePath: 'assets/images/themes/egypt/egypt_04.webp',
  ),
];

List<BlocksLevel> blocksLevelsFor(String countryId) => blocksLevels
    .where((level) => level.countryId == countryId)
    .toList(growable: false);
