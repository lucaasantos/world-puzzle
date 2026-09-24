import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../data/cards_data.dart';

class DebugCardGrantSheet extends StatefulWidget {
  const DebugCardGrantSheet({super.key});

  @override
  State<DebugCardGrantSheet> createState() => _DebugCardGrantSheetState();
}

class _DebugCardGrantSheetState extends State<DebugCardGrantSheet> {
  String selectedCardId = collectibleCards.first.id;
  bool working = false;

  @override
  Widget build(BuildContext context) {
    if (!AppScope.of(context).debugEconomyEnabled) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ferramentas de teste',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Disponível somente em builds de debug.',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: selectedCardId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Carta'),
              items: collectibleCards
                  .map(
                    (card) => DropdownMenuItem(
                      value: card.id,
                      child: Text(
                        '${card.catalogNumber}  ${card.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: working
                  ? null
                  : (value) => setState(
                      () => selectedCardId = value ?? selectedCardId,
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: working ? null : () => _grant(1),
                    child: const Text('Conceder +1'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: working ? null : () => _grant(2),
                    child: const Text('Conceder +2'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: working ? null : _grantAll,
              icon: const Icon(Icons.playlist_add_rounded),
              label: const Text('Conceder 1 de cada carta'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _grant(int quantity) async {
    setState(() => working = true);
    await AppScope.of(
      context,
      listen: false,
    ).debugGrantCard(selectedCardId, quantity: quantity);
    if (!mounted) return;
    setState(() => working = false);
    _showMessage(
      '$quantity cópia${quantity == 1 ? '' : 's'} concedida${quantity == 1 ? '' : 's'}.',
    );
  }

  Future<void> _grantAll() async {
    setState(() => working = true);
    await AppScope.of(context, listen: false).debugGrantAllCards();
    if (!mounted) return;
    setState(() => working = false);
    _showMessage('Uma cópia de cada carta foi concedida.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
