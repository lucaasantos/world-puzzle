import '../models/game_mode.dart';

const _japanSlidingLevels = ['japan_01', 'japan_02', 'japan_03', 'japan_04'];
const _unitedStatesSlidingLevels = [
  'united_states_01',
  'united_states_02',
  'united_states_03',
  'united_states_04',
];
const _unitedStatesJigsawLevels = [
  'jigsaw_united_states_easy',
  'jigsaw_united_states_medium',
  'jigsaw_united_states_hard',
  'jigsaw_united_states_veryHard',
];
const _unitedStatesBlocksLevels = [
  'blocks_united_states_easy',
  'blocks_united_states_medium',
  'blocks_united_states_hard',
  'blocks_united_states_veryHard',
];
const _egyptSlidingLevels = ['egypt_01', 'egypt_02', 'egypt_03', 'egypt_04'];
const _egyptJigsawLevels = [
  'jigsaw_egypt_easy',
  'jigsaw_egypt_medium',
  'jigsaw_egypt_hard',
  'jigsaw_egypt_veryHard',
];
const _egyptBlocksLevels = [
  'blocks_egypt_easy',
  'blocks_egypt_medium',
  'blocks_egypt_hard',
  'blocks_egypt_veryHard',
];
const _brazilSlidingLevels = [
  'brazil_01',
  'brazil_02',
  'brazil_03',
  'brazil_04',
];
const _brazilJigsawLevels = [
  'jigsaw_brazil_easy',
  'jigsaw_brazil_medium',
  'jigsaw_brazil_hard',
  'jigsaw_brazil_veryHard',
];
const _brazilBlocksLevels = [
  'blocks_brazil_easy',
  'blocks_brazil_medium',
  'blocks_brazil_hard',
  'blocks_brazil_veryHard',
];
const _japanJigsawLevels = [
  'jigsaw_japan_easy',
  'jigsaw_japan_medium',
  'jigsaw_japan_hard',
  'jigsaw_japan_veryHard',
];
const _japanBlocksLevels = [
  'blocks_japan_easy',
  'blocks_japan_medium',
  'blocks_japan_hard',
  'blocks_japan_veryHard',
];

const dailyExplorationCountryIds = [
  'brazil',
  'japan',
  'united_states',
  'egypt',
];

List<GameCountryConfig> _countriesFor(GameModeKind kind) => [
  GameCountryConfig(
    id: 'brazil',
    name: 'Brasil',
    flag: '🇧🇷',
    enabled: true,
    themeId: 'brazil',
    levelIds: kind == GameModeKind.sliding
        ? _brazilSlidingLevels
        : kind == GameModeKind.jigsaw
        ? _brazilJigsawLevels
        : _brazilBlocksLevels,
  ),
  GameCountryConfig(
    id: 'japan',
    name: 'Japão',
    flag: '🇯🇵',
    enabled: true,
    themeId: 'japan',
    levelIds: kind == GameModeKind.sliding
        ? _japanSlidingLevels
        : kind == GameModeKind.jigsaw
        ? _japanJigsawLevels
        : _japanBlocksLevels,
  ),
  GameCountryConfig(
    id: 'united_states',
    name: 'Estados Unidos',
    flag: '🇺🇸',
    enabled: true,
    themeId: 'united_states',
    levelIds: kind == GameModeKind.sliding
        ? _unitedStatesSlidingLevels
        : kind == GameModeKind.jigsaw
        ? _unitedStatesJigsawLevels
        : _unitedStatesBlocksLevels,
  ),
  GameCountryConfig(
    id: 'egypt',
    name: 'Egito',
    flag: '🇪🇬',
    enabled: true,
    themeId: 'egypt',
    levelIds: kind == GameModeKind.sliding
        ? _egyptSlidingLevels
        : kind == GameModeKind.jigsaw
        ? _egyptJigsawLevels
        : _egyptBlocksLevels,
  ),
];

final gameModes = <GameModeConfig>[
  GameModeConfig(
    id: 'sliding',
    name: 'Puzzle Deslizante',
    description: 'Deslize as peças e revele o destino',
    kind: GameModeKind.sliding,
    enabled: true,
    countries: _countriesFor(GameModeKind.sliding),
  ),
  GameModeConfig(
    id: 'jigsaw',
    name: 'Quebra-Cabeças',
    description: 'Encaixe as peças da sua viagem',
    kind: GameModeKind.jigsaw,
    enabled: true,
    countries: _countriesFor(GameModeKind.jigsaw),
  ),
  GameModeConfig(
    id: 'blocks',
    name: 'Blocos',
    description: 'Organize blocos e complete o mapa',
    kind: GameModeKind.blocks,
    enabled: true,
    countries: _countriesFor(GameModeKind.blocks),
  ),
];
