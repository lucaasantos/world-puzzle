import 'package:flutter/material.dart';

const String rareFrameAsset = 'assets/images/cards/frames/rare_frame.png';

/// Reusable electric-blue layout for every Rare card in the catalog.
class RareCardFrame extends StatelessWidget {
  const RareCardFrame({
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

  static const _blue = Color(0xFF46C7FF);
  static const _ice = Color(0xFFE8F8FF);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final scale = (width / 180).clamp(.35, 2.2);

      return DecoratedBox(
        key: const Key('rare-card-frame'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8 * scale),
          boxShadow: [
            BoxShadow(
              color: _blue.withValues(alpha: locked ? .08 : .19),
              blurRadius: 10 * scale,
              spreadRadius: .25 * scale,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8 * scale),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                rareFrameAsset,
                key: const Key('rare-frame-asset'),
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
                    border: Border.all(color: _blue, width: 1.35 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .42),
                        blurRadius: 2.5 * scale,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    key: const Key('rare-card-artwork'),
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
                child: _FittedRareText(
                  text: cardName,
                  fontSize: 18 * scale,
                  locked: locked,
                  key: const Key('rare-card-name'),
                ),
              ),
              Positioned(
                left: width * .315,
                right: width * .315,
                top: height * .675,
                height: height * .038,
                child: _FittedRareText(
                  text: categoryLabel.toUpperCase(),
                  fontSize: 10 * scale,
                  locked: locked,
                  key: const Key('rare-card-category'),
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
                        key: const Key('rare-card-metadata'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: locked ? _blue.withValues(alpha: .46) : _blue,
                          fontSize: 5.2 * scale,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 1.5 * scale),
                      Text(
                        'Descrição:',
                        style: TextStyle(
                          color: locked
                              ? _ice.withValues(alpha: .44)
                              : _ice.withValues(alpha: .78),
                          fontSize: 5.2 * scale,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 1 * scale),
                      Expanded(
                        child: _AdaptiveRareDescription(
                          description: description,
                          scale: scale,
                          locked: locked,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: width * .365,
                right: width * .365,
                top: height * .923,
                height: height * .032,
                child: _FittedRareText(
                  text: 'RARA',
                  fontSize: 9.5 * scale,
                  locked: locked,
                  key: const Key('rare-card-rarity'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AdaptiveRareDescription extends StatelessWidget {
  const _AdaptiveRareDescription({
    required this.description,
    required this.scale,
    required this.locked,
  });

  final String description;
  final double scale;
  final bool locked;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final baseStyle = TextStyle(
        color: locked
            ? RareCardFrame._ice.withValues(alpha: .52)
            : RareCardFrame._ice,
        fontFamily: 'serif',
        height: 1.02,
        fontWeight: FontWeight.w600,
        shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
      );
      final textDirection = Directionality.of(context);
      final textScaler = MediaQuery.textScalerOf(context);
      var minimum = 4.2 * scale;
      var maximum = 6 * scale;

      // Keep the regular size whenever it fits and reduce it only for longer
      // descriptions. Four lines at the minimum size cover the current
      // catalog without clipping or adding an ellipsis.
      for (var attempt = 0; attempt < 8; attempt++) {
        final candidate = (minimum + maximum) / 2;
        final painter = TextPainter(
          text: TextSpan(
            text: description,
            style: baseStyle.copyWith(fontSize: candidate),
          ),
          maxLines: 4,
          textDirection: textDirection,
          textScaler: textScaler,
        )..layout(maxWidth: constraints.maxWidth);
        final fits =
            !painter.didExceedMaxLines &&
            painter.height <= constraints.maxHeight;
        if (fits) {
          minimum = candidate;
        } else {
          maximum = candidate;
        }
      }

      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          description,
          key: const Key('rare-card-description'),
          maxLines: 4,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.left,
          style: baseStyle.copyWith(fontSize: minimum),
        ),
      );
    },
  );
}

class _FittedRareText extends StatelessWidget {
  const _FittedRareText({
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
            ? RareCardFrame._ice.withValues(alpha: .52)
            : RareCardFrame._ice,
        fontFamily: 'serif',
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: .35,
        shadows: const [
          Shadow(color: Color(0xFF003A67), offset: Offset(0, 1), blurRadius: 1),
          Shadow(color: Colors.black, blurRadius: 2.5),
        ],
      ),
    ),
  );
}
