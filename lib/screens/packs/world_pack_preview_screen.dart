import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/card_pack.dart';
import '../../widgets/card_pack/pack_artwork.dart';
import 'pack_opening_screen.dart';
import '../online/player_screens.dart';

class PackPreviewScreen extends StatefulWidget {
  const PackPreviewScreen({required this.pack, super.key});

  final PackDefinition pack;

  @override
  State<PackPreviewScreen> createState() => _PackPreviewScreenState();
}

class _PackPreviewScreenState extends State<PackPreviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tearController;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _tearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
  }

  @override
  void dispose() {
    _tearController.dispose();
    super.dispose();
  }

  Future<void> _openPack() async {
    if (_opening) return;
    setState(() => _opening = true);
    PackOpenOutcome outcome;
    try {
      outcome = await AppScope.of(
        context,
        listen: false,
      ).openPack(widget.pack.id);
    } catch (error) {
      if (mounted) {
        setState(() => _opening = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(onlineError(error))));
      }
      return;
    }
    if (!mounted) return;
    if (outcome.status != PackOpenStatus.success || outcome.result == null) {
      setState(() => _opening = false);
      final message = switch (outcome.status) {
        PackOpenStatus.notOwned => 'Você não possui este pacote.',
        PackOpenStatus.noCardsAvailable => 'Nenhuma carta válida disponível.',
        _ => 'Este pacote não está disponível.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    await _tearController.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, animation, secondaryAnimation) =>
            PackOpeningScreen(pack: widget.pack, result: outcome.result!),
        transitionsBuilder: (_, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final artworkPath = widget.pack.artworkPath;
    final primary = packColors(widget.pack.id).first;
    final foreground = packColors(widget.pack.id).last;
    return PopScope(
      canPop: !_opening,
      child: Scaffold(
        key: ValueKey('pack-preview-${widget.pack.id}'),
        backgroundColor: const Color(0xFFF7F9FC),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final packWidth = math.min(
                constraints.maxWidth * .84,
                constraints.maxHeight * .48,
              );
              return Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: packWidth,
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: artworkPath == null
                                ? const SizedBox.shrink()
                                : Transform.rotate(
                                    angle: -.035,
                                    child: _TearablePack(
                                      artworkPath: artworkPath,
                                      animation: _tearController,
                                      packId: widget.pack.id,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _opening
                          ? SizedBox(
                              key: ValueKey('opening-${widget.pack.id}'),
                              height: 52,
                              child: Center(
                                child: Text(
                                  'ABRINDO...',
                                  style: TextStyle(
                                    color: foreground,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              key: ValueKey('pack-actions-${widget.pack.id}'),
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    key: ValueKey(
                                      'open-pack-button-${widget.pack.id}',
                                    ),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                      backgroundColor: primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _openPack,
                                    child: const Text('ABRIR'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    key: ValueKey(
                                      'back-pack-button-${widget.pack.id}',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                      foregroundColor: foreground,
                                      side: BorderSide(color: foreground),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('VOLTAR'),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TearablePack extends StatelessWidget {
  const _TearablePack({
    required this.artworkPath,
    required this.animation,
    required this.packId,
  });

  final String artworkPath;
  final Animation<double> animation;
  final String packId;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final tear = Curves.easeOutCubic.transform(
        const Interval(0, .43).transform(animation.value),
      );
      final drop = Curves.easeInCubic.transform(
        const Interval(.28, 1).transform(animation.value),
      );
      final bodyOpacity = 1 - const Interval(.72, 1).transform(animation.value);
      final topOpacity =
          1 - const Interval(.62, .95).transform(animation.value);

      return Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Transform.translate(
            offset: Offset(0, 440 * drop),
            child: Opacity(
              opacity: bodyOpacity.clamp(0, 1),
              child: ClipPath(
                key: ValueKey('pack-body-piece-$packId'),
                clipper: const _PackPieceClipper(topPiece: false),
                child: ClipPath(
                  clipper: const PackSilhouetteClipper(),
                  child: Image.asset(artworkPath, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(68 * tear, -82 * tear),
            child: Transform.rotate(
              angle: .16 * tear,
              alignment: Alignment.bottomRight,
              child: Opacity(
                opacity: topOpacity.clamp(0, 1),
                child: ClipPath(
                  key: ValueKey('pack-top-piece-$packId'),
                  clipper: const _PackPieceClipper(topPiece: true),
                  child: ClipPath(
                    clipper: const PackSilhouetteClipper(),
                    child: Image.asset(artworkPath, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _PackPieceClipper extends CustomClipper<Path> {
  const _PackPieceClipper({required this.topPiece});

  final bool topPiece;

  List<Offset> _tearPoints(Size size) {
    final baseline = size.height * .115;
    return [
      for (var index = 0; index <= 14; index++)
        Offset(size.width * index / 14, baseline + (index.isEven ? -3.5 : 3.5)),
    ];
  }

  @override
  Path getClip(Size size) {
    final points = _tearPoints(size);
    final path = Path();
    if (topPiece) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0);
      for (final point in points.reversed) {
        path.lineTo(point.dx, point.dy);
      }
    } else {
      path.moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_PackPieceClipper oldClipper) => false;
}
