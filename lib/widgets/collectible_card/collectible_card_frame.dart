import 'package:flutter/material.dart';

const double collectibleCardCornerRadius = 3;

/// Standard frame shared by every collectible card.
///
/// Keep structural and visual changes in this widget so the full catalog is
/// updated at once. Card-specific artwork and labels are supplied dynamically.
class CollectibleCardFrame extends StatelessWidget {
  const CollectibleCardFrame({
    required this.artwork,
    required this.countryFlag,
    required this.countryName,
    required this.cardName,
    required this.rarityLabel,
    required this.rarityAccent,
    required this.categoryLabel,
    required this.categoryIcon,
    required this.catalogNumber,
    required this.stateLabel,
    required this.stateColor,
    required this.locked,
    required this.emphasized,
    this.quantity,
    super.key,
  });

  final Widget artwork;
  final String countryFlag;
  final String countryName;
  final String cardName;
  final String rarityLabel;
  final Color rarityAccent;
  final String categoryLabel;
  final IconData categoryIcon;
  final String catalogNumber;
  final String stateLabel;
  final Color stateColor;
  final bool locked;
  final bool emphasized;
  final int? quantity;

  static const _navy = Color(0xFF071E34);
  static const _navyDeep = Color(0xFF041322);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = (constraints.maxWidth / 180).clamp(.72, 2.2);
      final outerRadius = collectibleCardCornerRadius * scale;

      return DecoratedBox(
        key: const Key('collectible-card-frame'),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_navy, _navyDeep],
          ),
          borderRadius: BorderRadius.circular(outerRadius),
          border: Border.all(
            color: rarityAccent,
            width: (emphasized ? 2.2 : 1.9) * scale,
          ),
          boxShadow: [
            BoxShadow(
              color: rarityAccent.withValues(alpha: emphasized ? .18 : .10),
              blurRadius: (emphasized ? 14 : 8) * scale,
              spreadRadius: (emphasized ? .5 : .2) * scale,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            (collectibleCardCornerRadius - 1.5) * scale,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 35 * scale,
                child: _Header(
                  countryFlag: countryFlag,
                  countryName: countryName,
                  rarityLabel: rarityLabel,
                  rarityAccent: rarityAccent,
                  quantity: quantity,
                  locked: locked,
                  scale: scale,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                  child: ClipRect(
                    key: const Key('collectible-card-artwork'),
                    child: artwork,
                  ),
                ),
              ),
              SizedBox(
                height: 49 * scale,
                child: _Footer(
                  cardName: cardName,
                  categoryLabel: categoryLabel,
                  categoryIcon: categoryIcon,
                  catalogNumber: catalogNumber,
                  stateLabel: stateLabel,
                  stateColor: stateColor,
                  rarityAccent: rarityAccent,
                  locked: locked,
                  scale: scale,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.countryFlag,
    required this.countryName,
    required this.rarityLabel,
    required this.rarityAccent,
    required this.quantity,
    required this.locked,
    required this.scale,
  });

  final String countryFlag;
  final String countryName;
  final String rarityLabel;
  final Color rarityAccent;
  final int? quantity;
  final bool locked;
  final double scale;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 9 * scale, vertical: 6 * scale),
    child: Row(
      children: [
        Text(countryFlag, style: TextStyle(fontSize: 16 * scale)),
        SizedBox(width: 5 * scale),
        Expanded(
          child: Text(
            countryName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: locked ? Colors.white38 : Colors.white,
              fontSize: 9.5 * scale,
              fontWeight: FontWeight.w900,
              letterSpacing: .45 * scale,
            ),
          ),
        ),
        if (quantity != null) ...[
          _CompactLabel(
            label: '×$quantity',
            foreground: Colors.white,
            borderColor: Colors.white24,
            scale: scale,
          ),
          SizedBox(width: 5 * scale),
        ],
        _CompactLabel(
          label: rarityLabel.toUpperCase(),
          foreground: locked ? Colors.white38 : rarityAccent,
          borderColor: locked ? Colors.white12 : rarityAccent,
          scale: scale,
        ),
      ],
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.cardName,
    required this.categoryLabel,
    required this.categoryIcon,
    required this.catalogNumber,
    required this.stateLabel,
    required this.stateColor,
    required this.rarityAccent,
    required this.locked,
    required this.scale,
  });

  final String cardName;
  final String categoryLabel;
  final IconData categoryIcon;
  final String catalogNumber;
  final String stateLabel;
  final Color stateColor;
  final Color rarityAccent;
  final bool locked;
  final double scale;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(9 * scale, 5 * scale, 9 * scale, 6 * scale),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              cardName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: locked ? Colors.white54 : Colors.white,
                fontSize: 13 * scale,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: .2 * scale,
              ),
            ),
          ),
        ),
        SizedBox(height: 3 * scale),
        Row(
          children: [
            Icon(
              categoryIcon,
              size: 10 * scale,
              color: locked ? Colors.white38 : Colors.white70,
            ),
            SizedBox(width: 3 * scale),
            Flexible(
              child: Text(
                categoryLabel.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: locked ? Colors.white38 : Colors.white70,
                  fontSize: 7.5 * scale,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .35 * scale,
                ),
              ),
            ),
            SizedBox(width: 5 * scale),
            _CompactLabel(
              label: stateLabel,
              foreground: locked ? Colors.white38 : stateColor,
              borderColor: locked ? Colors.white12 : stateColor,
              scale: scale,
            ),
            SizedBox(width: 5 * scale),
            Text(
              catalogNumber,
              style: TextStyle(
                color: locked ? Colors.white38 : rarityAccent,
                fontSize: 7.5 * scale,
                fontWeight: FontWeight.w900,
                letterSpacing: .2 * scale,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CompactLabel extends StatelessWidget {
  const _CompactLabel({
    required this.label,
    required this.foreground,
    required this.borderColor,
    required this.scale,
  });

  final String label;
  final Color foreground;
  final Color borderColor;
  final double scale;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 5 * scale, vertical: 2 * scale),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .045),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: borderColor.withValues(alpha: .55)),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: TextStyle(
        color: foreground,
        fontSize: 6.8 * scale,
        height: 1,
        fontWeight: FontWeight.w900,
        letterSpacing: .2 * scale,
      ),
    ),
  );
}
