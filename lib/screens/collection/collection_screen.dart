import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/card_labels.dart';
import '../../data/cards_data.dart';
import '../../models/album_country.dart';
import '../../models/collectible_card.dart';
import '../../widgets/collectible_card/collectible_card_tile.dart';
import '../album/card_detail_screen.dart';
import 'debug_card_grant_sheet.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String country = '';
  String continent = '';
  String rarity = '';
  String category = '';
  bool duplicatesOnly = false;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final cards = controller.availableCollectionCards
        .where((card) {
          final cardCountry = CardCatalog.countryById(card.countryId);
          return (country.isEmpty || card.countryId == country) &&
              (continent.isEmpty || cardCountry?.continent == continent) &&
              (rarity.isEmpty || card.rarity == rarity) &&
              (category.isEmpty || card.category == category) &&
              (!duplicatesOnly ||
                  controller.inventoryFor(card.id).quantity > 1);
        })
        .toList(growable: false);
    final totalCopies = cards.fold<int>(
      0,
      (sum, card) => sum + controller.inventoryFor(card.id).quantity,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coleção'),
        actions: [
          if (AppScope.of(context).debugEconomyEnabled)
            IconButton(
              tooltip: 'Conceder cartas (debug)',
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const DebugCardGrantSheet(),
              ),
              icon: const Icon(Icons.bug_report_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          _FilterPanel(
            country: country,
            continent: continent,
            rarity: rarity,
            category: category,
            duplicatesOnly: duplicatesOnly,
            onCountry: (value) => setState(() => country = value),
            onContinent: (value) => setState(() => continent = value),
            onRarity: (value) => setState(() => rarity = value),
            onCategory: (value) => setState(() => category = value),
            onDuplicates: (value) => setState(() => duplicatesOnly = value),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${cards.length} carta${cards.length == 1 ? '' : 's'} diferente${cards.length == 1 ? '' : 's'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$totalCopies ${totalCopies == 1 ? 'cópia' : 'cópias'}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: cards.isEmpty
                ? const _EmptyCollection()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: collectibleCardAspectRatio,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final inventory = controller.inventoryFor(card.id);
                      return CollectibleCardTile(
                        card: card,
                        state: inventory.pastedInAlbum
                            ? AlbumCardState.pasted
                            : AlbumCardState.inCollection,
                        quantity: inventory.quantity,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => CardDetailScreen(card: card),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.country,
    required this.continent,
    required this.rarity,
    required this.category,
    required this.duplicatesOnly,
    required this.onCountry,
    required this.onContinent,
    required this.onRarity,
    required this.onCategory,
    required this.onDuplicates,
  });

  final String country;
  final String continent;
  final String rarity;
  final String category;
  final bool duplicatesOnly;
  final ValueChanged<String> onCountry;
  final ValueChanged<String> onContinent;
  final ValueChanged<String> onRarity;
  final ValueChanged<String> onCategory;
  final ValueChanged<bool> onDuplicates;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: const EdgeInsets.symmetric(horizontal: 20),
    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    leading: const Icon(Icons.tune_rounded),
    title: const Text('Filtros'),
    children: [
      Row(
        children: [
          Expanded(
            child: _FilterDropdown(
              label: 'País',
              value: country,
              items: {
                '': 'Todos',
                for (final item in albumCountries) item.id: item.name,
              },
              onChanged: onCountry,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilterDropdown(
              label: 'Continente',
              value: continent,
              items: {
                '': 'Todos',
                for (final item in WorldContinent.all)
                  item: continentLabel(item),
              },
              onChanged: onContinent,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _FilterDropdown(
              label: 'Raridade',
              value: rarity,
              items: {
                '': 'Todas',
                for (final item in CardRarity.initialValues)
                  item: rarityLabel(item),
              },
              onChanged: onRarity,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilterDropdown(
              label: 'Categoria',
              value: category,
              items: {
                '': 'Todas',
                for (final item
                    in collectibleCards.map((card) => card.category).toSet())
                  item: categoryLabel(item),
              },
              onChanged: onCategory,
            ),
          ),
        ],
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Mostrar somente duplicadas'),
        value: duplicatesOnly,
        onChanged: onDuplicates,
      ),
    ],
  );
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: items.entries
        .map(
          (entry) => DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(growable: false),
    onChanged: (value) => onChanged(value ?? ''),
  );
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style_outlined, size: 58, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma carta disponível com estes filtros.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
          if (AppScope.of(context).debugEconomyEnabled) ...[
            const SizedBox(height: 8),
            const Text(
              'Use o botão de debug no topo para conceder cartas de teste.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ],
      ),
    ),
  );
}
