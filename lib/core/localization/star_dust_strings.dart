import 'package:flutter/material.dart';

class StarDustStrings {
  const StarDustStrings._(this._values);

  static const _pt = StarDustStrings._({
    'title': 'Pó Estelar',
    'weeklyProgress': 'Progresso Semanal',
    'starsThisWeek': 'Estrelas coletadas esta semana',
    'stagesThisWeek': 'Fases concluídas esta semana',
    'nextReset': 'Próximo reset',
    'sunday': 'Domingo',
    'newWeeklyRecord': 'Novo recorde semanal!',
    'alreadyCollected': 'Recompensa semanal já coletada',
    'full': 'Pó Estelar cheio',
    'explanation':
        'Conclua fases com um bom desempenho para ganhar Pó Estelar. O Pó Estelar poderá ser trocado por itens mágicos no Mercado Semanal, disponível todos os domingos.',
  });

  static const _en = StarDustStrings._({
    'title': 'Star Dust',
    'weeklyProgress': 'Weekly Progress',
    'starsThisWeek': 'Stars collected this week',
    'stagesThisWeek': 'Stages completed this week',
    'nextReset': 'Next reset',
    'sunday': 'Sunday',
    'newWeeklyRecord': 'New weekly record!',
    'alreadyCollected': 'Weekly reward already collected',
    'full': 'Star Dust Full',
    'explanation':
        'Complete stages with good performance to earn Star Dust. Star Dust can be exchanged for magical items in the Weekly Market, available every Sunday.',
  });

  final Map<String, String> _values;

  static StarDustStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'pt' ? _pt : _en;

  String operator [](String key) => _values[key]!;
  bool get isPortuguese => identical(this, _pt);
  String earned(int amount) =>
      isPortuguese ? '+$amount Pó Estelar' : '+$amount Star Dust';
  String stars(int amount) =>
      isPortuguese ? '$amount estrelas' : '$amount stars';
  String stages(int amount) =>
      isPortuguese ? '$amount fases' : '$amount stages';
}
