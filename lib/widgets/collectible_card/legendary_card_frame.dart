import 'package:flutter/material.dart';

const String legendaryFrameAsset =
    'assets/images/cards/frames/legendary_frame.png';

/// Reusable Legendary layout. The frame is shared; every visible field and the
/// artwork are supplied by the card catalog at runtime.
class LegendaryCardFrame extends StatelessWidget {
  const LegendaryCardFrame({
    required this.artwork,
    required this.countryFlag,
    required this.countryName,
    required this.cardName,
    required this.categoryLabel,
    required this.description,
    required this.catalogNumber,
    required this.locked,
    super.key,
  });

  final Widget artwork;
  final String countryFlag;
  final String countryName;
  final String cardName;
  final String categoryLabel;
  final String description;
  final String catalogNumber;
  final bool locked;

  static const _gold = Color(0xFFFFD36D);
  static const _cream = Color(0xFFFFF0C7);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final scale = (width / 180).clamp(.35, 2.2);

      return DecoratedBox(
        key: const Key('legendary-card-frame'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8 * scale),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: locked ? .12 : .30),
              blurRadius: 14 * scale,
              spreadRadius: .5 * scale,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8 * scale),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                legendaryFrameAsset,
                key: const Key('legendary-frame-asset'),
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
              Positioned(
                left: width * .065,
                right: width * .065,
                top: height * .119,
                height: height * .540,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11 * scale),
                    border: Border.all(color: _gold, width: 1.5 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .45),
                        blurRadius: 3 * scale,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    key: const Key('legendary-card-artwork'),
                    borderRadius: BorderRadius.circular(9.5 * scale),
                    child: artwork,
                  ),
                ),
              ),
              Positioned(
                left: width * .125,
                right: width * .125,
                top: height * .042,
                height: height * .058,
                child: _FittedLegendaryText(
                  text: cardName,
                  fontSize: 18 * scale,
                  locked: locked,
                  key: const Key('legendary-card-name'),
                ),
              ),
              Positioned(
                left: width * .315,
                right: width * .315,
                top: height * .675,
                height: height * .038,
                child: _FittedLegendaryText(
                  text: categoryLabel.toUpperCase(),
                  fontSize: 10 * scale,
                  locked: locked,
                  key: const Key('legendary-card-category'),
                ),
              ),
              Positioned(
                left: width * .105,
                right: width * .105,
                top: height * .735,
                height: height * .132,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$countryFlag  |  $countryName  |  $catalogNumber',
                        key: const Key('legendary-card-metadata'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: locked ? _gold.withValues(alpha: .50) : _gold,
                          fontSize: 5.6 * scale,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3 * scale),
                      Text(
                        'Descrição:',
                        style: TextStyle(
                          color: locked
                              ? _cream.withValues(alpha: .48)
                              : _cream.withValues(alpha: .82),
                          fontSize: 5.7 * scale,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        description,
                        key: const Key('legendary-card-description'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: locked
                              ? _cream.withValues(alpha: .55)
                              : _cream,
                          fontFamily: 'serif',
                          fontSize: 7.2 * scale,
                          height: 1.10,
                          fontWeight: FontWeight.w600,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: width * .34,
                right: width * .34,
                top: height * .923,
                height: height * .032,
                child: _FittedLegendaryText(
                  text: 'LENDÁRIA',
                  fontSize: 9.5 * scale,
                  locked: locked,
                  key: const Key('legendary-card-rarity'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _FittedLegendaryText extends StatelessWidget {
  const _FittedLegendaryText({
    required this.text,
    required this.fontSize,
    required this.locked,
    super.key,
  });

  final String text;
  final double fontSize;
  final bool locked;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      text,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: locked
            ? LegendaryCardFrame._cream.withValues(alpha: .55)
            : LegendaryCardFrame._cream,
        fontFamily: 'serif',
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: .35,
        shadows: const [
          Shadow(color: Color(0xFF7A3100), offset: Offset(0, 1), blurRadius: 1),
          Shadow(color: Colors.black, blurRadius: 3),
        ],
      ),
    ),
  );
}
