import 'package:flutter/widgets.dart';

class WorldCoinStrings {
  const WorldCoinStrings._(this._values);

  static const _pt = WorldCoinStrings._({
    'title': 'World Coins',
    'balance': 'Saldo',
    'explanation': 'Ganhe World Coins assistindo a anúncios recompensados.',
    'watch': 'ASSISTIR ANÚNCIO',
    'today': 'Hoje',
    'future':
        'Guarde World Coins para pacotes de cartas e futuros recursos da economia do Puzzle World.',
    'loading': 'CARREGANDO ANÚNCIO…',
    'processing': 'CONFIRMANDO RECOMPENSA…',
    'limit': 'LIMITE DIÁRIO ATINGIDO',
    'tomorrow': 'Volte amanhã para ganhar mais World Coins.',
    'unavailable':
        'Anúncio indisponível no momento. Tente novamente mais tarde.',
    'notEarned':
        'Assista ao anúncio até a confirmação para receber a recompensa.',
    'pending':
        'A confirmação está demorando. Seu saldo será sincronizado automaticamente.',
    'offline':
        'É necessário ter internet para assistir a anúncios recompensados.',
    'earned': '+1 World Coin',
    'close': 'Fechar',
  });

  static const _en = WorldCoinStrings._({
    'title': 'World Coins',
    'balance': 'Balance',
    'explanation': 'Earn World Coins by watching rewarded ads.',
    'watch': 'WATCH AD',
    'today': 'Today',
    'future':
        'Save World Coins for card packs and future Puzzle World economy features.',
    'loading': 'LOADING AD…',
    'processing': 'CONFIRMING REWARD…',
    'limit': 'DAILY LIMIT REACHED',
    'tomorrow': 'Come back tomorrow to earn more World Coins.',
    'unavailable': 'Ad currently unavailable. Please try again later.',
    'notEarned':
        'Watch until the reward is confirmed to receive your World Coin.',
    'pending':
        'Confirmation is taking longer than expected. Your balance will sync automatically.',
    'offline': 'Internet connection is required to watch rewarded ads.',
    'earned': '+1 World Coin',
    'close': 'Close',
  });

  final Map<String, String> _values;
  String operator [](String key) => _values[key]!;

  static WorldCoinStrings of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'pt' ? _pt : _en;
}
