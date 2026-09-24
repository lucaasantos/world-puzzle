import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/card_labels.dart';
import '../../models/card_pack.dart';
import '../../models/collectible_card.dart';
import '../../widgets/card_pack/pack_artwork.dart';
import '../../widgets/collectible_card/card_artwork.dart';
import '../../widgets/collectible_card/collectible_card_frame.dart';
import '../../widgets/collectible_card/collectible_card_tile.dart';
import '../collection/collection_screen.dart';

int _rarityOrder(String rarity) {
  final index = CardRarity.initialValues.indexOf(rarity);
  return index < 0 ? CardRarity.initialValues.length : index;
}

class PackOpeningScreen extends StatefulWidget {
  const PackOpeningScreen({
    required this.pack,
    required this.result,
    super.key,
  });

  final PackDefinition pack;
  final PackOpeningResult result;

  @override
  State<PackOpeningScreen> createState() => _PackOpeningScreenState();
}

class _PackOpeningScreenState extends State<PackOpeningScreen>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  int? outgoingIndex;
  bool summary = false;
  bool precached = false;
  bool transitioning = false;
  late final AnimationController slideController;
  late final List<PackCardReward> cards;

  PackCardReward get current => cards[currentIndex];
  int get deckFrontIndex =>
      outgoingIndex == null ? currentIndex : currentIndex + 1;

  @override
  void initState() {
    super.initState();
    final indexedCards = widget.result.cards.asMap().entries.toList()
      ..sort((a, b) {
        final rarityComparison = _rarityOrder(
          a.value.card.rarity,
        ).compareTo(_rarityOrder(b.value.card.rarity));
        return rarityComparison != 0
            ? rarityComparison
            : a.key.compareTo(b.key);
      });
    cards = [for (final entry in indexedCards) entry.value];
    slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    slideController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (precached) return;
    precached = true;
    for (final reward in cards) {
      if (!reward.card.isPlaceholderImage) {
        precacheImage(AssetImage(reward.card.imagePath), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.pack.name),
      automaticallyImplyLeading: summary,
    ),
    body: AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: summary ? _buildSummary() : _buildReveal(),
    ),
  );

  Widget _buildReveal() => ListView(
    key: const ValueKey('reveal'),
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
    children: [
      Text(
        '${currentIndex + 1} / ${cards.length}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 285),
          child: AspectRatio(
            aspectRatio: collectibleCardAspectRatio,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (details) {
                if (!transitioning && (details.primaryVelocity ?? 0) < -250) {
                  _advance();
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (deckFrontIndex + 2 < cards.length)
                    Positioned.fill(
                      child: Transform.translate(
                        offset: const Offset(20, 12),
                        child: Transform.rotate(
                          angle: .035,
                          child: _DeckPreview(
                            key: ValueKey('deck-preview-${deckFrontIndex + 2}'),
                            accent: rarityAccent(
                              cards[deckFrontIndex + 2].card.rarity,
                            ),
                            depth: 2,
                          ),
                        ),
                      ),
                    ),
                  if (deckFrontIndex + 1 < cards.length)
                    Positioned.fill(
                      child: Transform.translate(
                        offset: const Offset(11, 6),
                        child: Transform.rotate(
                          angle: .018,
                          child: _DeckPreview(
                            key: ValueKey('deck-preview-${deckFrontIndex + 1}'),
                            accent: rarityAccent(
                              cards[deckFrontIndex + 1].card.rarity,
                            ),
                            depth: 1,
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(child: _buildCardStack()),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      _RewardLabel(reward: current),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: transitioning ? null : _advance,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(
          currentIndex == cards.length - 1 ? 'VER RESUMO' : 'PRÓXIMA CARTA',
        ),
      ),
    ],
  );

  Widget _cardView(int index, {required Key key}) {
    final reward = cards[index];
    return Material(
      key: key,
      type: MaterialType.transparency,
      child: CollectibleCardView(
        card: reward.card,
        state: AlbumCardState.inCollection,
      ),
    );
  }

  Widget _buildCardStack() {
    final leaving = outgoingIndex;
    if (leaving == null) {
      return _cardView(currentIndex, key: ValueKey('card-$currentIndex'));
    }

    final nextCard = _cardView(
      leaving + 1,
      key: ValueKey('card-${leaving + 1}'),
    );
    final outgoingCard = _cardView(
      leaving,
      key: ValueKey('outgoing-card-$leaving'),
    );
    return AnimatedBuilder(
      animation: slideController,
      builder: (context, child) {
        final progress = Curves.easeInCubic.transform(slideController.value);
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            ClipRect(clipper: _RightRevealClipper(progress), child: nextCard),
            Transform.translate(
              offset: Offset(-340 * progress, 18 * progress),
              child: Transform.rotate(
                angle: -.11 * progress,
                alignment: Alignment.bottomCenter,
                child: outgoingCard,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _advance() async {
    if (transitioning) return;
    if (currentIndex == cards.length - 1) {
      setState(() => summary = true);
      return;
    }
    final leaving = currentIndex;
    setState(() {
      transitioning = true;
      outgoingIndex = leaving;
    });
    await slideController.forward(from: 0);
    if (!mounted) return;
    setState(() {
      currentIndex = leaving + 1;
      outgoingIndex = null;
      transitioning = false;
    });
    slideController.reset();
  }

  Widget _buildSummary() => ListView(
    key: const ValueKey('summary'),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
    children: [
      const Icon(Icons.celebration_rounded, size: 58, color: AppTheme.primary),
      const SizedBox(height: 12),
      const Text(
        'PACOTE ABERTO!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 4),
      Text(
        widget.pack.name,
        textAlign: TextAlign.center,
        style: TextStyle(color: packAccent(widget.pack.id)),
      ),
      const SizedBox(height: 22),
      for (final reward in cards) _SummaryRow(reward: reward),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('CONTINUAR'),
      ),
      TextButton.icon(
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(builder: (_) => const CollectionScreen()),
        ),
        icon: const Icon(Icons.style_rounded),
        label: const Text('VER COLEÇÃO'),
      ),
    ],
  );
}

class _DeckPreview extends StatelessWidget {
  const _DeckPreview({required this.accent, required this.depth, super.key});

  final Color accent;
  final int depth;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Color.lerp(
        const Color(0xFF182125),
        accent,
        depth == 1 ? .12 : .06,
      ),
      borderRadius: BorderRadius.circular(collectibleCardCornerRadius),
      border: Border.all(
        color: accent.withValues(alpha: depth == 1 ? .72 : .38),
        width: depth == 1 ? 2 : 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .28),
          blurRadius: 12,
          offset: const Offset(5, 8),
        ),
      ],
    ),
  );
}

class _RightRevealClipper extends CustomClipper<Rect> {
  const _RightRevealClipper(this.progress);

  final double progress;

  @override
  Rect getClip(Size size) {
    final revealedWidth = (340 * progress).clamp(0.0, size.width);
    return Rect.fromLTWH(
      size.width - revealedWidth,
      0,
      revealedWidth,
      size.height,
    );
  }

  @override
  bool shouldReclip(_RightRevealClipper oldClipper) =>
      oldClipper.progress != progress;
}

class _RewardLabel extends StatelessWidget {
  const _RewardLabel({required this.reward});
  final PackCardReward reward;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (reward.isNew) ...[
        const Text(
          'NOVA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF7DDFC8),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
      const SizedBox(height: 4),
      Text(reward.card.name, style: const TextStyle(color: Colors.white70)),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.reward});
  final PackCardReward reward;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: rarityAccent(reward.card.rarity).withValues(alpha: .22),
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: rarityAccent(
            reward.card.rarity,
          ).withValues(alpha: .14),
          child: Icon(
            reward.card.rarity == CardRarity.legendary
                ? Icons.auto_awesome_rounded
                : Icons.style_rounded,
            color: rarityAccent(reward.card.rarity),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reward.card.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                rarityLabel(reward.card.rarity),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
