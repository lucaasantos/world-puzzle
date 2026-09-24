import 'package:flutter/material.dart';
import '../online/player_screens.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/card_labels.dart';
import '../../data/cards_data.dart';
import '../../models/collectible_card.dart';
import '../../widgets/collectible_card/card_artwork.dart';
import '../../widgets/collectible_card/collectible_card_tile.dart';

class CardDetailScreen extends StatelessWidget {
  const CardDetailScreen({required this.card, super.key});

  final CollectibleCard card;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final inventory = controller.inventoryFor(card.id);
    final country = CardCatalog.countryById(card.countryId);
    final canPaste = inventory.quantity > 0 && !inventory.pastedInAlbum;
    final cardState = inventory.pastedInAlbum
        ? AlbumCardState.pasted
        : inventory.quantity > 0
        ? AlbumCardState.inCollection
        : AlbumCardState.notOwned;
    return Scaffold(
      appBar: AppBar(title: Text(card.catalogNumber)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: AspectRatio(
                aspectRatio: collectibleCardAspectRatio,
                child: CollectibleCardView(
                  card: card,
                  state: cardState,
                  quantity: inventory.quantity > 0 ? inventory.quantity : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.localizedName ?? card.name,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${country?.flag ?? ''} ${country?.name ?? card.countryId}',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              _AlbumStatus(pasted: inventory.pastedInAlbum),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.diamond_outlined,
                label: rarityLabel(card.rarity),
                color: rarityAccent(card.rarity),
              ),
              _InfoChip(
                icon: Icons.category_outlined,
                label: categoryLabel(card.category),
              ),
              _InfoChip(
                icon: Icons.style_rounded,
                label: inventory.quantity == 1
                    ? '1 cópia disponível'
                    : '${inventory.quantity} cópias disponíveis',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            card.description,
            style: const TextStyle(color: Colors.white70, height: 1.55),
          ),
          const SizedBox(height: 28),
          if (canPaste)
            FilledButton.icon(
              onPressed: () => _confirmPaste(context),
              icon: const Icon(Icons.auto_stories_rounded),
              label: const Text('COLAR NO ÁLBUM'),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    inventory.pastedInAlbum
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    color: inventory.pastedInAlbum
                        ? AppTheme.primary
                        : Colors.white38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      inventory.pastedInAlbum
                          ? 'Esta carta já está colada no álbum.'
                          : 'Obtenha uma cópia para colar esta carta.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmPaste(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Colar esta carta no álbum?'),
        content: const Text(
          'Uma cópia será removida da sua coleção e adicionada permanentemente ao álbum.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Colar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    PasteCardResult result;
    try {
      result = await AppScope.of(
        context,
        listen: false,
      ).pasteCardInAlbum(card.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(onlineError(error))));
      }
      return;
    }
    if (!context.mounted) return;
    final message = switch (result) {
      PasteCardResult.success => '${card.name} foi colada no álbum.',
      PasteCardResult.alreadyPasted => 'Esta carta já está no álbum.',
      PasteCardResult.notOwned => 'Nenhuma cópia disponível na coleção.',
      PasteCardResult.cardNotFound => 'Esta carta não está disponível.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AlbumStatus extends StatelessWidget {
  const _AlbumStatus({required this.pasted});
  final bool pasted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: pasted
          ? AppTheme.primary.withValues(alpha: .15)
          : Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      pasted ? 'NO ÁLBUM' : 'NÃO COLADA',
      style: TextStyle(
        color: pasted ? AppTheme.primary : Colors.white54,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 17, color: color),
    label: Text(label),
    side: BorderSide(color: (color ?? Colors.white).withValues(alpha: .18)),
  );
}
