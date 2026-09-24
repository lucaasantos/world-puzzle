import 'package:flutter/material.dart';

class CollectionProgressBar extends StatelessWidget {
  const CollectionProgressBar({required this.value, this.color, super.key});
  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: LinearProgressIndicator(
      value: value,
      minHeight: 5,
      color: color ?? Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.white12,
    ),
  );
}
