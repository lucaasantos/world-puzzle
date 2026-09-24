import 'package:flutter/material.dart';

class DailyExplorationStrings {
  const DailyExplorationStrings._(this._values);

  static const _pt = DailyExplorationStrings._({
    'title': 'Exploração Diária',
    'objective': 'Complete uma fase em 4 países diferentes.',
    'higherDifficulty':
        'Concluir fases em níveis mais difíceis concede mais pontos.',
    'easy': 'Fácil',
    'medium': 'Médio',
    'hard': 'Difícil',
    'veryHard': 'Muito difícil',
    'difficulty': 'Dificuldade',
    'points': 'Pontos',
    'maximum': 'Máximo',
    'dailyScore': 'Pontuação da Exploração',
    'rewardProgress': 'Progresso da Recompensa',
    'currentRewardChances': 'Chances da Recompensa Atual',
    'rewardReady': 'Recompensa disponível',
    'continueImproving': 'Continue melhorando',
    'bestAlreadyRecorded': 'Melhor resultado já registrado',
    'readyToClaim': 'Pronto para resgatar',
    'claiming': 'Resgatando…',
    'openPacks': 'Abrir meus pacotes',
    'chancesAt40': 'Chances ao alcançar 40 pontos',
    'probabilities': 'probabilidades, não garantia',
    'rewardClaimed': 'Exploração concluída! Sua recompensa já foi resgatada.',
  });

  static const _en = DailyExplorationStrings._({
    'title': 'Daily Exploration',
    'objective': 'Complete one stage in 4 different countries.',
    'higherDifficulty':
        'Completing stages at higher difficulty levels awards more points.',
    'easy': 'Easy',
    'medium': 'Medium',
    'hard': 'Hard',
    'veryHard': 'Very hard',
    'difficulty': 'Difficulty',
    'points': 'Points',
    'maximum': 'Maximum',
    'dailyScore': 'Daily Score',
    'rewardProgress': 'Reward Progress',
    'currentRewardChances': 'Current Reward Chances',
    'rewardReady': 'Reward ready',
    'continueImproving': 'Continue improving',
    'bestAlreadyRecorded': 'Best result already recorded',
    'readyToClaim': 'Ready to claim',
    'claiming': 'Claiming…',
    'openPacks': 'Open my packs',
    'chancesAt40': 'Chances at 40 points',
    'probabilities': 'probabilities, not a guarantee',
    'rewardClaimed':
        'Exploration complete! Your reward has already been claimed.',
  });

  final Map<String, String> _values;

  static DailyExplorationStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'pt' ? _pt : _en;

  String operator [](String key) => _values[key]!;
  bool get isPortuguese => identical(this, _pt);

  String difficultyName(String? difficulty) => switch (difficulty) {
    'easy' => this['easy'],
    'medium' => this['medium'],
    'hard' => this['hard'],
    'veryHard' => this['veryHard'],
    _ => '—',
  };

  String countryName(String id, String fallback) {
    if (isPortuguese) return fallback;
    return const {
          'brazil': 'Brazil',
          'japan': 'Japan',
          'egypt': 'Egypt',
          'greece': 'Greece',
          'united_states': 'United States',
        }[id] ??
        fallback;
  }

  String packReceived(String name) => isPortuguese
      ? '$name recebido! Abra-o em Meus Pacotes.'
      : '$name received! Open it in My Packs.';
  String rewardTier(int milestone) => isPortuguese
      ? 'Faixa de $milestone pontos • ${this['probabilities']}'
      : '$milestone-point tier • ${this['probabilities']}';
  String objectiveStatus(int completed) => isPortuguese
      ? '$completed/4 países concluídos • A recompensa fica disponível aos 40 pontos.'
      : '$completed/4 countries complete • The reward becomes available at 40 points.';
  String get claimHint => isPortuguese
      ? '${this['rewardReady']} • ${this['continueImproving']} antes de resgatar para aumentar suas chances.'
      : '${this['rewardReady']} • ${this['continueImproving']} before claiming to improve your odds.';
  String resetIn(String time) =>
      isPortuguese ? 'Nova exploração em $time' : 'New exploration in $time';
  String previousClaim(String day) => isPortuguese
      ? 'Resgatar exploração anterior • $day'
      : 'Claim previous exploration • $day';
  String dailyFeedback(int points, int score) => isPortuguese
      ? '+$points pontos na Exploração Diária • $score/80'
      : '+$points Daily Exploration points • $score/80';
}
