import 'package:flutter/material.dart';

class WorldCoinIcon extends StatelessWidget {
  const WorldCoinIcon({this.size = 44, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/currency/world_coin.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    ),
  );
}
