import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../data/cards_data.dart';
import '../../models/album_country.dart';
import '../../models/collectible_card.dart';
import '../../widgets/collectible_card/collectible_card_tile.dart';
import 'card_detail_screen.dart';

class BookAlbumScreen extends StatefulWidget {
  const BookAlbumScreen({required this.initialCountry, super.key});

  final AlbumCountry initialCountry;

  @override
  State<BookAlbumScreen> createState() => _BookAlbumScreenState();
}

class _BookAlbumScreenState extends State<BookAlbumScreen> {
  static const _cardsPerSpread = 20;
  static const _pageTurnDuration = Duration(milliseconds: 680);

  late final List<_BookSheet> _sheets;
  late int _sheetIndex;
  int _turnDirection = 1;
  bool _turning = false;

  @override
  void initState() {
    super.initState();
    _sheets = _buildSheets();
    _sheetIndex = math.max(
      0,
      _sheets.indexWhere(
        (sheet) => sheet.country.id == widget.initialCountry.id,
      ),
    );
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
  }

  List<_BookSheet> _buildSheets() {
    final sheets = <_BookSheet>[];
    for (
      var countryIndex = 0;
      countryIndex < albumCountries.length;
      countryIndex++
    ) {
      final country = albumCountries[countryIndex];
      final cards = CardCatalog.cardsForCountry(country.id);
      final sheetCount = (cards.length / _cardsPerSpread).ceil();
      for (var sheetIndex = 0; sheetIndex < sheetCount; sheetIndex++) {
        final start = sheetIndex * _cardsPerSpread;
        final end = math.min(start + _cardsPerSpread, cards.length);
        sheets.add(
          _BookSheet(
            country: country,
            countryIndex: countryIndex,
            sheetIndex: sheetIndex,
            sheetCount: sheetCount,
            cards: cards.sublist(start, end),
          ),
        );
      }
    }
    return sheets;
  }

  @override
  void dispose() {
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]),
    );
    super.dispose();
  }

  Future<void> _openCard(CollectibleCard card) async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => CardDetailScreen(card: card)),
    );
    if (!mounted) return;
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _chooseCountry() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFF5E6C5),
        title: const Text(
          'Abrir capítulo',
          style: TextStyle(
            color: Color(0xFF3D2B21),
            fontFamily: 'serif',
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SizedBox(
          width: 560,
          height: 250,
          child: GridView.builder(
            itemCount: albumCountries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.45,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final country = albumCountries[index];
              final selectedCountry =
                  index == _sheets[_sheetIndex].countryIndex;
              return Material(
                color: selectedCountry
                    ? const Color(0xFFD7B87D)
                    : const Color(0xFFFFF3D7),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => Navigator.pop(dialogContext, index),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    child: Row(
                      children: [
                        Text(
                          country.flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            country.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF473328),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    final targetSheet = _sheets.indexWhere(
      (sheet) => sheet.countryIndex == selected,
    );
    await _goToSheet(targetSheet);
  }

  Future<void> _goToSheet(int target) async {
    if (_turning || target == _sheetIndex) return;
    setState(() {
      _turnDirection = target > _sheetIndex ? 1 : -1;
      _sheetIndex = target;
      _turning = true;
    });
    await Future<void>.delayed(_pageTurnDuration);
    if (mounted) setState(() => _turning = false);
  }

  void _turnPage(int direction) {
    final next = (_sheetIndex + direction).clamp(0, _sheets.length - 1);
    unawaited(_goToSheet(next));
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final currentSheet = _sheets[_sheetIndex];
    final currentCountry = currentSheet.country;
    final progress = controller.countryAlbumProgress(currentCountry.id);
    final spread = _BookSpread(
      key: ValueKey('book-sheet-$_sheetIndex'),
      country: currentCountry,
      chapter: currentSheet.countryIndex + 1,
      sheetIndex: currentSheet.sheetIndex,
      sheetCount: currentSheet.sheetCount,
      cards: currentSheet.cards,
      pasted: progress.pasted,
      total: progress.total,
      fraction: progress.fraction,
      stateFor: (card) {
        final inventory = controller.inventoryFor(card.id);
        if (inventory.pastedInAlbum) return AlbumCardState.pasted;
        if (inventory.quantity > 0) return AlbumCardState.inCollection;
        return AlbumCardState.notOwned;
      },
      onCard: _openCard,
    );

    return Scaffold(
      key: const Key('book-album-screen'),
      backgroundColor: const Color(0xFF160E0B),
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: const Color(0xFF2B1913),
        leading: IconButton(
          tooltip: 'Voltar ao catálogo',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.grid_view_rounded),
        ),
        titleSpacing: 0,
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, size: 20, color: Color(0xFFE3C58D)),
            SizedBox(width: 8),
            Text(
              'MODO LIVRO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            key: const Key('book-country-picker'),
            onPressed: _chooseCountry,
            icon: Text(currentCountry.flag),
            label: Text(
              currentCountry.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFE7B9),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 8, 30, 22),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4D291F),
                      Color(0xFF2C1712),
                      Color(0xFF4D291F),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFF9B6844), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity < -180) _turnPage(1);
                      if (velocity > 180) _turnPage(-1);
                    },
                    child: AnimatedSwitcher(
                      duration: _pageTurnDuration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        fit: StackFit.expand,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      ),
                      transitionBuilder: (child, animation) {
                        final incoming = child.key == spread.key;
                        return AnimatedBuilder(
                          animation: animation,
                          child: child,
                          builder: (context, animatedChild) {
                            final animationProgress = animation.value;
                            final sign = incoming
                                ? _turnDirection.toDouble()
                                : -_turnDirection.toDouble();
                            final angle =
                                (1 - animationProgress) * sign * math.pi / 2.15;
                            return Transform(
                              alignment: sign > 0
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, .0018)
                                ..rotateY(angle),
                              child: Opacity(
                                opacity: (.35 + animationProgress * .65).clamp(
                                  0.0,
                                  1.0,
                                ),
                                child: animatedChild,
                              ),
                            );
                          },
                        );
                      },
                      child: spread,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_sheetIndex > 0)
            Positioned(
              left: 7,
              top: 0,
              bottom: 0,
              child: Center(
                child: _PageTurnButton(
                  key: const Key('book-previous-page'),
                  tooltip: 'Folha anterior',
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => _turnPage(-1),
                ),
              ),
            ),
          if (_sheetIndex < _sheets.length - 1)
            Positioned(
              right: 7,
              top: 0,
              bottom: 0,
              child: Center(
                child: _PageTurnButton(
                  key: const Key('book-next-page'),
                  tooltip: 'Próxima folha',
                  icon: Icons.chevron_right_rounded,
                  onPressed: () => _turnPage(1),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 5,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC2B1913),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'CAP. ${currentSheet.countryIndex + 1}/${albumCountries.length}'
                    '  •  FOLHA ${currentSheet.sheetIndex + 1}/${currentSheet.sheetCount}'
                    '  •  deslize para virar',
                    style: const TextStyle(
                      color: Color(0xFFE5CDA0),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookSheet {
  const _BookSheet({
    required this.country,
    required this.countryIndex,
    required this.sheetIndex,
    required this.sheetCount,
    required this.cards,
  });

  final AlbumCountry country;
  final int countryIndex;
  final int sheetIndex;
  final int sheetCount;
  final List<CollectibleCard> cards;
}

class _PageTurnButton extends StatelessWidget {
  const _PageTurnButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filled(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xDD5F3528),
      foregroundColor: const Color(0xFFFFE2AC),
      side: const BorderSide(color: Color(0xFFB27A4A)),
    ),
    icon: Icon(icon),
  );
}

class _BookSpread extends StatelessWidget {
  const _BookSpread({
    required this.country,
    required this.chapter,
    required this.sheetIndex,
    required this.sheetCount,
    required this.cards,
    required this.pasted,
    required this.total,
    required this.fraction,
    required this.stateFor,
    required this.onCard,
    super.key,
  });

  final AlbumCountry country;
  final int chapter;
  final int sheetIndex;
  final int sheetCount;
  final List<CollectibleCard> cards;
  final int pasted;
  final int total;
  final double fraction;
  final AlbumCardState Function(CollectibleCard card) stateFor;
  final ValueChanged<CollectibleCard> onCard;

  @override
  Widget build(BuildContext context) {
    final leftCards = cards.take(10).toList(growable: false);
    final rightCards = cards.skip(10).toList(growable: false);

    return Stack(
      key: Key('country-book-page-${country.id}-${sheetIndex + 1}'),
      fit: StackFit.expand,
      children: [
        Row(
          children: [
            Expanded(
              child: _PaperPage(
                edge: Alignment.centerRight,
                child: Column(
                  children: [
                    _BookCountryHeader(
                      country: country,
                      chapter: chapter,
                      pasted: pasted,
                      total: total,
                      fraction: fraction,
                    ),
                    Expanded(
                      child: _BookCardsGrid(
                        cards: leftCards,
                        stateFor: stateFor,
                        onCard: onCard,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _PaperPage(
                edge: Alignment.centerLeft,
                child: Column(
                  children: [
                    _BookRightHeader(
                      country: country,
                      sheetIndex: sheetIndex,
                      sheetCount: sheetCount,
                    ),
                    Expanded(
                      child: _BookCardsGrid(
                        cards: rightCards,
                        stateFor: stateFor,
                        onCard: onCard,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: 13,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x00604A35),
                      Color(0x66503B2A),
                      Color(0x99503B2A),
                      Color(0x66503B2A),
                      Color(0x00604A35),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaperPage extends StatelessWidget {
  const _PaperPage({required this.edge, required this.child});

  final Alignment edge;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: edge,
        end: edge == Alignment.centerRight
            ? Alignment.centerLeft
            : Alignment.centerRight,
        colors: const [Color(0xFFE2CFA7), Color(0xFFFFF2D0)],
      ),
    ),
    child: CustomPaint(
      painter: const _BookPaperPainter(),
      child: Padding(padding: const EdgeInsets.all(10), child: child),
    ),
  );
}

class _BookCountryHeader extends StatelessWidget {
  const _BookCountryHeader({
    required this.country,
    required this.chapter,
    required this.pasted,
    required this.total,
    required this.fraction,
  });

  final AlbumCountry country;
  final int chapter;
  final int pasted;
  final int total;
  final double fraction;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 72,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E0),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF9A7047)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x334C3120),
                blurRadius: 4,
                offset: Offset(1, 2),
              ),
            ],
          ),
          child: Text(country.flag, style: const TextStyle(fontSize: 31)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAPÍTULO ${chapter.toString().padLeft(2, '0')}  •  ${country.code}',
                style: const TextStyle(
                  color: Color(0xFF8C6546),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Text(
                country.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF3D2A20),
                  fontFamily: 'serif',
                  fontSize: 21,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFD6C197),
                        color: const Color(0xFF8B4F35),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '$pasted/$total',
                    style: const TextStyle(
                      color: Color(0xFF715641),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BookRightHeader extends StatelessWidget {
  const _BookRightHeader({
    required this.country,
    required this.sheetIndex,
    required this.sheetCount,
  });

  final AlbumCountry country;
  final int sheetIndex;
  final int sheetCount;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 72,
    child: Stack(
      children: [
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: 118,
            child: CustomPaint(painter: _CountryDoodlePainter(country.id)),
          ),
        ),
        Positioned.fill(
          right: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DIÁRIO VISUAL  •  FOLHA ${sheetIndex + 1}/$sheetCount',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8B5E3F),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                country.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF5E4938),
                  fontFamily: 'serif',
                  fontSize: 10,
                  height: 1.15,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BookCardsGrid extends StatelessWidget {
  const _BookCardsGrid({
    required this.cards,
    required this.stateFor,
    required this.onCard,
  });

  final List<CollectibleCard> cards;
  final AlbumCardState Function(CollectibleCard card) stateFor;
  final ValueChanged<CollectibleCard> onCard;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const rowSpacing = 5.0;
      final rowHeight = math.max(1.0, (constraints.maxHeight - rowSpacing) / 2);

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(2, 1, 2, 2),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisExtent: rowHeight,
          crossAxisSpacing: 5,
          mainAxisSpacing: rowSpacing,
        ),
        itemBuilder: (context, index) {
          final card = cards[index];
          return FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 180,
              height: 252,
              child: CollectibleCardTile(
                card: card,
                state: stateFor(card),
                onTap: () => onCard(card),
              ),
            ),
          );
        },
      );
    },
  );
}

class _BookPaperPainter extends CustomPainter {
  const _BookPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ruled = Paint()
      ..color = const Color(0x10936E48)
      ..strokeWidth = 1;
    for (double y = 29; y < size.height; y += 31) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), ruled);
    }
    final speck = Paint()..color = const Color(0x17785B3D);
    for (var index = 0; index < 22; index++) {
      final x = ((index * 79) % 233) / 233 * size.width;
      final y = ((index * 53) % 197) / 197 * size.height;
      canvas.drawCircle(Offset(x, y), index.isEven ? .7 : .4, speck);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CountryDoodlePainter extends CustomPainter {
  const _CountryDoodlePainter(this.countryId);

  final String countryId;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x70854E34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.scale(size.width / 120, size.height / 70);
    switch (countryId) {
      case 'france':
        _eiffel(canvas, paint);
      case 'brazil':
        _christ(canvas, paint);
      case 'japan':
        _torii(canvas, paint);
      case 'egypt':
        _pyramids(canvas, paint);
      case 'italy':
        _colosseum(canvas, paint);
      case 'united_kingdom':
        _clockTower(canvas, paint);
      case 'china':
        _pagoda(canvas, paint);
      case 'india':
        _tajMahal(canvas, paint);
      case 'greece':
        _temple(canvas, paint);
      case 'mexico':
        _stepPyramid(canvas, paint);
      case 'canada':
        _mapleLeaf(canvas, paint);
      default:
        _compass(canvas, paint);
    }
    canvas.restore();
  }

  void _eiffel(Canvas canvas, Paint paint) {
    final tower = Path()
      ..moveTo(60, 4)
      ..lineTo(38, 65)
      ..moveTo(60, 4)
      ..lineTo(82, 65)
      ..moveTo(46, 43)
      ..lineTo(74, 43)
      ..moveTo(42, 55)
      ..lineTo(78, 55)
      ..moveTo(37, 65)
      ..quadraticBezierTo(60, 48, 83, 65)
      ..moveTo(52, 25)
      ..lineTo(68, 25);
    canvas.drawPath(tower, paint);
  }

  void _christ(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(60, 12), 6, paint);
    canvas.drawLine(const Offset(60, 18), const Offset(60, 56), paint);
    canvas.drawLine(const Offset(23, 27), const Offset(97, 27), paint);
    canvas.drawLine(const Offset(60, 56), const Offset(45, 66), paint);
    canvas.drawLine(const Offset(60, 56), const Offset(75, 66), paint);
    canvas.drawArc(
      const Rect.fromLTWH(34, 54, 52, 15),
      math.pi,
      math.pi,
      false,
      paint,
    );
  }

  void _torii(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(25, 14), const Offset(95, 14), paint);
    canvas.drawLine(const Offset(31, 8), const Offset(89, 8), paint);
    canvas.drawLine(const Offset(39, 14), const Offset(39, 64), paint);
    canvas.drawLine(const Offset(81, 14), const Offset(81, 64), paint);
    canvas.drawLine(const Offset(34, 26), const Offset(86, 26), paint);
    canvas.drawArc(
      const Rect.fromLTWH(73, 34, 40, 34),
      math.pi,
      math.pi,
      false,
      paint,
    );
  }

  void _pyramids(Canvas canvas, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(7, 64)
        ..lineTo(42, 17)
        ..lineTo(77, 64)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(55, 64)
        ..lineTo(82, 31)
        ..lineTo(111, 64)
        ..close(),
      paint,
    );
  }

  void _colosseum(Canvas canvas, Paint paint) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(13, 18, 94, 47),
      const Radius.circular(18),
    );
    canvas.drawRRect(body, paint);
    for (var row = 0; row < 2; row++) {
      for (var column = 0; column < 6; column++) {
        canvas.drawArc(
          Rect.fromLTWH(20 + column * 14, 28 + row * 17, 8, 11),
          math.pi,
          math.pi,
          false,
          paint,
        );
      }
    }
    canvas.drawLine(const Offset(15, 45), const Offset(105, 45), paint);
  }

  void _clockTower(Canvas canvas, Paint paint) {
    canvas.drawRect(const Rect.fromLTWH(42, 14, 36, 51), paint);
    canvas.drawPath(
      Path()
        ..moveTo(40, 14)
        ..lineTo(60, 2)
        ..lineTo(80, 14),
      paint,
    );
    canvas.drawCircle(const Offset(60, 27), 9, paint);
    canvas.drawLine(const Offset(60, 27), const Offset(60, 20), paint);
    canvas.drawLine(const Offset(60, 27), const Offset(66, 30), paint);
  }

  void _pagoda(Canvas canvas, Paint paint) {
    for (var level = 0; level < 3; level++) {
      final y = 22.0 + level * 16;
      final inset = level * 6.0;
      canvas.drawLine(Offset(21 + inset, y), Offset(99 - inset, y), paint);
      canvas.drawLine(
        Offset(28 + inset, y - 7),
        Offset(92 - inset, y - 7),
        paint,
      );
      canvas.drawLine(Offset(28 + inset, y - 7), Offset(21 + inset, y), paint);
      canvas.drawLine(Offset(92 - inset, y - 7), Offset(99 - inset, y), paint);
    }
    canvas.drawLine(const Offset(60, 5), const Offset(60, 65), paint);
  }

  void _tajMahal(Canvas canvas, Paint paint) {
    canvas.drawRect(const Rect.fromLTWH(28, 34, 64, 31), paint);
    canvas.drawArc(
      const Rect.fromLTWH(39, 8, 42, 48),
      math.pi,
      math.pi,
      false,
      paint,
    );
    canvas.drawLine(const Offset(60, 8), const Offset(60, 2), paint);
    for (final x in [18.0, 102.0]) {
      canvas.drawLine(Offset(x, 19), Offset(x, 65), paint);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(x, 17), width: 12, height: 13),
        math.pi,
        math.pi,
        false,
        paint,
      );
    }
  }

  void _temple(Canvas canvas, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(15, 22)
        ..lineTo(60, 5)
        ..lineTo(105, 22)
        ..close(),
      paint,
    );
    canvas.drawLine(const Offset(12, 24), const Offset(108, 24), paint);
    for (final x in [25.0, 43.0, 61.0, 79.0, 97.0]) {
      canvas.drawLine(Offset(x, 26), Offset(x, 60), paint);
    }
    canvas.drawLine(const Offset(10, 64), const Offset(110, 64), paint);
  }

  void _stepPyramid(Canvas canvas, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(13, 64)
        ..lineTo(13, 56)
        ..lineTo(27, 56)
        ..lineTo(27, 46)
        ..lineTo(40, 46)
        ..lineTo(40, 36)
        ..lineTo(53, 36)
        ..lineTo(53, 25)
        ..lineTo(67, 25)
        ..lineTo(67, 36)
        ..lineTo(80, 36)
        ..lineTo(80, 46)
        ..lineTo(93, 46)
        ..lineTo(93, 56)
        ..lineTo(107, 56)
        ..lineTo(107, 64)
        ..close(),
      paint,
    );
  }

  void _mapleLeaf(Canvas canvas, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(60, 65)
        ..lineTo(60, 49)
        ..lineTo(43, 55)
        ..lineTo(47, 43)
        ..lineTo(30, 38)
        ..lineTo(39, 30)
        ..lineTo(34, 14)
        ..lineTo(51, 23)
        ..lineTo(60, 5)
        ..lineTo(69, 23)
        ..lineTo(86, 14)
        ..lineTo(81, 30)
        ..lineTo(90, 38)
        ..lineTo(73, 43)
        ..lineTo(77, 55)
        ..lineTo(60, 49),
      paint,
    );
  }

  void _compass(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(60, 35), 27, paint);
    canvas.drawCircle(const Offset(60, 35), 4, paint);
    canvas.drawPath(
      Path()
        ..moveTo(60, 7)
        ..lineTo(67, 35)
        ..lineTo(60, 63)
        ..lineTo(53, 35)
        ..close(),
      paint,
    );
    canvas.drawLine(const Offset(27, 35), const Offset(93, 35), paint);
  }

  @override
  bool shouldRepaint(covariant _CountryDoodlePainter oldDelegate) =>
      oldDelegate.countryId != countryId;
}
