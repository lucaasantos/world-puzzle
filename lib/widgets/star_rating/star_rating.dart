import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  const StarRating({required this.stars, this.size = 18, super.key});
  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      3,
      (index) => Padding(
        padding: const EdgeInsets.only(right: 2),
        child: Icon(
          index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
          color: index < stars ? const Color(0xFFF4CD6A) : Colors.white24,
          size: size,
        ),
      ),
    ),
  );
}
